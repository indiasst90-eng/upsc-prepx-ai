-- Migration 048: Mindmap Editing & Collaboration
-- Story 9.6: Version history, sharing, and collaboration

-- ============================================
-- MINDMAP VERSIONS TABLE (AC 7)
-- ============================================

CREATE TABLE IF NOT EXISTS public.mindmap_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mindmap_id UUID NOT NULL REFERENCES public.mindmaps(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  structure_json JSONB NOT NULL,
  change_summary TEXT,
  created_by UUID ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(mindmap_id, version_number)
);

CREATE INDEX idx_versions_mindmap ON public.mindmap_versions(mindmap_id);
CREATE INDEX idx_versions_created ON public.mindmap_versions(created_at DESC);

-- ============================================
-- MINDMAP SHARES TABLE (AC 8)
-- ============================================

CREATE TABLE IF NOT EXISTS public.mindmap_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mindmap_id UUID NOT NULL REFERENCES public.mindmaps(id) ON DELETE CASCADE,
  share_code TEXT UNIQUE NOT NULL,
  permission TEXT NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'edit', 'comment')),
  created_by UUID NOT NULL ,
  expires_at TIMESTAMPTZ,
  max_uses INTEGER,
  use_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shares_mindmap ON public.mindmap_shares(mindmap_id);
CREATE INDEX idx_shares_code ON public.mindmap_shares(share_code);

-- ============================================
-- MINDMAP COLLABORATORS TABLE (AC 9)
-- ============================================

CREATE TABLE IF NOT EXISTS public.mindmap_collaborators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mindmap_id UUID NOT NULL REFERENCES public.mindmaps(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  permission TEXT NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'edit', 'admin')),
  added_by UUID ,
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(mindmap_id, user_id)
);

CREATE INDEX idx_collaborators_mindmap ON public.mindmap_collaborators(mindmap_id);
CREATE INDEX idx_collaborators_user ON public.mindmap_collaborators(user_id);

-- ============================================
-- EDIT HISTORY FOR UNDO/REDO (AC 5)
-- ============================================

CREATE TABLE IF NOT EXISTS public.mindmap_edit_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mindmap_id UUID NOT NULL REFERENCES public.mindmaps(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  action_type TEXT NOT NULL CHECK (action_type IN ('add_node', 'delete_node', 'rename_node', 'move_node', 'add_edge', 'delete_edge', 'change_color', 'add_notes', 'bulk')),
  before_state JSONB,
  after_state JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_history_mindmap ON public.mindmap_edit_history(mindmap_id, created_at DESC);

-- RLS Policies
ALTER TABLE public.mindmap_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mindmap_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mindmap_collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mindmap_edit_history ENABLE ROW LEVEL SECURITY;

-- Versions policy: owner or collaborator can view
CREATE POLICY "Users can view versions of owned/shared mindmaps"
  ON public.mindmap_versions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.mindmaps m 
      WHERE m.id = mindmap_id 
      AND (m.user_id = auth.uid() OR m.is_public = TRUE)
    ) OR
    EXISTS (
      SELECT 1 FROM public.mindmap_collaborators c
      WHERE c.mindmap_id = mindmap_versions.mindmap_id AND c.user_id = auth.uid()
    )
  );

-- Shares policy: owner can manage
CREATE POLICY "Users can manage own shares"
  ON public.mindmap_shares FOR ALL
  USING (created_by = auth.uid());

-- Collaborators policy
CREATE POLICY "Users can view collaborator status"
  ON public.mindmap_collaborators FOR SELECT
  USING (user_id = auth.uid() OR added_by = auth.uid());

-- Edit history policy
CREATE POLICY "Users can view own edit history"
  ON public.mindmap_edit_history FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert edit history"
  ON public.mindmap_edit_history FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- AC 7: Save version
CREATE OR REPLACE FUNCTION save_mindmap_version(
  p_mindmap_id UUID,
  p_user_id UUID,
  p_change_summary TEXT DEFAULT 'Auto-saved version'
)
RETURNS INTEGER AS $$
DECLARE
  v_version INTEGER;
  v_mindmap RECORD;
BEGIN
  -- Get current mindmap
  SELECT * INTO v_mindmap FROM public.mindmaps WHERE id = p_mindmap_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  
  -- Get next version number
  SELECT COALESCE(MAX(version_number), 0) + 1 INTO v_version
  FROM public.mindmap_versions WHERE mindmap_id = p_mindmap_id;
  
  -- Save version
  INSERT INTO public.mindmap_versions (
    mindmap_id, version_number, title, structure_json, change_summary, created_by
  ) VALUES (
    p_mindmap_id, v_version, v_mindmap.title, v_mindmap.structure_json, p_change_summary, p_user_id
  );
  
  RETURN v_version;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Revert to version
