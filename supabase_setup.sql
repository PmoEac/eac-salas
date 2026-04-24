-- ============================================================
-- GESTÃO DE SALAS — ENERGISA ACRE
-- Cole este script inteiro no Supabase > SQL Editor > Run
-- ============================================================

-- 1. TABELA DE PERFIS (roles dos usuários)
create table if not exists public.profiles (
  id         uuid references auth.users on delete cascade primary key,
  email      text not null,
  nome       text not null default '',
  role       text not null default 'master' check (role in ('admin', 'master')),
  ativo      boolean not null default true,
  created_at timestamptz default now()
);

-- 2. TABELA DE RESERVAS
create table if not exists public.reservas (
  id         bigserial primary key,
  sala       text not null check (sala in ('compromisso', 'pessoas')),
  data       date not null,
  inicio     time not null,
  fim        time not null,
  descricao  text not null default '',
  solicitante text not null default '',
  reservado_por text not null default '',
  situacao   text not null default 'Confirmado' check (situacao in ('Confirmado', 'Pendente', 'Cancelado')),
  obs        text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. TRIGGER: atualiza updated_at automaticamente
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists reservas_updated_at on public.reservas;
create trigger reservas_updated_at
  before update on public.reservas
  for each row execute function public.handle_updated_at();

-- 4. TRIGGER: cria profile automaticamente ao criar usuário no Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, nome, role, ativo)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'master'),
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. RLS — Row Level Security
alter table public.profiles enable row level security;
alter table public.reservas  enable row level security;

-- PROFILES: qualquer um lê; só admin altera outros; user altera o próprio
drop policy if exists "profiles_select"        on public.profiles;
drop policy if exists "profiles_update_admin"  on public.profiles;
drop policy if exists "profiles_delete_admin"  on public.profiles;

create policy "profiles_select" on public.profiles
  for select using (true);

create policy "profiles_update_admin" on public.profiles
  for update using (
    auth.uid() = id
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.ativo = true
    )
  );

create policy "profiles_delete_admin" on public.profiles
  for delete using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin' and p.ativo = true
    )
  );

-- RESERVAS: qualquer um lê (viewers anônimos); só master/admin escreve
drop policy if exists "reservas_select"  on public.reservas;
drop policy if exists "reservas_insert"  on public.reservas;
drop policy if exists "reservas_update"  on public.reservas;
drop policy if exists "reservas_delete"  on public.reservas;

create policy "reservas_select" on public.reservas
  for select using (true);

create policy "reservas_insert" on public.reservas
  for insert with check (
    auth.uid() is not null and
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('admin','master') and p.ativo = true
    )
  );

create policy "reservas_update" on public.reservas
  for update using (
    auth.uid() is not null and
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('admin','master') and p.ativo = true
    )
  );

create policy "reservas_delete" on public.reservas
  for delete using (
    auth.uid() is not null and
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role in ('admin','master') and p.ativo = true
    )
  );

-- 6. REALTIME — habilitar para a tabela reservas
alter publication supabase_realtime add table public.reservas;

-- 7. INSERIR O ADMIN INICIAL
-- ATENÇÃO: Depois de criar o usuário rogerio.chagas@energisa.com.br
-- no Supabase > Authentication > Users, rode este update:
--
-- update public.profiles
-- set role = 'admin', nome = 'Rogério Chagas'
-- where email = 'rogerio.chagas@energisa.com.br';
--
-- (O trigger já cria o profile automaticamente ao criar o usuário no Auth)

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
