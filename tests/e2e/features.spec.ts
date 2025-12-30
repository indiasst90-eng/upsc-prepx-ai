import { test, expect } from '@playwright/test';
import { login } from '../utils/auth';

test.describe('Notes Generation Feature', () => {
  test.beforeEach(async ({ page }) => {
    // Login with test user
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('user can navigate to notes page', async ({ page }) => {
    await page.goto('/notes');
    await expect(page).toHaveURL('/notes');
    await expect(page.locator('h1')).toContainText('Notes');
  });

  test('notes page has topic search', async ({ page }) => {
    await page.goto('/notes');
    await expect(page.locator('input[placeholder*="Search"]')).toBeVisible();
  });

  test('user can request comprehensive notes', async ({ page }) => {
    await page.goto('/notes');
    
    // Find and fill topic input
    const topicInput = page.locator('input[name="topic"], input[placeholder*="topic"]').first();
    await topicInput.fill('Fundamental Rights');
    
    // Submit the form
    const generateButton = page.locator('button:has-text("Generate")').first();
    if (await generateButton.isVisible()) {
      await generateButton.click();
      // Wait for loading to complete or notes to appear
      await page.waitForTimeout(2000);
    }
  });
});

test.describe('Practice & PYQ Features', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('user can access PYQ database', async ({ page }) => {
    await page.goto('/pyqs');
    await expect(page).toHaveURL('/pyqs');
    await expect(page.locator('h1')).toContainText('PYQ');
  });

  test('PYQ filters are visible', async ({ page }) => {
    await page.goto('/pyqs');
    // Check for filter dropdowns
    await expect(page.locator('select, [role="combobox"]').first()).toBeVisible();
  });

  test('user can access practice section', async ({ page }) => {
    await page.goto('/practice');
    await expect(page).toHaveURL('/practice');
  });

  test('practice page shows question generation option', async ({ page }) => {
    await page.goto('/practice/generate');
    await expect(page.locator('h1, h2')).toContainText(/Question|Generate|Practice/);
  });
});

test.describe('Knowledge Base Search', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('search functionality is accessible', async ({ page }) => {
    await page.goto('/search');
    await expect(page.locator('input[type="search"], input[placeholder*="Search"]')).toBeVisible();
  });

  test('search returns results for valid query', async ({ page }) => {
    await page.goto('/search');
    const searchInput = page.locator('input[type="search"], input[placeholder*="Search"]').first();
    await searchInput.fill('Constitution');
    await searchInput.press('Enter');
    
    // Wait for results
    await page.waitForTimeout(1500);
    
    // Should show some results or "no results" message
    const resultsOrMessage = page.locator('[data-testid="search-results"], .results, .no-results');
    await expect(resultsOrMessage.first()).toBeVisible({ timeout: 5000 });
  });
});

test.describe('Subscription & Entitlements', () => {
  test('free user sees upgrade prompts for premium features', async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
    await page.goto('/pricing');
    
    // Pricing page should show subscription options
    await expect(page.locator('text=/Pro|Premium|Subscribe/')).toBeVisible();
  });

  test('billing page is accessible', async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
    await page.goto('/billing');
    await expect(page).toHaveURL('/billing');
  });
});

test.describe('Daily Current Affairs', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('daily CA page loads', async ({ page }) => {
    await page.goto('/daily-ca');
    await expect(page).toHaveURL('/daily-ca');
    await expect(page.locator('h1, h2')).toContainText(/Current|Affairs|Daily/);
  });

  test('news page shows latest updates', async ({ page }) => {
    await page.goto('/news');
    await expect(page).toHaveURL('/news');
  });
});

test.describe('Syllabus Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('syllabus page shows UPSC papers', async ({ page }) => {
    await page.goto('/syllabus');
    await expect(page).toHaveURL('/syllabus');
    
    // Should show GS papers
    await expect(page.locator('text=/GS1|GS2|GS3|GS4|General Studies/')).toBeVisible();
  });

  test('user can navigate syllabus tree', async ({ page }) => {
    await page.goto('/syllabus');
    
    // Click on a paper/topic if visible
    const gsLink = page.locator('text=/GS1|General Studies 1/').first();
    if (await gsLink.isVisible()) {
      await gsLink.click();
      await page.waitForTimeout(500);
    }
  });
});

test.describe('Progress Tracking', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, 'test-free@example.com', 'test-password-123');
  });

  test('progress page shows user stats', async ({ page }) => {
    await page.goto('/progress');
    await expect(page).toHaveURL('/progress');
    await expect(page.locator('h1, h2')).toContainText(/Progress|Stats|Dashboard/);
  });
});
