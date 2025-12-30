## Epic 6: Progress Tracking & Personalization

**Epic Goal:**
Build comprehensive progress tracking and personalization features including ultra-detailed syllabus dashboard, AI study schedule builder, concept confidence meter, and smart revision booster. By the end of this epic, users shall have complete visibility into their learning progress across all UPSC topics, receive personalized adaptive study schedules considering weak areas and time constraints, and get automated revision packages targeting their 5 weakest topics weekly. This epic transforms the platform from content delivery to intelligent personalized learning coach.

### Story 6.1: Syllabus Tracking Dashboard - Master View

**As a** UPSC aspirant,
**I want** a comprehensive dashboard showing my completion status, strength/weakness analysis, and predicted readiness across all UPSC topics,
**so that** I can understand my overall progress and prioritize my study efforts.

#### Acceptance Criteria

1. Dashboard page: `/progress` with hero metric cards (Overall Completion %, Estimated Readiness, Study Streak, Total Study Hours)
2. Completion calculation: (topics completed / total syllabus topics) * 100, topic marked "completed" if video watched + notes read + quiz passed
3. Subject breakdown: bar chart showing completion % per subject (Polity, History, Geography, Economy, etc.)
4. Paper breakdown: pie chart showing completion % per paper (GS1, GS2, GS3, GS4, CSAT, Essay)
5. Strength/weakness heatmap: color-coded grid (subjects vs papers), green (>80% score), yellow (50-79%), red (<50%)
6. Weakest 5 topics: list with topic name, current score, study suggestions ("Watch video", "Take quiz", "Review notes")
7. Predicted Prelims score: ML model estimates score based on quiz performance, topic coverage, time spent
8. Time-on-topic chart: stacked bar showing hours spent per subject over last 30 days
9. Custom milestones: user can set goals ("Complete Polity by March 1"), progress bar shows status
10. Export report: download PDF with all metrics, charts, recommendations

---

### Story 6.2: Confidence Meter - Per-Topic Visualization

**As a** UPSC aspirant,
**I want** a visual confidence indicator (red/yellow/green) for every topic based on my performance,
**so that** I can quickly identify which topics I've mastered and which need more work.

#### Acceptance Criteria

1. Confidence score calculation: weighted average (quiz scores 40%, time spent 30%, spaced repetition performance 30%)
2. Color coding: Red (0-49%), Yellow (50-79%), Green (80-100%)
3. Confidence meter displayed: on syllabus navigator nodes, notes pages, dashboard
4. Meter animation: smooth transition when confidence changes, celebratory animation on reaching green
5. Confidence delta: show change from last week ("↑ +5%", "↓ -2%")
6. Suggested actions: if confidence < 50%, show "Recommended: Watch video, Take quiz, Review flashcards"
7. Confidence report: weekly email summarizing confidence changes, highlighting improvements and declines
8. Filter by confidence: syllabus navigator filter "Show only red topics" for focused study
9. Historical tracking: line graph showing confidence trends over time for each topic
10. Batch confidence update: after taking test, confidence scores update for all relevant topics

---

### Story 6.3: AI Study Schedule Builder - Input & Preferences

**As a** UPSC aspirant,
**I want** to input my exam date, available study hours, and current level to generate a personalized study schedule,
**so that** I can follow a structured plan optimized for my situation.

#### Acceptance Criteria

1. Schedule builder page: `/schedule/builder` with wizard-style form (4 steps)
2. Step 1 - Exam details: target exam date (dropdown: Prelims 2026, Mains 2026, etc.), days remaining auto-calculated
3. Step 2 - Availability: daily study hours (slider 1-12), flexible vs fixed schedule (toggle), days off per week
4. Step 3 - Current level: self-assessment quiz (20 questions across subjects) to gauge baseline
5. Step 4 - Priorities: subject preferences (rank importance 1-7), weak areas (multi-select from quiz results)
6. AI algorithm: optimize schedule balancing coverage (all topics), depth (weak areas get more time), retention (spaced repetition)
7. Schedule generated: daily plan from today to exam date, viewable as calendar or list
8. Each day shows: 3-5 study sessions, topics to cover, resources (videos, notes, quizzes), estimated time per session
9. Flexibility: if user misses a day, schedule auto-adjusts redistributing pending topics
10. Save schedule: stored in `study_schedules` table, linked to user profile

