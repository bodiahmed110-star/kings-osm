export type Product = {
  id: string
  category_id: string
  name: string
  slug: string
  description: string | null
  price_egp: number
  old_price_egp: number | null
  discount_percent: number | null
  bonus_text: string | null
  stock_label: string | null
  stock_status: 'in_stock' | 'limited' | 'out_of_stock'
  image_url: string | null
  featured: boolean
  popular: boolean
  enabled: boolean
  sort_order: number
  created_at: string
  category?: Category
}

export type Category = {
  id: string
  name: string
  slug: string
  description: string | null
  icon: string
  enabled: boolean
  sort_order: number
}

export type StoreSettings = {
  id: string
  store_name: string
  description: string
  whatsapp_number: string
  currency: string
  logo_url: string | null
  announcement: string | null
  contact_note: string | null
  instagram_url: string | null
  facebook_url: string | null
  telegram_url: string | null
  primary_color: string
  secondary_color: string
}

export type CartItem = { product: Product; quantity: number }

export type Order = {
  id: string
  order_number: string
  customer_name: string
  customer_phone: string
  notes: string | null
  total_egp: number
  status: 'pending' | 'processing' | 'completed' | 'cancelled'
  created_at: string
  order_items?: { product_name: string; unit_price_egp: number; quantity: number; line_total_egp: number }[]
}
