# Landing Page

Landing pública em Next.js para SEO. Ela não contém planos nem política de
privacidade chumbados: ambos são carregados do backend NestJS.

## Ambiente

Copie `.env.example` para `.env.local` quando quiser rodar localmente.

```text
API_BASE_URL=http://localhost:3001/api
```

## Desenvolvimento

```bash
npm install
npm run dev -- -p 3458
```

## Build

```bash
npm run typecheck
npm run build
```

## Deploy

No Railway, esta aplicação roda dentro do serviço único da raiz do repositório.
O `Dockerfile.backend` builda a landing e o roteador interno envia `/`, `/pt`,
`/robots.txt` e `/sitemap.xml` para o Next.js.
