-- Eden Music: Recently Played foundation
-- Stores a fan's most recently played songs without duplicating the song itself.

create table if not exists public.recently_played (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    song_id uuid not null references public.songs(id) on delete cascade,
    played_at timestamptz not null default now(),
    constraint recently_played_unique_user_song unique (user_id, song_id)
);

create index if not exists recently_played_user_played_at_idx
    on public.recently_played(user_id, played_at desc);

alter table public.recently_played enable row level security;

drop policy if exists "Users can read their recently played" on public.recently_played;
create policy "Users can read their recently played"
on public.recently_played
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can add their recently played" on public.recently_played;
create policy "Users can add their recently played"
on public.recently_played
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update their recently played" on public.recently_played;
create policy "Users can update their recently played"
on public.recently_played
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can remove their recently played" on public.recently_played;
create policy "Users can remove their recently played"
on public.recently_played
for delete
to authenticated
using (user_id = auth.uid());
