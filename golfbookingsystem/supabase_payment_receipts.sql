insert into storage.buckets (id, name, public)
values ('payment-receipts', 'payment-receipts', true)
on conflict (id) do update set public = true;

drop policy if exists "Anyone can view payment receipts" on storage.objects;
create policy "Anyone can view payment receipts"
  on storage.objects
  for select
  using (bucket_id = 'payment-receipts');

drop policy if exists "Users can upload their own payment receipts" on storage.objects;
create policy "Users can upload their own payment receipts"
  on storage.objects
  for insert
  with check (
    bucket_id = 'payment-receipts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update their own payment receipts" on storage.objects;
create policy "Users can update their own payment receipts"
  on storage.objects
  for update
  using (
    bucket_id = 'payment-receipts'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'payment-receipts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
