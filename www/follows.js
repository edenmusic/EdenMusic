// www/follows.js
// Client helpers for following/unfollowing artists and displaying follower counts

export async function getFollowerCount(userId) {
  if (!window.supabase) return 0;
  const { data, error } = await supabase
    .from('follows')
    .select('id', { count: 'exact' })
    .eq('followee', userId);

  if (error) {
    console.error('getFollowerCount error', error);
    return 0;
  }
  return data?.length || 0;
}

export async function isFollowing(currentUserId, profileUserId) {
  if (!window.supabase || !currentUserId) return false;
  const { data, error } = await supabase
    .from('follows')
    .select('id')
    .eq('follower', currentUserId)
    .eq('followee', profileUserId)
    .limit(1);

  if (error) {
    console.error('isFollowing error', error);
    return false;
  }
  return data && data.length > 0;
}

export async function toggleFollow(profileUserId) {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return alert('Please sign in to follow this artist.');
  const currentUserId = session.user.id;

  // check existing
  const { data: existing } = await supabase
    .from('follows')
    .select('id')
    .eq('follower', currentUserId)
    .eq('followee', profileUserId)
    .limit(1);

  if (existing && existing.length) {
    // unfollow
    await supabase.from('follows').delete().eq('id', existing[0].id);
  } else {
    // follow
    await supabase.from('follows').insert([{ follower: currentUserId, followee: profileUserId }]);
  }
}

export function initFollowButton(buttonId, profileUserId, countElementId) {
  const btn = document.getElementById(buttonId);
  const countEl = document.getElementById(countElementId);
  if (!btn) return;

  async function refresh() {
    const { data: { session } } = await supabase.auth.getSession();
    const currentUserId = session?.user?.id || null;
    const following = currentUserId ? await isFollowing(currentUserId, profileUserId) : false;
    btn.textContent = following ? 'Following' : 'Follow';
    const { data: followers } = await supabase.from('follows').select('id', { count: 'exact' }).eq('followee', profileUserId);
    if (countEl) countEl.textContent = followers?.length || 0;
  }

  btn.onclick = async () => {
    await toggleFollow(profileUserId);
    await refresh();
  };

  // Subscribe to realtime follower changes for this profile to update counts
  supabase
    .channel(`public:follows:followee=eq.${profileUserId}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'follows', filter: `followee=eq.${profileUserId}` }, payload => {
      refresh();
    })
    .subscribe();

  // initial render
  refresh().catch(console.error);
}
