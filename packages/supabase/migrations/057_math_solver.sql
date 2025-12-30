-- Story 11.1: Math Solver - Manim Animation Step-by-Step
-- Migration 057: Math problems with OCR, steps, and animation

-- Create math_problems table (AC 1, 2, 3, 10)
CREATE TABLE IF NOT EXISTS public.math_problems (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  
  -- AC 1: Input methods
  input_type TEXT NOT NULL CHECK (input_type IN ('typed', 'image')),
  original_input TEXT, -- Typed equation
  image_url TEXT, -- Uploaded image URL
  
  -- AC 2: OCR processing
  ocr_extracted_text TEXT,
  ocr_confidence DECIMAL(3, 2),
  
  -- AC 3: Problem classification
  problem_type TEXT CHECK (problem_type IN (
    'arithmetic', 'algebra', 'geometry', 'data_interpretation', 'graphs',
    'percentage', 'ratio_proportion', 'time_work', 'time_distance', 'profit_loss'
  )),
  problem_complexity TEXT DEFAULT 'medium' CHECK (problem_complexity IN ('easy', 'medium', 'hard')),
  
  -- Problem content
  problem_statement TEXT NOT NULL,
  final_answer TEXT,
  
  -- AC 4: Solution steps (5-10 steps with reasoning)
  solution_steps JSONB DEFAULT '[]'::jsonb, -- [{ step_number, equation, explanation, visual_type }]
  step_count INTEGER DEFAULT 0,
  
  -- AC 5: Manim animation
  manim_script_id TEXT, -- Reference to Manim service
  animation_status TEXT DEFAULT 'pending' CHECK (animation_status IN (
    'pending', 'generating', 'rendering', 'completed', 'failed'
  )),
  
  -- AC 6: Video details
  video_url TEXT,
  video_duration_seconds INTEGER, -- 2-5 minutes = 120-300 seconds
  thumbnail_url TEXT,
  
  -- AC 7: TTS narration
  narration_url TEXT,
  narration_text TEXT,
  
  -- AC 8: Text solution
  text_solution TEXT,
  
  -- AC 9: Similar problems (references to question bank)
  similar_problem_ids UUID[] DEFAULT '{}',
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  solved_at TIMESTAMPTZ,
  
  -- For history (AC 10)
  is_favorite BOOLEAN DEFAULT FALSE,
  view_count INTEGER DEFAULT 1
);

-- Create math_problem_steps table for detailed step storage
CREATE TABLE IF NOT EXISTS public.math_problem_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  problem_id UUID NOT NULL REFERENCES public.math_problems(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  
  -- Step content
  equation TEXT NOT NULL, -- The mathematical expression
  explanation TEXT NOT NULL, -- Reasoning for this step
  
  -- AC 5: Visual representation type for Manim
  visual_type TEXT CHECK (visual_type IN (
    'equation_animation', 'bar_chart', 'pie_chart', 'number_line',
    'coordinate_graph', 'venn_diagram', 'geometric_shape', 'table', 'none'
  )) DEFAULT 'equation_animation',
  visual_data JSONB, -- Data for specific visual type
  
  -- Animation timing
  start_time_seconds DECIMAL(6, 2),
  duration_seconds DECIMAL(5, 2),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(problem_id, step_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_math_problems_user ON public.math_problems(user_id);
CREATE INDEX IF NOT EXISTS idx_math_problems_type ON public.math_problems(problem_type);
CREATE INDEX IF NOT EXISTS idx_math_problems_status ON public.math_problems(animation_status);
CREATE INDEX IF NOT EXISTS idx_math_problems_created ON public.math_problems(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_math_steps_problem ON public.math_problem_steps(problem_id);

-- Enable RLS
ALTER TABLE public.math_problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.math_problem_steps ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own math problems"
  ON public.math_problems FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own math problems"
  ON public.math_problems FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view steps of own problems"
  ON public.math_problem_steps FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.math_problems p
    WHERE p.id = problem_id AND p.user_id = auth.uid()
  ));

CREATE POLICY "Users can manage steps of own problems"
  ON public.math_problem_steps FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.math_problems p
    WHERE p.id = problem_id AND p.user_id = auth.uid()
  ));

