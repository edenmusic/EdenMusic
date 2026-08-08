-- Eden Music: live viewer presence foundation
-- A fan has at most one presence row per live event. The client refreshes last_seen
-- while viewing; stale rows are excluded from the active-viewer count.

create table if not exists public.live_viewers (
    live_event_id uuid not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    joined_at timestamptz not null default now(),
    last_seen_at timestamptz not null default now(),
    primary key (live_event_id, user_id)
);

create index if not exists live_viewers_event_last_seen_idx
    on public.live_viewers(live_event_id, last_seen_at desc);

alter table public.live_viewers enable row level security;

drop policy if exists "Authenticated users can read live viewers" on public.live_viewers;
create policy "Authenticated users can read live viewers"
on public.live_viewers
for select
to authenticated
using (true);

drop policy if exists "Users can manage own live presence" on public.live_viewers;
create policy "Users can manage own live presence"
on public.live_viewers
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Developers can moderate live viewer presence" on public.live_viewers;
create policy "Developers can moderate live viewer presence"
on public.live_viewers
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

create or replace function public.get_live_viewer_count(p_live_event_id uuid)
returns bigint
language sql
stable
security invoker
as $$
    select count(*)
    from public.live_viewers
    where live_event_id = p_live_event_id
      and last_seen_at > now() - interval '90 seconds';
$$;
