# Deploy no Cloudflare Pages e Railway

Esta configuração mantém um único endereço público:

- `https://seu-dominio.com/pt`, `/en` e `/es`: SEO renderizado pelo NestJS.
- `https://seu-dominio.com/app/`: Flutter Web estático no Cloudflare Pages.
- `https://seu-dominio.com/api/`: API NestJS no Railway.
- `https://seu-dominio.com/socket.io/`: Socket.IO no Railway.

O Pages Worker encaminha as rotas dinâmicas. O endereço público nativo do
Railway é usado apenas como origem e não deve ser divulgado no aplicativo.

## 1. Criar o projeto Railway

Crie um projeto e adicione, no mesmo ambiente e região:

1. Um serviço a partir deste repositório GitHub, usando a raiz do repositório.
   O Railway encontrará `railway.toml` e `Dockerfile.backend`.
2. Um MongoDB pelo template oficial do Railway.
3. Um Redis pelo template oficial do Railway.
4. Um Storage Bucket chamado `Bucket`.

No Redis, confirme que existe um volume em `/data` e que AOF está habilitado.
A fila de pagamentos não pode desaparecer após um restart. MongoDB e Redis são
serviços não gerenciados: configure backups e monitoração antes de vender o
produto.

Desative **Serverless** no backend. Conexões do BullMQ, MongoDB, Redis e
Socket.IO manteriam o serviço acordado de qualquer forma, e o primeiro request
após o sono pode falhar.

## 2. Variáveis do backend

Use `backend/.env.railway.example` como lista. Não envie o arquivo ao Railway;
adicione as variáveis na aba **Variables** do serviço.

As referências dependem dos nomes dos serviços. Com os nomes `MongoDB`, `Redis`
e `Bucket`, use:

```text
MONGO_URI=${{MongoDB.MONGO_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
BUCKET=${{Bucket.BUCKET}}
ENDPOINT=${{Bucket.ENDPOINT}}
REGION=${{Bucket.REGION}}
ACCESS_KEY_ID=${{Bucket.ACCESS_KEY_ID}}
SECRET_ACCESS_KEY=${{Bucket.SECRET_ACCESS_KEY}}
```

Gere valores independentes para JWT e CSRF:

```bash
openssl rand -base64 48
openssl rand -base64 48
```

Em **Networking**, gere um domínio Railway para o backend. Guarde o endereço,
por exemplo `https://my-family-production.up.railway.app`, e confira:

```text
https://my-family-production.up.railway.app/api/health
```

## 3. Criar o Cloudflare Pages

Crie um projeto Pages do tipo **Direct Upload**. O nome escolhido será usado na
variável GitHub `CLOUDFLARE_PAGES_PROJECT`.

Em **Settings > Variables and Secrets**, configure para Production e Preview:

```text
RAILWAY_BACKEND_URL=https://my-family-production.up.railway.app
```

Esse valor precisa apontar para o domínio nativo do Railway. Apontar para o
domínio do Pages criaria um loop de proxy.

## 4. Configurar o GitHub Actions

No repositório GitHub, crie os secrets:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`, com permissão para editar Cloudflare Pages

Crie as variables:

- `CLOUDFLARE_PAGES_PROJECT`
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_WEB_PUSH_CERTIFICATE_KEY`

As variáveis Firebase do cliente Web são identificadores públicos, mas devem ser
restritas ao domínio de produção no console Firebase.

Execute manualmente o workflow **Deploy Cloudflare Pages** na primeira vez. Os
próximos pushes na branch `main` que alterarem o Flutter ou o proxy publicarão
automaticamente.

## 5. Domínio e integrações

Adicione o domínio definitivo ao projeto Pages. Depois atualize no Railway:

```text
CORS_ORIGIN=https://seu-dominio.com
BILLING_SUCCESS_URL=https://seu-dominio.com/app/billing
BILLING_CANCEL_URL=https://seu-dominio.com/app/billing
PASSWORD_RESET_URL=https://seu-dominio.com/app/reset-password
```

Configure no Stripe o webhook:

```text
https://seu-dominio.com/api/billing/webhook
```

Selecione os eventos de checkout e assinatura usados pelo backend. Copie o
signing secret resultante para `STRIPE_WEBHOOK_SECRET` no Railway.

## 6. Mobile

Android e iOS não passam pelo build Web. Configure os builds mobile com:

```text
API_BASE_URL=https://seu-dominio.com/api
SOCKET_URL=https://seu-dominio.com
PUBLIC_WEB_URL=https://seu-dominio.com
```

No Web esses valores são inferidos automaticamente do domínio atual, evitando
um novo build quando o domínio do Pages for trocado.

## 7. Verificação antes de abrir vendas

1. Acesse `/pt`, `/en`, `/es`, `/robots.txt` e `/sitemap.xml`.
2. Teste `/app/demo`, cadastro, login e recuperação de senha.
3. Envie foto e vídeo, reinicie o backend e confirme que continuam disponíveis.
4. Faça um checkout de teste e confira o job `payments` no Redis.
5. Reinicie Redis e confirme que o job permanece por causa do AOF.
6. Teste chat e reconexão Socket.IO no Web e mobile.
7. Confirme backups restauráveis do MongoDB e do Bucket.

Na primeira inicialização após esta versão, o backend remove automaticamente os
índices globais antigos de palavras e configurações de jogos e cria os índices
únicos compostos por `tenantId`. Se houver dados duplicados dentro da mesma
família, o backend interromperá a inicialização para que os registros sejam
corrigidos, em vez de iniciar sem isolamento correto.
