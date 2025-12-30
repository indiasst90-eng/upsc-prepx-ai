# Epic 5: Monetization & Subscription System

**Epic Goal:**
Implement comprehensive monetization infrastructure including trial logic (7 days full access), RevenueCat integration for subscription management (Monthly ₹599, Quarterly ₹1499, Half-Yearly ₹2699, Annual ₹4999), entitlement checks on all premium features, Razorpay payment gateway, coupon system, and admin revenue dashboard. By the end of this epic, the platform shall have fully functional payment flows, trial-to-paid conversion tracking, and granular entitlement enforcement ensuring sustainable revenue generation while maintaining excellent user experience during trial and post-purchase.

## Story 5.1: RevenueCat Integration - Setup & Configuration

**As a** backend developer,
**I want** RevenueCat SDK integrated for subscription management across web and future mobile apps,
**so that** we have unified subscription state and cross-platform entitlement management.

### Acceptance Criteria

1. RevenueCat project created: app configured for Web, iOS (future), Android (future)
2. Product IDs created in RevenueCat: `pro_monthly`, `pro_quarterly`, `pro_half_yearly`, `pro_annual`
3. Entitlements configured: `pro_access` (grants access to all premium features)
4. RevenueCat Web SDK installed: `@revenuecat/purchases-js` in frontend
5. Backend integration: RevenueCat webhook endpoint `POST /api/webhooks/revenuecat` handles events (purchase, renewal, cancellation, expiry)
6. Supabase RLS policies: `subscriptions` table enforces user can only read own subscription
7. Sync job: on webhook event, update `subscriptions` table (status, plan, expires_at, revenuecat_id)
8. Environment variables: `REVENUECAT_API_KEY`, `REVENUECAT_WEBHOOK_SECRET` configured in Supabase Secrets
9. Test mode: sandbox environment for testing purchases without real payments
10. Documentation: internal docs for adding new products and entitlements

---

## Story 5.2: Payment Gateway Integration - Razorpay

**As a** UPSC aspirant,
**I want** to subscribe to Pro plans using UPI, cards, or net banking through a secure payment gateway,
**so that** I can unlock premium features with confidence.

### Acceptance Criteria

1. Razorpay account created: API keys obtained (test and live modes)
2. Razorpay Checkout integrated: `razorpay-web-sdk` in frontend for payment modal
3. Payment flow: user selects plan → clicks "Subscribe" → Razorpay modal opens → payment completed → subscription activated
4. Subscription plans created in Razorpay: Monthly, Quarterly, Half-Yearly, Annual with auto-debit (optional for user)
5. Payment confirmation webhook: `POST /api/webhooks/razorpay` verifies signature, creates subscription record
6. Transaction logging: all payments logged to `payment_transactions` table (txn_id, user_id, amount, status, gateway_response)
7. Failed payment handling: if payment fails, show error message, log to database, email user with retry link
8. PCI compliance: no card data stored in our database, all handled by Razorpay
9. Invoice generation: on successful payment, generate invoice PDF (company details, transaction ID, amount, GST if applicable)
10. Test payments: use Razorpay test cards for QA validation before production

---

## Story 5.3: Trial Logic - Automatic Activation & Expiry

**As a** UPSC aspirant,
**I want** a 7-day free trial with full Pro access automatically activated on signup,
**so that** I can evaluate all premium features before committing to a subscription.

### Acceptance Criteria

1. On user signup: database trigger creates subscription record (status = 'trial', trial_started_at = NOW(), trial_expires_at = NOW() + INTERVAL '7 days')
2. Entitlement function: `checkEntitlement(user_id, feature_slug)` returns true if NOW() <= trial_expires_at
3. Trial status badge: displayed in header "Trial: 5 days left", changes to "Trial ending today" on last day
4. Email notifications: Day 1 (welcome + trial info), Day 3 (tips + feature highlights), Day 5 (2 days left + upgrade CTA), Day 7 (trial ends today + upgrade prompt)
5. Post-trial experience: on expiry, user not blocked from app, but premium features show upgrade modal
6. One trial per user: check by email and phone, prevent trial abuse (multiple signups)
7. Trial extension: admin can manually extend trial via admin panel (e.g., +3 days for user request)
8. Analytics: trial-to-paid conversion tracked (metric: % of trial users who subscribe within 7 days + 7 days post-trial)
9. Dashboard countdown: visual progress bar showing trial days remaining
10. Grace period: if user subscribes on Day 7 (last day), subscription starts immediately, no gap

