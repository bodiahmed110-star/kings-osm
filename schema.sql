-- Sheko0o Madrid production schema for Supabase
create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.admins where user_id = auth.uid()); $$;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  icon text not null default '✦',
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null,
  slug text unique not null,
  description text,
  price_egp numeric(12,2) not null check (price_egp >= 0),
  old_price_egp numeric(12,2) check (old_price_egp is null or old_price_egp >= 0),
  discount_percent numeric(5,2) check (discount_percent is null or (discount_percent >= 0 and discount_percent <= 100)),
  bonus_text text,
  stock_label text,
  stock_status text not null default 'in_stock' check (stock_status in ('in_stock','limited','out_of_stock')),
  image_url text,
  featured boolean not null default false,
  popular boolean not null default false,
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists products_category_idx on public.products(category_id);
create index if not exists products_enabled_idx on public.products(enabled);

create table if not exists public.store_settings (
  id uuid primary key default gen_random_uuid(),
  store_name text not null default 'Sheko0o Madrid',
  description text not null default 'متجر متخصص في المنتجات الرقمية وشحن الألعاب',
  whatsapp_number text not null default '201014138243',
  currency text not null default 'ج.م',
  logo_url text,
  announcement text,
  contact_note text,
  instagram_url text,
  facebook_url text,
  telegram_url text,
  primary_color text not null default '#f0a33c',
  secondary_color text not null default '#ffd48b',
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_name text not null,
  customer_phone text not null,
  notes text,
  total_egp numeric(12,2) not null default 0,
  status text not null default 'pending' check (status in ('pending','processing','completed','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price_egp numeric(12,2) not null,
  quantity integer not null check (quantity > 0),
  line_total_egp numeric(12,2) not null,
  created_at timestamptz not null default now()
);
create index if not exists order_items_order_idx on public.order_items(order_id);

alter table public.admins enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.store_settings enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Public storefront reads
create policy "public can read enabled categories" on public.categories for select using (enabled = true or public.is_admin());
create policy "public can read enabled products" on public.products for select using (enabled = true or public.is_admin());
create policy "public can read settings" on public.store_settings for select using (true);

-- Admin writes/reads
create policy "admins manage categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage settings" on public.store_settings for all using (public.is_admin()) with check (public.is_admin());
create policy "admins read orders" on public.orders for select using (public.is_admin());
create policy "admins update orders" on public.orders for update using (public.is_admin()) with check (public.is_admin());
create policy "admins read order items" on public.order_items for select using (public.is_admin());

-- Secure order creation: client submits only product ids + quantities.
create or replace function public.create_order(
  p_customer_name text,
  p_customer_phone text,
  p_notes text,
  p_items jsonb
)
returns table(order_id uuid, order_number text, total_egp numeric)
language plpgsql security definer set search_path = public
as $$
declare
  v_order_id uuid;
  v_order_number text;
  v_total numeric(12,2);
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
begin
  if length(trim(coalesce(p_customer_name,''))) < 2 then raise exception 'الاسم غير صالح'; end if;
  if length(regexp_replace(coalesce(p_customer_phone,''),'[^0-9]','','g')) < 8 then raise exception 'رقم الهاتف غير صالح'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'السلة فارغة'; end if;

  v_order_number := 'SM-' || to_char(now(),'YYYYMMDD') || '-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
  insert into public.orders(order_number,customer_name,customer_phone,notes,status,total_egp)
  values(v_order_number,trim(p_customer_name),trim(p_customer_phone),nullif(trim(p_notes),''),'pending',0)
  returning id into v_order_id;

  v_total := 0;
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := greatest(1, least(999, (v_item->>'quantity')::integer));
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and enabled = true for update;
    if not found or v_product.stock_status = 'out_of_stock' then raise exception 'منتج غير متاح'; end if;
    v_total := v_total + (v_product.price_egp * v_qty);
    insert into public.order_items(order_id,product_id,product_name,unit_price_egp,quantity,line_total_egp)
    values(v_order_id,v_product.id,v_product.name,v_product.price_egp,v_qty,v_product.price_egp*v_qty);
  end loop;

  update public.orders set total_egp = v_total where id = v_order_id;
  return query select v_order_id,v_order_number,v_total;
end; $$;

revoke all on function public.create_order(text,text,text,jsonb) from public;
grant execute on function public.create_order(text,text,text,jsonb) to anon, authenticated;

-- Secure tracking endpoint uses the service role in the Edge Function; public order rows stay private.

insert into public.categories(name,slug,description,icon,sort_order)
values
('كوينز المدرب الأفضل OSM','osm-coins','اشحن كوينز OSM بسرعة وأمان','🪙',1),
('أموال المدرب الأفضل OSM','osm-money','شراء أموال وحزم OSM','💳',2),
('PES / eFootball','pes','شحن وشراء منتجات PES / eFootball','⚽',3),
('العروض والباقات','offers','أفضل الباقات والعروض المتاحة','✦',4)
on conflict (slug) do nothing;

insert into public.store_settings(store_name,description,whatsapp_number,currency,announcement)
select 'Sheko0o Madrid','متجر متخصص في المنتجات الرقمية وشحن الألعاب','201014138243','ج.م','عروض رقمية مميزة — الطلب عبر واتساب بسهولة'
where not exists(select 1 from public.store_settings);

-- Storage bucket for product artwork. Only admins can upload/update files.
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict (id) do nothing;
create policy "public can read product images" on storage.objects for select using (bucket_id='product-images');
create policy "admins upload product images" on storage.objects for insert with check (bucket_id='product-images' and public.is_admin());
create policy "admins update product images" on storage.objects for update using (bucket_id='product-images' and public.is_admin()) with check (bucket_id='product-images' and public.is_admin());
create policy "admins delete product images" on storage.objects for delete using (bucket_id='product-images' and public.is_admin());
