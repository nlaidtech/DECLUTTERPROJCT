-- Enable realtime for posts table (REQUIRED for real-time updates)
alter publication supabase_realtime add table posts;

-- Optional: Enable realtime for messages table
alter publication supabase_realtime add table messages;

-- Already enabled (skip these):
-- alter publication supabase_realtime add table profiles;
-- alter publication supabase_realtime add table conversations;
