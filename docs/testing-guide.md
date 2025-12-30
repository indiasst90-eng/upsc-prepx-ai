# Testing Guide

## Overview

This project uses a multi-level testing strategy:

- **Unit Tests**: Vitest for utilities, filters, and components
- **Integration Tests**: Playwright for API integration
- **E2E Tests**: Playwright for user flows

## Running Tests

```bash
# Run all tests
pnpm test

# Run only unit tests
pnpm test --filter @upsc-prepx-ai/config

# Run E2E tests
pnpm playwright test

# Run E2E tests with UI
pnpm playwright test --ui

# Debug specific test
pnpm playwright test user-auth-flow.spec.ts --debug
```

## Test Structure

```
tests/
├── e2e/                    # Playwright E2E tests
│   ├── user-auth-flow.spec.ts
│   └── ...
├── mocks/                  # MSW mock handlers
│   └── handlers.ts
├── utils/                  # Test utilities
│   ├── auth.ts
│   └── database.ts
└── playwright.config.ts    # Playwright configuration
```

## Writing E2E Tests

```typescript
import { test, expect } from '@playwright/test';
import { login } from '../utils/auth';

test.describe('Feature Name', () => {
  test.beforeEach(async () => {
    // Reset database and seed data
  });

  test('user can perform action', async ({ page }) => {
    await login(page, 'test@example.com', 'password');
    // Perform action
    // Verify result
  });
});
```

## Debugging

### View Traces

```bash
pnpm playwright show-report
```

### Screenshots on Failure

Screenshots and traces are automatically saved to `playwright-report/` on test failure.

## CI Integration

Tests run automatically in GitHub Actions:
1. Lint → Type Check → Unit Tests
2. Playwright Install
3. E2E Tests

See `.github/workflows/ci.yml` for configuration.
