-- Eden Music: Following system foundation
-- A fan can follow an artist profile once. Unfollowing removes that relationship.

create table if not exists public.artist_follows (
    id uuid primary key default gen_random_uuid(),
    fan_user_id uuid not null references auth.users(id) on delete cascade,
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    constraint artist_follows_unique_follow unique (fan_user_id, artist_user_id),
    constraint artist_follows_not_self check (fan_user_id <> artist_user_id)
);

create index if not exists artist_follows_fan_user_id_idx
    on public.artist_follows(fan_user_id);

create index if not exists artist_follows_artist_user_id_idx
    on public.artist_follows(artist_user_id);

alter table public.artist_follows enable row level security;

drop policy if exists "Users can read follows" on public.artist_follows;
create policy "Users can read follows"
on public.artist_follows
for select
to authenticated
using (true);

drop policy if exists "Fans can follow artists" on public.artist_follows;
create policy "Fans can follow artists"
on public.artist_follows
for insert
to authenticated
with check (
    fan_user_id = auth.uid()
    and fan_user_id <> artist_user_id
    and exists (
        select 1
        from public.profiles
        where profiles.user_id = artist_follows.artist_user_id
          and profiles.role = 'developer'
    )
);

drop policy if exists "Fans can unfollow artists" on public.artist_follows;
create policy "Fans can unfollow artists"
on public.artist_follows
for delete
to authenticated
using (fan_user_id = auth.uid());
