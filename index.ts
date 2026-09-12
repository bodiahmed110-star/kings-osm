import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS' }
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return new Response(JSON.stringify({error:'Method not allowed'}),{status:405,headers:{...corsHeaders,'content-type':'application/json'}})
  try {
    const {order_number, phone} = await req.json()
    const cleanPhone = String(phone ?? '').replace(/[^0-9]/g,'')
    if (!order_number || cleanPhone.length < 8) return new Response(JSON.stringify({order:null}),{status:400,headers:{...corsHeaders,'content-type':'application/json'}})
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const {data,error} = await admin.from('orders').select('order_number,total_egp,status,created_at,customer_name,customer_phone,order_items(product_name,unit_price_egp,quantity,line_total_egp)').eq('order_number',String(order_number).trim()).maybeSingle()
    if (error || !data) return new Response(JSON.stringify({order:null}),{status:200,headers:{...corsHeaders,'content-type':'application/json'}})
    const storedPhone = String(data.customer_phone).replace(/[^0-9]/g,'')
    if (storedPhone !== cleanPhone) return new Response(JSON.stringify({order:null}),{status:200,headers:{...corsHeaders,'content-type':'application/json'}})
    return new Response(JSON.stringify({order:{order_number:data.order_number,total_egp:data.total_egp,status:data.status,created_at:data.created_at,order_items:data.order_items}}),{status:200,headers:{...corsHeaders,'content-type':'application/json'}})
  } catch { return new Response(JSON.stringify({error:'Bad request'}),{status:400,headers:{...corsHeaders,'content-type':'application/json'}}) }
})
