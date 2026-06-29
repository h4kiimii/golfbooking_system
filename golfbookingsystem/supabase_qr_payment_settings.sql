create table if not exists public.system_settings (
  setting_key text primary key,
  setting_value text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.system_settings
  add column if not exists setting_key text,
  add column if not exists setting_value text;

create unique index if not exists system_settings_setting_key_unique
  on public.system_settings (setting_key);

insert into public.system_settings (setting_key, setting_value)
values
  ('qr_payment_image_url', ''),
  ('payment_qr_url', ''),
  ('qr_payment_data', 'https://payment.upsi-driving-range.example/checkout')
on conflict (setting_key) do nothing;

update public.system_settings app_qr
set setting_value = website_qr.setting_value
from public.system_settings website_qr
where app_qr.setting_key = 'qr_payment_image_url'
  and website_qr.setting_key = 'payment_qr_url'
  and coalesce(nullif(trim(website_qr.setting_value), ''), '') <> ''
  and (
    app_qr.setting_value is null
    or trim(app_qr.setting_value) = ''
    or app_qr.setting_value = 'PASTE_YOUR_SUPABASE_STORAGE_QR_IMAGE_PUBLIC_URL_HERE'
  );

alter table public.system_settings enable row level security;

drop policy if exists "Anyone can read system settings" on public.system_settings;
create policy "Anyone can read system settings"
  on public.system_settings
  for select
  using (true);

drop policy if exists "Admins can manage system settings" on public.system_settings;
create policy "Admins can manage system settings"
  on public.system_settings
  for all
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role::text in ('admin', 'main_admin')
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role::text in ('admin', 'main_admin')
    )
  );
