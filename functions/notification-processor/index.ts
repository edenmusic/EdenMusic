import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_KEY");
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY || !FCM_SERVER_KEY) {
  console.error('Missing required environment variables (SUPABASE_URL, SUPABASE_SERVICE_KEY, FCM_SERVER_KEY)');
}

async function supabaseGet(path) {
  const url = `${SUPABASE_URL}/rest/v1/${path}`;
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });
  return res.json();
}

async function supabasePatch(path, body) {
  const url = `${SUPABASE_URL}/rest/v1/${path}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify(body)
  });
  return res.json();
}

async function supabasePost(path, body) {
  const url = `${SUPABASE_URL}/rest/v1/${path}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: JSON.stringify(body)
  });
  return res.json();
}

async function sendFcm(token, title, body, data = {}) {
  const payload = {
    to: token,
    notification: {
      title,
      body
    },
    data
  };

  const res = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  const json = await res.json();
  return { status: res.status, json };
}

serve(async () => {
  // Fetch pending notifications (channel=push, sent=false)
  try {
    const notifications = await supabaseGet("notifications?channel=eq.push&sent=eq.false&select=*");

    for (const n of notifications) {
      // resolve tokens based on target
      let tokens = [];
      if (n.target === 'all') {
        tokens = await supabaseGet('user_push_tokens?select=token,provider,platform');
      } else if (n.target === 'user' && n.target_user) {
        tokens = await supabaseGet(`user_push_tokens?user_id=eq.${n.target_user}&select=token,provider,platform`);
      } else if (n.target === 'role' && n.target_role) {
        // role handling: simple fallback to all tokens for now
        tokens = await supabaseGet('user_push_tokens?select=token,provider,platform');
      }

      const results = [];
      for (const t of tokens) {
        try {
          const r = await sendFcm(t.token, n.title, n.body || '', n.data || {});
          results.push({ token: t.token, result: r });
        } catch (err) {
          results.push({ token: t.token, error: err.message });
        }
      }

      // Mark notification sent
      await supabasePatch(`notifications?id=eq.${n.id}`, { sent: true, sent_at: new Date().toISOString() });
    }

    return new Response(JSON.stringify({ ok: true, processed: notifications.length }), { status: 200 });
  } catch (err) {
    console.error('Processor error', err);
    return new Response(JSON.stringify({ ok: false, error: String(err) }), { status: 500 });
  }
});
