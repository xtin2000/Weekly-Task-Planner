-- ============================================================
-- Weekly Dashboard — Supabase schema
-- Run this in the Supabase SQL Editor after creating your project.
-- It creates one table and locks it down so users only see their own data.
-- ============================================================

-- 1) The dashboard_state table
create table if not exists public.dashboard_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data    jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 2) Enable row-level security
alter table public.dashboard_state enable row level security;

-- 3) Policies: a user can only read/write their own row
drop policy if exists "select_own_state" on public.dashboard_state;
create policy "select_own_state"
  on public.dashboard_state
  for select
  using (auth.uid() = user_id);

drop policy if exists "insert_own_state" on public.dashboard_state;
create policy "insert_own_state"
  on public.dashboard_state
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "update_own_state" on public.dashboard_state;
create policy "update_own_state"
  on public.dashboard_state
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "delete_own_state" on public.dashboard_state;
create policy "delete_own_state"
  on public.dashboard_state
  for delete
  using (auth.uid() = user_id);

-- 4) Auto-update updated_at on changes
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_touch_dashboard_state on public.dashboard_state;
create trigger trg_touch_dashboard_state
  before update on public.dashboard_state
  for each row execute function public.touch_updated_at();
