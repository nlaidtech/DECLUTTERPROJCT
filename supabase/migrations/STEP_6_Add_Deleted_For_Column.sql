-- Add deleted_for column to messages table
-- This allows users to hide messages from their view without deleting for everyone

ALTER TABLE messages ADD COLUMN IF NOT EXISTS deleted_for UUID[] DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN messages.deleted_for IS 'Array of user IDs who have deleted this message from their view';

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Added deleted_for column to messages table';
  RAISE NOTICE 'Users can now delete messages for themselves only';
END $$;
