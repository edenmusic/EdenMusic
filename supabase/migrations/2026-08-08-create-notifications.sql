-- supabase/migrations/2026-08-08-create-notifications.sql

-- Notifications table: stores in-app and push notifications
create extension if not exists pgcrypto;

create table if not exists notifications (
  id uuid default gen_random_uuid() primary key,
  target text default 'user', -- 'user'|'role'|'all'
  target_user uuid null,      -- when target = 'user'
  target_role text null,      -- when target = 'role'
  type text not null,
  title text not null,
  body text,
  data jsonb default '{}'::jsonb,
  channel text default 'in_app', -- 'in_app'|'push'
  created_at timestamptz default now(),
  sent boolean default false,
  sent_at timestamptz null
);

create index if not exists idx_notifications_target_user on notifications(target_user);
create index if not exists idx_notifications_created_at on notifications(created_at desc);

-- Table to store push tokens for users/devices
create table if not exists user_push_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  provider text not null,    -- 'fcm'|'apns'|'webpush'
  token text not null,
  platform text null,        -- 'android'|'ios'|'web'
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  last_seen timestamptz default now(),
  constraint uq_user_provider_token unique(user_id, provider, token)
);

create index if not exists idx_user_push_tokens_user_id on user_push_tokens(user_id);
