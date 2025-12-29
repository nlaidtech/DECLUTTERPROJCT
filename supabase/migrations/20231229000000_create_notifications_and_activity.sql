-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'like', 'message', 'comment', 'follow', 'post_saved'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_item_id UUID, -- Post ID, message ID, etc.
    related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_user_name TEXT,
    related_user_avatar TEXT,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create activity_history table
CREATE TABLE IF NOT EXISTS activity_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- 'created_post', 'updated_post', 'deleted_post', 'saved_post', 'unsaved_post', 'sent_message', 'profile_updated'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    related_item_id UUID, -- Post ID, message ID, etc.
    related_item_title TEXT,
    related_item_image TEXT,
    metadata JSONB, -- Additional data specific to action type
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);

CREATE INDEX IF NOT EXISTS idx_activity_user_id ON activity_history(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_created_at ON activity_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_action ON activity_history(action);

-- Enable Row Level Security (RLS)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notifications table
-- Users can only read their own notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert notifications (for system or other users to create)
CREATE POLICY "Users can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (true);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
    ON notifications FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for activity_history table
-- Users can only read their own activity
CREATE POLICY "Users can view own activity"
    ON activity_history FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own activity
CREATE POLICY "Users can create own activity"
    ON activity_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own activity
CREATE POLICY "Users can delete own activity"
    ON activity_history FOR DELETE
    USING (auth.uid() = user_id);

-- Optional: Create a function to automatically clean old notifications
CREATE OR REPLACE FUNCTION delete_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Optional: Create a function to automatically clean old activity
CREATE OR REPLACE FUNCTION delete_old_activity()
RETURNS void AS $$
BEGIN
    DELETE FROM activity_history
    WHERE created_at < NOW() - INTERVAL '180 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
