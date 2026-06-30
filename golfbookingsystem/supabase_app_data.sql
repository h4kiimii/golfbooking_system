alter type public.booking_type add value if not exists 'driving_range';
alter type public.booking_type add value if not exists 'trainer';

create extension if not exists pgcrypto;

alter table public.bookings alter column id set default gen_random_uuid();
alter table public.payments alter column id set default gen_random_uuid();

do $$
begin
  if to_regclass('public.feedback_review') is null
    and to_regclass('public.reviews') is not null then
    alter table public.reviews rename to feedback_review;
  end if;
end $$;

create table if not exists public.feedback_review (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  booking_id uuid null,
  category text default 'General Feedback',
  name text,
  email text,
  message text,
  status text not null default 'active',
  created_at timestamptz default now(),
  submitted_at timestamptz default now()
);

alter table public.feedback_review alter column id set default gen_random_uuid();

alter table public.bookings
  add column if not exists app_booking_type text,
  add column if not exists title text,
  add column if not exists booking_date date,
  add column if not exists booking_time text,
  add column if not exists amount numeric not null default 0,
  add column if not exists total_amount numeric not null default 0,
  add column if not exists number_of_bucket integer,
  add column if not exists total_balls integer,
  add column if not exists membership_type text,
  add column if not exists bucket_option_id uuid,
  add column if not exists tee_slot_id uuid,
  add column if not exists booking_status text,
  add column if not exists amount_text text,
  add column if not exists payment_method text,
  add column if not exists status text not null default 'reserved',
  add column if not exists start_time text,
  add column if not exists end_time text,
  add column if not exists duration_label text,
  add column if not exists duration_minutes integer,
  add column if not exists lane_code text,
  add column if not exists lane_id_text text,
  add column if not exists lane_label text,
  add column if not exists payment_reference text,
  add column if not exists payment_receipt_name text,
  add column if not exists payment_receipt_url text,
  add column if not exists receipt_url text,
  add column if not exists payment_receipt_uploaded_at timestamptz,
  add column if not exists trainer_phone_number text,
  add column if not exists trainer_email text,
  add column if not exists training_class_type text,
  add column if not exists receipt_number text,
  add column if not exists verified_at timestamptz,
  add column if not exists scheduled_date date,
  add column if not exists scheduled_time time,
  add column if not exists payment_status text,
  add column if not exists customer_note text,
  add column if not exists cancellation_reason text,
  add column if not exists cancellation_type text,
  add column if not exists previous_booking_status text,
  add column if not exists previous_payment_status text,
  add column if not exists cancelled_by uuid references auth.users(id),
  add column if not exists cancelled_at timestamptz,
  add column if not exists hidden_for_user boolean not null default false,
  add column if not exists hidden_for_admin boolean not null default false,
  add column if not exists driving_range_lane_id uuid,
  add column if not exists lane_id text,
  add column if not exists created_at timestamptz not null default now();

alter table public.payments
  add column if not exists booking_id uuid references public.bookings(id) on delete cascade,
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists amount numeric not null default 0,
  add column if not exists total_amount numeric not null default 0,
  add column if not exists amount_text text,
  add column if not exists payment_method text,
  add column if not exists payment_reference text,
  add column if not exists payment_note text,
  add column if not exists receipt_file_name text,
  add column if not exists receipt_file_url text,
  add column if not exists receipt_url text,
  add column if not exists receipt_image_url text,
  add column if not exists receipt_uploaded_at timestamptz,
  add column if not exists payment_status text,
  add column if not exists rejected_reason text,
  add column if not exists status text not null default 'pendingVerification',
  add column if not exists created_at timestamptz not null default now();

alter table public.feedback_review
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists booking_id uuid null,
  add column if not exists name text,
  add column if not exists email text,
  add column if not exists category text,
  add column if not exists message text,
  add column if not exists status text not null default 'active',
  add column if not exists submitted_at timestamptz not null default now(),
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.trainers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  email text,
  address text,
  description text,
  rate numeric not null default 0,
  min_booking_hours integer not null default 1,
  max_booking_hours integer not null default 2,
  profile_image_url text,
  status text not null default 'available',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.trainers
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists phone_number text,
  add column if not exists whatsapp_phone text,
  add column if not exists email text,
  add column if not exists address text,
  add column if not exists description text,
  add column if not exists level text,
  add column if not exists qualification text,
  add column if not exists certification text,
  add column if not exists rate numeric not null default 0,
  add column if not exists min_booking_hours integer not null default 1,
  add column if not exists max_booking_hours integer not null default 2,
  add column if not exists profile_image_url text,
  add column if not exists status text not null default 'available',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.trainers
set description = coalesce(nullif(trim(description), ''), qualification, level)
where description is null or trim(description) = '';

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'feedback_review'
      and column_name = 'comment'
  ) then
    execute $sql$
      update public.feedback_review
      set message = coalesce(nullif(message, ''), comment)
      where message is null or message = ''
    $sql$;
    execute 'alter table public.feedback_review drop column comment';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'feedback_review'
      and column_name = 'rating'
  ) then
    execute 'alter table public.feedback_review drop column rating';
  end if;
end $$;

alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.feedback_review enable row level security;
alter table public.trainers enable row level security;

drop policy if exists "Anyone can read available trainers" on public.trainers;
create policy "Anyone can read available trainers"
  on public.trainers
  for select
  using (
    status is null
    or lower(trim(status)) in ('active', 'available')
  );

drop policy if exists "Users can read their own bookings" on public.bookings;
create policy "Users can read their own bookings"
  on public.bookings
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own bookings" on public.bookings;
create policy "Users can create their own bookings"
  on public.bookings
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own bookings" on public.bookings;
create policy "Users can update their own bookings"
  on public.bookings
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own bookings" on public.bookings;
create policy "Users can delete their own bookings"
  on public.bookings
  for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can read their own payments" on public.payments;
create policy "Users can read their own payments"
  on public.payments
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own payments" on public.payments;
create policy "Users can create their own payments"
  on public.payments
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can read their own feedback" on public.feedback_review;
create policy "Users can read their own feedback"
  on public.feedback_review
  for select
  using (
    auth.uid() = user_id
    or exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role::text in ('admin', 'main_admin')
    )
  );

drop policy if exists "Users can create their own feedback" on public.feedback_review;
create policy "Users can create their own feedback"
  on public.feedback_review
  for insert
  with check (auth.uid() = user_id);
