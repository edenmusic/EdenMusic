import { createClient } from "./supabase-browser.js";

const supabaseUrl = "https://kokjxhgnguskgioeqhul.supabase.co"
const supabaseKey = "sb_publishable_zoBChaJuIHnR0ArIGK4MKA_B9XBi3PN"

export const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storage: window.localStorage
    }
});

window.supabase = supabase;

let edenArtistUserId = null;
let edenFollowInitialized = false;

async function getEdenArtistUserId() {
    if (edenArtistUserId) return edenArtistUserId;
    const { data, error } = await supabase.from("profiles").select("user_id").eq("role", "developer").limit(1).maybeSingle();
    if (error) { console.error("Eden artist lookup error:", error); return null; }
    edenArtistUserId = data?.user_id || null;
    return edenArtistUserId;
}

async function loadEdenFollowState() {
    const button = document.getElementById("eden-follow-button");
    const count = document.getElementById("eden-follower-count");
    if (!button || !count) return;

    const artistUserId = await getEdenArtistUserId();
    if (!artistUserId) return;

    const { count: followerCount, error: countError } = await supabase.from("artist_follows").select("id", { count: "exact", head: true }).eq("artist_user_id", artistUserId);
    if (countError) { console.error("Follower count error:", countError); return; }
    count.textContent = `${followerCount || 0} ${(followerCount || 0) === 1 ? "follower" : "followers"}`;

    const { data: { user: fan } } = await supabase.auth.getUser();
    if (!fan) { button.textContent = "Follow Eden"; button.dataset.following = "false"; return; }

    const { data: follow, error: followError } = await supabase.from("artist_follows").select("id").eq("fan_user_id", fan.id).eq("artist_user_id", artistUserId).maybeSingle();
    if (followError) { console.error("Follow state error:", followError); return; }
    button.dataset.following = follow ? "true" : "false";
    button.textContent = follow ? "Following" : "Follow Eden";
    button.classList.toggle("eden-following", Boolean(follow));
}

async function toggleEdenFollow() {
    const button = document.getElementById("eden-follow-button");
    if (!button || button.disabled) return;
    const { data: { user: fan } } = await supabase.auth.getUser();
    if (!fan) { if (typeof window.showMessage === "function") window.showMessage("Create a fan account to follow Eden."); else alert("Create a fan account to follow Eden."); return; }

    const artistUserId = await getEdenArtistUserId();
    if (!artistUserId) return;
    button.disabled = true;
    const following = button.dataset.following === "true";

    const result = following
        ? await supabase.from("artist_follows").delete().eq("fan_user_id", fan.id).eq("artist_user_id", artistUserId)
        : await supabase.from("artist_follows").insert({ fan_user_id: fan.id, artist_user_id: artistUserId });

    if (result.error) { console.error(following ? "Unfollow error:" : "Follow error:", result.error); button.disabled = false; return; }
    await loadEdenFollowState();
    button.disabled = false;
}

function ensureEdenFollowUI() {
    const profileHeader = document.querySelector("#profile-screen .profile-header-card");
    if (!profileHeader) return false;

    if (!document.getElementById("eden-follow-controls")) {
        const controls = document.createElement("div");
        controls.id = "eden-follow-controls";
        controls.style.cssText = "display:flex;flex-direction:column;align-items:center;gap:8px;margin-top:16px;";
        controls.innerHTML = '<button id="eden-follow-button" type="button" class="primary-btn">Follow Eden</button><span id="eden-follower-count" class="small-label">0 followers</span>';
        profileHeader.appendChild(controls);
        document.getElementById("eden-follow-button").addEventListener("click", toggleEdenFollow);
    }
    loadEdenFollowState();
    return true;
}

window.loadEdenFollowState = loadEdenFollowState;
window.toggleEdenFollow = toggleEdenFollow;

function initializeEdenFollowing() {
    if (edenFollowInitialized) return;
    edenFollowInitialized = true;
    ensureEdenFollowUI();
    const profileScreen = document.getElementById("profile-screen");
    if (profileScreen) {
        const observer = new MutationObserver(() => { if (profileScreen.classList.contains("active")) ensureEdenFollowUI(); });
        observer.observe(profileScreen, { attributes: true, attributeFilter: ["class"] });
    }
    supabase.auth.onAuthStateChange(() => { if (document.getElementById("eden-follow-button")) loadEdenFollowState(); });
}

if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initializeEdenFollowing);
else initializeEdenFollowing();
