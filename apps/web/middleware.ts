import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

// Public routes that don't require authentication
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/signup',
  '/forgot-password',
  '/reset-password',
  '/auth/callback',
  '/api/webhooks',
  '/api/health',
  '/pricing',
];

// Routes that require subscription/trial
const PREMIUM_ROUTES = [
  '/notes',
  '/practice',
  '/videos',
  '/essay',
  '/ethics',
  '/interview',
  '/memory',
  '/mindmap',
  '/flashcards',
  '/documentary',
  '/lectures',
  '/predictor',
  '/schedule',
];

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value,
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
    }
  )

  const pathname = request.nextUrl.pathname;

  // Allow public routes
  const isPublicRoute = PUBLIC_ROUTES.some(route => pathname.startsWith(route));
  if (isPublicRoute) {
    return response;
  }

  // Allow static assets and API routes (except protected ones)
  if (pathname.startsWith('/_next') || 
      pathname.startsWith('/favicon') ||
      pathname.includes('.')) {
    return response;
  }

  // Get session
  const { data: { session } } = await supabase.auth.getSession()

  // If no session, redirect to login
  if (!session) {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/login'
    redirectUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(redirectUrl)
  }

  // Admin-only routes check
  if (pathname.startsWith('/admin')) {
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('role')
      .eq('user_id', session.user.id)
      .single()

    if (profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/', request.url))
    }
  }

  // Premium routes - check subscription/trial status
  const isPremiumRoute = PREMIUM_ROUTES.some(route => pathname.startsWith(route));
  if (isPremiumRoute) {
    // Check user's subscription status
    const { data: subscription } = await supabase
      .from('subscriptions')
      .select('status, trial_end, plan_id')
      .eq('user_id', session.user.id)
      .single()

    // If no subscription record, check if trial should be created
    if (!subscription) {
      // Create trial subscription for new users
      const trialEnd = new Date();
      trialEnd.setDate(trialEnd.getDate() + 1); // 1 day trial
      
      await supabase.from('subscriptions').insert({
        user_id: session.user.id,
        status: 'trialing',
        trial_end: trialEnd.toISOString(),
        plan_id: 'trial',
        created_at: new Date().toISOString(),
      });
    } else {
      // Check if trial has expired
      if (subscription.status === 'trialing' && subscription.trial_end) {
        const trialEndDate = new Date(subscription.trial_end);
        if (trialEndDate < new Date()) {
          // Trial expired - redirect to pricing
          return NextResponse.redirect(new URL('/pricing?expired=true', request.url))
        }
      }
      
      // Check if subscription is active
      if (subscription.status !== 'active' && subscription.status !== 'trialing') {
        return NextResponse.redirect(new URL('/pricing', request.url))
      }
    }
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (public folder)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
