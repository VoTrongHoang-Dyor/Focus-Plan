-- Source of truth cho bảng pomodoro_sessions (issue 006).
-- Bảng sẽ được user tạo tay trên remote qua SQL Editor; file này để version-control.
-- KHÔNG chạy `supabase db push` lên remote đang chạy.

create table if not exists public.pomodoro_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  started_at timestamptz not null,
  duration_minutes int not null,
  created_at timestamptz not null default now()
);
alter table public.pomodoro_sessions enable row level security;
drop policy if exists "pomodoro_sessions_select_own" on public.pomodoro_sessions;
drop policy if exists "pomodoro_sessions_insert_own" on public.pomodoro_sessions;
create policy "pomodoro_sessions_select_own" on public.pomodoro_sessions for select using (auth.uid() = user_id);
create policy "pomodoro_sessions_insert_own" on public.pomodoro_sessions for insert with check (auth.uid() = user_id);
