-- Eden Music: fan favorites foundation
-- UI wiring is intentionally separate from this migration.

create table if not exists public.fan_favorites (
    user_id uuid not null references auth.users(id) on delete cascade,
    song_id uuid not null,
    created_at timestamptz not null default now(),
    primary key (user_id, song_id)
);

create index if not exists fan_favorites_user_created_idx
    on public.fan_favorites(user_id, created_at desc);

create index if not exists fan_favorites_song_idx
    on public.fan_favorites(song_id);

alter table public.fan_favorites enable row level security;

drop policy if exists "Fans can read own favorites" on public.fan_favorites;
create policy "Fans can read own favorites"
on public.fan_favorites
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Fans can add own favorites" on public.fan_favorites;
create policy "Fans can add own favorites"
on public.fan_favorites
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Fans can remove own favorites" on public.fan_favorites;
create policy "Fans can remove own favorites"
on public.fan_favorites
for delete
to authenticated
using (user_id = auth.uid());

create or replace function public.set_fan_song_favorite(p_song_id uuid, p_favorite boolean)
returns boolean
language plpgsql
security invoker
as $$
begin
    if auth.uid() is null then
        raise exception 'Authentication required';
    end if;

    if p_favorite then
        insert into public.fan_favorites (user_id, song_id)
        values (auth.uid(), p_song_id)
        on conflict (user_id, song_id) do nothing;
    else
        delete from public.fan_favorites
        where user_id = auth.uid()
          and song_id = p_song_id;
    end if;

    return p_favorite;
end;
$$;
