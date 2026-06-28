const http = require('node:http');
const net = require('node:net');
const path = require('node:path');
const { spawn } = require('node:child_process');

const rootDir = path.resolve(__dirname, '..');
const backendDir = path.join(rootDir, 'backend');
const landingDir = path.join(rootDir, 'landing-page');

const publicPort = portFromEnv('PORT', 3000);
const backendPort = publicPort + 1;
const nextPort = publicPort + 2;

const apiBaseUrl = requiredEnv('API_BASE_URL');
const backendOrigin = `http://127.0.0.1:${backendPort}`;
const nextOrigin = `http://127.0.0.1:${nextPort}`;
const publicOrigin = originFromApiBaseUrl(apiBaseUrl);

const children = [
  startProcess('backend', 'node', ['dist/main.js'], {
    cwd: backendDir,
    env: {
      ...process.env,
      PORT: String(backendPort),
      NODE_ENV: process.env.NODE_ENV || 'production',
    },
  }),
  startProcess(
    'landing',
    path.join(landingDir, 'node_modules', '.bin', 'next'),
    ['start', '-H', '127.0.0.1', '-p', String(nextPort)],
    {
      cwd: landingDir,
      env: {
        ...process.env,
        PORT: String(nextPort),
        NODE_ENV: process.env.NODE_ENV || 'production',
        API_BASE_URL: apiBaseUrl,
      },
    },
  ),
];

const server = http.createServer((request, response) => {
  proxyHttp(request, response, routeFor(request.url));
});

server.on('upgrade', (request, socket, head) => {
  proxyUpgrade(request, socket, head, routeFor(request.url));
});

server.listen(publicPort, '0.0.0.0', () => {
  console.log(
    `[router] listening on ${publicPort}; /api, /app and /socket.io -> backend; everything else -> landing`,
  );
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    server.close();
    for (const child of children) child.kill(signal);
    setTimeout(() => process.exit(0), 5000).unref();
  });
}

function routeFor(url = '/') {
  const pathName = url.split('?')[0] || '/';
  if (
    pathName === '/app' ||
    pathName.startsWith('/app/') ||
    pathName === '/api' ||
    pathName.startsWith('/api/') ||
    pathName === '/socket.io' ||
    pathName.startsWith('/socket.io/')
  ) {
    return { origin: backendOrigin, port: backendPort };
  }
  return { origin: nextOrigin, port: nextPort };
}

function proxyHttp(request, response, target) {
  const headers = forwardedHeaders(request.headers);
  const upstream = http.request(
    {
      hostname: '127.0.0.1',
      port: target.port,
      method: request.method,
      path: request.url,
      headers,
    },
    (upstreamResponse) => {
      response.writeHead(
        upstreamResponse.statusCode || 502,
        upstreamResponse.headers,
      );
      upstreamResponse.pipe(response);
    },
  );

  upstream.on('error', (error) => {
    console.error(`[router] proxy error for ${request.url}:`, error.message);
    if (!response.headersSent) {
      response.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    }
    response.end('Upstream unavailable');
  });

  request.pipe(upstream);
}

function proxyUpgrade(request, socket, head, target) {
  const upstream = net.connect(target.port, '127.0.0.1', () => {
    upstream.write(
      `${request.method} ${request.url} HTTP/${request.httpVersion}\r\n`,
    );
    const headers = forwardedHeaders(request.headers);
    for (const [name, value] of Object.entries(headers)) {
      if (Array.isArray(value)) {
        for (const item of value) upstream.write(`${name}: ${item}\r\n`);
      } else if (value !== undefined) {
        upstream.write(`${name}: ${value}\r\n`);
      }
    }
    upstream.write('\r\n');
    if (head?.length) upstream.write(head);
    socket.pipe(upstream).pipe(socket);
  });

  upstream.on('error', (error) => {
    console.error(`[router] upgrade error for ${request.url}:`, error.message);
    socket.destroy();
  });
}

function forwardedHeaders(headers) {
  const forwarded = { ...headers };
  forwarded['x-forwarded-host'] = headers.host || '';
  forwarded['x-forwarded-proto'] =
    headers['x-forwarded-proto'] ||
    (publicOrigin.startsWith('https') ? 'https' : 'http');
  forwarded['x-forwarded-port'] = String(publicPort);
  return forwarded;
}

function startProcess(name, command, args, options) {
  const child = spawn(command, args, {
    ...options,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout.on('data', (chunk) => prefixOutput(name, chunk, false));
  child.stderr.on('data', (chunk) => prefixOutput(name, chunk, true));
  child.on('exit', (code, signal) => {
    if (signal) {
      console.error(`[${name}] stopped by ${signal}`);
    } else {
      console.error(`[${name}] exited with code ${code}`);
    }
    process.exit(code || 1);
  });
  return child;
}

function prefixOutput(name, chunk, isError) {
  const stream = isError ? process.stderr : process.stdout;
  for (const line of chunk.toString().split(/\r?\n/)) {
    if (line) stream.write(`[${name}] ${line}\n`);
  }
}

function requiredEnv(name) {
  const value = process.env[name]?.trim().replace(/\/+$/, '');
  if (!value) throw new Error(`${name} is required.`);
  return value;
}

function originFromApiBaseUrl(value) {
  if (!value.endsWith('/api')) {
    throw new Error('API_BASE_URL must end with /api.');
  }
  return value.slice(0, -4);
}

function portFromEnv(name, fallback) {
  const value = Number(process.env[name] || fallback);
  if (!Number.isFinite(value) || value <= 0) return fallback;
  return value;
}
