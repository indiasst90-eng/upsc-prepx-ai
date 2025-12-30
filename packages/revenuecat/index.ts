/**
 * RevenueCat Integration for Subscription Management
 */

import { getEnv } from '../config';

export type Entitlement = 'free' | 'pro' | 'premium';
export type SubscriptionStatus = 'active' | 'expired' | 'trial' | 'none';

export interface SubscriptionInfo {
  status: SubscriptionStatus;
  entitlement: Entitlement;
  expiresAt: string | null;
  startedAt: string | null;
  trialEndsAt: string | null;
  isInTrial: boolean;
}

export interface Offering {
  id: string;
  productId: string;
  duration: 'monthly' | 'quarterly' | 'half_yearly' | 'annual';
  price: number;
  currency: string;
}

// RevenueCat API client
class RevenueCatClient {
  private baseUrl = 'https://api.revenuecat.com/v1';
  private apiKey: string;

  constructor() {
    this.apiKey = getEnv().REVENUECAT_SECRET_API_KEY || '';
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`RevenueCat API error: ${response.status} - ${error}`);
    }

    return response.json();
  }

  // Get subscriber info
  async getSubscriber(userId: string): Promise<SubscriptionInfo> {
    const data = await this.request<any>(`/subscribers/${userId}`);

    const entitlements = data.subscriber?.entitlements || {};
    const proEntitlement = entitlements['pro'];

    if (!proEntitlement) {
      return {
        status: 'none',
        entitlement: 'free',
        expiresAt: null,
        startedAt: null,
        trialEndsAt: null,
        isInTrial: false,
      };
    }

    const isInTrial = proEntitlement.period_type === 'trial';
    const isActive = proEntitlement.entitlement_id === 'pro' &&
      ['active', 'trial'].includes(proEntitlement.status);

    return {
      status: isActive ? (isInTrial ? 'trial' : 'active') : 'expired',
      entitlement: 'pro',
      expiresAt: proEntitlement.expires_date,
      startedAt: proEntitlement.start_date,
      trialEndsAt: proEntitlement.trial_end_date,
      isInTrial,
    };
  }

  // Check entitlement
  async checkEntitlement(userId: string, entitlementId: string): Promise<boolean> {
    const data = await this.request<any>(`/subscribers/${userId}/entitlements/${entitlementId}`);
    return data.entitlement?.is_active === true;
  }

  // Get offerings
  async getOfferings(offeringId: string = 'default'): Promise<Offering[]> {
    const data = await this.request<any>(`/offerings/${offeringId}`);

    return (data.offering?.available_packages || []).map((pkg: any) => ({
      id: pkg.identifier,
      productId: pkg.product.id,
      duration: this.mapDuration(pkg.product.duration_unit),
      price: pkg.product.price,
      currency: pkg.product.currency,
    }));
  }

  private mapDuration(unit: string): 'monthly' | 'quarterly' | 'half_yearly' | 'annual' {
    switch (unit) {
      case 'month': return 'monthly';
      case '3month': return 'quarterly';
      case '6month': return 'half_yearly';
      case 'year': return 'annual';
      default: return 'monthly';
    }
  }
}

// Export singleton
export const revenuecat = new RevenueCatClient();

// Helper functions for frontend
export function getDefaultPlan(): Offering {
  return {
    id: 'quarterly',
    productId: 'prepx_quarterly',
    duration: 'quarterly',
    price: 1499,
    currency: 'INR',
  };
}

export function getPlanOptions(): Offering[] {
  return [
    {
      id: 'monthly',
      productId: 'prepx_monthly',
      duration: 'monthly',
      price: 599,
      currency: 'INR',
    },
    {
      id: 'quarterly',
      productId: 'prepx_quarterly',
      duration: 'quarterly',
      price: 1499,
      currency: 'INR',
    },
    {
      id: 'half_yearly',
      productId: 'prepx_half_yearly',
      duration: 'half_yearly',
      price: 2699,
      currency: 'INR',
    },
    {
      id: 'annual',
      productId: 'prepx_annual',
      duration: 'annual',
      price: 4999,
      currency: 'INR',
    },
  ];
}

// Check if user has access to a feature
export function canAccessFeature(
  subscription: SubscriptionInfo | null,
  featureRequired: Entitlement
): boolean {
  if (!subscription) return featureRequired === 'free';

  if (featureRequired === 'free') return true;
  if (featureRequired === 'pro') return subscription.entitlement === 'pro';
  if (featureRequired === 'premium') return subscription.entitlement === 'premium';

  return false;
}

// Feature mapping
export const FEATURES = {
  basic_search: 'free' as Entitlement,
  notes_generation: 'pro' as Entitlement,
  video_generation: 'pro' as Entitlement,
  daily_news: 'free' as Entitlement,
  doubt_video: 'pro' as Entitlement,
  practice_questions: 'free' as Entitlement,
  detailed_solutions: 'pro' as Entitlement,
  unlimited_search: 'pro' as Entitlement,
  download_pdf: 'pro' as Entitlement,
  offline_access: 'premium' as Entitlement,
};
