/*
# Create AI Video Studio schema

1. Overview
   Adds the tables that back the AI Video Generator mobile app:
   - `app_users` mirrors the auth user with a display name for the app.
   - `videos` stores each generation job (title, prompt, style, status,
     progress, thumbnail/video URLs, color palette, timestamps).
   - `video_captions` stores structured, timestamped caption segments per
     video.

   The mobile app authenticates via custom JWT issuance from the
   `auth-login` / `auth-register` edge functions. Those functions create
   real auth.users rows and return the Supabase access token, so RLS can
   rely on `auth.uid()` for ownership checks.

2. New Tables
   - `app_users`
     - `id` uuid PK, references `auth.users(id)` ON DELETE CASCADE
     - `name` text (display name)
     - `created_at` timestamptz default now()
   - `videos`
     - `id` uuid PK default gen_random_uuid()
     - `user_id` uuid NOT NULL DEFAULT auth.uid(), references app_users
     - `title` text not null
     - `prompt` text not null
     - `style` text not null
     - `status` text not null default 'queued' (queued|processing|completed|failed)
     - `progress` int not null default 0 (0..100)
     - `thumbnail_url` text
     - `video_url` text
     - `color_palette` text[] default '{}'
     - `error_message` text
     - `created_at` timestamptz default now()
     - `completed_at` timestamptz
   - `video_captions`
     - `id` uuid PK default gen_random_uuid()
     - `video_id` uuid references videos(id) ON DELETE CASCADE
     - `start_ms` int not null
     - `end_ms` int not null
     - `text` text not null
     - `seq` int not null default 0
     - `language` text

3. Indexes
   - videos(user_id) for per-user listings
   - video_captions(video_id, seq) for ordered caption retrieval

4. Security
   - RLS enabled on all three tables.
   - app_users: owner can read/update own row; insert via service role
     only (edge function creates the row after auth signup).
   - videos: owner-scoped CRUD (select/insert/update/delete) for
     authenticated users; insert uses DEFAULT auth.uid() so the client
     does not need to pass user_id.
   - video_captions: owner-scoped through the parent video (SELECT for
     owner; INSERT/UPDATE/DELETE restricted to the video owner).

5. Notes
   - `user_id` defaults to `auth.uid()` so app inserts that omit it
     still satisfy the WITH CHECK ownership predicate.
   - No destructive operations; safe to re-run (idempotent).
*/

CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_app_user" ON app_users;
CREATE POLICY "select_own_app_user" ON app_users FOR SELECT
  TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_app_user" ON app_users;
CREATE POLICY "update_own_app_user" ON app_users FOR UPDATE
  TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE TABLE IF NOT EXISTS videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES app_users(id) ON DELETE CASCADE,
  title text NOT NULL,
  prompt text NOT NULL,
  style text NOT NULL,
  status text NOT NULL DEFAULT 'queued',
  progress int NOT NULL DEFAULT 0,
  thumbnail_url text,
  video_url text,
  color_palette text[] NOT NULL DEFAULT '{}',
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_videos" ON videos;
CREATE POLICY "select_own_videos" ON videos FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "insert_own_videos" ON videos;
CREATE POLICY "insert_own_videos" ON videos FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_videos" ON videos;
CREATE POLICY "update_own_videos" ON videos FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "delete_own_videos" ON videos;
CREATE POLICY "delete_own_videos" ON videos FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS videos_user_id_idx ON videos(user_id);

CREATE TABLE IF NOT EXISTS video_captions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id uuid NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  start_ms int NOT NULL DEFAULT 0,
  end_ms int NOT NULL DEFAULT 0,
  text text NOT NULL,
  seq int NOT NULL DEFAULT 0,
  language text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE video_captions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_captions" ON video_captions;
CREATE POLICY "select_own_captions" ON video_captions FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM videos v WHERE v.id = video_captions.video_id AND v.user_id = auth.uid())
  );

DROP POLICY IF EXISTS "insert_own_captions" ON video_captions;
CREATE POLICY "insert_own_captions" ON video_captions FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM videos v WHERE v.id = video_captions.video_id AND v.user_id = auth.uid())
  );

DROP POLICY IF EXISTS "update_own_captions" ON video_captions;
CREATE POLICY "update_own_captions" ON video_captions FOR UPDATE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM videos v WHERE v.id = video_captions.video_id AND v.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM videos v WHERE v.id = video_captions.video_id AND v.user_id = auth.uid())
  );

DROP POLICY IF EXISTS "delete_own_captions" ON video_captions;
CREATE POLICY "delete_own_captions" ON video_captions FOR DELETE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM videos v WHERE v.id = video_captions.video_id AND v.user_id = auth.uid())
  );

CREATE INDEX IF NOT EXISTS video_captions_video_seq_idx ON video_captions(video_id, seq);
