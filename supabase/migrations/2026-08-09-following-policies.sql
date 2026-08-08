-- supabase/migrations/2026-08-09-following-policies.sql

-- Enable RLS on follows if not already enabled
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert follow rows where follower = auth.uid()
CREATE POLICY "follows_insert_auth" ON follows
  FOR INSERT
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (follower = auth.uid());

-- Allow followers to delete their own follow rows
CREATE POLICY "follows_delete_owner" ON follows
  FOR DELETE
  USING (follower = auth.uid());

-- Allow anyone to select follow rows (could be tightened in production)
CREATE POLICY "follows_select" ON follows
  FOR SELECT
  USING (true);

-- Trigger: when a new follow is created, create an in-app notification for the followed user
CREATE FUNCTION notify_on_follow() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO notifications (target, target_user, type, title, body, data, channel, created_at)
  VALUES (
    'user',
    NEW.followee,
    'NEW_FOLLOWER',
    'New follower',
    (SELECT coalesce(display_name, 'Someone') || ' started following you' FROM users WHERE id = NEW.follower),
    jsonb_build_object('follower_id', NEW.follower),
    'in_app',
    now()
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER follow_notify
AFTER INSERT ON follows
FOR EACH ROW EXECUTE FUNCTION notify_on_follow();
