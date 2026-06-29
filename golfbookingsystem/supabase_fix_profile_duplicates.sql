delete from public.profiles profile
where profile.email is not null
  and exists (
    select 1
    from auth.users auth_user
    where lower(auth_user.email) = lower(profile.email)
      and auth_user.id <> profile.id
  );

insert into public.profiles (
  id,
  full_name,
  email,
  age,
  birthday,
  address,
  phone_number,
  login_provider
)
select
  auth_user.id,
  coalesce(auth_user.raw_user_meta_data ->> 'full_name', 'Golf Member'),
  auth_user.email,
  21,
  date '2005-01-01',
  'Kuala Lumpur, Malaysia',
  coalesce(auth_user.raw_user_meta_data ->> 'phone_number', '+60 12-345 6789'),
  'User Email'
from auth.users auth_user
where auth_user.email is not null
on conflict (id) do update set
  email = excluded.email,
  full_name = coalesce(public.profiles.full_name, excluded.full_name),
  age = coalesce(public.profiles.age, excluded.age),
  birthday = coalesce(public.profiles.birthday, excluded.birthday),
  address = coalesce(public.profiles.address, excluded.address),
  phone_number = coalesce(public.profiles.phone_number, excluded.phone_number),
  login_provider = coalesce(public.profiles.login_provider, excluded.login_provider);
