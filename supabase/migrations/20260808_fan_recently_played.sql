-- Eden Music: fan recently-played foundation
-- Music-player UI wiring is intentionally separate from this migration.

create table if not exists public.fan_recently_played (
    user_id uuid not null references auth.users(id) on delete cascade,
    song_id uuid not null,
    last_played_at timestamptz not null default now(),
    play_count bigint not null default 1 check (play_count > 0),
    primary key (user_id, song_id)
);

create index if not exists fan_recently_played_user_last_played_idx
    on public.fan_recently_played(user_id, last_played_at desc);

alter table public.fan_recently_played enable row level security;

drop policy if exists "Fans can read own recently played" on public.fan_recently_played;
create policy "Fans can read own recently played"
on public.fan_recently_played
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Fans can record own recently played" on public.fan_recently_played;
create policy "Fans can record own recently played"
on public.fan_recently_played
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Fans can update own recently played" on public.fan_recently_played;
create policy "Fans can update own recently played"
on public.fan_recently_played
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Fans can delete own recently played" on public.fan_recently_played;
create policy "Fans can delete own recently played"
on public.fan_recently_played
for delete
to authenticated
using (user_id = auth.uid());

create or replace function public.record_fan_song_play(p_song_id uuid)
returns public.fan_recently_played
language plpgsql
security invoker
as $$
declare
    result public.fan_recently_played;
begin
    if auth.uid() is null then
        raise exception 'Authentication required';
    end if;

    insert into public.fan_recently_played (user_id, song_id, last_played_at, play_count)
    values (auth.uid(), p_song_id, now(), 1)
    on conflict (user_id, song_id)
    do update set
        last_played_at = now(),
        play_count = public.fan_recently_played.play_count + 1
    returning * into result;

    return result;
end;
$$;