---

## Story 5.4: Entitlement Checks - Feature-Level Enforcement

**As a** product manager,
**I want** granular entitlement checks on every premium feature to enforce access control,
**so that** only authorized users (Trial, Pro) can use paid features while maintaining excellent UX.

### Acceptance Criteria

1. Feature manifest table: `feature_manifests` with columns (feature_slug, name, tier, description)
2. Tiers defined: Free, Trial, Pro Monthly, Pro Annual (some features exclusive to Annual)
3. Entitlement check function: `checkEntitlement(user_id, feature_slug)` queries `subscriptions` + `feature_manifests`
4. Returns object: `{ allowed: boolean, reason: string, show_paywall: boolean, upgrade_cta: string }`
5. Client-side: every premium feature button/page checks entitlement before rendering
6. Server-side: Edge Functions enforce entitlement before processing (e.g., doubt video creation checks entitlement first)
7. Paywall modal: shown when allowed = false, displays reason, plan comparison, "Upgrade Now" button
8. Soft paywalls: Free users see premium features grayed out with "Pro" badge, click shows upgrade modal
9. Hard blocks: API returns 403 Forbidden if entitlement check fails server-side
10. Cache entitlements: client caches entitlement state for 5 minutes, refreshes on page load or subscription change

---

## Story 5.5: Subscription Management - User Dashboard

**As a** UPSC aspirant,
**I want** to view my current subscription, billing history, and manage renewals from my profile,
**so that** I can control my subscription and access invoices.

### Acceptance Criteria

1. Subscription page: `/settings/subscription` with current plan card (plan name, price, next billing date, status)
2. Plan details: features included (list with checkmarks), usage stats (doubts used, videos generated)
3. Billing history: table with columns (date, amount, invoice, status), download invoice button (PDF)
4. Manage subscription: "Change Plan" button (upgrade/downgrade options), "Cancel Subscription" button
5. Change plan flow: user selects new plan → confirmation modal → prorated calculation shown → confirm → updated immediately
6. Cancel flow: confirmation modal with retention offer ("Get 20% off next month if you stay") → if proceed, subscription cancels at period end (not immediately)
7. Renewal toggle: user can enable/disable auto-renewal (for Razorpay subscriptions with auto-debit)
8. Payment method: display saved payment method (last 4 digits), "Update Payment Method" button redirects to Razorpay
9. Subscription status: Active (green), Cancelled (yellow), Expired (red), Trial (blue)
10. Support link: "Having issues? Contact support" opens chat or email form

---

## Story 5.6: Pricing Page - Plan Comparison & CTA

**As a** UPSC aspirant,
**I want** a clear pricing page comparing all plans with features and benefits,
**so that** I can make an informed decision on which plan to purchase.

### Acceptance Criteria

