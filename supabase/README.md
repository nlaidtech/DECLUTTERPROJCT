# Supabase Database Setup

## 🚀 Quick Start

### Step 1: Run Migrations

Go to your Supabase SQL Editor: https://miqbkzkmfkyzpdjyglab.supabase.co/project/default/sql

Run these SQL files **in order**:

1. **001_initial_schema.sql** - Creates all tables, indexes, and helper functions
2. **002_row_level_security.sql** - Sets up security policies
3. **003_realtime_setup.sql** - Enables real-time subscriptions

Copy and paste each file's contents into the SQL Editor and click "Run".

### Step 2: Set Up Storage Buckets

1. Go to **Storage** section in Supabase Dashboard
2. Create two public buckets:
   - `post-images` (for item photos)
   - `profile-images` (for user avatars)

**Bucket Settings:**
- Public: ✅ Yes
- File size limit: 5 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

### Step 3: Configure Storage Policies

For each bucket, add these policies:

**post-images bucket:**
```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload post images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'post-images' AND
  auth.uid() IS NOT NULL
);

-- Allow public to view images
CREATE POLICY "Public can view post images"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-images');

-- Users can delete their own images
CREATE POLICY "Users can delete own post images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'post-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

**profile-images bucket:**
```sql
-- Allow users to upload their profile image
CREATE POLICY "Users can upload own profile image"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public to view profile images
CREATE POLICY "Public can view profile images"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

-- Users can update their profile image
CREATE POLICY "Users can update own profile image"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their profile image
CREATE POLICY "Users can delete own profile image"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### Step 4: Verify Setup

Run this query to verify tables were created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see:
- ✅ profiles
- ✅ posts
- ✅ favorites
- ✅ conversations
- ✅ conversation_participants
- ✅ messages
- ✅ ratings

### Step 5: Test Authentication

Create a test user in **Authentication > Users** section or use the signup screen in your app.

## 📊 Database Schema

### Tables Overview

| Table | Description | Key Fields |
|-------|-------------|------------|
| `profiles` | User profiles (extends auth.users) | display_name, location, avatar_url |
| `posts` | Items being shared | title, description, category, type, status |
| `favorites` | Saved items | user_id, post_id |
| `conversations` | Chat conversations | post_id |
| `conversation_participants` | Who's in each conversation | conversation_id, user_id |
| `messages` | Chat messages | content, sender_id, conversation_id |
| `ratings` | User/item ratings | rating (1-5), comment |

### Relationships

```
auth.users (Supabase Auth)
    ↓
profiles (auto-created on signup)
    ↓
    ├─→ posts (user's listings)
    ├─→ favorites (saved items)
    ├─→ conversation_participants (chats)
    ├─→ messages (sent messages)
    └─→ ratings (reviews given)
```

## 🔐 Security Features

### Row Level Security (RLS)

All tables have RLS enabled. Users can only:
- View their own data or public data
- Modify their own records
- Cannot access other users' private information

### Storage Security

Images are organized by user ID:
- `post-images/{user_id}/{filename}.jpg`
- `profile-images/{user_id}/profile.jpg`

## 🔄 Real-time Features

The following tables broadcast changes in real-time:
- ✅ messages (for live chat)
- ✅ conversations (for conversation updates)
- ✅ conversation_participants (for member changes)

## 📱 Usage in Flutter App

```dart
import 'package:declutter_project/main.dart';

// Query posts
final posts = await supabase
  .from('posts')
  .select()
  .eq('status', 'active')
  .order('created_at', ascending: false);

// Real-time messages
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('conversation_id', conversationId)
  .listen((data) {
    // Handle new messages
  });

// Upload image
await supabase.storage
  .from('post-images')
  .upload('${userId}/${fileName}.jpg', imageBytes);
```

## 🐛 Troubleshooting

### "Row Level Security policy violation"
- Make sure user is authenticated
- Check if user has permission to access the resource

### "relation does not exist"
- Run migrations in correct order
- Verify table was created in SQL Editor

### "realtime subscription failed"
- Check if Realtime is enabled for the table
- Run 003_realtime_setup.sql

### Images not uploading
- Verify storage buckets exist
- Check storage policies are configured
- Ensure bucket is set to public

## 📚 Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase Dashboard](https://miqbkzkmfkyzpdjyglab.supabase.co)
