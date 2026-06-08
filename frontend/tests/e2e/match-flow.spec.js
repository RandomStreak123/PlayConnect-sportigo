import { test, expect } from '@playwright/test';

test.describe('PlayConnect E2E Match Flow', () => {

  test('should log in and create a new sports match successfully', async ({ page }) => {
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
    
    // Click Sign In button
    await page.locator('button.submit-btn:has-text("Sign In")').click();

    // Verify login is successful
    await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
    
    // 3. Open Create Match Modal
    await page.locator('button.category-create-btn:has-text("Create Match")').click();

    // Verify modal is open by checking header title
    await expect(page.locator('.modal-title')).toHaveText('Create New Match');

    // 4. Fill in Match Details
    await page.locator('button.sport-chip:has-text("Football")').click();

    const testTitle = `E2E Playwright Football Match ${Date.now()}`;
    await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill(testTitle);

    // Set Date & Time (using standard ISO format)
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in the future
    const year = futureDate.getFullYear();
    const month = String(futureDate.getMonth() + 1).padStart(2, '0');
    const day = String(futureDate.getDate()).padStart(2, '0');
    const hours = String(futureDate.getHours()).padStart(2, '0');
    const minutes = String(futureDate.getMinutes()).padStart(2, '0');
    const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
    await page.locator('input[type="datetime-local"]').fill(formattedDate);

    // Enter Location
    await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('HotFut Turf, Gachibowli');

    // Enter Slots
    await page.locator('input[placeholder="e.g. 10"]').fill('8');

    // Wait for the POST response to /api/matches
    const responsePromise = page.waitForResponse(response => 
      response.url().includes('/api/matches') && response.request().method() === 'POST'
    );

    // Submit Match Creation
    await page.locator('button.submit-btn:has-text("Create Match")').click();

    const response = await responsePromise;
    console.log('API RESPONSE STATUS:', response.status());
    console.log('API RESPONSE BODY:', await response.text());

    // 5. Verify Successful Creation
    await expect(page.locator('.modal-title')).not.toBeVisible({ timeout: 10000 });
    
    const matchCard = page.locator(`.match-card:has-text("${testTitle}")`).first();
    await expect(matchCard).toBeVisible({ timeout: 15000 });

    // 6. Open Match Details Modal
    await matchCard.click();

    // Verify Match Details Modal is open
    await expect(page.locator('.modal-sheet .match-title')).toHaveText(testTitle, { timeout: 10000 });

    // Verify that "This spot is waiting for you!" is NOT visible to the creator/host
    await expect(page.locator('.waiting-spot')).not.toBeVisible();
    await expect(page.locator('text="This spot is waiting for you!"')).not.toBeVisible();

    // Verify that "Match Chat" section/text is NOT visible to any user
    await expect(page.locator('.chat-section')).not.toBeVisible();
    await expect(page.locator('text="Match Chat"')).not.toBeVisible();
  });

});