1. Pricing page: `/pricing` with 4-column plan comparison table
2. Plans displayed: Free, Pro Monthly (₹599), Pro Quarterly (₹1499, save 16%), Pro Annual (₹4999, save 30%)
3. Features listed: row per feature (RAG Search, Doubt Videos, Topic Shorts, Daily CA, Documentary Lectures, etc.), checkmarks/crosses per plan
4. Highlight recommended plan: Pro Monthly with "Most Popular" badge, visual emphasis (shadow, color)
5. CTA buttons: "Start Free Trial" (Free), "Subscribe Now" (paid plans), click opens payment modal
6. Billing toggle: switch between Monthly/Annual view, prices update dynamically
7. Money-back guarantee: "7-day money-back guarantee" badge on all paid plans
8. Testimonials: 3-4 user testimonials with photos, names, exam ranks below pricing table
9. FAQs section: collapsible accordion with 8-10 common questions (What's included? Can I cancel? Refund policy?)
10. Comparison calculator: "How much will you save?" slider shows savings for Annual vs Monthly over 12 months

---

## Story 5.7: Coupon & Discount System

**As a** marketing manager,
**I want** a coupon system for promotional discounts and affiliate offers,
**so that** we can run campaigns and partner with influencers for user acquisition.

### Acceptance Criteria

1. Coupons table: `coupons` with columns (code, discount_type, discount_value, max_uses, used_count, expires_at, applicable_plans, active)
2. Discount types: percentage (10%, 20%, 50%), flat (₹100 off), free trial extension (+7 days)
3. Coupon creation: admin panel `/admin/coupons` with form to create coupons, set restrictions
4. Coupon validation: API endpoint `POST /api/coupons/validate` checks code, returns discount amount, expiry, restrictions
5. Apply coupon flow: payment modal has "Have a coupon?" field → user enters code → validate → price updates with discount shown
6. Restrictions: per-user limit (1 use per user), plan restrictions (only for Annual), first-time user only
7. Coupon analytics: admin dashboard shows coupon usage (code, uses, revenue generated, conversion rate)
8. Affiliate coupons: special codes for influencers, track referrals, calculate commission (10% of revenue)
9. Auto-apply: if user lands via affiliate link with `?coupon=XYZ`, auto-fill coupon code at checkout
10. Expiry handling: expired coupons show error "This coupon has expired", invalid codes show "Invalid coupon code"

---

## Story 5.8: Revenue Dashboard - Admin Analytics

**As a** business owner,
**I want** a comprehensive revenue dashboard showing MRR, ARR, churn, LTV, and cohort analysis,
**so that** I can track business health and make data-driven decisions.

### Acceptance Criteria

1. Revenue dashboard: `/admin/revenue` with key metric cards (MRR, ARR, Active Subscriptions, Churn Rate, Trial-to-Paid %)
2. MRR calculation: sum of all active monthly recurring revenue (normalize quarterly/annual to monthly)
3. ARR calculation: MRR * 12
4. Churn rate: % of subscribers who cancelled in last 30 days
5. Lifetime Value (LTV): average revenue per user over their subscription lifetime
6. Growth chart: line graph showing MRR trend over last 12 months
7. Plan distribution: pie chart showing % of users on each plan (Free, Trial, Monthly, Annual)
8. Cohort analysis: table showing retention by signup month (e.g., Jan 2025 cohort: Month 0: 100%, Month 1: 85%, Month 2: 70%)
9. Revenue by source: breakdown by acquisition channel (organic, paid ads, affiliates)
10. Export data: download CSV with all transaction data, filtered by date range

---

## Story 5.9: Refund Processing & Money-Back Guarantee

**As a** UPSC aspirant,
**I want** a hassle-free refund process within 7 days if I'm not satisfied,
**so that** I can try the platform risk-free.

### Acceptance Criteria

1. Refund policy: 7-day money-back guarantee from subscription start date (no questions asked)
2. Refund request: user clicks "Request Refund" on subscription page → confirmation modal → reason dropdown (optional)
3. API endpoint: `POST /api/refunds/request` creates refund record (user_id, subscription_id, amount, reason, status = 'pending')
4. Admin review: refunds appear in `/admin/refunds` queue, admin can approve/reject
5. Approval: if approved, Razorpay refund API called, amount credited to user's original payment method
6. Refund timeline: processed within 48 hours (business hours), user notified via email
7. Post-refund: subscription immediately cancelled, user downgraded to Free tier
8. Partial refunds: pro-rated refunds for mid-cycle cancellations (e.g., cancel on Day 15 of Monthly plan → refund 50%)
9. Refund limits: max 1 refund per user per year (prevent abuse)
10. Analytics: refund rate tracked (target <5%), reasons analyzed for product improvements

---

## Story 5.10: Institutional Licensing - Bulk Subscriptions

**As an** coaching institute owner,
**I want** to purchase bulk subscriptions for my students at discounted rates,
**so that** I can provide UPSC AI Mentor access as part of my coaching program.

### Acceptance Criteria

1. Institutional plan: custom pricing for 50+ users (e.g., ₹300/user/month for 100 users = ₹30,000/month)
2. Admin panel: `/admin/institutions` to create institution accounts, assign licenses
3. License allocation: institution admin can invite students via email, assign licenses
4. Student activation: invited student receives email with activation link, creates account, license auto-applied
5. License management: institution admin dashboard shows licenses (total, assigned, available), usage analytics per student
6. Billing: single invoice for institution, monthly or annual payment, auto-renewal optional
7. Custom branding (optional): white-label option for large institutions (logo, colors, domain)
8. Reporting: institution admin sees aggregate analytics (students active, videos generated, topics covered, test scores)
9. License transfer: if student leaves, institution can revoke license and reassign to new student
10. Contract management: legal agreements, invoicing, support escalation handled via dedicated account manager

---
