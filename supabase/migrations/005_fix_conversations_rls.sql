-- Fix Conversations RLS - Allow authenticated users to create conversations
-- Created: December 30, 2025
-- Run this to fix the "new row violates row-level security policy" error

-- ============================================
-- DROP OLD CONVERSATION POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;

-- ============================================
-- SIMPLIFIED CONVERSATIONS POLICIES
-- ============================================

-- Allow authenticated users to view conversations they're part of
CREATE POLICY "Users can view their conversations"
  ON conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_id = conversations.id
      AND user_id = auth.uid()
    )
  );

-- Allow any authenticated user to create conversations
-- The WITH CHECK clause should allow the insert
CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow users to update conversations they're part of
CREATE POLICY "Users can update their conversations"
  ON conversations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_id = conversations.id
      AND user_id = auth.uid()
    )
  );

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Conversations RLS policies fixed!';
  RAISE NOTICE 'Authenticated users can now create conversations.';
END $$;
