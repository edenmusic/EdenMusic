-- Eden Music: fan following foundation
-- Supports fans following artists without altering existing artist profiles.

create table if not exists public.fan_following (
    fan_user_id uuid not null references auth.users(id) on delete cascade,
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (fan_user_id, artist_user_id),
    check (fan_user_id <> artist_user_id)
);

create index if not exists fan_following_fan_created_idx
    on public.fan_following(fan_user_id, created_at desc);

create index if not exists fan_following_artist_idx
    on public.fan_following(artist_user_id);

alter table public.fan_following enable row level security;

drop policy if exists "Fans can read following" on public.fan_following;
create policy "Fans can read following"
on public.fan_following
for select
to authenticated
using (fan_user_id = auth.uid() or artist_user_id = auth.uid());

drop policy if exists "Fans can follow artists" on public.fan_following;
create policy "Fans can follow artists"
on public.fan_following
for insert
to authenticated
with check (
    fan_user_id = auth.uid()
    and exists (
        select 1 from public.profiles
        where profiles.user_id = fan_following.artist_user_id
          and profiles.role = 'developer'
    )
);

drop policy if exists "Fans can unfollow artists" on public.fan_following;
create policy "Fans can unfollow artists"
on public.fan_following
for delete
to authenticated
using (fan_user_id = auth.uid());

create or replace function public.set_artist_following(p_artist_user_id uuid, p_follow boolean)
returns boolean
language plpgsql
security invoker
as $$
begin
    if auth.uid() is null then
        raise exception 'Authentication required';
    end if;

    if auth.uid() = p_artist_user_id then
        raise exception 'Cannot follow yourself';
    end if;

    if not exists (
        select 1 from public.profiles
        where profiles.user_id = p_artist_user_id
          and profiles.role = 'developer'
    ) then
        raise exception 'Artist not found';
    end if;

    if p_follow then
        insert into public.fan_following (fan_user_id, artist_user_id)
        values (auth.uid(), p_artist_user_id)
        on conflict (fan_user_id, artist_user_id) do nothing;
    else
        delete from public.fan_following
        where fan_user_id = auth.uid()
          and artist_user_id = p_artist_user_id;
    end if;

    return p_follow;
end;
$$;

create or replace function public.get_artist_follower_count(p_artist_user_id uuid)
returns bigint
language sql
stable
security invoker
as $$
    select count(*)
    from public.fan_following
    where artist_user_id = p_artist_user_id;
$$;
