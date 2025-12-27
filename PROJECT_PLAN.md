# Declutter Project - Development Plan

**Last Updated:** December 27, 2025  
**Status:** Active Development  
**Target Platform:** Flutter (Android, iOS, Web)

---

## 🎯 Executive Summary

Declutter is a community-based sustainability platform for giving away items. The project is currently built with Firebase and will transition to **Supabase** for improved developer experience, cost efficiency, and PostgreSQL database capabilities.

**Current State:** ~70% complete  
**Major Gap:** Messaging system (UI-only), iOS support, item management features

---

## 📋 Table of Contents

1. [Migration: Firebase → Supabase](#1-migration-firebase--supabase)
2. [Critical Issues to Fix](#2-critical-issues-to-fix)
3. [Core Features Implementation](#3-core-features-implementation)
4. [Enhanced Features](#4-enhanced-features)
5. [Long-term Roadmap](#5-long-term-roadmap)
6. [Technical Debt](#6-technical-debt)
7. [Testing Strategy](#7-testing-strategy)
8. [Deployment Strategy](#8-deployment-strategy)

---

## 1. Migration: Firebase → Supabase

### 🔄 Why Supabase?

- **PostgreSQL:** Relational database with powerful queries and joins
- **Real-time subscriptions:** Built-in WebSocket support
- **Row Level Security (RLS):** Better security model
- **Cost-effective:** More generous free tier
- **REST API:** Auto-generated APIs from database schema
- **Better developer experience:** Direct SQL access, migrations

### Phase 1.1: Setup & Configuration (Priority: HIGH)

**Estimated Time:** 2-4 hours

#### Tasks:

- [ ] **1.1.1** Create Supabase project at [supabase.com](https://supabase.com)
  - Project name: `declutter-project`
  - Region: Choose closest to Panabo, Philippines (Singapore recommended)
  
- [ ] **1.1.2** Install Supabase Flutter package
  ```yaml
  dependencies:
    supabase_flutter: ^2.5.0  # Replace Firebase packages
  ```

- [ ] **1.1.3** Remove Firebase dependencies
  ```yaml
  # REMOVE from pubspec.yaml:
  # firebase_core: ^3.6.0
  # firebase_auth: ^5.3.1
  # cloud_firestore: ^5.4.4
  # firebase_storage: ^12.3.4
  ```

- [ ] **1.1.4** Initialize Supabase in `main.dart`
  ```dart
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  ```

### Phase 1.2: Database Schema Design (Priority: HIGH)

**Estimated Time:** 3-4 hours

#### Database Tables:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  location TEXT DEFAULT 'Panabo',
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts/Items table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  location TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  type TEXT CHECK (type IN ('giveaway', 'available')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'reserved', 'completed')),
  image_urls TEXT[],
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favorites/Saved items
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- Conversations
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation participants
CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- Messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'system')),
  read_by UUID[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ratings/Reviews
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, reviewer_id)
);

-- Indexes for performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_location ON posts(location);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
```

#### Row Level Security (RLS) Policies:

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all, update only their own
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Posts: Public read, authenticated create/update/delete own
CREATE POLICY "Posts are viewable by everyone"
  ON posts FOR SELECT USING (status = 'active' OR user_id = auth.uid());

CREATE POLICY "Authenticated users can create posts"
  ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE USING (auth.uid() = user_id);

-- Messages: Only conversation participants can access
CREATE POLICY "Users can view messages in their conversations"
  ON messages FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_id = messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages to their conversations"
  ON messages FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_id = messages.conversation_id
      AND user_id = auth.uid()
    )
  );
```

#### Tasks:

- [ ] **1.2.1** Create all tables in Supabase SQL Editor
- [ ] **1.2.2** Set up RLS policies
- [ ] **1.2.3** Enable Realtime for `messages` and `conversations` tables
- [ ] **1.2.4** Configure Storage bucket for images: `post-images`, `profile-images`

### Phase 1.3: Service Migration (Priority: HIGH)

**Estimated Time:** 6-8 hours

#### Tasks:

- [ ] **1.3.1** Create `lib/services/supabase_service.dart` - Singleton instance
- [ ] **1.3.2** Migrate `auth_service.dart` to use Supabase Auth
  - Sign up with email/password
  - Login
  - Password reset
  - Social auth (optional: Google, Apple)
  
- [ ] **1.3.3** Create `lib/services/posts_service.dart`
  - Create post
  - Fetch posts with filters
  - Update post
  - Delete post
  - Search posts
  
- [ ] **1.3.4** Create `lib/services/messaging_service.dart`
  - Create conversation
  - Send message
  - Real-time message subscription
  - Mark messages as read
  
- [ ] **1.3.5** Create `lib/services/supabase_storage_service.dart`
  - Upload images to Supabase Storage
  - Delete images
  - Get public URLs

- [ ] **1.3.6** Update `favorites_service.dart` to use Supabase
  
- [ ] **1.3.7** Delete old Firebase services:
  - `database_service.dart`
  - `firestore_service.dart` (duplicate)
  - `storage_service.dart`

### Phase 1.4: UI Migration (Priority: MEDIUM)

**Estimated Time:** 4-6 hours

#### Tasks:

- [ ] **1.4.1** Update all screens to use new Supabase services
- [ ] **1.4.2** Replace Firebase Auth state listeners with Supabase Auth
- [ ] **1.4.3** Update post creation flow
- [ ] **1.4.4** Migrate favorites functionality
- [ ] **1.4.5** Test all authentication flows

### Phase 1.5: Data Migration (Priority: MEDIUM)

**Estimated Time:** 2-3 hours

#### Tasks:

- [ ] **1.5.1** Export existing Firebase data (if any production data exists)
- [ ] **1.5.2** Transform data to match Supabase schema
- [ ] **1.5.3** Import data to Supabase
- [ ] **1.5.4** Verify data integrity
- [ ] **1.5.5** Remove Firebase configuration files

### Phase 1.6: Testing & Cleanup (Priority: HIGH)

**Estimated Time:** 2-3 hours

#### Tasks:

- [ ] **1.6.1** Test authentication flow end-to-end
- [ ] **1.6.2** Test post creation, editing, deletion
- [ ] **1.6.3** Test favorites functionality
- [ ] **1.6.4** Test on Android, iOS, Web
- [ ] **1.6.5** Remove Firebase files:
  - `firebase_options.dart`
  - `android/app/google-services.json`
  - Firebase configuration from iOS

---

## 2. Critical Issues to Fix

### 2.1: Connect Real-time Messaging (Priority: CRITICAL)

**Status:** UI exists, no backend  
**Estimated Time:** 6-8 hours

#### Tasks:

- [ ] **2.1.1** Connect `advanced_chat_screen.dart` to Supabase
- [ ] **2.1.2** Implement real-time message subscription
- [ ] **2.1.3** Add conversation creation from item posts
- [ ] **2.1.4** Add "Message Seller" button on item detail screen
- [ ] **2.1.5** Implement message status (sent, delivered, read)
- [ ] **2.1.6** Add typing indicator with real-time presence
- [ ] **2.1.7** Image messages support
- [ ] **2.1.8** Message notifications

**Dependencies:** Complete Phase 1.3.4 (messaging_service)

### 2.2: iOS Platform Support (Priority: HIGH)

**Status:** Not configured  
**Estimated Time:** 30 minutes

#### Tasks:

- [ ] **2.2.1** Add iOS configuration for Supabase
- [ ] **2.2.2** Update `Info.plist` with required permissions
- [ ] **2.2.3** Test on iOS simulator
- [ ] **2.2.4** Test on physical iOS device

### 2.3: Remove Duplicate Code (Priority: MEDIUM)

**Status:** Code duplication causing confusion  
**Estimated Time:** 1 hour

#### Tasks:

- [ ] **2.3.1** Remove `user_model.dart` (insecure password storage)
- [ ] **2.3.2** Remove duplicate `firestore_service.dart`
- [ ] **2.3.3** Consolidate all database operations in new Supabase services
- [ ] **2.3.4** Update all imports

---

## 3. Core Features Implementation

### 3.1: Item Management (Priority: HIGH)

**Status:** Can create but not manage posts  
**Estimated Time:** 4-6 hours

#### Tasks:

- [ ] **3.1.1** Create "My Posts" screen in profile section
  - Display user's active/reserved/completed items
  - Swipe actions for quick edit/delete
  
- [ ] **3.1.2** Implement edit post functionality
  - Reuse `create_post_screen.dart` in edit mode
  - Pre-populate form fields
  - Allow image reordering/replacement
  
- [ ] **3.1.3** Implement delete post functionality
  - Confirmation dialog
  - Delete from database
  - Delete associated images from storage
  
- [ ] **3.1.4** Add status management
  - Mark as "Reserved" when someone requests
  - Mark as "Given Away" when completed
  - Archive completed items

- [ ] **3.1.5** Add post analytics
  - View count tracking
  - Favorite count
  - Message count

### 3.2: Enhanced Item Detail Screen (Priority: HIGH)

**Status:** Exists but needs improvements  
**Estimated Time:** 3-4 hours

#### Tasks:

- [ ] **3.2.1** Add "Message Seller" button (if not own post)
- [ ] **3.2.2** Display seller profile info
- [ ] **3.2.3** Show distance from user's location
- [ ] **3.2.4** Add share functionality
- [ ] **3.2.5** Display ratings/reviews
- [ ] **3.2.6** Add image gallery with zoom
- [ ] **3.2.7** Show view count and favorite count
- [ ] **3.2.8** Similar items section

### 3.3: Search & Filters (Priority: MEDIUM)

**Status:** Search screen exists but incomplete  
**Estimated Time:** 4-5 hours

#### Tasks:

- [ ] **3.3.1** Implement full-text search in Supabase
  ```sql
  CREATE INDEX idx_posts_title_description ON posts 
  USING gin(to_tsvector('english', title || ' ' || description));
  ```
  
- [ ] **3.3.2** Add search filters UI
  - Category filter (multi-select)
  - Type filter (Giveaway/Available)
  - Distance radius slider
  - Date range picker
  
- [ ] **3.3.3** Implement search results with sorting
  - Sort by: Newest, Closest, Most Popular
  - Pagination/infinite scroll
  
- [ ] **3.3.4** Add search history (local storage)
- [ ] **3.3.5** Add saved searches

### 3.4: Location Features (Priority: MEDIUM)

**Status:** Service exists, needs integration  
**Estimated Time:** 5-6 hours

#### Tasks:

- [ ] **3.4.1** Get user's current location on app start
- [ ] **3.4.2** Filter items by proximity (configurable radius)
- [ ] **3.4.3** Display distance on item cards
- [ ] **3.4.4** Add map view of all items
  - Cluster markers when zoomed out
  - Tap marker to view item details
  
- [ ] **3.4.5** Location-based notifications
  - Alert when new item posted nearby
  
- [ ] **3.4.6** Improve location picker
  - Search for addresses
  - Better map UI
  - Save favorite locations

---

## 4. Enhanced Features

### 4.1: Rating & Review System (Priority: MEDIUM)

**Status:** Schema exists, no UI  
**Estimated Time:** 4-5 hours

#### Tasks:

- [ ] **4.1.1** Add rating dialog after item given away
- [ ] **4.1.2** Display average rating on user profiles
- [ ] **4.1.3** Show ratings on item cards (historical)
- [ ] **4.1.4** Reviews section on profile
- [ ] **4.1.5** Reputation badge system
  - "Super Giver" - 50+ items given
  - "Verified" - 10+ 5-star ratings
  - "Helper" - 100+ items given

### 4.2: Profile Enhancements (Priority: MEDIUM)

**Status:** Basic profile exists  
**Estimated Time:** 3-4 hours

#### Tasks:

- [ ] **4.2.1** Profile picture upload/edit
  - Crop image before upload
  - Set as avatar
  
- [ ] **4.2.2** Edit profile information
  - Display name
  - Bio/description
  - Location (with map picker)
  
- [ ] **4.2.3** View other users' profiles
  - Navigate from item cards
  - See their active listings
  - Reputation score
  - Reviews received
  
- [ ] **4.2.4** Profile statistics dashboard
  - Items posted
  - Items given away
  - Items received
  - Sustainability impact (estimated CO2 saved)

### 4.3: Notifications System (Priority: LOW)

**Status:** Not implemented  
**Estimated Time:** 6-8 hours

#### Tasks:

- [ ] **4.3.1** Set up push notifications (Firebase Cloud Messaging or OneSignal)
- [ ] **4.3.2** In-app notifications UI
- [ ] **4.3.3** Notification types:
  - New message received
  - Item request received
  - Item marked as reserved
  - Item picked up/completed
  - New item nearby
  
- [ ] **4.3.4** Notification preferences screen
- [ ] **4.3.5** Notification history

### 4.4: Gamification & Community (Priority: LOW)

**Status:** Not implemented  
**Estimated Time:** 8-10 hours

#### Tasks:

- [ ] **4.4.1** Achievement/badge system
  - First post
  - 10 items given away
  - 50 items given away
  - Sustainability hero
  
- [ ] **4.4.2** Leaderboard
  - Top givers this month
  - Most helpful community members
  
- [ ] **4.4.3** Impact metrics dashboard
  - Total items rescued from landfill
  - Estimated environmental impact
  - CO2 emissions avoided
  - Trees saved equivalent
  
- [ ] **4.4.4** Social sharing
  - Share item posts to social media
  - Share personal impact stats
  - Invite friends

### 4.5: Request System (Priority: MEDIUM)

**Status:** Not implemented  
**Estimated Time:** 5-6 hours

#### Tasks:

- [ ] **4.5.1** Add "Request This Item" button
- [ ] **4.5.2** Create requests table in database
- [ ] **4.5.3** Request approval workflow
  - Giver receives notification
  - Can approve/decline
  - Can choose from multiple requesters
  
- [ ] **4.5.4** Pickup scheduling
  - Date/time picker
  - Meeting location
  - Confirmation system
  
- [ ] **4.5.5** Automatic status updates
  - Mark as reserved when approved
  - Mark as completed after pickup

---

## 5. Long-term Roadmap

### 5.1: Advanced Features (6+ months)

- [ ] **Multi-language support** (English, Filipino)
- [ ] **AI-powered category detection** (from images)
- [ ] **Smart matching algorithm** (suggest items to users)
- [ ] **Community groups/neighborhoods**
- [ ] **Item condition assessment** (AI from photos)
- [ ] **QR code generation** for easy pickup
- [ ] **Integration with charity organizations**
- [ ] **Delivery service integration**

### 5.2: Platform Expansion

- [ ] **Desktop apps** (Windows, macOS, Linux)
- [ ] **TV app** (Android TV, Apple TV)
- [ ] **Web admin dashboard**
- [ ] **API for third-party integrations**

### 5.3: Business Model (Future)

- [ ] **Premium features** (featured listings, priority support)
- [ ] **Business accounts** (for stores, organizations)
- [ ] **Sponsored posts**
- [ ] **Partnership with local governments**
- [ ] **Donation tracking for tax purposes**

---

## 6. Technical Debt

### 6.1: Code Quality (Priority: MEDIUM)

**Estimated Time:** 4-6 hours

- [ ] Remove commented code
- [ ] Improve error handling across all services
- [ ] Add input validation everywhere
- [ ] Implement proper loading states
- [ ] Add null safety improvements
- [ ] Code documentation (JSDoc style comments)

### 6.2: State Management (Priority: LOW)

**Estimated Time:** 10-15 hours

Current: Mix of `setState`, ChangeNotifier  
Recommendation: Migrate to **Riverpod** or **Bloc**

- [ ] Evaluate state management options
- [ ] Create state management architecture plan
- [ ] Migrate incrementally (one feature at a time)
- [ ] Update documentation

### 6.3: Testing (Priority: MEDIUM)

**Estimated Time:** 15-20 hours

- [ ] **Unit tests** for services (target: 80% coverage)
- [ ] **Widget tests** for key screens
- [ ] **Integration tests** for critical flows
- [ ] **E2E tests** with Patrol or Flutter Driver
- [ ] Set up CI/CD pipeline with automated testing

---

## 7. Testing Strategy

### 7.1: Testing Phases

#### Phase 1: Unit Testing
- All service methods
- Model serialization/deserialization
- Utility functions
- Validation logic

#### Phase 2: Widget Testing
- Authentication screens
- Post creation flow
- Profile screen
- Search & filters

#### Phase 3: Integration Testing
- Complete user signup → post creation → favorite → message flow
- Post edit/delete operations
- Real-time messaging

#### Phase 4: Performance Testing
- Image upload performance
- Database query optimization
- Real-time subscription efficiency
- App bundle size optimization

### 7.2: Testing Tools

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0  # Mocking
  patrol: ^3.0.0    # E2E testing
  integration_test:
    sdk: flutter
```

---

## 8. Deployment Strategy

### 8.1: Version Control

- [ ] Set up proper Git branching strategy
  - `main` - production
  - `develop` - development
  - `feature/*` - new features
  - `hotfix/*` - urgent fixes

### 8.2: Environments

- [ ] **Development:** Local + Supabase dev project
- [ ] **Staging:** Supabase staging project
- [ ] **Production:** Supabase production project

### 8.3: Release Process

- [ ] Set up semantic versioning
- [ ] Create release checklist
- [ ] App Store submission guidelines
- [ ] Google Play submission guidelines
- [ ] Beta testing with TestFlight/Internal Testing
- [ ] Crash reporting (Sentry or Firebase Crashlytics)
- [ ] Analytics (Mixpanel or PostHog)

### 8.4: CI/CD Pipeline

```yaml
# GitHub Actions example
- Build and test on PR
- Auto-deploy staging on merge to develop
- Manual deploy to production
- Automated changelog generation
```

---

## 📊 Timeline Estimate

### Sprint 1: Supabase Migration (2 weeks)
- Complete Phase 1.1 - 1.6
- Fix critical issues (Section 2)
- **Deliverable:** Working app with Supabase backend

### Sprint 2: Core Features (2 weeks)
- Item management (Section 3.1)
- Real-time messaging (Section 2.1)
- Enhanced item detail (Section 3.2)
- **Deliverable:** Full CRUD operations, working chat

### Sprint 3: Search & Location (1.5 weeks)
- Search implementation (Section 3.3)
- Location features (Section 3.4)
- **Deliverable:** Advanced search and proximity filtering

### Sprint 4: Enhanced Features (2 weeks)
- Rating system (Section 4.1)
- Profile enhancements (Section 4.2)
- Request system (Section 4.5)
- **Deliverable:** Complete user experience

### Sprint 5: Polish & Testing (1 week)
- Fix technical debt (Section 6)
- Comprehensive testing (Section 7)
- UI/UX improvements
- **Deliverable:** Production-ready app

### Sprint 6: Launch Preparation (1 week)
- App store submissions
- Marketing materials
- User documentation
- **Deliverable:** Public launch

**Total Timeline:** ~10 weeks (2.5 months)

---

## 🎯 Success Metrics

### Technical Metrics
- [ ] Code coverage > 80%
- [ ] App launch time < 2 seconds
- [ ] Image upload time < 5 seconds
- [ ] Real-time message latency < 500ms
- [ ] Crash-free rate > 99.5%

### User Metrics
- [ ] 100 active users in first month
- [ ] Average 10 items posted per day
- [ ] 20% item request conversion rate
- [ ] 4.5+ star rating in app stores

### Business Metrics
- [ ] 500+ items rescued from landfill in first 3 months
- [ ] Active user growth of 20% MoM
- [ ] 50% user retention after 30 days

---

## 📝 Notes

### Decision Log

**2025-12-27:** Decision to migrate from Firebase to Supabase
- **Reason:** Better developer experience, PostgreSQL, lower costs
- **Impact:** 2-week migration effort, improved scalability
- **Status:** Planning phase

### Known Limitations

- iOS push notifications require paid Apple Developer account
- Google Maps API requires billing setup after free tier
- Supabase free tier limits: 500MB database, 1GB storage, 2GB bandwidth
- Consider upgrading to Supabase Pro ($25/mo) at 100+ active users

### Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter + Supabase Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices)

---

**Last Updated:** December 27, 2025  
**Maintained By:** Development Team  
**Next Review:** January 10, 2026
