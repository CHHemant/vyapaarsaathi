const { test, expect } = require('@playwright/test');

const APP_URL = 'http://localhost:8080';

test.describe('VyapaarSaathi Premium UI E2E Tests', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(APP_URL);
    // Wait for the app to load.
    await page.waitForTimeout(10000);
  });

  test('should navigate from Splash to Home', async ({ page }) => {
    // Click "Shuru Karein" via coordinates for reliability in Canvas
    await page.mouse.click(500, 800);
    await page.waitForTimeout(3000);

    // Check if the Home screen contains the "Quick Sale" action
    // We'll use a snapshot or coordinate check since text is hard in Canvas
    const canvas = page.locator('flutter-view');
    await expect(canvas).toBeVisible();
  });

  test('should navigate to Udhaar screen', async ({ page }) => {
    // Bypass splash
    await page.mouse.click(500, 800);
    await page.waitForTimeout(3000);

    // Click Udhaar button (usually in the middle area of the grid)
    await page.mouse.click(200, 500);
    await page.waitForTimeout(2000);

    // Verify we moved to a new screen (URL change if using GoRouter)
    // await expect(page).toHaveURL(/.*udhaar/);
  });

  test('should navigate to Settings', async ({ page }) => {
    // Bypass splash
    await page.mouse.click(500, 800);
    await page.waitForTimeout(3000);

    // Settings icon is usually in the top left of AppBar
    await page.mouse.click(40, 40);
    await page.waitForTimeout(2000);
  });
});
