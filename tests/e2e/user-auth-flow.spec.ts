import { test, expect } from '@playwright/test';
import { login, logout, signup, expectLoggedIn } from '../utils/auth';
import { resetTestDatabase, seedTestData } from '../utils/database';

test.describe('User Authentication Flow', () => {
  test.beforeEach(async () => {
    await resetTestDatabase();
    await seedTestData();
  });

  test('user can signup, login, and logout', async ({ page }) => {
    // Step 1: Signup
    await signup(page, 'newuser@example.com', 'password123', 'New User');
    await expect(page).toHaveURL('/dashboard');
    await expectLoggedIn(page, 'New User');

    // Step 2: Logout
    await logout(page);
    await expect(page).toHaveURL('/login');

    // Step 3: Login
    await login(page, 'newuser@example.com', 'password123');
    await expect(page).toHaveURL('/dashboard');
    await expectLoggedIn(page, 'New User');
  });

  test('user cannot login with invalid credentials', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[name="email"]', 'wrong@example.com');
    await page.fill('[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');
    await expect(page.locator('[data-testid="error-message"]')).toContainText('Invalid credentials');
  });
});

test.describe('Dashboard', () => {
  test.beforeEach(async () => {
    await resetTestDatabase();
    await seedTestData();
  });

  test('authenticated user sees dashboard stats', async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });

  test('quick action cards are visible', async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
    await expect(page.locator('text=Ask a Doubt')).toBeVisible();
    await expect(page.locator('text=Comprehensive Notes')).toBeVisible();
    await expect(page.locator('text=Daily News Video')).toBeVisible();
  });
});
