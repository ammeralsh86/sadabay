create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'account_type') then
    create type public.account_type as enum
    ('INDIVIDUAL','COMMERCIAL','DISTRIBUTOR','AGENT');
  end if;

  if not exists (select 1 from pg_type where typname = 'user_status') then
    create type public.user_status as enum
    ('PENDING','ACTIVE','SUSPENDED','REJECTED','DISABLED');
  end if;

  if not exists (select 1 from pg_type where typname = 'identity_type') then
    create type public.identity_type as enum
    ('PASSPORT','PERSONAL_ID','RESIDENCE_PERMIT');
  end if;

  if not exists (select 1 from pg_type where typname = 'request_status') then
    create type public.request_status as enum
    ('PENDING','APPROVED','REJECTED');
  end if;

  if not exists (select 1 from pg_type where typname = 'transaction_status') then
    create type public.transaction_status as enum
    ('PENDING','PROCESSING','SUCCESS','FAILED','CANCELLED');
  end if;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  country_code text,
  full_name text not null,
  date_of_birth date,
  country text,
  region text,
  district text,
  neighborhood text,
  account_type public.account_type not null default 'INDIVIDUAL',
  trade_name text,
  commercial_registration text,
  identity_type public.identity_type,
  identity_number text,
  identity_issue_date date,
  identity_expiry_date date,
  status public.user_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  storage_path text not null,
  verified boolean not null default false,
  uploaded_at timestamptz not null default now(),
  verified_at timestamptz
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  description text,
  created_at timestamptz not null default now()
);

insert into public.roles (name,description) values
('OWNER','مالك النظام'),
('ADMIN','مدير النظام'),
('MANAGER','مدير'),
('EMPLOYEE','موظف'),
('AGENT','وكيل'),
('DISTRIBUTOR','موزع'),
('CUSTOMER','عميل')
on conflict (name) do nothing;

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  description text,
  created_at timestamptz not null default now()
);

insert into public.permissions (code,description) values
('customers.view','عرض العملاء'),
('customers.add','إضافة العملاء'),
('customers.edit','تعديل العملاء'),
('customers.suspend','إيقاف العملاء'),
('balances.view','عرض الأرصدة'),
('balances.edit','تعديل الأرصدة'),
('transactions.view','عرض العمليات'),
('transactions.execute','تنفيذ العمليات'),
('services.view','عرض الخدمات'),
('services.manage','إدارة الخدمات'),
('prices.edit','تعديل الأسعار'),
('commissions.edit','تعديل العمولات'),
('agents.manage','إدارة الوكلاء'),
('distributors.manage','إدارة الموزعين'),
('registration_requests.view','عرض طلبات التسجيل'),
('registration_requests.manage','إدارة طلبات التسجيل'),
('employees.view','عرض الموظفين'),
('employees.manage','إدارة الموظفين'),
('permissions.manage','إدارة الصلاحيات'),
('providers.manage','إدارة مزودي الخدمات'),
('api.settings','إعدادات API'),
('reports.view','عرض التقارير'),
('financial_reports.view','عرض التقارير المالية'),
('audit_log.view','عرض سجل التدقيق'),
('system.settings','إعدادات النظام')
on conflict (code) do nothing;

create table if not exists public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id,role_id)
);

create table if not exists public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id,permission_id)
);

create table if not exists public.user_permissions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  allowed boolean not null default true,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id,permission_id)
);