---

### Story 6.4: Study Schedule - Execution & Tracking

**As a** UPSC aspirant,
**I want** to follow my daily schedule with checkboxes, notifications, and progress tracking,
**so that** I stay accountable and motivated to complete planned tasks.

#### Acceptance Criteria

1. Today's schedule view: `/schedule/today` with ordered list of tasks (e.g., "1. Watch Polity video - Article 370 (15 min)")
2. Task cards: checkbox to mark complete, expand for details (resource links, why this topic, UPSC relevance)
3. Completion tracking: check task → mark complete → progress bar updates
4. Push notifications: reminders at scheduled times ("Time to study Polity!"), configurable in settings
5. Google Calendar sync: option to export schedule to Google Calendar (iCal format)
6. Micro-goals: each day has a "Daily Goal" (e.g., "Complete 3 topics, watch 2 videos"), visual indicator when achieved
7. Streaks: consecutive days completing daily goal tracked, displayed with fire icon
8. Missed tasks: if task not completed, moved to next day or marked "Skip" with reason dropdown
9. Weekly summary: every Sunday, email shows week's completion %, tasks done, streak status
10. Schedule adjustment: "I need more time" button extends schedule, reducing daily load

---

### Story 6.5: Study Schedule - Daily Briefing Video (Optional)

**As a** UPSC aspirant,
**I want** an optional daily video briefing (2-3 minutes) summarizing today's schedule and motivational message,
**so that** I start my study session with clarity and motivation.

#### Acceptance Criteria

1. Daily briefing generation: triggered at 6 AM IST after daily CA video publish
2. Script generated: "Good morning! Here's your plan for today: [3 tasks summary]. Focus on [weakest topic]. You're [X%] towards your goal!"
3. Manim visuals: progress ring showing overall completion, today's tasks list animation
4. TTS narration: motivational voice (selectable in settings), upbeat tone
5. Revideo assembly: `DailyBriefingTemplate` with user's name, date, tasks, progress visualization
6. Video length: 90-120 seconds
7. Render time: <45 seconds, lower priority than daily CA
8. Delivery: push notification "Your daily briefing is ready!", accessible from dashboard
9. Opt-in: feature disabled by default, user enables in settings ("Generate daily briefing video")
10. History: past briefings accessible from archive, useful for reviewing progress over time

---

### Story 6.6: Smart Revision Booster - Weakness Detection

**As a** system,
**I want** to automatically identify each user's 5 weakest topics weekly using performance data,
**so that** targeted revision packages can be generated.

#### Acceptance Criteria

1. Weakness detection algorithm: runs every Sunday at midnight, analyzes last 7 days' data
2. Scoring factors: quiz accuracy (weight 0.5), time since last studied (0.3), confidence score (0.2)
3. Topics ranked: all topics user has interacted with sorted by weakness score (0-100, lower = weaker)
4. Top 5 weakest selected: stored in `revision_targets` table (user_id, topic_ids, generated_at)
5. Edge cases: if user studied <5 topics, select all studied topics; if no data, select random 5 from syllabus
6. Deduplication: don't select same topic 2 weeks in row unless it's still weakest
7. Notification: "Your weekly revision package is ready!" sent Monday morning
8. Admin override: admin can manually trigger revision generation for specific user
9. Historical tracking: past revision targets stored for analytics (are users improving targeted topics?)
10. Performance optimization: query uses indexed columns, completes for all users in <5 minutes

---

### Story 6.7: Smart Revision Booster - Package Generation

**As a** UPSC aspirant,
**I want** a curated revision package for my 5 weakest topics with video, flashcards, and quiz,
**so that** I can efficiently strengthen my weak areas.

#### Acceptance Criteria

1. Package contents: for each of 5 topics: 60-90s revision video, 5 flashcards, 10-question quiz
2. Revision video generation: condensed from original topic video, focuses on key definitions and facts
3. Script structure: "Quick revision: [Topic]. Key point 1... Key point 2... Remember: [mnemonic]"
4. Manim visuals: reuse cached scenes from original video, add "Quick Revision" title card
5. Flashcards: auto-generated from notes, front (question/term), back (answer/definition)
6. Quiz: 10 MCQs, difficulty = medium, instant feedback on submission
7. Package saved to `revision_packages` table: user_id, topics, video_urls, flashcards_json, quiz_id
8. Delivery: accessible from dashboard "This Week's Revision" card, email with package link
9. Spaced repetition: flashcards show again in 3 days, 7 days, 14 days (SM-2 algorithm)
10. Generation time: <5 minutes for complete package (parallelized video rendering)

