-- Nguồn sự thật version-controlled cho bảng public.tasks + RLS (issue 002).
-- Bảng này đã được user tạo tay trên Supabase remote → KHÔNG chạy `supabase db push`
-- lên môi trường đang chạy (sẽ conflict "already exists"). File dùng để:
--   (1) làm nguồn sự thật của schema/RLS trong repo (multi-user isolation không còn
--       chỉ tồn tại ở remote state), và
--   (2) provision lại trên môi trường sạch mới.
-- Viết idempotent để tái tạo an toàn.

create extension if not exists pgcrypto;

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  estimated_minutes integer,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  deadline timestamptz,
  created_at timestamptz not null default now()
);

alter table public.tasks enable row level security;

-- 4 policy scope theo auth.uid() = user_id.
drop policy if exists tasks_select_own on public.tasks;
create policy tasks_select_own on public.tasks
  for select using (auth.uid() = user_id);

drop policy if exists tasks_insert_own on public.tasks;
create policy tasks_insert_own on public.tasks
  for insert with check (auth.uid() = user_id);

drop policy if exists tasks_update_own on public.tasks;
create policy tasks_update_own on public.tasks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists tasks_delete_own on public.tasks;
create policy tasks_delete_own on public.tasks
  for delete using (auth.uid() = user_id);

-- issue 004: phân loại năng lượng cho Scheduling Engine (deep/shallow).
alter table public.tasks
  add column if not exists task_type text not null default 'shallow'
  check (task_type in ('deep', 'shallow'));
