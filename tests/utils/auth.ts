/**
 * Authentication Test Utilities
 */

import { Page, expect } from '@playwright/test';

export async function login(page: Page, email: string, password: string) {
  await page.goto('/login');
  await page.fill('[name="email"]', email);
  await page.fill('[name="password"]', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('/dashboard');
}

export async function logout(page: Page) {
  await page.click('[data-testid="user-menu"]');
  await page.click('[data-testid="logout-button"]');
  await page.waitForURL('/login');
}

export async function signup(page: Page, email: string, password: string, name: string) {
  await page.goto('/signup');
  await page.fill('[name="name"]', name);
  await page.fill('[name="email"]', email);
  await page.fill('[name="password"]', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('/dashboard');
}

export async function expectLoggedIn(page: Page, userName?: string) {
  await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
  if (userName) {
    await expect(page.locator('[data-testid="user-name"]')).toHaveText(userName);
  }
}

export async function expectLoggedOut(page: Page) {
  await expect(page.locator('[data-testid="login-button"]')).toBeVisible();
}
