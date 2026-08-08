import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return Response.json(
      { success: false, message: "Method not allowed." },
      { status: 405, headers: corsHeaders }
    );
  }

  try {
    const { reference } = await req.json();

    if (!reference) {
      return Response.json(
        { success: false, message: "Payment reference is required." },
        { status: 400, headers: corsHeaders }
      );
    }

    const secretKey = Deno.env.get("PAYSTACK_SECRET_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!secretKey || !supabaseUrl || !serviceRoleKey) {
      return Response.json(
        { success: false, message: "Payment provider is not configured." },
        { status: 500, headers: corsHeaders }
      );
    }

    const response = await fetch(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json"
        }
      }
    );

    const data = await response.json();

    if (!response.ok || !data?.status || data?.data?.status !== "success") {
      return new Response(JSON.stringify(data), {
        status: response.status,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { error: updateError } = await supabaseAdmin
      .from("merch_orders")
      .update({ payment_status: "paid" })
      .eq("payment_reference", reference);

    if (updateError) {
      console.error("Order payment update error:", updateError);

      return Response.json(
        {
          success: false,
          message: "Payment verified but order could not be updated."
        },
        { status: 500, headers: corsHeaders }
      );
    }

    return Response.json(
      {
        success: true,
        message: "Payment verified and order updated.",
        data: data.data
      },
      { headers: corsHeaders }
    );
  } catch (error) {
    console.error("Verify payment error:", error);

    return Response.json(
      {
        success: false,
        message: "Could not verify payment."
      },
      { status: 500, headers: corsHeaders }
    );
  }
});
