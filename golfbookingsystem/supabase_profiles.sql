create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  age integer,
  birthday date,
  address text,
  phone text,
  phone_number text,
  login_provider text not null default 'User Email',
  role text not null default 'user',
  image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists email text,
  add column if not exists age integer,
  add column if not exists birthday date,
  add column if not exists address text,
  add column if not exists phone text,
  add column if not exists phone_number text,
  add column if not exists login_provider text not null default 'User Email',
  add column if not exists role text not null default 'user',
  add column if not exists image_path text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.profiles enable row level security;

update public.profiles
set phone = coalesce(nullif(trim(phone), ''), phone_number),
    phone_number = coalesce(nullif(trim(phone_number), ''), phone)
where coalesce(nullif(trim(phone), ''), '') <> coalesce(nullif(trim(phone_number), ''), '');

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter type public.user_role add value if not exists 'main_admin';

update public.profiles
set role = (case
  when lower(trim(role::text)) in ('main_admin', 'main admin', 'main-admin', 'super_admin', 'super admin') then 'main_admin'
  when lower(trim(role::text)) in ('admin', 'administrator', 'admins', 'admin email', 'admin_email') then 'admin'
  else 'user'
end)::public.user_role
where role is null
  or lower(trim(role::text)) not in ('user', 'admin', 'main_admin');

alter table public.profiles
  add constraint profiles_role_check
  check (role::text in ('user', 'admin', 'main_admin'));

create or replace function public.current_user_is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role::text in ('admin', 'main_admin')
  );
$$;

drop policy if exists "Users can read their own profile" on public.profiles;
drop policy if exists "Admins can read profiles" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles
  for select
  using (auth.uid() = id);

create policy "Admins can read profiles"
  on public.profiles
  for select
  using (public.current_user_is_admin());

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
  on public.profiles
  for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Admins can update profiles" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Admins can update profiles"
  on public.profiles
  for update
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());
