import { test, expect } from '@playwright/test';

test.describe('PlayConnect E2E Past Date Validation & Language Switcher', () => {

  test('should validate past date and support language switching', async ({ page }) => {
    // Listen to console logs and page errors
    page.on('console', msg => console.log('PAGE LOG:', msg.text()));
    page.on('pageerror', err => console.log('PAGE ERROR:', err.message));

    // 1. Visit the home page
    await page.goto('/');

    // Verify brand title is shown
    await expect(page.locator('.brand-title')).toHaveText('PlayConnect');

    // 2. Perform Login
    await page.locator('input[placeholder="Enter your username"]').fill('Ajith');
    await page.locator('input[placeholder="Enter your password"]').fill('24681000');
    await page.locator('button.submit-btn:has-text("Sign In")').click();

    // Verify login is successful
    await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
    
    // 3. Open Create Match Modal
    await page.locator('button.category-create-btn:has-text("Create Match")').click();

    // Verify modal is open by checking header title
    await expect(page.locator('.modal-title')).toHaveText('Create New Match');

    // 4. Fill in Match Details with a PAST date
    await page.locator('button.sport-chip:has-text("Football")').click();

    await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill('E2E Past Date Match');

    // Set Date & Time to 1 day in the past
    const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const year = pastDate.getFullYear();
    const month = String(pastDate.getMonth() + 1).padStart(2, '0');
    const day = String(pastDate.getDate()).padStart(2, '0');
    const hours = String(pastDate.getHours()).padStart(2, '0');
    const minutes = String(pastDate.getMinutes()).padStart(2, '0');
    const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
    await page.locator('input[type="datetime-local"]').fill(formattedDate);

    // Enter Location
    await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('Sportigo Arena, Madhapur');

    // Enter Slots
    await page.locator('input[placeholder="e.g. 10"]').fill('6');

    // Submit Match Creation (Should trigger validation error)
    await page.locator('button.submit-btn:has-text("Create Match")').click();

    // Verify validation error banner is visible and has correct error text
    const errorBanner = page.locator('.error-banner');
    await expect(errorBanner).toBeVisible({ timeout: 5000 });
    await expect(errorBanner).toContainText('Please select a date and time in the future');

    // Close Create Match Modal
    await page.locator('.close-btn').click();
    await expect(page.locator('.modal-sheet')).not.toBeVisible();

    // 5. Test Language Switcher on Profile Screen
    // Click on Profile tab
    await page.locator('.link-label:has-text("Profile"), .nav-label:has-text("Profile")').filter({ visible: true }).click();

    // Check that we are on the profile page
    await expect(page.locator('.title').first()).toContainText('Player Profile');

    // Locate the language selector select dropdown
    const select = page.locator('select.language-select-dropdown');
    await expect(select).toBeVisible();

    // Switch to Hindi
    await select.selectOption('hi');

    // Verify translations are applied reactively
    // Profile title should translate to "खिलाड़ी प्रोफ़ाइल"
    await expect(page.locator('.title').first()).toContainText('खिलाड़ी प्रोफ़ाइल');
    // Navigation label should translate to "होम" instead of "Home"
    await expect(page.locator('.link-label:has-text("होम"), .nav-label:has-text("होम")').filter({ visible: true })).toBeVisible();

    // Switch back to English
    await select.selectOption('en');

    // Verify translations revert to English
    await expect(page.locator('.title').first()).toContainText('Player Profile');
    await expect(page.locator('.link-label:has-text("Home"), .nav-label:has-text("Home")').filter({ visible: true })).toBeVisible();
  });

});
