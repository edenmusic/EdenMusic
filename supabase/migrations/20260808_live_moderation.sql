-- Eden Music: Live Moderation foundation
-- Provides developer-controlled mute/block actions for live sessions.

create table if not exists public.live_moderation_actions (
    id uuid primary key default gen_random_uuid(),
    live_event_id uuid not null,
    target_user_id uuid not null references auth.users(id) on delete cascade,
    moderator_user_id uuid not null references auth.users(id) on delete cascade,
    action_type text not null check (action_type in ('mute','unmute','block','unblock')),
    reason text check (reason is null or char_length(reason) <= 500),
    created_at timestamptz not null default now()
);

create index if not exists live_moderation_event_target_idx
    on public.live_moderation_actions(live_event_id, target_user_id, created_at desc);

create index if not exists live_moderation_target_idx
    on public.live_moderation_actions(target_user_id, created_at desc);

alter table public.live_moderation_actions enable row level security;

drop policy if exists "Developers can manage live moderation" on public.live_moderation_actions;
create policy "Developers can manage live moderation"
on public.live_moderation_actions
for all to authenticated
using (
    moderator_user_id = auth.uid()
    and exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid() and profiles.role = 'developer'
    )
)
with check (
    moderator_user_id = auth.uid()
    and exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid() and profiles.role = 'developer'
    )
);

create or replace function public.set_live_moderation_action(
    p_live_event_id uuid,
    p_target_user_id uuid,
    p_action_type text,
    p_reason text default null
)
returns public.live_moderation_actions
language plpgsql
security invoker
as $$
declare
    result public.live_moderation_actions;
begin
    if auth.uid() is null then raise exception 'Authentication required'; end if;
    if p_target_user_id = auth.uid() then raise exception 'Cannot moderate yourself'; end if;
    if p_action_type not in ('mute','unmute','block','unblock') then
        raise exception 'Invalid moderation action';
    end if;

    insert into public.live_moderation_actions
        (live_event_id, target_user_id, moderator_user_id, action_type, reason)
    values
        (p_live_event_id, p_target_user_id, auth.uid(), p_action_type, p_reason)
    returning * into result;

    return result;
end;
$$;

create or replace function public.get_live_user_moderation_state(
    p_live_event_id uuid,
    p_target_user_id uuid
)
returns table (
    is_muted boolean,
    is_blocked boolean
)
language sql
stable
security invoker
as $$
with latest as (
    select distinct on (action_type_group) action_type_group, action_type
    from (
        select
            case when action_type in ('mute','unmute') then 'mute' else 'block' end as action_type_group,
            action_type,
            created_at
        from public.live_moderation_actions
        where live_event_id = p_live_event_id
          and target_user_id = p_target_user_id
        order by action_type_group, created_at desc
    ) x
)
select
    coalesce((select action_type = 'mute' from latest where action_type_group = 'mute'), false) as is_muted,
    coalesce((select action_type = 'block' from latest where action_type_group = 'block'), false) as is_blocked;
$$;
