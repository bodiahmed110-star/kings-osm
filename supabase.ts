import { createClient } from '@supabase/supabase-js'
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined
export const supabase = url && anonKey ? createClient(url, anonKey) : null
export function assertSupabase() { if (!supabase) throw new Error('Supabase environment variables are missing. Copy .env.example to .env and configure them.'); return supabase }
