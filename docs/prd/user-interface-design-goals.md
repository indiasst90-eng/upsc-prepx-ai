# User Interface Design Goals

## Overall UX Vision

**"Neon Glass Dark Mode" - Mobile-First, Distraction-Free Learning Interface**

UPSC AI Mentor shall provide a premium, modern interface that feels like a personal AI tutor in your pocket. The design philosophy centers on **"learning-first, not entertainment-first"** - every UI element must serve educational outcomes, not engagement metrics. The interface uses a dark theme with frosted glass effects, neon blue/purple accents, and smooth Framer Motion animations to create a professional yet inviting study environment. Students should feel they're using cutting-edge technology while never being distracted from actual learning.

## Key Interaction Paradigms

1. **Progressive Disclosure:** Complex features (like 34 total features) are organized into clear categories (Study, Practice, Review, Insights) with simple entry points
2. **Lazy Loading & Async Patterns:** Videos and content load on-demand; users see immediate text responses while videos render in background
3. **Confidence Transparency:** Every AI-generated answer displays confidence score and source citations prominently
4. **Mobile-First Video Player:** Custom HLS player optimized for 4G/5G with quality adaptation, speed controls, and offline download (Pro only)
5. **No Dark Patterns:** No infinite scroll, no manipulative notifications post-10 PM, no competitive leaderboards creating anxiety
6. **Accessibility by Default:** Keyboard navigation, screen reader support, high-contrast mode toggle built into every component

## Core Screens and Views

**Public Screens:**
1. **Landing Page** - Marketing hero with feature showcase, pricing comparison table, testimonials from UPSC toppers
2. **Pricing Page** - 4 subscription plans with feature comparison matrix, trial CTA prominent
3. **Login/Signup** - Google OAuth primary, Email/Phone secondary, clean minimalist form

**Authenticated Dashboard:**
4. **Home Dashboard** - Personalized greeting, today's current affairs card, quick access tiles (Ask Doubt, Continue Learning, Take Test), progress ring showing overall syllabus completion
5. **Syllabus Navigator** - 2D/3D tree visualization (React Three Fiber), sidebar filters (GS1-4, CSAT, Essay), node click opens topic detail modal
6. **Daily Current Affairs Page** - Video player top, transcript below, 5 MCQs collapsed accordion, PDF download button, archive calendar
7. **Ask Doubt Page** - Text input with mic icon, image upload zone, style selector (concise/detailed/example-rich), response shows text preview immediately then video when ready
8. **Notes Library** - Grid view of topic cards with thumbnails, filter by subject/paper, search bar, each note has 3-level depth toggle
9. **Search Results Page** - Google-like results list, each result shows confidence score, book citation, snippet, "Explain more" button generates video
10. **Practice Hub** - Tabs for Answer Writing, Essay Practice, Test Series, PYQ Bank; each shows progress stats
11. **Progress Dashboard** - Hero metric cards (syllabus completion %, confidence score, study streak), charts (time-on-topic bar graph, strength/weakness heat map), predicted readiness gauge
12. **Settings/Profile** - Account details, subscription management, voice preferences, notification settings, accessibility toggles

**Admin Panel:**
13. **Admin Dashboard** - Revenue metrics, user stats, error rate graphs, job queue status
14. **User Management** - Searchable user list, subscription status, entitlement grants
15. **Knowledge Base Upload** - Drag-drop PDF zone, processing status table, reprocess button
16. **Video Render Monitor** - Job queue table with status, logs, retry buttons

## Accessibility

**Target: WCAG 2.1 AA Compliance**

- All interactive elements keyboard accessible (Tab navigation, Enter/Space activation)
- Screen reader announcements for dynamic content (video render complete, answer evaluated)
- Color contrast ratio ≥4.5:1 for normal text, ≥3:1 for large text
- Focus indicators visible on all focusable elements
- Alternative text for all images, diagrams, video thumbnails
- Captions/transcripts for all videos (VTT format)
- High-contrast mode toggle in settings (switches to white backgrounds, black text)

## Branding

**Visual Identity:**
- **Color Palette:**
  - Primary: Neon Blue (#3B82F6 to #1D4ED8 gradient)
  - Secondary: Purple Accent (#8B5CF6)
  - Background: Dark Slate (#0F172A)
  - Glass Effects: Frosted glass with backdrop-blur-md
- **Typography:**
  - Headings: Satoshi (modern, geometric)
  - Body: Inter (readable, clean)
- **Animations:** Framer Motion for page transitions, button interactions, skeleton loaders
- **Design System:** shadcn/ui components with custom dark theme overrides

## Target Platforms

**Primary: Web Responsive (Mobile-First)**
- Progressive Web App (PWA) with offline capabilities
- Install prompt for "Add to Home Screen" on mobile
- Responsive breakpoints: Mobile (<640px), Tablet (640-1024px), Desktop (>1024px)

**Future (Post-MVP):**
- Native iOS app (Swift UI)
- Native Android app (Kotlin/Jetpack Compose)
- Desktop apps (Electron) for offline study

---
