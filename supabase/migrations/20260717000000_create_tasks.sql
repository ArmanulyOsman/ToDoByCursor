create table if not exists public.tasks (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  notes text not null default '',
  due_date date,
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high')),
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists tasks_user_due_date_idx
  on public.tasks (user_id, due_date);

alter table public.tasks enable row level security;

create policy "Users manage only their own tasks"
  on public.tasks
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.tasks to authenticated;
