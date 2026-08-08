-- Eden Music: fan comments foundation
-- Supports comments on songs and Fan Vault videos, plus artist replies.

create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    song_id uuid references public.songs(id) on delete cascade,
    fan_vault_video_id uuid,
    parent_comment_id uuid references public.comments(id) on delete cascade,
    body text not null check (char_length(trim(body)) between 1 and 2000),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint comments_single_target check (
        (song_id is not null and fan_vault_video_id is null)
        or
        (song_id is null and fan_vault_video_id is not null)
    )
);

create index if not exists comments_song_id_idx
    on public.comments(song_id, created_at desc);

create index if not exists comments_fan_vault_video_id_idx
    on public.comments(fan_vault_video_id, created_at desc);

create index if not exists comments_user_id_idx
    on public.comments(user_id);

create index if not exists comments_parent_comment_id_idx
    on public.comments(parent_comment_id);

alter table public.comments enable row level security;

drop policy if exists "Authenticated users can read comments" on public.comments;
create policy "Authenticated users can read comments"
on public.comments
for select
to authenticated
using (true);

drop policy if exists "Users can create comments" on public.comments;
create policy "Users can create comments"
on public.comments
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can edit own comments" on public.comments;
create policy "Users can edit own comments"
on public.comments
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can delete own comments" on public.comments;
create policy "Users can delete own comments"
on public.comments
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "Developers can moderate comments" on public.comments;
create policy "Developers can moderate comments"
on public.comments
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
