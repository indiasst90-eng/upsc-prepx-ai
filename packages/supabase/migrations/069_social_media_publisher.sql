-- Migration: 069_social_media_publisher.sql
-- Description: Social Media Auto-Publisher - Admin Tool
-- Story: 16.2
-- Created: 2025-12-28

-- =====================================================
-- SOCIAL PLATFORMS (AC 1)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_platforms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL CHECK (slug IN ('youtube', 'instagram', 'facebook', 'twitter', 'telegram')),
  icon TEXT,
  api_base_url TEXT,
  
  -- Platform-specific configuration (AC 4)
  formatting_rules JSONB DEFAULT '{}',
  -- e.g., {"max_caption": 2200, "aspect_ratio": "9:16", "max_hashtags": 30}
  
  -- Supported content types (AC 2)
  supported_content_types TEXT[] DEFAULT ARRAY['video', 'image', 'text'],
  
  -- Optimal posting times (AC 8)
  optimal_posting_hours JSONB DEFAULT '[9, 12, 18, 21]',
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- CONNECTED ACCOUNTS (AC 5 - OAuth)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_connected_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform_id UUID REFERENCES social_platforms(id) ON DELETE CASCADE,
  
  -- Account info
  account_name TEXT NOT NULL,
  account_handle TEXT,
  account_id TEXT NOT NULL, -- Platform's user/channel ID
  profile_image_url TEXT,
  
  -- OAuth tokens
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  scopes TEXT[],
  
  -- Connection status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'error')),
  last_used_at TIMESTAMPTZ,
  error_message TEXT,
  
  -- Team access (AC 9)
  connected_by UUID ,
  team_accessible BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- ADMIN TEAM MEMBERS (AC 9)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  UNIQUE,
  
  role TEXT DEFAULT 'editor' CHECK (role IN ('admin', 'editor', 'viewer')),
  
  -- Permissions
  can_publish BOOLEAN DEFAULT false,
  can_schedule BOOLEAN DEFAULT true,
  can_connect_accounts BOOLEAN DEFAULT false,
  can_manage_team BOOLEAN DEFAULT false,
  
  invited_by UUID ,
  accepted_at TIMESTAMPTZ,
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- CONTENT TYPES (AC 2)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_content_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL CHECK (slug IN ('daily_ca', 'topic_short', 'weekly_documentary', 'announcement', 'poll', 'story')),
  description TEXT,
  
  -- Which platforms support this content type
  target_platforms TEXT[] NOT NULL,
  
  -- Default formatting
  default_format JSONB DEFAULT '{}',
  
  -- Template for captions
  caption_template TEXT,
  hashtag_template TEXT[],
  
  -- Scheduling
  auto_schedule BOOLEAN DEFAULT true,
  schedule_offset_hours INTEGER DEFAULT 0, -- Hours after content generation
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- SCHEDULED POSTS (AC 3, 6, 8)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Content reference
  content_type_id UUID REFERENCES social_content_types(id),
  source_content_id UUID, -- Reference to the actual content (video, documentary, etc.)
  source_content_type TEXT, -- 'daily_ca_video', 'documentary', 'topic_short'
  
  -- Post content
  title TEXT NOT NULL,
  caption TEXT,
  hashtags TEXT[],
  media_urls TEXT[],
  thumbnail_url TEXT,
  
  -- Platform-specific formatting (AC 4)
  platform_id UUID REFERENCES social_platforms(id),
  account_id UUID REFERENCES social_connected_accounts(id),
  formatted_content JSONB DEFAULT '{}',
  -- Stores platform-specific data like YouTube tags, Instagram alt text, etc.
  
  -- Compliance (AC 10)
  disclaimer TEXT,
  compliance_checked BOOLEAN DEFAULT false,
  
  -- Status (AC 6)
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'publishing', 'published', 'failed', 'cancelled')),
  
  -- Scheduling (AC 8)
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  
  -- Publishing details
  platform_post_id TEXT, -- ID returned by platform after publishing
  platform_url TEXT, -- Direct link to the post
  
  -- Error handling
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  
  -- Created/updated by (AC 9)
  created_by UUID ,
  updated_by UUID ,
  approved_by UUID ,
  approved_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- POST ANALYTICS (AC 7)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_post_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES social_posts(id) ON DELETE CASCADE,
  
  -- Metrics
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  saves INTEGER DEFAULT 0,
  
  -- Platform-specific metrics
  platform_metrics JSONB DEFAULT '{}',
  -- e.g., {"youtube_watch_time": 1234, "instagram_reach": 5678}
  
  -- Engagement rate
  engagement_rate DECIMAL(5,2),
  
  -- Time series
  metrics_history JSONB DEFAULT '[]',
  -- Array of {timestamp, views, likes, ...}
  
  last_synced_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- PUBLISHING QUEUE
