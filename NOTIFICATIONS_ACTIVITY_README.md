# Notifications & Activity History Features

This document describes the notifications and activity history features implemented in the Declutter app.

## Overview

Two new features have been added to track user interactions and keep users informed:

1. **Notifications** - Real-time notifications for user interactions
2. **Activity History** - Complete timeline of user actions

## Features Implemented

### 1. Notifications System

#### Models
- `NotificationModel` - Data structure for notifications with the following fields:
  - `id`, `userId`, `type`, `title`, `message`
  - `relatedItemId`, `relatedUserId`, `relatedUserName`
  - `imageUrl`, `isRead`, `createdAt`

#### Notification Types
- 🔖 `post_saved` - When someone saves your post
- 💬 `message` - New message received
- ❤️ `like` - Someone likes your post (future)
- 💭 `comment` - Someone comments on your post (future)
- 👤 `follow` - Someone follows you (future)

#### Features
- View all notifications in chronological order
- Mark individual notifications as read
- Mark all notifications as read
- Delete individual notifications (swipe to dismiss)
- Delete all notifications
- Unread notification count badge
- Click to navigate to related content
- Real-time notification updates via Supabase

#### NotificationService Methods
```dart
// Fetch notifications
getNotifications({int limit = 50})
getUnreadCount()
getUnreadNotifications()

// Create notifications
createNotification({...})
notifyPostSaved({...})
notifyNewMessage({...})

// Update notifications
markAsRead(String notificationId)
markAllAsRead()

// Delete notifications
deleteNotification(String notificationId)
deleteAllNotifications()

// Real-time
subscribeToNotifications(Function callback)
```

### 2. Activity History System

#### Models
- `ActivityHistoryModel` - Data structure for activity with fields:
  - `id`, `userId`, `action`, `title`, `description`
  - `relatedItemId`, `relatedItemTitle`, `relatedItemImage`
  - `metadata`, `createdAt`

#### Activity Types
- ✨ `created_post` - Created a new post
- ✏️ `updated_post` - Updated a post
- 🗑️ `deleted_post` - Deleted a post
- 🔖 `saved_post` - Saved a post
- 📌 `unsaved_post` - Removed from saved
- 💬 `sent_message` - Sent a message
- 👤 `profile_updated` - Updated profile

#### Features
- View all activities grouped by date (Today, Yesterday, specific dates)
- Filter activities by type (All, Posts, Saved, Messages)
- Activity statistics showing count by type
- Delete individual activities (swipe to dismiss)
- Delete all activities
- Delete old activities (90+ days)
- Color-coded activity types with icons
- Click to navigate to related content

#### ActivityHistoryService Methods
```dart
// Fetch activity
getActivityHistory({int limit = 100, String? action})
getActivityByDate({int limit = 100})
getActivityStats()

// Log activity
logActivity({...})
logPostCreated({...})
logPostUpdated({...})
logPostDeleted({...})
logPostSaved({...})
logPostUnsaved({...})
logMessageSent({...})
logProfileUpdated()

// Delete activity
deleteActivity(String activityId)
deleteAllActivity()
deleteOldActivity({int daysToKeep = 90})
```

## Navigation

### From Profile Screen
- **Activity History** - View your activity timeline
- **Notifications** - Manage notification preferences

### Routes Added
```dart
'/notifications': (context) => const NotificationsScreen(),
'/activity-history': (context) => const ActivityHistoryScreen(),
```

## Database Schema

### Notifications Table
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    type VARCHAR(50),
    title TEXT,
    message TEXT,
    related_item_id UUID,
    related_user_id UUID,
    related_user_name TEXT,
    related_user_avatar TEXT,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE
);
```

### Activity History Table
```sql
CREATE TABLE activity_history (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    action VARCHAR(50),
    title TEXT,
    description TEXT,
    related_item_id UUID,
    related_item_title TEXT,
    related_item_image TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE
);
```

### Indexes Created
- User ID indexes for both tables
- Created date indexes for chronological queries
- is_read index for notifications
- Action type index for activity filtering

### Row Level Security (RLS)
- Users can only view their own notifications and activity
- Users can create, update, and delete their own data
- Notifications can be created by any user (for cross-user notifications)

## Usage Examples

### Creating a Notification
```dart
final notificationService = NotificationService();

