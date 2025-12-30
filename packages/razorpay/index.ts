/**
 * Razorpay Payment Gateway Integration
 *
 * Handles subscription payments, order creation, and webhook verification.
 */

export interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
  status: string;
  receipt: string;
  created_at: number;
}

export interface RazorpayPayment {
  id: string;
  order_id: string;
  amount: number;
  currency: string;
  status: string;
  method: string;
  email: string;
  contact: string;
  created_at: number;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  duration: string; // monthly, quarterly, half_yearly, annual
  priceInr: number;
  razorpayPlanId?: string;
  features: string[];
  popular?: boolean;
}

export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
  {
    id: 'monthly',
    name: 'Monthly',
    duration: 'monthly',
    priceInr: 599,
    razorpayPlanId: process.env.RAZORPAY_MONTHLY_PLAN_ID,
    features: [
      'Unlimited AI Doubt → Video',
      'Comprehensive Notes Generator',
      'RAG Search Engine',
      'Daily CA Videos',
      'Priority Support',
    ],
  },
  {
    id: 'quarterly',
    name: 'Quarterly',
    duration: 'quarterly',
    priceInr: 1499,
    razorpayPlanId: process.env.RAZORPAY_QUARTERLY_PLAN_ID,
    features: [
      'All Monthly features',
      'Essay Trainer',
      'Answer Writing Practice',
      'PYQ Video Explanations',
      'Save 17% vs monthly',
    ],
    popular: true,
  },
  {
    id: 'half_yearly',
    name: 'Half-Yearly',
    duration: 'half_yearly',
    priceInr: 2699,
    razorpayPlanId: process.env.RAZORPAY_HALFYEARLY_PLAN_ID,
    features: [
      'All Quarterly features',
      'Memory Palace Videos',
      'Ethics Simulator',
      '3-Hour Documentary Lectures',
      'Save 25% vs quarterly',
    ],
  },
  {
    id: 'annual',
    name: 'Annual',
    duration: 'annual',
    priceInr: 4999,
    razorpayPlanId: process.env.RAZORPAY_ANNUAL_PLAN_ID,
    features: [
      'All Half-Yearly features',
      'Interview Prep Studio',
      '1-on-1 Mentor Sessions',
      'Exclusive Study Materials',
      'Save 30% vs half-yearly',
    ],
  },
];

class RazorpayClient {
  private keyId: string;
  private keySecret: string;
  private baseUrl = 'https://api.razorpay.com/v1';

  constructor() {
    this.keyId = process.env.RAZORPAY_KEY_ID || '';
    this.keySecret = process.env.RAZORPAY_KEY_SECRET || '';
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${Buffer.from(`${this.keyId}:${this.keySecret}`).toString('base64')}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.description || `Razorpay API error: ${response.status}`);
    }

    return response.json();
  }

  /**
   * Create a new order for subscription
   */
  async createOrder(
    amount: number,
    currency: string = 'INR',
    receipt: string,
    notes?: Record<string, string>
  ): Promise<RazorpayOrder> {
    return this.request<RazorpayOrder>('/orders', {
      method: 'POST',
      body: JSON.stringify({
        amount: amount * 100, // Convert to paise
        currency,
        receipt,
        notes: {
          ...notes,
          source: 'upsc-prepx-ai',
        },
      }),
    });
  }

  /**
   * Get order details
   */
  async getOrder(orderId: string): Promise<RazorpayOrder> {
    return this.request<RazorpayOrder>(`/orders/${orderId}`);
  }

  /**
   * Verify payment signature
   */
  verifySignature(
    orderId: string,
    paymentId: string,
    signature: string
  ): boolean {
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', this.keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    return expectedSignature === signature;
  }

  /**
   * Create a subscription
   */
  async createSubscription(
    planId: string,
    customerId: string,
    totalCount: number,
    notes?: Record<string, string>
  ) {
    return this.request('/subscriptions', {
      method: 'POST',
      body: JSON.stringify({
        plan_id: planId,
        customer_id: customerId,
        total_count: totalCount,
        notes: notes,
      }),
    });
  }

  /**
   * Create or get customer
   */
  async createCustomer(
    name: string,
    email: string,
    contact: string,
    notes?: Record<string, string>
  ) {
    return this.request('/customers', {
      method: 'POST',
      body: JSON.stringify({
        name,
        email,
        contact,
        notes: notes,
      }),
    });
  }

  /**
   * Get customer by email
   */
  async getCustomer(customerId: string) {
    return this.request(`/customers/${customerId}`);
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(subscriptionId: string, cancelAtCycleEnd: boolean = true) {
    return this.request(`/subscriptions/${subscriptionId}/cancel`, {
      method: 'POST',
      body: JSON.stringify({
        cancel_at_cycle_end: cancelAtCycleEnd,
      }),
    });
  }

  /**
   * Get subscription details
   */
  async getSubscription(subscriptionId: string) {
    return this.request(`/subscriptions/${subscriptionId}`);
  }

  /**
   * Create invoice for one-time payment
   */
  async createInvoice(
    customerId: string,
    items: Array<{ name: string; amount: number; quantity: number }>,
    notes?: Record<string, string>
  ) {
    return this.request('/invoices', {
      method: 'POST',
      body: JSON.stringify({
        customer_id: customerId,
        line_items: items.map((item) => ({
          name: item.name,
          amount: item.amount * 100,
          quantity: item.quantity,
        })),
        notes: notes,
      }),
    });
  }

  /**
   * Refund payment
   */
  async createRefund(
    paymentId: string,
    amount?: number,
    notes?: Record<string, string>
  ) {
    return this.request(`/refunds`, {
      method: 'POST',
      body: JSON.stringify({
        payment_id: paymentId,
        amount: amount ? amount * 100 : undefined,
        notes: notes,
      }),
    });
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(body: string, signature: string): boolean {
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', this.keySecret)
      .update(body)
      .digest('hex');

    return expectedSignature === signature;
  }
}

// Export singleton
export const razorpay = new RazorpayClient();

// Helper functions
export function getPlanById(planId: string): SubscriptionPlan | undefined {
  return SUBSCRIPTION_PLANS.find((p) => p.id === planId);
}

export function getDefaultPlan(): SubscriptionPlan {
  return SUBSCRIPTION_PLANS.find((p) => p.id === 'quarterly')!;
}

export function calculateSavings(monthlyPrice: number, planPrice: number): number {
  const monthlyEquivalent = planPrice / getDurationInMonths(planPrice);
  return Math.round(((monthlyPrice - monthlyEquivalent) / monthlyPrice) * 100);
}

function getDurationInMonths(price: number): number {
  const plan = SUBSCRIPTION_PLANS.find((p) => p.priceInr === price);
  switch (plan?.duration) {
    case 'monthly':
      return 1;
    case 'quarterly':
      return 3;
    case 'half_yearly':
      return 6;
    case 'annual':
      return 12;
    default:
      return 1;
  }
}

export function formatPrice(priceInr: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(priceInr);
}
