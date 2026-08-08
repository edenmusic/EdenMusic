-- Eden Music: Fan Vault membership access levels
-- This migration adds access metadata without changing existing Fan Vault rows.
-- Existing content remains free unless explicitly assigned a higher level later.

create table if not exists public.fan_vault_access (
    id uuid primary key default gen_random_uuid(),
    fan_vault_video_id uuid not null unique,
    required_level public.fan_membership_level not null default 'free',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists fan_vault_access_level_idx
    on public.fan_vault_access(required_level);

alter table public.fan_vault_access enable row level security;

drop policy if exists "Users can read fan vault access" on public.fan_vault_access;
create policy "Users can read fan vault access"
on public.fan_vault_access
for select
to authenticated
using (true);

drop policy if exists "Developers can manage fan vault access" on public.fan_vault_access;
create policy "Developers can manage fan vault access"
on public.fan_vault_access
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

create or replace function public.can_access_fan_vault_video(p_video_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security invoker
as $$
    select
        public.fan_membership_rank(public.get_fan_membership_level(p_user_id))
        >= public.fan_membership_rank(coalesce(
            (select required_level from public.fan_vault_access where fan_vault_video_id = p_video_id),
            'free'::public.fan_membership_level
        ));
$$;
