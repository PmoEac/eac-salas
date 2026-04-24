# Gestão de Salas — Energisa Acre

Sistema de agendamento de salas de reunião com autenticação, controle de acesso por perfil e sincronização em tempo real via Supabase.

## Salas gerenciadas
- **Sala Compromisso** — 50+ pessoas, videoconferência, TV 100"
- **Sala Pessoas** — até 15 pessoas, TV projeção

## Perfis de acesso
| Perfil | Acesso |
|---|---|
| **Visitante** (sem login) | Visualização somente leitura, atualização em tempo real |
| **Master** | Criar, editar e cancelar reservas |
| **Admin** | Tudo do Master + gerenciar usuários |

## Setup

### 1. Supabase
1. Crie um projeto em [supabase.com](https://supabase.com)
2. Vá em **SQL Editor** e execute o conteúdo de `supabase_setup.sql`
3. Vá em **Authentication > Users > Add user** e crie o usuário admin
4. No SQL Editor, execute:
```sql
update public.profiles
set role = 'admin', nome = 'Seu Nome'
where email = 'seu@email.com';
```

### 2. Configuração local
```bash
cp config.example.js config.js
```
Edite `config.js` com sua URL e chave anon do Supabase (Settings > API).

### 3. GitHub Pages
1. Suba os arquivos para o repositório (o `config.js` está no `.gitignore`)
2. Vá em **Settings > Pages > Branch: main** e ative o GitHub Pages
3. Acesse via `https://seuusuario.github.io/nome-do-repo`

> ⚠️ O `config.js` com as credenciais fica apenas na sua máquina local e não vai para o GitHub.

## Arquivos
```
index.html          ← sistema completo
config.js           ← credenciais (local, não vai ao GitHub)
config.example.js   ← template público das credenciais
supabase_setup.sql  ← script de criação do banco
.gitignore          ← protege config.js
README.md
```
