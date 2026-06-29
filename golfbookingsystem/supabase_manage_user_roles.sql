alter table public.profiles
  add column if not exists role text not null default 'user';

update public.profiles
set role = 'admin'
where lower(trim(role::text)) in (
  'administrator',
  'admins',
  'admin email',
  'admin_email'
);

update public.profiles
set role = 'user'
where role is null
  or lower(trim(role::text)) = ''
  or lower(trim(role::text)) not in ('user', 'admin');

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('user', 'admin'));

-- Put your real admin email here, then run this query.
-- Example:
-- update public.profiles
-- set role = 'admin'
-- where lower(email) = lower('admin@example.com');
