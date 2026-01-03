-- Fix RLS Policy for Users Table
-- Add INSERT policy so users can create their own profile record
-- Run this in Supabase SQL Editor

-- Add INSERT policy for users table
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Verify the policy was created
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd;

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Users table INSERT policy added!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Users can now create their own records';
  RAISE NOTICE 'Try publishing a post again';
  RAISE NOTICE '========================================';
END $$;
