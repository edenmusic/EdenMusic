-- Eden Music: VIP / exclusive Fan Vault membership foundation
-- Payment wiring is intentionally excluded. Membership levels can be assigned
-- by trusted developer tooling now and connected to payments later.

create type public.fan_membership_level as enum ('free', 'supporter', 'vip', 'premium');

create table if not exists public.fan_memberships (
    user_id uuid primary key references auth.users(id) on delete cascade,
    level public.fan_membership_level not null default 'free',
    starts_at timestamptz not null default now(),
    expires_at timestamptz,
    updated_at timestamptz not null default now()
);

create index if not exists fan_memberships_level_idx
    on public.fan_memberships(level);

alter table public.fan_memberships enable row level security;

drop policy if exists "Users can read own membership" on public.fan_memberships;
create policy "Users can read own membership"
on public.fan_memberships
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Developers can manage memberships" on public.fan_memberships;
create policy "Developers can manage memberships"
on public.fan_memberships
for all
to authenticated
using (
    exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
)
with check (
    exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
);

create or replace function public.get_fan_membership_level(p_user_id uuid default auth.uid())
returns public.fan_membership_level
language sql
stable
security invoker
as $$
    select coalesce(
        (
            select fm.level
            from public.fan_memberships fm
            where fm.user_id = p_user_id
              and (fm.expires_at is null or fm.expires_at > now())
        ),
        'free'::public.fan_membership_level
    );
$$;

-- Access hierarchy used by future Fan Vault content restrictions.
create or replace function public.fan_membership_rank(p_level public.fan_membership_level)
returns integer
language sql
immutable
as $$
    select case p_level
        when 'free' then 0
        when 'supporter' then 1
        when 'vip' then 2
        when 'premium' then 3
    end;
$$;
