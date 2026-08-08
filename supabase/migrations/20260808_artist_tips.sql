-- Eden Music: Tip the Artist foundation
-- Payment processing is intentionally not wired here.

create table if not exists public.artist_tip_settings (
    artist_user_id uuid primary key references auth.users(id) on delete cascade,
    enabled boolean not null default true,
    currency text not null default 'KES' check (char_length(currency) between 3 and 5),
    suggested_amounts numeric[] not null default '{100,250,500,1000}',
    updated_at timestamptz not null default now()
);

create table if not exists public.artist_tips (
    id uuid primary key default gen_random_uuid(),
    artist_user_id uuid not null references auth.users(id) on delete cascade,
    fan_user_id uuid not null references auth.users(id) on delete cascade,
    amount numeric(12,2) not null check (amount > 0),
    currency text not null default 'KES' check (char_length(currency) between 3 and 5),
    message text check (message is null or char_length(message) <= 500),
    payment_status text not null default 'pending' check (payment_status in ('pending','paid','failed','cancelled')),
    created_at timestamptz not null default now()
);

create index if not exists artist_tips_artist_created_idx
    on public.artist_tips(artist_user_id, created_at desc);

create index if not exists artist_tips_fan_created_idx
    on public.artist_tips(fan_user_id, created_at desc);

alter table public.artist_tip_settings enable row level security;
alter table public.artist_tips enable row level security;

drop policy if exists "Anyone can read enabled tip settings" on public.artist_tip_settings;
create policy "Anyone can read enabled tip settings"
on public.artist_tip_settings
for select
using (enabled = true);

drop policy if exists "Developers can manage tip settings" on public.artist_tip_settings;
create policy "Developers can manage tip settings"
on public.artist_tip_settings
for all
to authenticated
using (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
)
with check (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
);

drop policy if exists "Fans can create pending tips" on public.artist_tips;
create policy "Fans can create pending tips"
on public.artist_tips
for insert
to authenticated
with check (
    fan_user_id = auth.uid()
    and payment_status = 'pending'
    and exists (
        select 1 from public.artist_tip_settings s
        where s.artist_user_id = artist_tips.artist_user_id
          and s.enabled = true
    )
);

drop policy if exists "Fans can read own tips" on public.artist_tips;
create policy "Fans can read own tips"
on public.artist_tips
for select
to authenticated
using (fan_user_id = auth.uid());

drop policy if exists "Developers can manage artist tips" on public.artist_tips;
create policy "Developers can manage artist tips"
on public.artist_tips
for all
to authenticated
using (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
)
with check (
    artist_user_id = auth.uid()
    and exists (select 1 from public.profiles where profiles.user_id = auth.uid() and profiles.role = 'developer')
);
