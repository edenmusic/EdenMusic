-- Eden Music: live chat foundation
-- Stores fan messages for an Eden live session. Real-time delivery can be enabled
-- by adding this table to Supabase Realtime publication in the project dashboard.

create table if not exists public.live_chat_messages (
    id uuid primary key default gen_random_uuid(),
    live_event_id uuid not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    message text not null check (char_length(trim(message)) between 1 and 500),
    created_at timestamptz not null default now()
);

create index if not exists live_chat_messages_event_created_idx
    on public.live_chat_messages(live_event_id, created_at asc);

create index if not exists live_chat_messages_user_id_idx
    on public.live_chat_messages(user_id);

alter table public.live_chat_messages enable row level security;

drop policy if exists "Authenticated users can read live chat" on public.live_chat_messages;
create policy "Authenticated users can read live chat"
on public.live_chat_messages
for select
to authenticated
using (true);

drop policy if exists "Users can send live chat messages" on public.live_chat_messages;
create policy "Users can send live chat messages"
on public.live_chat_messages
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can delete own live chat messages" on public.live_chat_messages;
create policy "Users can delete own live chat messages"
on public.live_chat_messages
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "Developers can moderate live chat" on public.live_chat_messages;
create policy "Developers can moderate live chat"
on public.live_chat_messages
for all
to authenticated
using (
    exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
)
with check (
    exists (
        select 1
        from public.profiles
        where profiles.user_id = auth.uid()
          and profiles.role = 'developer'
    )
);