CREATE OR REPLACE FUNCTION revert_mindmap_version(
  p_mindmap_id UUID,
  p_version_number INTEGER,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_version RECORD;
BEGIN
  -- Get version
  SELECT * INTO v_version FROM public.mindmap_versions 
  WHERE mindmap_id = p_mindmap_id AND version_number = p_version_number;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Save current as new version first
  PERFORM save_mindmap_version(p_mindmap_id, p_user_id, 'Before revert to v' || p_version_number);
  
  -- Update mindmap with version data
  UPDATE public.mindmaps SET
    structure_json = v_version.structure_json,
    updated_at = NOW()
  WHERE id = p_mindmap_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- AC 8: Create share link
CREATE OR REPLACE FUNCTION create_share_link(
  p_mindmap_id UUID,
  p_user_id UUID,
  p_permission TEXT DEFAULT 'view',
  p_expires_days INTEGER DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  v_code TEXT;
  v_expires TIMESTAMPTZ;
BEGIN
  -- Generate unique code
  v_code := encode(gen_random_bytes(12), 'base64');
  v_code := replace(replace(v_code, '/', '_'), '+', '-');
  
  -- Calculate expiry
  IF p_expires_days IS NOT NULL THEN
    v_expires := NOW() + (p_expires_days || ' days')::INTERVAL;
  END IF;
  
  -- Insert share
  INSERT INTO public.mindmap_shares (
    mindmap_id, share_code, permission, created_by, expires_at
  ) VALUES (
    p_mindmap_id, v_code, p_permission, p_user_id, v_expires
  );
  
  RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- AC 8: Access share link
CREATE OR REPLACE FUNCTION access_share_link(p_share_code TEXT, p_user_id UUID)
RETURNS TABLE (
  mindmap_id UUID,
  permission TEXT,
  is_valid BOOLEAN
) AS $$
DECLARE
  v_share RECORD;
BEGIN
  SELECT * INTO v_share FROM public.mindmap_shares
  WHERE share_code = p_share_code AND is_active = TRUE;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::UUID, 'none'::TEXT, FALSE;
    RETURN;
  END IF;
  
  -- Check expiry
  IF v_share.expires_at IS NOT NULL AND v_share.expires_at < NOW() THEN
    RETURN QUERY SELECT NULL::UUID, 'expired'::TEXT, FALSE;
    RETURN;
  END IF;
  
  -- Check max uses
  IF v_share.max_uses IS NOT NULL AND v_share.use_count >= v_share.max_uses THEN
    RETURN QUERY SELECT NULL::UUID, 'maxed'::TEXT, FALSE;
    RETURN;
  END IF;
  
  -- Increment use count
  UPDATE public.mindmap_shares SET use_count = use_count + 1 WHERE id = v_share.id;
  
  -- Add as collaborator if edit permission
  IF v_share.permission = 'edit' AND p_user_id IS NOT NULL THEN
    INSERT INTO public.mindmap_collaborators (mindmap_id, user_id, permission, added_by)
    VALUES (v_share.mindmap_id, p_user_id, 'edit', v_share.created_by)
    ON CONFLICT (mindmap_id, user_id) DO NOTHING;
  END IF;
  
  RETURN QUERY SELECT v_share.mindmap_id, v_share.permission, TRUE;
END;
$$ LANGUAGE plpgsql;

-- AC 5: Record edit action
CREATE OR REPLACE FUNCTION record_edit_action(
  p_mindmap_id UUID,
  p_user_id UUID,
  p_action_type TEXT,
  p_before_state JSONB,
  p_after_state JSONB
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.mindmap_edit_history (
    mindmap_id, user_id, action_type, before_state, after_state
  ) VALUES (
    p_mindmap_id, p_user_id, p_action_type, p_before_state, p_after_state
  )
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Get versions for mindmap
CREATE OR REPLACE FUNCTION get_mindmap_versions(p_mindmap_id UUID)
RETURNS TABLE (
  version_number INTEGER,
  title TEXT,
  change_summary TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.version_number,
    v.title,
    v.change_summary,
    v.created_at
  FROM public.mindmap_versions v
  WHERE v.mindmap_id = p_mindmap_id
  ORDER BY v.version_number DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.mindmap_versions IS 'Story 9.6 AC 7: Version history';
COMMENT ON TABLE public.mindmap_shares IS 'Story 9.6 AC 8: Share links';
COMMENT ON TABLE public.mindmap_collaborators IS 'Story 9.6 AC 9: Collaborators';
COMMENT ON TABLE public.mindmap_edit_history IS 'Story 9.6 AC 5: Undo/redo history';

