# Landing Page

Landing pública em Next.js para SEO. Ela não contém planos nem política de
privacidade chumbados: ambos são carregados do backend NestJS.

## Ambiente

Copie `.env.example` para `.env.local` quando quiser rodar localmente.

```text
BACKEND_ORIGIN=http://localhost:3000
NEXT_PUBLIC_SITE_ORIGIN=http://localhost:3458
NEXT_PUBLIC_APP_ORIGIN=http://localhost:3000/app
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

## Railway

Crie um serviço separado no Railway com root directory `landing-page`. Esse
serviço usa `landing-page/railway.toml` e precisa das três variáveis acima
apontando para os domínios públicos de produção.
