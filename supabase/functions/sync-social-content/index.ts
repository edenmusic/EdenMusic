import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
    try {
        const body = await req.json().catch(() => ({}));

        return new Response(
            JSON.stringify({
                success: true,
                platform: body.platform || "all",
                message: "Social content sync request received."
            }),
            {
                headers: {
                    "Content-Type": "application/json"
                }
            }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({
                success: false,
                error: String(error)
            }),
            {
                status: 500,
                headers: {
                    "Content-Type": "application/json"
                }
            }
        );
    }
});