await notificationService.notifyPostSaved(
  postOwnerId: 'user-uuid',
  postId: 'post-uuid',
  postTitle: 'Free Couch',
  postImage: 'https://...',
);
```

### Logging Activity
```dart
final activityService = ActivityHistoryService();

await activityService.logPostCreated(
  postId: 'post-uuid',
  postTitle: 'Free Couch',
  postImage: 'https://...',
);
```

### Subscribing to Real-time Notifications
```dart
final channel = notificationService.subscribeToNotifications(
  (notification) {
    // Handle new notification
    print('New notification: ${notification.title}');
  },
);

// Don't forget to unsubscribe
channel.unsubscribe();
```

## Integration Points

### Where to Add Activity Logging

1. **Post Creation** (`create_post_screen.dart`)
   ```dart
   await ActivityHistoryService().logPostCreated(...);
   ```

2. **Post Update** (`edit_post_screen.dart`)
   ```dart
   await ActivityHistoryService().logPostUpdated(...);
   ```

3. **Post Deletion**
   ```dart
   await ActivityHistoryService().logPostDeleted(...);
   ```

4. **Save Post** (`favorites_service.dart`)
   ```dart
   await ActivityHistoryService().logPostSaved(...);
   await NotificationService().notifyPostSaved(...);
   ```

5. **Send Message** (`advanced_chat_screen.dart`)
   ```dart
   await ActivityHistoryService().logMessageSent(...);
   await NotificationService().notifyNewMessage(...);
   ```

6. **Profile Update** (`edit_profile_screen.dart`)
   ```dart
   await ActivityHistoryService().logProfileUpdated();
   ```

## Database Migration

Run the migration file to create the tables:

```bash
# If using Supabase CLI
supabase db push

# Or manually run the SQL in Supabase Dashboard
# Navigate to: SQL Editor > New Query
# Paste contents of: supabase/migrations/20231229000000_create_notifications_and_activity.sql
```

## Future Enhancements

1. **Push Notifications** - FCM integration for mobile push notifications
2. **Email Notifications** - Email digest of important notifications
3. **Notification Preferences** - Allow users to customize notification types
4. **Activity Analytics** - Charts and graphs of user activity over time
5. **Export Activity** - Export activity history as CSV/JSON
6. **Notification Grouping** - Group similar notifications together
7. **Comment Notifications** - Notify when someone comments on posts
8. **Like Notifications** - Notify when someone likes posts
9. **Follow Notifications** - Notify when someone follows you

## Testing Checklist

- [ ] Create a notification and verify it appears in the list
- [ ] Mark notification as read and verify badge count updates
- [ ] Delete notification with swipe gesture
- [ ] Mark all notifications as read
- [ ] Delete all notifications
- [ ] Log activity and verify it appears grouped by date
- [ ] Filter activity by type
- [ ] View activity statistics
- [ ] Delete individual activity
- [ ] Delete old activities
- [ ] Navigate from notification to related content
- [ ] Navigate from activity to related content
- [ ] Test with no notifications/activity (empty states)

## Files Created

1. **Models**
   - `lib/models/notification_model.dart`
   - `lib/models/activity_history_model.dart`

2. **Services**
   - `lib/services/notification_service.dart`
   - `lib/services/activity_service.dart`

3. **Screens**
   - `lib/screens/notifications_screen.dart`
   - `lib/screens/activity_history_screen.dart`

4. **Database**
   - `supabase/migrations/20231229000000_create_notifications_and_activity.sql`

## Files Modified

1. `lib/main.dart` - Added routes for new screens
2. `lib/screens/profile_screen.dart` - Added navigation to new features