create table if not exists public.admin_registration_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  requested_role_id uuid references public.roles(id) on delete set null,
  status public.request_status not null default 'PENDING',
  reviewed_by uuid references public.profiles(id) on delete set null,
  review_note text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  currency text not null default 'YER',
  balance numeric(18,2) not null default 0 check (balance >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  transaction_type text not null,
  reference_id uuid,
  description text,
  balance_before numeric(18,2) not null,
  balance_after numeric(18,2) not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.services (name,code,description) values
('تحويل لحساب','ACCOUNT_TRANSFER','تحويل الأموال إلى حساب آخر'),
('شحن رصيد','MOBILE_RECHARGE','شحن رصيد الهاتف'),
('تسديد الإنترنت','INTERNET_PAYMENT','تسديد خدمات الإنترنت'),
('باقات الإنترنت','INTERNET_PACKAGE','شراء باقات الإنترنت'),
('بطاقات الألعاب','GAME_CARDS','شراء بطاقات الألعاب'),
('خدمات أخرى','OTHER','خدمات إضافية')
on conflict (code) do nothing;

create table if not exists public.service_prices (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  account_type public.account_type not null,
  price numeric(18,2) not null check (price >= 0),
  commission numeric(18,2) not null default 0 check (commission >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete restrict,
  service_id uuid references public.services(id) on delete restrict,
  amount numeric(18,2) not null check (amount >= 0),
  fee numeric(18,2) not null default 0 check (fee >= 0),
  commission numeric(18,2) not null default 0 check (commission >= 0),
  total_amount numeric(18,2) not null check (total_amount >= 0),
  status public.transaction_status not null default 'PENDING',
  external_reference text,
  customer_reference text,
  provider_reference text,
  failure_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  table_name text,
  record_id uuid,
  old_data jsonb,
  new_data jsonb,
  ip_address text,
  created_at timestamptz not null default now()
);

create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  description text,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

insert into public.system_settings
(key,value,description) values
('app_name','"مدى باي"','اسم التطبيق'),
('default_currency','"YER"','العملة الافتراضية'),
('registration_enabled','true','السماح بتسجيل العملاء الجدد')
on conflict (key) do nothing;

create index if not exists idx_profiles_phone on public.profiles(phone);
create index if not exists idx_profiles_status on public.profiles(status);
create index if not exists idx_documents_user on public.user_documents(user_id);
create index if not exists idx_user_roles_user on public.user_roles(user_id);
create index if not exists idx_user_permissions_user on public.user_permissions(user_id);
create index if not exists idx_admin_requests_status on public.admin_registration_requests(status);
create index if not exists idx_wallet_transactions_wallet on public.wallet_transactions(wallet_id);
create index if not exists idx_transactions_user on public.transactions(user_id);
create index if not exists idx_transactions_status on public.transactions(status);
create index if not exists idx_transactions_created on public.transactions(created_at desc);
create index if not exists idx_notifications_user on public.notifications(user_id);
create index if not exists idx_audit_logs_user on public.audit_logs(user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists wallets_updated_at on public.wallets;
create trigger wallets_updated_at
before update on public.wallets
for each row execute function public.set_updated_at();

drop trigger if exists services_updated_at on public.services;
create trigger services_updated_at
before update on public.services
for each row execute function public.set_updated_at();

drop trigger if exists service_prices_updated_at on public.service_prices;
create trigger service_prices_updated_at
before update on public.service_prices
for each row execute function public.set_updated_at();

drop trigger if exists transactions_updated_at on public.transactions;
create trigger transactions_updated_at
before update on public.transactions
for each row execute function public.set_updated_at();

drop trigger if exists system_settings_updated_at on public.system_settings;
create trigger system_settings_updated_at
before update on public.system_settings
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.user_documents enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.user_roles enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_permissions enable row level security;
alter table public.admin_registration_requests enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.services enable row level security;
alter table public.service_prices enable row level security;
alter table public.transactions enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_settings enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "Users can view own wallet" on public.wallets;
create policy "Users can view own wallet"
on public.wallets for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can view own transactions" on public.transactions;
create policy "Users can view own transactions"
on public.transactions for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications"
on public.notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Authenticated users can view active services"
on public.services;
create policy "Authenticated users can view active services"
on public.services for select to authenticated
using (active = true);

drop policy if exists "Authenticated users can view active prices"
on public.service_prices;
create policy "Authenticated users can view active prices"
on public.service_prices for select to authenticated
using (active = true);
