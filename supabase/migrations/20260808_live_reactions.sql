-- Eden Music: Live Reactions foundation
-- Stores lightweight reactions sent during an Eden Live session.

create table if not exists public.live_reactions (
    id uuid primary key default gen_random_uuid(),
    live_event_id uuid not null,
    fan_user_id uuid not null references auth.users(id) on delete cascade,
    reaction_type text not null check (reaction_type in ('heart','fire','clap','laugh','wow')),
    created_at timestamptz not null default now()
);

create index if not exists live_reactions_event_created_idx
    on public.live_reactions(live_event_id, created_at desc);

create index if not exists live_reactions_event_type_idx
    on public.live_reactions(live_event_id, reaction_type, created_at desc);

alter table public.live_reactions enable row level security;

drop policy if exists "Fans can send live reactions" on public.live_reactions;
create policy "Fans can send live reactions"
on public.live_reactions
for insert to authenticated
with check (fan_user_id = auth.uid());

drop policy if exists "Authenticated users can read live reactions" on public.live_reactions;
create policy "Authenticated users can read live reactions"
on public.live_reactions
for select to authenticated
using (true);

create or replace function public.send_live_reaction(
    p_live_event_id uuid,
    p_reaction_type text
)
returns public.live_reactions
language plpgsql
security invoker
as $$
declare
    result public.live_reactions;
begin
    if auth.uid() is null then
        raise exception 'Authentication required';
    end if;

    if p_reaction_type not in ('heart','fire','clap','laugh','wow') then
        raise exception 'Invalid reaction type';
    end if;

    insert into public.live_reactions (live_event_id, fan_user_id, reaction_type)
    values (p_live_event_id, auth.uid(), p_reaction_type)
    returning * into result;

    return result;
end;
$$;
