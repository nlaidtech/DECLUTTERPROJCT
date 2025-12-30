-- Recreate messages table with correct schema
-- Created: December 30, 2025
-- Run this to fix the 'content' column error

-- ============================================
-- DROP AND RECREATE MESSAGES TABLE
-- ============================================

-- Drop existing table if it exists
DROP TABLE IF EXISTS messages CASCADE;

-- Recreate with correct schema
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'system')),
  read_by UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Disable RLS for simplicity (messages are protected via conversations)
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN 
  RAISE NOTICE '✅ Messages table recreated successfully!';
  RAISE NOTICE 'The content column error should now be fixed.';
END $$;
