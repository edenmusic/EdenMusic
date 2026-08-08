-- Eden Music: Artist announcements foundation
-- Announcements are authored by developer/artist accounts and can be drafted,
-- scheduled, published, or unpublished without affecting songs, events, or Fan Vault content.

create table if not exists public.announcements (
    id uuid primary key default gen_random_uuid(),
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    title text not null check (char_length(trim(title)) between 1 and 200),
    body text not null check (char_length(trim(body)) between 1 and 10000),
    image_url text,
    scheduled_for timestamptz,
    published_at timestamptz,
    is_published boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists announcements_artist_user_id_idx
    on public.announcements(artist_user_id);

create index if not exists announcements_published_idx
    on public.announcements(is_published, published_at desc);

create index if not exists announcements_scheduled_for_idx
    on public.announcements(scheduled_for);

alter table public.announcements enable row level security;

drop policy if exists "Anyone can read published announcements" on public.announcements;
create policy "Anyone can read published announcements"
on public.announcements
for select
using (
    is_published = true
    and (scheduled_for is null or scheduled_for <= now())
);

drop policy if exists "Developers can manage announcements" on public.announcements;
create policy "Developers can manage announcements"
on public.announcements
for all
to authenticated
using (
    artist_user_id = auth.uid()
    and exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
)
with check (
    artist_user_id = auth.uid()
    and exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
);
