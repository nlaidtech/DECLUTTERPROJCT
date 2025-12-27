-- Declutter Project - Realtime Configuration
-- Created: December 27, 2025
-- Enables real-time subscriptions for messages and conversations

-- ============================================
-- ENABLE REALTIME for MESSAGES
-- ============================================
-- This allows Flutter app to listen to message changes in real-time

ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_participants;

-- ============================================
-- REALTIME BROADCAST for TYPING INDICATORS
-- ============================================
-- Note: Typing indicators use Supabase Broadcast feature
-- No SQL needed - handled in Flutter app

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Realtime subscriptions enabled!';
  RAISE NOTICE 'Tables enabled for realtime:';
  RAISE NOTICE '  - messages';
  RAISE NOTICE '  - conversations';
  RAISE NOTICE '  - conversation_participants';
END $$;
