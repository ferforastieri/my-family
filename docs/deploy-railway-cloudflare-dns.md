# Deploy no Railway com Cloudflare DNS

Esta configuracao usa um unico endereco publico:

- `https://seu-dominio.com/pt`, `/en` e `/es`: paginas SEO renderizadas pelo NestJS.
- `https://seu-dominio.com/app/`: Flutter Web estatico servido pelo NestJS.
- `https://seu-dominio.com/api/`: API NestJS.
- `https://seu-dominio.com/socket.io/`: Socket.IO.

Cloudflare nao hospeda arquivos neste desenho. Ele fica apenas como DNS,
proxy, SSL, WAF e camada de seguranca na frente do Railway.

## 1. Criar o projeto Railway

Crie um projeto e adicione, no mesmo ambiente e regiao:

1. Um servico a partir deste repositorio GitHub, usando a raiz do repositorio.
   O Railway usa `railway.toml` e `Dockerfile.backend`.
2. Um MongoDB pelo template oficial do Railway ou uma URI externa, como Atlas.
3. Um Redis pelo template oficial do Railway.
4. Um Storage Bucket chamado `Bucket`.

Desative Serverless no backend. MongoDB, Redis, BullMQ e Socket.IO precisam de
um processo sempre ativo.

## 2. Variaveis do backend

Use `backend/.env.railway.example` como lista. Adicione os valores na aba
Variables do servico Railway.

Com servicos chamados `MongoDB`, `Redis` e `Bucket`, as referencias ficam:

```text
MONGO_URI=${{MongoDB.MONGO_URL}}/my-family?authSource=admin
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

As variaveis Firebase Web podem ficar no mesmo servico Railway. Elas sao usadas
como argumentos de build pelo Dockerfile quando existirem.

## 3. Domínio na Cloudflare

No Railway, adicione o dominio definitivo ao servico fullstack. O Railway vai
mostrar um CNAME e um TXT de verificacao.

Na Cloudflare:

1. Adicione o TXT exatamente como o Railway indicar.
2. Adicione o CNAME do dominio ou subdominio apontando para o alvo Railway.
3. Ative o proxy da Cloudflare no registro de trafego Web.
4. Configure SSL/TLS como Full.
5. Ative WAF, rate limiting e regras de seguranca conforme necessario.

Depois atualize no Railway:

```text
CORS_ORIGIN=https://seu-dominio.com
BILLING_SUCCESS_URL=https://seu-dominio.com/app/billing
BILLING_CANCEL_URL=https://seu-dominio.com/app/billing
PASSWORD_RESET_URL=https://seu-dominio.com/app/reset-password
```

Evite divulgar o dominio nativo `*.up.railway.app`. O dominio publico do
produto deve ser o dominio protegido pela Cloudflare.

## 4. Integrações

Configure no Stripe o webhook:

```text
https://seu-dominio.com/api/billing/webhook
```

Para email transacional, configure SMTP e autentique o dominio do remetente com
SPF, DKIM e DMARC antes de abrir vendas.

## 5. Mobile

Android e iOS continuam recebendo as URLs por `dart-define`:

```text
API_BASE_URL=https://seu-dominio.com/api
SOCKET_URL=https://seu-dominio.com
PUBLIC_WEB_URL=https://seu-dominio.com
```

No Flutter Web essas URLs sao inferidas do dominio atual quando os valores de
build ficam vazios.

## 6. Verificação antes de abrir vendas

1. Acesse `/pt`, `/en`, `/es`, `/robots.txt` e `/sitemap.xml`.
2. Teste `/app/demo`, cadastro, login e recuperacao de senha.
3. Envie foto e video, reinicie o backend e confirme que continuam disponiveis.
4. Faça um checkout de teste e confira o job `payments` no Redis.
5. Reinicie Redis e confirme que jobs atrasados continuam persistidos.
6. Teste chat e reconexao Socket.IO no Web e mobile.
7. Confirme backups restauraveis do MongoDB e do Bucket.