-- Function to create math problem (AC 1, 2)
CREATE OR REPLACE FUNCTION create_math_problem(
  p_user_id UUID,
  p_input_type TEXT,
  p_original_input TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_ocr_text TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_problem_id UUID;
  v_problem_statement TEXT;
BEGIN
  -- Use OCR text if image, otherwise use original input
  v_problem_statement := COALESCE(p_ocr_text, p_original_input, 'Math Problem');
  
  INSERT INTO public.math_problems (
    user_id, input_type, original_input, image_url, 
    ocr_extracted_text, problem_statement
  ) VALUES (
    p_user_id, p_input_type, p_original_input, p_image_url,
    p_ocr_text, v_problem_statement
  )
  RETURNING id INTO v_problem_id;
  
  RETURN v_problem_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to classify problem type (AC 3)
CREATE OR REPLACE FUNCTION classify_math_problem(
  p_problem_id UUID,
  p_problem_type TEXT,
  p_complexity TEXT DEFAULT 'medium'
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.math_problems
  SET problem_type = p_problem_type,
      problem_complexity = p_complexity,
      updated_at = NOW()
  WHERE id = p_problem_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save solution steps (AC 4)
CREATE OR REPLACE FUNCTION save_solution_steps(
  p_problem_id UUID,
  p_steps JSONB,
  p_final_answer TEXT,
  p_text_solution TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_step JSONB;
  v_step_num INTEGER := 0;
BEGIN
  -- Delete existing steps
  DELETE FROM public.math_problem_steps WHERE problem_id = p_problem_id;
  
  -- Insert new steps
  FOR v_step IN SELECT * FROM jsonb_array_elements(p_steps)
  LOOP
    v_step_num := v_step_num + 1;
    INSERT INTO public.math_problem_steps (
      problem_id, step_number, equation, explanation,
      visual_type, visual_data
    ) VALUES (
      p_problem_id,
      v_step_num,
      v_step->>'equation',
      v_step->>'explanation',
      COALESCE(v_step->>'visual_type', 'equation_animation'),
      v_step->'visual_data'
    );
  END LOOP;
  
  -- Update problem with steps summary
  UPDATE public.math_problems
  SET solution_steps = p_steps,
      step_count = v_step_num,
      final_answer = p_final_answer,
      text_solution = p_text_solution,
      updated_at = NOW()
  WHERE id = p_problem_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update animation status (AC 5, 6)
CREATE OR REPLACE FUNCTION update_animation_status(
  p_problem_id UUID,
  p_status TEXT,
  p_video_url TEXT DEFAULT NULL,
  p_duration INTEGER DEFAULT NULL,
  p_thumbnail TEXT DEFAULT NULL,
  p_narration_url TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.math_problems
  SET animation_status = p_status,
      video_url = COALESCE(p_video_url, video_url),
      video_duration_seconds = COALESCE(p_duration, video_duration_seconds),
      thumbnail_url = COALESCE(p_thumbnail, thumbnail_url),
      narration_url = COALESCE(p_narration_url, narration_url),
      solved_at = CASE WHEN p_status = 'completed' THEN NOW() ELSE solved_at END,
      updated_at = NOW()
  WHERE id = p_problem_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to link similar problems (AC 9)
CREATE OR REPLACE FUNCTION link_similar_problems(
  p_problem_id UUID,
  p_similar_ids UUID[]
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.math_problems
  SET similar_problem_ids = p_similar_ids,
      updated_at = NOW()
  WHERE id = p_problem_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's math history (AC 10)
CREATE OR REPLACE FUNCTION get_math_problem_history(
  p_user_id UUID,
  p_problem_type TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(problem ORDER BY created_at DESC)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', m.id,
      'input_type', m.input_type,
      'problem_statement', LEFT(m.problem_statement, 100),
      'problem_type', m.problem_type,
      'complexity', m.problem_complexity,
      'animation_status', m.animation_status,
      'video_url', m.video_url,
      'thumbnail_url', m.thumbnail_url,
      'step_count', m.step_count,
      'final_answer', m.final_answer,
      'is_favorite', m.is_favorite,
      'created_at', m.created_at,
      'solved_at', m.solved_at
    ) as problem,
    m.created_at
    FROM public.math_problems m
    WHERE m.user_id = p_user_id
      AND (p_problem_type IS NULL OR m.problem_type = p_problem_type)
    ORDER BY m.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) problems;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get problem with steps
CREATE OR REPLACE FUNCTION get_math_problem_with_steps(p_problem_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_problem RECORD;
  v_steps JSONB;
BEGIN
  SELECT * INTO v_problem
  FROM public.math_problems
  WHERE id = p_problem_id;
  
  IF v_problem IS NULL THEN
    RETURN jsonb_build_object('error', 'Problem not found');
  END IF;
  
  -- Increment view count
  UPDATE public.math_problems
  SET view_count = view_count + 1
  WHERE id = p_problem_id;
  
  -- Get steps
  SELECT jsonb_agg(s ORDER BY s.step_number)
  INTO v_steps
  FROM (
    SELECT jsonb_build_object(
      'step_number', step_number,
      'equation', equation,
      'explanation', explanation,
      'visual_type', visual_type,
      'visual_data', visual_data,
      'start_time', start_time_seconds,
      'duration', duration_seconds
    ) as s,
    step_number
    FROM public.math_problem_steps
    WHERE problem_id = p_problem_id
  ) steps;
  
  RETURN jsonb_build_object(
    'problem', to_jsonb(v_problem),
    'steps', COALESCE(v_steps, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_math_problem TO authenticated;
GRANT EXECUTE ON FUNCTION classify_math_problem TO authenticated;
GRANT EXECUTE ON FUNCTION save_solution_steps TO authenticated;
GRANT EXECUTE ON FUNCTION update_animation_status TO authenticated;
GRANT EXECUTE ON FUNCTION link_similar_problems TO authenticated;
GRANT EXECUTE ON FUNCTION get_math_problem_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_math_problem_with_steps TO authenticated;

