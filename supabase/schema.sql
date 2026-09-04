-- Guitcoin: schema das tabelas de dados (financeiro pessoal).
-- Rodar uma vez no SQL Editor do painel Supabase (projeto próprio do
-- Guitcoin, separado do Guitchelin/Letterborgs).
--
-- Convenção (mesma do Guitchelin): toda tabela tem `id text primary key`
-- (gerado no cliente via uid()), `user_id uuid` dono da linha (RLS por
-- `user_id = auth.uid()`, default na coluna) e `inserted_at` pra ordenação.
-- Cada tabela ganha 4 políticas de RLS (select/insert/update/delete), todas
-- `using/with check (user_id = auth.uid())`.
--
-- Fases seguintes (ainda sem tabela): Fase 2 — expense_templates,
-- expense_instances (Despesas + Recorrências); Fase 3 — investment_snapshots
-- (Investimentos); Fase 4 — wishlist_items (Lista de Sonhos).

-- ===================== Fase 1: Receitas =====================

create table if not exists public.income_sources (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  tipo text not null default 'work', -- 'work' (fixa/salário) | 'extra'
  ativo boolean not null default true,
  ordem int not null default 0,
  created_at text,
  inserted_at timestamptz not null default now()
);

alter table public.income_sources enable row level security;

create policy "income_sources_select_own" on public.income_sources
  for select using (user_id = auth.uid());
create policy "income_sources_insert_own" on public.income_sources
  for insert with check (user_id = auth.uid());
create policy "income_sources_update_own" on public.income_sources
  for update using (user_id = auth.uid());
create policy "income_sources_delete_own" on public.income_sources
  for delete using (user_id = auth.uid());

create table if not exists public.income_entries (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  source_id text not null references public.income_sources(id) on delete cascade,
  competencia text not null, -- "YYYY-MM"
  valor numeric not null default 0,
  created_at text,
  inserted_at timestamptz not null default now()
);

alter table public.income_entries enable row level security;

create policy "income_entries_select_own" on public.income_entries
  for select using (user_id = auth.uid());
create policy "income_entries_insert_own" on public.income_entries
  for insert with check (user_id = auth.uid());
create policy "income_entries_update_own" on public.income_entries
  for update using (user_id = auth.uid());
create policy "income_entries_delete_own" on public.income_entries
  for delete using (user_id = auth.uid());

create table if not exists public.income_projections (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ano int not null,
  renda_fixa_mensal_esperada numeric not null default 0,
  created_at text,
  inserted_at timestamptz not null default now()
);

alter table public.income_projections enable row level security;

create policy "income_projections_select_own" on public.income_projections
  for select using (user_id = auth.uid());
create policy "income_projections_insert_own" on public.income_projections
  for insert with check (user_id = auth.uid());
create policy "income_projections_update_own" on public.income_projections
  for update using (user_id = auth.uid());
create policy "income_projections_delete_own" on public.income_projections
  for delete using (user_id = auth.uid());

-- Convenção de migração: toda vez que um campo novo for adicionado a um
-- objeto no index.html, adiciona a coluna aqui via `create table if not
-- exists` (instalações novas) E deixa uma linha `alter table ... add column
-- if not exists ...;` comentada logo abaixo, pra rodar uma vez no SQL Editor
-- em instalações existentes. Última coluna adicionada: nenhuma ainda desde o
-- schema inicial da Fase 1.
