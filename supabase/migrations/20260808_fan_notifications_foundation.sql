-- Eden Music: Fan notifications foundation
-- Creates a broadcast-capable notification feed plus per-user read state.

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    type text not null check (type in (
        'new_music',
        'fan_vault_video',
        'live_starting',
        'event_reminder',
        'merchandise_drop',
        'announcement'
    )),
    title text not null,
    body text,
    target_type text,
    target_id uuid,
    scheduled_for timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.notification_reads (
    notification_id uuid not null references public.notifications(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    read_at timestamptz not null default now(),
    primary key (notification_id, user_id)
);

create index if not exists notifications_user_id_idx
    on public.notifications(user_id);

create index if not exists notifications_created_at_idx
    on public.notifications(created_at desc);

create index if not exists notifications_scheduled_for_idx
    on public.notifications(scheduled_for);

create index if not exists notification_reads_user_id_idx
    on public.notification_reads(user_id);

alter table public.notifications enable row level security;
alter table public.notification_reads enable row level security;

-- Fans can see notifications addressed to them and broadcast notifications.
drop policy if exists "Fans can read notifications" on public.notifications;
create policy "Fans can read notifications"
on public.notifications
for select
to authenticated
using (user_id is null or user_id = auth.uid());

-- Users can manage only their own read state.
drop policy if exists "Users can read their notification state" on public.notification_reads;
create policy "Users can read their notification state"
on public.notification_reads
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can mark notifications read" on public.notification_reads;
create policy "Users can mark notifications read"
on public.notification_reads
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update their notification state" on public.notification_reads;
create policy "Users can update their notification state"
on public.notification_reads
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Developers can create and manage notification records.
drop policy if exists "Developers can manage notifications" on public.notifications;
create policy "Developers can manage notifications"
on public.notifications
for all
to authenticated
using (
    exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
)
with check (
    exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
);
