-- ============================================
-- COMBINED MIGRATIONS TO RUN IN SUPABASE
-- Run this entire script in Supabase SQL Editor
-- Updated: January 2, 2026
-- ============================================

-- ===========================================
-- PART 1: ADD MISSING COLUMNS
-- ===========================================

-- 1. Add photo_url column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- 2. Add birthday column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS birthday DATE;

-- 3. Add description column to posts table (if missing)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS description TEXT;

-- 4. Add latitude and longitude columns to posts table  
ALTER TABLE posts ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 5. Add index for location-based queries
CREATE INDEX IF NOT EXISTS idx_posts_location ON posts(latitude, longitude);

-- 6. Add comments for documentation
COMMENT ON COLUMN profiles.photo_url IS 'URL to user profile photo in storage';
COMMENT ON COLUMN profiles.birthday IS 'User birthday for age calculation';
COMMENT ON COLUMN posts.description IS 'Detailed description of the item';
COMMENT ON COLUMN posts.latitude IS 'Latitude coordinate of the item location';
COMMENT ON COLUMN posts.longitude IS 'Longitude coordinate of the item location';

-- ===========================================
-- PART 2: FIX MESSAGING RLS POLICIES
-- ===========================================

-- Drop all existing message policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON messages;
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON messages;

-- Create fixed message policies (ensures BOTH participants see ALL messages)
CREATE POLICY "Users can view messages in their conversations"
  ON messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages to their conversations"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() 
    AND conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own messages"
  ON messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can delete own messages"
  ON messages FOR DELETE
  USING (sender_id = auth.uid());

-- ===========================================
-- PART 3: FIX POST-CONVERSATION RELATIONSHIP
-- ===========================================

-- Drop existing post_id foreign key constraint
DO $$ 
DECLARE
  constraint_name TEXT;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint
  WHERE conrelid = 'conversations'::regclass
    AND confrelid = 'posts'::regclass
    AND contype = 'f';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE conversations DROP CONSTRAINT IF EXISTS %I', constraint_name);
  END IF;
END $$;

-- Recreate with ON DELETE SET NULL (conversation persists when post is deleted)
ALTER TABLE conversations
  ADD CONSTRAINT conversations_post_id_fkey
  FOREIGN KEY (post_id)
  REFERENCES posts(id)
  ON DELETE SET NULL;

-- ===========================================
-- VERIFICATION QUERIES
-- ===========================================

-- Verify column additions
SELECT 
    'profiles' as table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'profiles' 
    AND column_name = 'photo_url'
UNION ALL
SELECT 
    'posts' as table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'posts' 
    AND column_name IN ('latitude', 'longitude')
ORDER BY table_name, column_name;

-- Verify message policies
SELECT 
  policyname,
  cmd as command
FROM pg_policies
WHERE tablename = 'messages'
ORDER BY policyname;

-- Verify post-conversation relationship
SELECT
  conname as constraint_name,
  CASE confdeltype
    WHEN 'a' THEN 'NO ACTION'
    WHEN 'r' THEN 'RESTRICT'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET NULL ✅'
    WHEN 'd' THEN 'SET DEFAULT'
  END as on_delete_action
FROM pg_constraint
WHERE conrelid = 'conversations'::regclass
  AND confrelid = 'posts'::regclass
  AND contype = 'f';

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================
DO $$ 
BEGIN 
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ ALL MIGRATIONS COMPLETED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Applied:';
  RAISE NOTICE '1. ✅ Added photo_url to profiles';
  RAISE NOTICE '2. ✅ Added latitude/longitude to posts';
  RAISE NOTICE '3. ✅ Fixed messaging RLS (both users see messages)';
  RAISE NOTICE '4. ✅ Conversations persist when posts deleted';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '- Test messaging between users';
  RAISE NOTICE '- Test deleting a post with active conversation';
  RAISE NOTICE '- Create new posts with location';
  RAISE NOTICE '========================================';
END $$;
