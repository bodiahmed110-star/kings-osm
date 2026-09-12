# Sheko0o Madrid

Production-oriented Arabic digital gaming store built with React + Vite + Supabase.

## Features
- Premium orange-gold / charcoal storefront
- OSM Coins, OSM Money, PES/eFootball and offers categories
- Search, filtering and sorting
- Persistent remote products/categories/settings/orders
- Secure Supabase Auth admin login
- RLS policies for storefront/admin separation
- Server-side order pricing through `create_order` RPC
- WhatsApp order handoff with order number + cart details
- Secure order tracking Edge Function using order number + phone
- Product image URL support and Supabase Storage bucket
- Responsive mobile-first UI

## Setup

1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Create an admin user in Supabase Auth (email/password).
4. In SQL Editor insert that user into `public.admins` using their Auth user UUID:

```sql
insert into public.admins(user_id) values ('YOUR_AUTH_USER_UUID');
```

5. Copy `.env.example` to `.env` and set:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
6. Run `npm install` then `npm run dev`.
7. Deploy the Vite app to Vercel/Netlify/Cloudflare Pages. `vercel.json` is included for SPA routes such as `/admin`.
8. Deploy the Supabase Edge Function from `supabase/functions/track-order` as `track-order`. The included `supabase/config.toml` marks this function as publicly callable because it only returns an order after matching both order number and phone.

## Important production notes
- Never put the Supabase service-role key in frontend code.
- Add only trusted staff accounts to `public.admins`.
- Configure Supabase Auth email/password settings as desired.
- Replace demo fallback catalog data by inserting the real catalog in the admin dashboard.
