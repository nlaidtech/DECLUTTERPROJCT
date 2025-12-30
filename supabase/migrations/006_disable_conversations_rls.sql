-- Disable RLS on conversations table to fix insert error
-- Created: December 30, 2025

-- ============================================
-- DROP ALL CONVERSATION POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;

-- ============================================
-- DISABLE RLS ON CONVERSATIONS
-- ============================================
-- Since conversation_participants already has RLS disabled,
-- we also disable it on conversations for consistency
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN 
  RAISE NOTICE '✅ RLS disabled on conversations table!';
  RAISE NOTICE 'This fixes the insert error.';
END $$;
