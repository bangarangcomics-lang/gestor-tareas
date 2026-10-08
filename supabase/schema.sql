-- Gestor de tareas · esquema de base de datos para Supabase
-- Pégalo entero en Supabase → SQL Editor → New query → Run.
-- Se puede ejecutar más de una vez sin romper nada.

-- ───────────── Tablas ─────────────

create table if not exists public.members (
  id              uuid primary key default gen_random_uuid(),
  name            text not null check (length(trim(name)) between 1 and 60),
  email           text not null unique check (email = lower(email)),
  color           text not null default '#0b7bd6',
  is_admin        boolean not null default false,
  can_edit_others boolean not null default false,
  sort            double precision not null default extract(epoch from now()),
  created_at      timestamptz not null default now()
);

create table if not exists public.tasks (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null references public.members(id) on delete cascade,
  text       text not null check (length(text) between 1 and 500),
  date       date,                       -- null = "Algún día"
  done       boolean not null default false,
  status     text check (status in ('proceso', 'atascado')),
  sort       double precision not null default extract(epoch from now()) * 1000,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tasks_date_idx on public.tasks (date);
create index if not exists tasks_open_idx on public.tasks (done) where done = false;

create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

drop trigger if exists tasks_touch on public.tasks;
create trigger tasks_touch before update on public.tasks
  for each row execute function public.touch_updated_at();

-- ───────────── Quién es quién ─────────────
-- Una persona del equipo se reconoce por el correo con el que inicia sesión.

create or replace function public.my_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;

create or replace function public.me() returns public.members
language sql stable security definer set search_path = public as $$
  select * from public.members where email = public.my_email() limit 1
$$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where email = public.my_email())
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from public.members where email = public.my_email()), false)
$$;

create or replace function public.can_edit_task(task_owner uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.members m
    where m.email = public.my_email()
      and (m.is_admin or m.can_edit_others or m.id = task_owner)
  )
$$;

-- La primera persona que entra con la base de datos vacía se convierte en administradora.
create or replace function public.claim_first_admin(p_name text) returns public.members
language plpgsql security definer set search_path = public as $$
declare r public.members;
begin
  if auth.uid() is null or public.my_email() = '' then
    raise exception 'Hay que iniciar sesión';
  end if;
  lock table public.members in exclusive mode;
  if exists (select 1 from public.members) then
    raise exception 'El equipo ya tiene administrador';
  end if;
  insert into public.members (name, email, is_admin, can_edit_others, color)
  values (trim(p_name), public.my_email(), true, true, '#0b7bd6')
  returning * into r;
  return r;
end $$;

revoke all on function public.claim_first_admin(text) from public, anon;
grant execute on function public.claim_first_admin(text) to authenticated;

-- Permite a la app saber si el equipo ya existe aunque quien pregunta no forme parte de él.
create or replace function public.team_exists() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members)
$$;

revoke all on function public.team_exists() from public, anon;
grant execute on function public.team_exists() to authenticated;

-- ───────────── Permisos (Row Level Security) ─────────────

alter table public.members enable row level security;
alter table public.tasks   enable row level security;

drop policy if exists members_read  on public.members;
drop policy if exists members_write on public.members;
create policy members_read  on public.members for select to authenticated using (public.is_member());
create policy members_write on public.members for all    to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists tasks_read   on public.tasks;
drop policy if exists tasks_insert on public.tasks;
drop policy if exists tasks_update on public.tasks;
drop policy if exists tasks_delete on public.tasks;
create policy tasks_read   on public.tasks for select to authenticated using (public.is_member());
create policy tasks_insert on public.tasks for insert to authenticated with check (public.can_edit_task(owner));
create policy tasks_update on public.tasks for update to authenticated
  using (public.can_edit_task(owner)) with check (public.can_edit_task(owner));
create policy tasks_delete on public.tasks for delete to authenticated using (public.can_edit_task(owner));

-- ───────────── Tiempo real ─────────────

do $$ begin
  begin alter publication supabase_realtime add table public.members; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.tasks;   exception when duplicate_object then null; end;
end $$;
