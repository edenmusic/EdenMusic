import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
    const url = new URL(req.url);
    const code = url.searchParams.get("code");

    if (!code) {
        return new Response("Missing TikTok authorization code.", {
            status: 400
        });
    }

    const clientKey = Deno.env.get("TIKTOK_CLIENT_KEY");
    const clientSecret = Deno.env.get("TIKTOK_CLIENT_SECRET");

    if (!clientKey || !clientSecret) {
        return new Response("TikTok OAuth credentials are not configured.", {
            status: 500
        });
    }

    const redirectUri =
        "https://kokjxhgnguskgioeqhul.supabase.co/functions/v1/tiktok-oauth";

    const tokenResponse = await fetch(
        "https://open.tiktokapis.com/v2/oauth/token/",
        {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: new URLSearchParams({
                client_key: clientKey,
                client_secret: clientSecret,
                code,
                grant_type: "authorization_code",
                redirect_uri: redirectUri
            })
        }
    );

    const tokenData = await tokenResponse.json();

    if (!tokenResponse.ok) {
        console.error("TikTok token exchange failed:", tokenData);

        return new Response(
            JSON.stringify({
                success: false,
                error: "TikTok token exchange failed."
            }),
            {
                status: 400,
                headers: {
                    "Content-Type": "application/json"
                }
            }
        );
    }

    return new Response(
        JSON.stringify({
            success: true,
            message: "TikTok account authorized successfully.",
            token_received: !!tokenData.access_token
        }),
        {
            headers: {
                "Content-Type": "application/json"
            }
        }
    );
});
