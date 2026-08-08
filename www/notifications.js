// www/notifications.js
// Client-side helper: subscribe to Supabase notifications table and show in-app banners

// Require: window.supabase (already in repo) and existing UI helper showMessage/openNotifications/loadNotifications

export async function initNotificationsClient() {
  if (!window.supabase) return;

  try {
    const { data: { session } } = await supabase.auth.getSession();
    const userId = session?.user?.id || null;

    // Subscribe to realtime notifications inserts
    const channel = supabase
      .channel('public:notifications')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, payload => {
        const note = payload.new;
        const deliver = (
          note.target === 'all' ||
          (note.target === 'user' && note.target_user === userId) ||
          (note.target === 'role' && /* TODO: check user role */ false)
        );

        if (!deliver) return;

        // Add to UI: if Notifications screen is open, reload list; otherwise show banner
        if (document.getElementById('notifications-screen')?.classList?.contains('active')) {
          loadNotifications();
        } else {
          showInAppNotificationBanner(note.title, note.body || '', note.data || {});
        }
      })
      .subscribe();

    // load existing notifications for the user
    await loadNotifications();

    return channel;
  } catch (err) {
    console.error('initNotificationsClient error', err);
  }
}

export async function loadNotifications() {
  const { data: { session } } = await supabase.auth.getSession();
  const userId = session?.user?.id || null;

  if (!userId) {
    // Show generic or nothing
    const list = document.getElementById('notifications-list');
    if (list) list.innerHTML = '<p class="dashboard-empty">Sign in to see notifications</p>';
    return;
  }

  // Fetch last 50 notifications where target=all or target_user matches user
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .or(`target.eq.all,target_user.eq.${userId}`)
    .order('created_at', { ascending: false })
    .limit(50);

  const list = document.getElementById('notifications-list');
  if (!list) return;

  if (error) {
    list.innerHTML = `<p class="dashboard-empty">Error loading notifications</p>`;
    console.error(error);
    return;
  }

  if (!data || data.length === 0) {
    list.innerHTML = '<p class="dashboard-empty">No notifications yet.</p>';
    return;
  }

  list.innerHTML = '';
  data.forEach(n => {
    const item = document.createElement('div');
    item.className = 'notification-row';
    item.innerHTML = `
      <strong>${escapeHtml(n.title)}</strong>
      <p>${escapeHtml(n.body || '')}</p>
      <small>${new Date(n.created_at).toLocaleString()}</small>
    `;
    list.appendChild(item);
  });
}

function showInAppNotificationBanner(title, body, data) {
  // Simple banner: reuse showMessage with clickable to open Notifications
  showMessage(`${title} — ${body}`);
}

function escapeHtml(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