-- =====================================================
CREATE TABLE IF NOT EXISTS social_publishing_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES social_posts(id) ON DELETE CASCADE,
  
  -- Queue status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  priority INTEGER DEFAULT 5, -- 1 = highest, 10 = lowest
  
  -- Retry logic
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  last_attempt_at TIMESTAMPTZ,
  next_attempt_at TIMESTAMPTZ,
  
  -- Worker assignment
  worker_id TEXT,
  locked_until TIMESTAMPTZ,
  
  error_log JSONB DEFAULT '[]',
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- PLATFORM DISCLAIMERS (AC 10)
-- =====================================================
CREATE TABLE IF NOT EXISTS social_disclaimers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform_id UUID REFERENCES social_platforms(id),
  content_type_id UUID REFERENCES social_content_types(id),
  
  disclaimer_text TEXT NOT NULL,
  is_required BOOLEAN DEFAULT true,
  placement TEXT DEFAULT 'end' CHECK (placement IN ('start', 'end', 'separate')),
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- SEED DATA: Platforms (AC 1)
-- =====================================================
INSERT INTO social_platforms (name, slug, icon, formatting_rules, supported_content_types, optimal_posting_hours) VALUES
(
  'YouTube',
  'youtube',
  '📺',
  '{"max_title": 100, "max_description": 5000, "max_tags": 500, "aspect_ratios": ["16:9", "9:16"], "supports_shorts": true}',
  ARRAY['video'],
  '[9, 15, 18, 21]'
),
(
  'Instagram',
  'instagram',
  '📷',
  '{"max_caption": 2200, "max_hashtags": 30, "aspect_ratios": ["1:1", "4:5", "9:16"], "supports_reels": true, "supports_stories": true}',
  ARRAY['video', 'image'],
  '[11, 14, 19, 21]'
),
(
  'Facebook',
  'facebook',
  '📘',
  '{"max_post": 63206, "supports_watch": true, "supports_reels": true}',
  ARRAY['video', 'image', 'text'],
  '[9, 13, 16, 19]'
),
(
  'Twitter/X',
  'twitter',
  '🐦',
  '{"max_tweet": 280, "max_video_length": 140, "supports_threads": true}',
  ARRAY['video', 'image', 'text'],
  '[8, 12, 17, 21]'
),
(
  'Telegram',
  'telegram',
  '✈️',
  '{"max_caption": 1024, "supports_channels": true, "supports_groups": true}',
  ARRAY['video', 'image', 'text'],
  '[8, 12, 18, 22]'
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- SEED DATA: Content Types (AC 2)
-- =====================================================
INSERT INTO social_content_types (name, slug, description, target_platforms, default_format, caption_template, hashtag_template, auto_schedule) VALUES
(
  'Daily Current Affairs',
  'daily_ca',
  'Daily current affairs video for UPSC preparation',
  ARRAY['youtube', 'telegram'],
  '{"youtube": {"category": "Education", "privacy": "public"}, "telegram": {"disable_notification": false}}',
  'Current Affairs for {date}\n\nToday''s important news for UPSC aspirants:\n{summary}\n\n#UPSC #CurrentAffairs #IAS',
  ARRAY['#UPSC', '#CurrentAffairs', '#IAS', '#UPSC2025', '#DailyCurrent', '#UPSCPreparation'],
  true
),
(
  'Topic Shorts',
  'topic_short',
  'Short educational videos on specific topics',
  ARRAY['instagram', 'youtube', 'twitter'],
  '{"instagram": {"share_to_feed": true}, "youtube": {"shorts": true}}',
  '{topic} explained in 60 seconds! 🎯\n\n{key_point}\n\n#UPSC #Shorts',
  ARRAY['#UPSC', '#Shorts', '#UPSCShorts', '#Education', '#LearnOnInstagram', '#QuickLearn'],
  true
),
(
  'Weekly Documentary',
  'weekly_documentary',
  'Weekly in-depth documentary on UPSC topics',
  ARRAY['youtube'],
  '{"youtube": {"category": "Education", "made_for_kids": false}}',
  '{title}\n\n{description}\n\nTimestamps:\n{chapters}\n\n#UPSC #Documentary #DeepDive',
  ARRAY['#UPSC', '#Documentary', '#InDepthAnalysis', '#UPSCPreparation', '#IndianHistory', '#Polity'],
  true
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- SEED DATA: Disclaimers (AC 10)
-- =====================================================
INSERT INTO social_disclaimers (platform_id, disclaimer_text, placement) 
SELECT p.id, 
  'This content is for educational purposes only. UPSC Mastery is not affiliated with UPSC.',
  'end'
FROM social_platforms p
WHERE p.slug IN ('youtube', 'instagram', 'facebook')
ON CONFLICT DO NOTHING;

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Schedule a post
CREATE OR REPLACE FUNCTION schedule_social_post(
  p_content_type_slug TEXT,
  p_source_id UUID,
  p_title TEXT,
  p_caption TEXT,
  p_media_urls TEXT[],
  p_scheduled_at TIMESTAMPTZ DEFAULT NULL,
  p_created_by UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_content_type RECORD;
  v_platform RECORD;
  v_account RECORD;
  v_post RECORD;
  v_posts JSONB := '[]'::jsonb;
  v_scheduled_time TIMESTAMPTZ;
BEGIN
  -- Get content type
  SELECT * INTO v_content_type FROM social_content_types WHERE slug = p_content_type_slug;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Content type not found');
  END IF;
  
  -- Create posts for each target platform
  FOR v_platform IN 
    SELECT p.* FROM social_platforms p 
    WHERE p.slug = ANY(v_content_type.target_platforms) AND p.is_active = true
  LOOP
    -- Get connected account for platform
    SELECT * INTO v_account FROM social_connected_accounts 
    WHERE platform_id = v_platform.id AND status = 'active' 
    ORDER BY last_used_at DESC NULLS LAST LIMIT 1;
    
    IF FOUND THEN
      -- Calculate scheduled time if not provided
      v_scheduled_time := COALESCE(
        p_scheduled_at,
        now() + (v_content_type.schedule_offset_hours || ' hours')::INTERVAL
      );
      
      -- Get disclaimer
      DECLARE
        v_disclaimer TEXT;
      BEGIN
        SELECT disclaimer_text INTO v_disclaimer 
        FROM social_disclaimers 
        WHERE platform_id = v_platform.id 
        AND (content_type_id = v_content_type.id OR content_type_id IS NULL)
        AND is_active = true
        LIMIT 1;
        
        -- Create the post
        INSERT INTO social_posts (
          content_type_id, source_content_id, source_content_type,
          title, caption, hashtags, media_urls,
          platform_id, account_id,
          disclaimer, status, scheduled_at, created_by
        ) VALUES (
          v_content_type.id, p_source_id, p_content_type_slug,
          p_title, p_caption, v_content_type.hashtag_template, p_media_urls,
          v_platform.id, v_account.id,
          v_disclaimer, 
          CASE WHEN v_content_type.auto_schedule THEN 'scheduled' ELSE 'draft' END,
          v_scheduled_time, p_created_by
        ) RETURNING * INTO v_post;
        
        -- Add to queue if scheduled
        IF v_content_type.auto_schedule THEN
          INSERT INTO social_publishing_queue (post_id, next_attempt_at)
          VALUES (v_post.id, v_scheduled_time);
        END IF;
        
        v_posts := v_posts || jsonb_build_object(
          'post_id', v_post.id,
          'platform', v_platform.slug,
          'status', v_post.status,
          'scheduled_at', v_scheduled_time
        );
      END;
    END IF;
  END LOOP;
  
  RETURN jsonb_build_object('success', true, 'posts', v_posts);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get publishing dashboard
CREATE OR REPLACE FUNCTION get_social_dashboard(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_pending_posts JSONB;
  v_scheduled_posts JSONB;
  v_recent_published JSONB;
  v_analytics_summary JSONB;
  v_connected_accounts JSONB;
BEGIN
  -- Pending drafts
  SELECT COALESCE(jsonb_agg(to_jsonb(p.*)), '[]'::jsonb) INTO v_pending_posts
  FROM social_posts p WHERE p.status = 'draft'
  ORDER BY p.created_at DESC LIMIT 10;
  
  -- Scheduled posts
  SELECT COALESCE(jsonb_agg(to_jsonb(p.*)), '[]'::jsonb) INTO v_scheduled_posts
  FROM social_posts p WHERE p.status = 'scheduled' AND p.scheduled_at > now()
  ORDER BY p.scheduled_at ASC LIMIT 20;
  
  -- Recent published
  SELECT COALESCE(jsonb_agg(to_jsonb(p.*)), '[]'::jsonb) INTO v_recent_published
  FROM social_posts p WHERE p.status = 'published'
  ORDER BY p.published_at DESC LIMIT 10;
  
  -- Analytics summary
  SELECT jsonb_build_object(
    'total_posts', COUNT(*),
    'total_views', COALESCE(SUM((pa.views)::bigint), 0),
    'total_engagement', COALESCE(SUM(pa.likes + pa.comments + pa.shares), 0),
    'avg_engagement_rate', COALESCE(AVG(pa.engagement_rate), 0)
  ) INTO v_analytics_summary
  FROM social_posts p
  LEFT JOIN social_post_analytics pa ON pa.post_id = p.id
  WHERE p.status = 'published' AND p.published_at > now() - INTERVAL '30 days';
  
  -- Connected accounts
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', a.id,
    'platform', p.slug,
    'platform_name', p.name,
    'account_name', a.account_name,
    'status', a.status
  )), '[]'::jsonb) INTO v_connected_accounts
  FROM social_connected_accounts a
  JOIN social_platforms p ON p.id = a.platform_id
  WHERE a.status = 'active';
  
  RETURN jsonb_build_object(
    'pending_drafts', v_pending_posts,
    'scheduled', v_scheduled_posts,
    'recent_published', v_recent_published,
    'analytics_summary', v_analytics_summary,
    'connected_accounts', v_connected_accounts
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Approve and publish post
CREATE OR REPLACE FUNCTION approve_social_post(
  p_post_id UUID,
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_post RECORD;
BEGIN
  UPDATE social_posts SET
    status = 'scheduled',
    approved_by = p_user_id,
    approved_at = now(),
    updated_at = now(),
    updated_by = p_user_id
  WHERE id = p_post_id AND status = 'draft'
  RETURNING * INTO v_post;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Post not found or already processed');
  END IF;
  
  -- Add to publishing queue
  INSERT INTO social_publishing_queue (post_id, next_attempt_at)
  VALUES (p_post_id, v_post.scheduled_at)
  ON CONFLICT DO NOTHING;
  
  RETURN jsonb_build_object('success', true, 'post', to_jsonb(v_post));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sync analytics from platform
CREATE OR REPLACE FUNCTION sync_post_analytics(
  p_post_id UUID,
  p_views INTEGER,
  p_likes INTEGER,
  p_comments INTEGER,
  p_shares INTEGER,
  p_saves INTEGER DEFAULT 0,
  p_platform_metrics JSONB DEFAULT '{}'
) RETURNS VOID AS $$
DECLARE
  v_engagement_rate DECIMAL(5,2);
BEGIN
  -- Calculate engagement rate
  IF p_views > 0 THEN
    v_engagement_rate := ((p_likes + p_comments + p_shares)::DECIMAL / p_views) * 100;
  ELSE
    v_engagement_rate := 0;
  END IF;
  
  INSERT INTO social_post_analytics (
    post_id, views, likes, comments, shares, saves,
    platform_metrics, engagement_rate,
    metrics_history, last_synced_at
  ) VALUES (
    p_post_id, p_views, p_likes, p_comments, p_shares, p_saves,
    p_platform_metrics, v_engagement_rate,
    jsonb_build_array(jsonb_build_object(
      'timestamp', now(),
      'views', p_views,
      'likes', p_likes,
      'comments', p_comments,
      'shares', p_shares
    )),
    now()
  )
  ON CONFLICT (post_id) DO UPDATE SET
    views = p_views,
    likes = p_likes,
    comments = p_comments,
    shares = p_shares,
    saves = p_saves,
    platform_metrics = p_platform_metrics,
    engagement_rate = v_engagement_rate,
    metrics_history = social_post_analytics.metrics_history || jsonb_build_array(jsonb_build_object(
      'timestamp', now(),
      'views', p_views,
      'likes', p_likes,
      'comments', p_comments,
      'shares', p_shares
    )),
    last_synced_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get optimal posting time
CREATE OR REPLACE FUNCTION get_optimal_posting_time(
  p_platform_slug TEXT,
  p_target_date DATE DEFAULT CURRENT_DATE
) RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_platform RECORD;
  v_optimal_hour INTEGER;
BEGIN
  SELECT * INTO v_platform FROM social_platforms WHERE slug = p_platform_slug;
  
  IF NOT FOUND THEN
    RETURN p_target_date + INTERVAL '9 hours'; -- Default to 9 AM
  END IF;
  
  -- Get first optimal hour
  SELECT (v_platform.optimal_posting_hours->>0)::INTEGER INTO v_optimal_hour;
  
  RETURN p_target_date + (v_optimal_hour || ' hours')::INTERVAL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check team permission
CREATE OR REPLACE FUNCTION check_social_permission(
  p_user_id UUID,
  p_permission TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_member RECORD;
BEGIN
  SELECT * INTO v_member FROM social_team_members 
  WHERE user_id = p_user_id AND is_active = true;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Admins have all permissions
  IF v_member.role = 'admin' THEN
    RETURN true;
  END IF;
  
  CASE p_permission
    WHEN 'publish' THEN RETURN v_member.can_publish;
    WHEN 'schedule' THEN RETURN v_member.can_schedule;
    WHEN 'connect' THEN RETURN v_member.can_connect_accounts;
    WHEN 'manage_team' THEN RETURN v_member.can_manage_team;
    ELSE RETURN false;
  END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE social_platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_connected_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_content_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_post_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_publishing_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_disclaimers ENABLE ROW LEVEL SECURITY;

-- Public read for platforms and content types
CREATE POLICY "Public can view platforms" ON social_platforms FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view content types" ON social_content_types FOR SELECT USING (is_active = true);

-- Team members can access
CREATE POLICY "Team can view accounts" ON social_connected_accounts 
  FOR SELECT TO authenticated 
  USING (team_accessible = true OR connected_by = auth.uid());

CREATE POLICY "Team can view posts" ON social_posts 
  FOR SELECT TO authenticated 
  USING (EXISTS (SELECT 1 FROM social_team_members WHERE user_id = auth.uid() AND is_active = true));

CREATE POLICY "Team can manage posts" ON social_posts 
  FOR ALL TO authenticated 
  USING (EXISTS (SELECT 1 FROM social_team_members WHERE user_id = auth.uid() AND is_active = true AND (can_schedule = true OR can_publish = true)));

CREATE POLICY "Team can view analytics" ON social_post_analytics 
  FOR SELECT TO authenticated 
  USING (EXISTS (SELECT 1 FROM social_team_members WHERE user_id = auth.uid() AND is_active = true));

CREATE POLICY "Admins manage team" ON social_team_members 
  FOR ALL TO authenticated 
  USING (EXISTS (SELECT 1 FROM social_team_members WHERE user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "View own membership" ON social_team_members 
  FOR SELECT TO authenticated 
  USING (user_id = auth.uid());

CREATE POLICY "Team can view queue" ON social_publishing_queue 
  FOR SELECT TO authenticated 
  USING (EXISTS (SELECT 1 FROM social_team_members WHERE user_id = auth.uid() AND is_active = true));

CREATE POLICY "View disclaimers" ON social_disclaimers 
  FOR SELECT TO authenticated 
  USING (is_active = true);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_posts_status ON social_posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_scheduled ON social_posts(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_posts_platform ON social_posts(platform_id);
CREATE INDEX IF NOT EXISTS idx_accounts_platform ON social_connected_accounts(platform_id);
CREATE INDEX IF NOT EXISTS idx_accounts_status ON social_connected_accounts(status);
CREATE INDEX IF NOT EXISTS idx_queue_status ON social_publishing_queue(status, next_attempt_at);
CREATE INDEX IF NOT EXISTS idx_analytics_post ON social_post_analytics(post_id);
CREATE INDEX IF NOT EXISTS idx_team_user ON social_team_members(user_id);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_social_post_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_social_post_timestamp ON social_posts;
CREATE TRIGGER trigger_update_social_post_timestamp
  BEFORE UPDATE ON social_posts
  FOR EACH ROW EXECUTE FUNCTION update_social_post_timestamp();

DROP TRIGGER IF EXISTS trigger_update_social_account_timestamp ON social_connected_accounts;
CREATE TRIGGER trigger_update_social_account_timestamp
  BEFORE UPDATE ON social_connected_accounts
  FOR EACH ROW EXECUTE FUNCTION update_social_post_timestamp();

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE social_platforms IS 'Story 16.2: Supported social media platforms (AC 1)';
COMMENT ON TABLE social_connected_accounts IS 'Story 16.2: OAuth connected accounts (AC 5)';
COMMENT ON TABLE social_posts IS 'Story 16.2: Scheduled and published posts (AC 3, 6, 8)';
COMMENT ON TABLE social_post_analytics IS 'Story 16.2: Post analytics and engagement metrics (AC 7)';
COMMENT ON TABLE social_team_members IS 'Story 16.2: Team collaboration for publishing (AC 9)';
COMMENT ON TABLE social_disclaimers IS 'Story 16.2: Platform-specific disclaimers (AC 10)';

