-- Eden Music: generic content scheduling foundation
-- UI wiring and automatic publishing workers can consume this table later.

create type public.scheduled_content_type as enum (
    'song',
    'fan_vault_video',
    'announcement',
    'event'
);

create type public.scheduled_content_status as enum (
    'scheduled',
    'published',
    'cancelled'
);

create table if not exists public.content_schedules (
    id uuid primary key default gen_random_uuid(),
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    content_type public.scheduled_content_type not null,
    content_id uuid not null,
    publish_at timestamptz not null,
    status public.scheduled_content_status not null default 'scheduled',
    published_at timestamptz,
    cancelled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint content_schedules_unique_content unique (content_type, content_id)
);

create index if not exists content_schedules_due_idx
    on public.content_schedules(status, publish_at);

create index if not exists content_schedules_artist_idx
    on public.content_schedules(artist_user_id, publish_at desc);

alter table public.content_schedules enable row level security;

drop policy if exists "Developers can manage content schedules" on public.content_schedules;
create policy "Developers can manage content schedules"
on public.content_schedules
for all
to authenticated
using (
    artist_user_id = auth.uid()
    and exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
)
with check (
    artist_user_id = auth.uid()
    and exists (
        select 1 from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
);

create or replace function public.get_due_content_schedules()
returns setof public.content_schedules
language sql
stable
security invoker
as $$
    select *
    from public.content_schedules
    where status = 'scheduled'
      and publish_at <= now()
    order by publish_at asc;
$$;

create or replace function public.cancel_content_schedule(p_schedule_id uuid)
returns boolean
language plpgsql
security invoker
as $$
begin
    update public.content_schedules
    set status = 'cancelled',
        cancelled_at = now(),
        updated_at = now()
    where id = p_schedule_id
      and artist_user_id = auth.uid()
      and status = 'scheduled';
    return found;
end;
$$;
