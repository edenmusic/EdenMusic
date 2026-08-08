-- Eden Music: fan profile foundation
-- Kept separate from the existing artist/developer profile structure so existing
-- public artist profiles remain untouched.

create table if not exists public.fan_profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    username text not null unique check (char_length(trim(username)) between 3 and 30),
    display_name text not null check (char_length(trim(display_name)) between 1 and 80),
    avatar_url text,
    bio text check (bio is null or char_length(bio) <= 500),
    is_public boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists fan_profiles_public_idx
    on public.fan_profiles(is_public);

alter table public.fan_profiles enable row level security;

drop policy if exists "Public fan profiles are readable" on public.fan_profiles;
create policy "Public fan profiles are readable"
on public.fan_profiles
for select
using (is_public = true or user_id = auth.uid());

drop policy if exists "Users can create own fan profile" on public.fan_profiles;
create policy "Users can create own fan profile"
on public.fan_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update own fan profile" on public.fan_profiles;
create policy "Users can update own fan profile"
on public.fan_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can delete own fan profile" on public.fan_profiles;
create policy "Users can delete own fan profile"
on public.fan_profiles
for delete
to authenticated
using (user_id = auth.uid());

-- Case-insensitive username uniqueness helper.
create unique index if not exists fan_profiles_username_lower_idx
    on public.fan_profiles(lower(username));
