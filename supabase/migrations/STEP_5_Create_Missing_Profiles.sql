-- Create profiles for any auth.users that don't have a profile yet
-- This fixes the messaging error for newly created accounts

INSERT INTO profiles (id, email, display_name, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(
    au.raw_user_meta_data->>'name',
    au.raw_user_meta_data->>'display_name',
    split_part(au.email, '@', 1)
  ) as display_name,
  au.created_at,
  NOW() as updated_at
FROM auth.users au
LEFT JOIN profiles p ON p.id = au.id
WHERE p.id IS NULL;

-- Show the profiles that were created
SELECT 
  id,
  email,
  display_name,
  'Profile created successfully' as status
FROM profiles
WHERE created_at >= NOW() - INTERVAL '1 minute';

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Missing profiles created successfully!';
  RAISE NOTICE 'You can now send messages without errors';
END $$;
