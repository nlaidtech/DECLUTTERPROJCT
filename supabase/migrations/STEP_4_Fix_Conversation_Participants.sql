-- Fix conversation_participants foreign key constraint
-- This fixes the error: "conversation_participants_user_id_fkey" violates foreign key constraint

-- Step 1: Drop the incorrect foreign key constraint if it exists
DO $$ 
DECLARE
  constraint_name TEXT;
BEGIN
  -- Find the constraint name that references 'users' table
  SELECT conname INTO constraint_name
  FROM pg_constraint
  WHERE conrelid = 'conversation_participants'::regclass
    AND conname LIKE '%user_id%'
    AND contype = 'f';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE conversation_participants DROP CONSTRAINT IF EXISTS %I', constraint_name);
    RAISE NOTICE 'Dropped constraint: %', constraint_name;
  END IF;
END $$;

-- Step 2: Add the correct foreign key constraint to profiles table
ALTER TABLE conversation_participants
  DROP CONSTRAINT IF EXISTS conversation_participants_user_id_fkey;

ALTER TABLE conversation_participants
  ADD CONSTRAINT conversation_participants_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Step 3: Verify the fix
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'conversation_participants'::regclass
  AND contype = 'f'
  AND conname LIKE '%user_id%';

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Foreign key constraint fixed successfully!';
  RAISE NOTICE 'conversation_participants.user_id now correctly references profiles(id)';
END $$;
