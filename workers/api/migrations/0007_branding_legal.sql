ALTER TABLE tenants ADD COLUMN logo_path TEXT;
ALTER TABLE tenants ADD COLUMN logo_updated_at INTEGER;

CREATE TABLE IF NOT EXISTS platform_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  terms TEXT NOT NULL DEFAULT '',
  privacy TEXT NOT NULL DEFAULT '',
  logo_path TEXT,
  logo_updated_at INTEGER,
  updated_at INTEGER NOT NULL
);

INSERT OR IGNORE INTO platform_settings (id, terms, privacy, updated_at)
VALUES (
  1,
  'Sião — Termos de uso

1. Uso responsável
Cada pessoa responde pelo conteúdo que publica e pelos convites que envia.

2. Conta e acesso
Sua senha é pessoal e não deve ser compartilhada com terceiros.

3. Disponibilidade
Podemos realizar manutenção e aplicar limites necessários para manter o serviço seguro.

4. Conteúdo da família
O conteúdo pertence à família e fica isolado por família. A plataforma acompanha somente a operação do serviço, sem navegar pelo conteúdo privado.',
  'Sião — Política de privacidade

1. Dados utilizados
Usamos email, dados de perfil e o conteúdo que a própria família decide armazenar.

2. Finalidade
Os dados existem para autenticar pessoas e entregar os recursos privados contratados.

3. Controle
Administradores da família gerenciam membros e permissões. Solicitações legais serão atendidas pelos canais oficiais.

4. Segurança
Arquivos e eventos em tempo real são isolados por família. O acesso à mídia é protegido e temporário.',
  strftime('%s','now') * 1000
);
