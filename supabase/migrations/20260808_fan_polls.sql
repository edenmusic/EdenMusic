-- Eden Music: Fan Polls
-- Polls can be created by the artist/developer and voted on once per authenticated fan.

create table if not exists public.fan_polls (
    id uuid primary key default gen_random_uuid(),
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    question text not null check (char_length(trim(question)) between 1 and 500),
    description text,
    starts_at timestamptz not null default now(),
    ends_at timestamptz,
    is_published boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    check (ends_at is null or ends_at > starts_at)
);

create table if not exists public.fan_poll_options (
    id uuid primary key default gen_random_uuid(),
    poll_id uuid not null references public.fan_polls(id) on delete cascade,
    option_text text not null check (char_length(trim(option_text)) between 1 and 200),
    position integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists public.fan_poll_votes (
    poll_id uuid not null references public.fan_polls(id) on delete cascade,
    option_id uuid not null references public.fan_poll_options(id) on delete cascade,
    fan_user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (poll_id, fan_user_id)
);

create index if not exists fan_polls_artist_idx on public.fan_polls(artist_user_id, created_at desc);
create index if not exists fan_polls_visibility_idx on public.fan_polls(is_published, starts_at, ends_at);
create index if not exists fan_poll_options_poll_idx on public.fan_poll_options(poll_id, position);
create index if not exists fan_poll_votes_option_idx on public.fan_poll_votes(option_id);

alter table public.fan_polls enable row level security;
alter table public.fan_poll_options enable row level security;
alter table public.fan_poll_votes enable row level security;

drop policy if exists "Anyone can read published polls" on public.fan_polls;
create policy "Anyone can read published polls" on public.fan_polls
for select using (
    is_published = true
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
);

drop policy if exists "Developers can manage polls" on public.fan_polls;
create policy "Developers can manage polls" on public.fan_polls
for all to authenticated
using (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
)
with check (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
);

drop policy if exists "Anyone can read published poll options" on public.fan_poll_options;
create policy "Anyone can read published poll options" on public.fan_poll_options
for select using (
    exists (
        select 1 from public.fan_polls p
        where p.id = poll_id
          and p.is_published = true
          and p.starts_at <= now()
          and (p.ends_at is null or p.ends_at > now())
    )
);

drop policy if exists "Developers can manage poll options" on public.fan_poll_options;
create policy "Developers can manage poll options" on public.fan_poll_options
for all to authenticated
using (
    exists (
        select 1 from public.fan_polls p
        where p.id = poll_id
          and p.artist_user_id = auth.uid()
          and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
    )
)
with check (
    exists (
        select 1 from public.fan_polls p
        where p.id = poll_id
          and p.artist_user_id = auth.uid()
          and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
    )
);

drop policy if exists "Fans can read own poll votes" on public.fan_poll_votes;
create policy "Fans can read own poll votes" on public.fan_poll_votes
for select to authenticated using (fan_user_id = auth.uid());

drop policy if exists "Fans can vote in active polls" on public.fan_poll_votes;
create policy "Fans can vote in active polls" on public.fan_poll_votes
for insert to authenticated
with check (
    fan_user_id = auth.uid()
    and exists (
        select 1 from public.fan_polls p
        where p.id = poll_id
          and p.is_published = true
          and p.starts_at <= now()
          and (p.ends_at is null or p.ends_at > now())
    )
    and exists (
        select 1 from public.fan_poll_options o
        where o.id = option_id and o.poll_id = fan_poll_votes.poll_id
    )
);

create or replace function public.cast_fan_poll_vote(p_poll_id uuid, p_option_id uuid)
returns boolean
language plpgsql
security invoker
as $$
begin
    if auth.uid() is null then raise exception 'Authentication required'; end if;
    if not exists (
        select 1 from public.fan_polls p
        where p.id = p_poll_id and p.is_published = true
          and p.starts_at <= now() and (p.ends_at is null or p.ends_at > now())
    ) then raise exception 'Poll is not active'; end if;
    if not exists (select 1 from public.fan_poll_options o where o.id = p_option_id and o.poll_id = p_poll_id) then
        raise exception 'Invalid poll option';
    end if;
    insert into public.fan_poll_votes (poll_id, option_id, fan_user_id)
    values (p_poll_id, p_option_id, auth.uid());
    return true;
exception when unique_violation then
    raise exception 'You have already voted in this poll';
end;
$$;
