insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Anyone can view profile images" on storage.objects;
create policy "Anyone can view profile images"
  on storage.objects
  for select
  using (bucket_id = 'profile-images');

drop policy if exists "Users can upload their own profile images" on storage.objects;
create policy "Users can upload their own profile images"
  on storage.objects
  for insert
  with check (
    bucket_id = 'profile-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update their own profile images" on storage.objects;
create policy "Users can update their own profile images"
  on storage.objects
  for update
  using (
    bucket_id = 'profile-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'profile-images'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