---

### Story 6.8: Smart Revision Booster - Spaced Repetition System

**As a** UPSC aspirant,
**I want** flashcards and quizzes to reappear at optimal intervals based on my performance,
**so that** I retain information long-term without over-studying.

#### Acceptance Criteria

1. Spaced repetition algorithm: SM-2 (SuperMemo 2) or Leitner system
2. Review intervals: if answered correctly: 1 day → 3 days → 7 days → 14 days → 30 days; if wrong: reset to 1 day
3. Flashcard interface: `/revision/flashcards` with card stack UI (flip on click, swipe left = wrong, right = correct)
4. Quiz scheduling: user prompted "Time to review [Topic]" when interval reached
5. Daily review limit: max 20 flashcards/day (configurable in settings), prevents overwhelming user
6. Performance tracking: for each card, store (last_reviewed, ease_factor, review_count, correct_count)
7. Retention analytics: admin dashboard shows average retention rate, identifies problematic topics (low retention)
8. Push reminders: "You have 5 cards due for review today" at user's preferred time
9. Mobile-optimized: flashcards work smoothly on touch devices, swipe gestures intuitive
10. Gamification: streak counter for consecutive review days, badges for milestones (100 cards reviewed, 30-day streak)

---

### Story 6.9: Custom Study Plans - Working Professional Mode

**As a** working professional preparing for UPSC,
**I want** a pre-built "5 Hours Per Day" study plan optimized for limited time,
**so that** I can prepare effectively despite my job commitments.

#### Acceptance Criteria

1. Pre-built template: "UPSC in 5 Hours/Day" accessible from `/schedule/templates`
2. Schedule structure: 2 hours morning (6-8 AM), 3 hours evening (7-10 PM), weekends flexible
3. Daily breakdown: 1.5 hrs new topics, 1 hr revision, 1 hr practice (quizzes/answer writing), 1 hr current affairs, 0.5 hr admin (planning, review)
4. Syllabus coverage: prioritizes high-weightage topics (Polity, Current Affairs, Ethics), optional depth in niche areas
5. Weekend deep-dives: Saturdays for long documentaries (2-3 hours), Sundays for full-length tests
6. Customization: user can drag-drop to reschedule tasks, adjust hours per session
7. Auto-adjust: if user misses weekday session, content moved to weekend, not cumulative (prevents overload)
8. Template variants: also provide "3 Hours/Day" (very aggressive, final revision), "8 Hours/Day" (full-time aspirants)
9. Community sharing: users can share custom templates, rate others' templates
10. Success stories: showcase testimonials from working professionals who cleared UPSC using 5-hour plan

---

### Story 6.10: Goal Setting & Milestone Tracking

**As a** UPSC aspirant,
**I want** to set custom goals (e.g., "Finish Polity by March") and track progress towards them,
**so that** I stay motivated and celebrate achievements.

#### Acceptance Criteria

1. Goal creation: `/progress/goals` page with "New Goal" button
2. Goal types: Completion-based ("Complete all GS1 topics"), Score-based ("Average 80% on Polity quizzes"), Time-based ("Study 30 hours this month")
3. Goal form: name, type, target value, deadline, linked subjects/topics
4. Progress visualization: circular progress indicator showing % complete, color changes as approaching deadline
5. Goal reminders: if falling behind, weekly email "You're 20% behind on your Polity goal"
6. Achievement celebration: when goal completed, confetti animation, "Congratulations!" modal, achievement badge added to profile
7. Goal history: past goals archived, visible in "Achievements" section
8. Shared goals: opt-in to join community goals (e.g., "Complete 500 PYQs in Jan"), leaderboard for participants
9. Smart suggestions: AI suggests goals based on exam date and current progress ("Suggestion: Aim to complete 3 subjects by next month")
10. Gamification: goal streaks (consecutive months meeting goals), XP awarded for achievements

---

