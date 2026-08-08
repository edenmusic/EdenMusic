-- supabase/migrations/2026-08-09-playlists.sql

-- Playlists and queue schema for Eden Music
-- Playlists: user-created collections of songs
create table if not exists playlists (
  id uuid default gen_random_uuid() primary key,
  owner uuid not null,
  title text not null,
  description text null,
  is_public boolean default true,
  created_at timestamptz default now()
);

create table if not exists playlist_items (
  id uuid default gen_random_uuid() primary key,
  playlist_id uuid not null references playlists(id) on delete cascade,
  song_id uuid not null,
  position int default 0,
  added_at timestamptz default now(),
  constraint uq_playlist_song unique(playlist_id, song_id)
);

create index if not exists idx_playlists_owner on playlists(owner);
create index if not exists idx_playlist_items_playlist on playlist_items(playlist_id, position);

-- Play queue (per-user ephemeral queue)
create table if not exists play_queue (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  song_id uuid not null,
  position int not null,
  added_at timestamptz default now()
);
create index if not exists idx_play_queue_user_pos on play_queue(user_id, position);

-- Recently played already provided in extended schema, ensure index exists
create index if not exists idx_recently_played_user on recently_played(user_id, played_at desc);

-- RLS: enable and policies for playlists and playlist_items
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_items ENABLE ROW LEVEL SECURITY;

-- Only authenticated users can create playlists and must be owner
CREATE POLICY "playlists_insert_auth" ON playlists
  FOR INSERT
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (owner = auth.uid());

-- Owners can update/delete their playlists
CREATE POLICY "playlists_update_owner" ON playlists
  FOR UPDATE
  USING (owner = auth.uid())
  WITH CHECK (owner = auth.uid());

CREATE POLICY "playlists_delete_owner" ON playlists
  FOR DELETE
  USING (owner = auth.uid());

-- Select: allow public playlists to be readable by anyone; private only by owner
CREATE POLICY "playlists_select_public_or_owner" ON playlists
  FOR SELECT
  USING (is_public = true OR owner = auth.uid());

-- playlist_items policies: only playlist owner may insert/delete
CREATE POLICY "playlist_items_insert_owner" ON playlist_items
  FOR INSERT
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (exists (select 1 from playlists p where p.id = playlist_items.playlist_id and p.owner = auth.uid()));

CREATE POLICY "playlist_items_delete_owner" ON playlist_items
  FOR DELETE
  USING (exists (select 1 from playlists p where p.id = playlist_items.playlist_id and p.owner = auth.uid()));

CREATE POLICY "playlist_items_select" ON playlist_items
  FOR SELECT
  USING (exists (select 1 from playlists p where p.id = playlist_items.playlist_id and (p.is_public = true OR p.owner = auth.uid())));

-- Play queue policies: user owns their queue rows
ALTER TABLE play_queue ENABLE ROW LEVEL SECURITY;
CREATE POLICY "play_queue_insert_owner" ON play_queue
  FOR INSERT
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "play_queue_select_owner" ON play_queue
  FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "play_queue_delete_owner" ON play_queue
  FOR DELETE
  USING (user_id = auth.uid());

-- Helper function: reorder playlist items (simple reposition by updating positions)
CREATE OR REPLACE FUNCTION reorder_playlist_items(p_playlist_id uuid, p_item_id uuid, p_new_position int) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  _old_pos int;
BEGIN
  SELECT position INTO _old_pos FROM playlist_items WHERE id = p_item_id AND playlist_id = p_playlist_id;
  IF _old_pos IS NULL THEN
    RAISE EXCEPTION 'item not found in playlist';
  END IF;

  IF p_new_position = _old_pos THEN
    RETURN;
  END IF;

  IF p_new_position > _old_pos THEN
    UPDATE playlist_items SET position = position - 1
      WHERE playlist_id = p_playlist_id AND position > _old_pos AND position <= p_new_position;
  ELSE
    UPDATE playlist_items SET position = position + 1
      WHERE playlist_id = p_playlist_id AND position >= p_new_position AND position < _old_pos;
  END IF;

  UPDATE playlist_items SET position = p_new_position WHERE id = p_item_id;
END;
$$;
