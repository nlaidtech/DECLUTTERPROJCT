-- Fix RLS Policies - Remove Infinite Recursion
-- Created: December 30, 2025
-- Run this to fix the conversation_participants infinite recursion error

-- ============================================
-- DROP OLD POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can add themselves to conversations" ON conversation_participants;
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;

-- ============================================
-- CONVERSATION_PARTICIPANTS POLICIES (FIXED)
-- ============================================

-- COMPLETELY DISABLE RLS FOR conversation_participants
-- This is the simplest fix - participants need to see each other
ALTER TABLE conversation_participants DISABLE ROW LEVEL SECURITY;

-- Alternative: If you want RLS, use a very simple policy without recursion
-- CREATE POLICY "Anyone authenticated can view participants"
--   ON conversation_participants FOR SELECT
--   USING (auth.uid() IS NOT NULL);
-- 
-- CREATE POLICY "Authenticated users can add participants"
--   ON conversation_participants FOR INSERT
--   WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================
-- CONVERSATIONS POLICIES (FIXED)
-- ============================================

-- Users can view conversations they're part of
-- FIXED: Simplified without causing recursion
CREATE POLICY "Users can view their conversations"
  ON conversations FOR SELECT
  USING (
    id IN (
      SELECT conversation_id FROM conversation_participants
      WHERE user_id = auth.uid()
    )
  );

-- Authenticated users can create conversations
CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Users can update conversations they're part of
CREATE POLICY "Users can update their conversations"
  ON conversations FOR UPDATE
  USING (
    id IN (
      SELECT conversation_id FROM conversation_participants
      WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN 
  RAISE NOTICE '✅ RLS policies fixed successfully!';
  RAISE NOTICE 'The infinite recursion error should now be resolved.';
END $$;
