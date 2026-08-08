-- supabase/migrations/2026-08-08-extended-schema.sql

-- Extended app schema for Eden Music feature set
-- Comments & moderation (supports replies via parent_id)
create table if not exists comments (
  id uuid default gen_random_uuid() primary key,
  content text not null,
  author uuid not null,
  parent_id uuid null,
  target_type text not null, -- 'song'|'video'|'announcement' etc
  target_id uuid not null,
  likes int default 0,
  is_reported boolean default false,
  created_at timestamptz default now()
);
create index if not exists idx_comments_target on comments(target_type, target_id);
create index if not exists idx_comments_parent on comments(parent_id);

-- Follow system
create table if not exists follows (
  id uuid default gen_random_uuid() primary key,
  follower uuid not null,
  followee uuid not null,
  created_at timestamptz default now(),
  constraint uq_follow unique(follower, followee)
);
create index if not exists idx_follows_follower on follows(follower);
create index if not exists idx_follows_followee on follows(followee);

-- Playlists
create table if not exists playlists (
  id uuid default gen_random_uuid() primary key,
  owner uuid not null,
  title text not null,
  is_public boolean default true,
  created_at timestamptz default now()
);
create table if not exists playlist_items (
  id uuid default gen_random_uuid() primary key,
  playlist_id uuid not null references playlists(id) on delete cascade,
  song_id uuid not null,
  position int default 0,
  added_at timestamptz default now()
);
create index if not exists idx_playlist_owner on playlists(owner);

-- Recently played and queue
create table if not exists recently_played (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  song_id uuid not null,
  played_at timestamptz default now()
);
create index if not exists idx_recently_played_user on recently_played(user_id, played_at desc);

create table if not exists play_queue (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  song_id uuid not null,
  position int not null,
  added_at timestamptz default now()
);
create index if not exists idx_play_queue_user on play_queue(user_id, position);

-- Lyrics sync (for animated synchronized lyrics)
create table if not exists lyrics_sync (
  id uuid default gen_random_uuid() primary key,
  song_id uuid not null,
  lrc text not null,
  created_at timestamptz default now()
);

-- Shares (song sharing)
create table if not exists shares (
  id uuid default gen_random_uuid() primary key,
  song_id uuid not null,
  shared_by uuid null,
  share_token text not null unique,
  created_at timestamptz default now(),
  expires_at timestamptz null
);

-- Offline downloads (records for authorized downloads)
create table if not exists offline_downloads (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  song_id uuid not null,
  downloaded_at timestamptz default now()
);
create index if not exists idx_offline_user on offline_downloads(user_id);

-- Announcements & polls & requests
create table if not exists announcements (
  id uuid default gen_random_uuid() primary key,
  author uuid not null,
  title text not null,
  body text,
  created_at timestamptz default now(),
  published boolean default false,
  published_at timestamptz null
);

create table if not exists polls (
  id uuid default gen_random_uuid() primary key,
  author uuid not null,
  question text not null,
  options jsonb not null, -- array of option objects {id,label}
  created_at timestamptz default now(),
  ends_at timestamptz null
);

create table if not exists poll_votes (
  id uuid default gen_random_uuid() primary key,
  poll_id uuid not null references polls(id) on delete cascade,
  voter uuid not null,
  option_id text not null,
  created_at timestamptz default now(),
  constraint uq_poll_vote unique(poll_id, voter)
);

create table if not exists fan_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  subject text,
  body text,
  status text default 'open', -- open|closed|answered
  created_at timestamptz default now()
);

-- Fan Vault membership levels & badges
create table if not exists fan_levels (
  id uuid default gen_random_uuid() primary key,
  key text not null unique, -- free/supporter/vip/premium
  title text not null,
  description text,
  price numeric null
);

create table if not exists fan_memberships (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  fan_level_id uuid not null references fan_levels(id),
  started_at timestamptz default now(),
  expires_at timestamptz null
);

create table if not exists badges (
  id uuid default gen_random_uuid() primary key,
  key text not null unique,
  title text not null,
  image_url text
);

create table if not exists user_badges (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  badge_id uuid not null references badges(id),
  awarded_at timestamptz default now()
);

-- Monetization: tips, paid content, digital products, coupons
create table if not exists tips (
  id uuid default gen_random_uuid() primary key,
  user_id uuid null,
  amount numeric not null,
  provider text,
  transaction_ref text,
  created_at timestamptz default now()
);

create table if not exists paid_content (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  price numeric not null,
  asset_url text,
  created_at timestamptz default now()
);

create table if not exists digital_products (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  price numeric not null,
  file_url text,
  created_at timestamptz default now()
);

create table if not exists coupons (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  discount_percent int null,
  discount_amount numeric null,
  expires_at timestamptz null,
  created_at timestamptz default now()
);

-- Live features: chat, reactions, moderation, viewers
create table if not exists live_sessions (
  id uuid default gen_random_uuid() primary key,
  title text,
  description text,
  scheduled_at timestamptz null,
  is_live boolean default false,
  created_at timestamptz default now()
);

create table if not exists live_messages (
  id uuid default gen_random_uuid() primary key,
  session_id uuid not null references live_sessions(id) on delete cascade,
  user_id uuid not null,
  message text not null,
  is_deleted boolean default false,
  created_at timestamptz default now()
);

create table if not exists live_reactions (
  id uuid default gen_random_uuid() primary key,
  session_id uuid not null references live_sessions(id) on delete cascade,
  user_id uuid null,
  reaction text not null,
  created_at timestamptz default now()
);

create table if not exists live_viewers (
  id uuid default gen_random_uuid() primary key,
  session_id uuid not null references live_sessions(id) on delete cascade,
  user_id uuid null,
  joined_at timestamptz default now()
);

create table if not exists moderation_actions (
  id uuid default gen_random_uuid() primary key,
  target_table text not null,
  target_id uuid not null,
  action text not null, -- delete|mute|block|warn
  moderator uuid not null,
  reason text,
  created_at timestamptz default now()
);

-- Admin reports
create table if not exists reports (
  id uuid default gen_random_uuid() primary key,
  reporter uuid null,
  target_table text not null,
  target_id uuid not null,
  reason text,
  status text default 'open',
  created_at timestamptz default now()
);

-- Analytics/events
create table if not exists analytics_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid null,
  event_type text not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Content scheduling
create table if not exists content_schedule (
  id uuid default gen_random_uuid() primary key,
  content_table text not null,
  content_id uuid not null,
  publish_at timestamptz not null,
  created_at timestamptz default now()
);

-- Audit log
create table if not exists audit_logs (
  id uuid default gen_random_uuid() primary key,
  actor uuid null,
  action text not null,
  target_table text null,
  target_id uuid null,
  data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Basic trigger example: when announcements are published, create notifications for followers
create function notify_on_announcement_publish() returns trigger language plpgsql as $$
begin
  if (new.published = true and (old is null or old.published = false)) then
    insert into notifications (target, type, title, body, data, channel, created_at)
      values ('all', 'ANNOUNCEMENT', new.title, new.body, jsonb_build_object('announcement_id', new.id), 'in_app', now());
  end if;
  return new;
end;
$$;

create trigger announcement_publish_trigger
after insert or update on announcements
for each row execute function notify_on_announcement_publish();
