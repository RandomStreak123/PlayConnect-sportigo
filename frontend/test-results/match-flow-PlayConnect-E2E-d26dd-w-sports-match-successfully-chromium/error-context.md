# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: match-flow.spec.js >> PlayConnect E2E Match Flow >> should log in and create a new sports match successfully
- Location: tests/e2e/match-flow.spec.js:5:3

# Error details

```
Error: page.goto: net::ERR_EMPTY_RESPONSE at http://localhost:5173/
Call log:
  - navigating to "http://localhost:5173/", waiting until "load"

```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | 
  3   | test.describe('PlayConnect E2E Match Flow', () => {
  4   | 
  5   |   test('should log in and create a new sports match successfully', async ({ page }) => {
  6   |     // Listen to console logs and page errors
  7   |     page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  8   |     page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  9   | 
  10  |     let matchId = null;
  11  | 
  12  |     try {
  13  |       // 1. Visit the home page
> 14  |       await page.goto('/');
      |                  ^ Error: page.goto: net::ERR_EMPTY_RESPONSE at http://localhost:5173/
  15  | 
  16  |       // Verify brand title is shown
  17  |       await expect(page.locator('.brand-title')).toHaveText('PlayConnect');
  18  | 
  19  |       // 2. Perform Login
  20  |       await page.locator('input[placeholder="Enter your username"]').fill('Ajith');
  21  |       await page.locator('input[placeholder="Enter your password"]').fill('24681000');
  22  |       
  23  |       // Click Sign In button
  24  |       await page.locator('button.submit-btn:has-text("Sign In")').click();
  25  | 
  26  |       // Verify login is successful
  27  |       await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
  28  |       
  29  |       // 3. Open Create Match Modal
  30  |       await page.locator('button.category-create-btn:has-text("Create Match")').click();
  31  | 
  32  |       // Verify modal is open by checking header title
  33  |       await expect(page.locator('.modal-title')).toHaveText('Create New Match');
  34  | 
  35  |       // 4. Fill in Match Details
  36  |       await page.locator('button.sport-chip:has-text("Football")').click();
  37  | 
  38  |       const testTitle = `E2E Playwright Football Match ${Date.now()}`;
  39  |       await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill(testTitle);
  40  | 
  41  |       // Set Date & Time (using standard ISO format)
  42  |       const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in the future
  43  |       const year = futureDate.getFullYear();
  44  |       const month = String(futureDate.getMonth() + 1).padStart(2, '0');
  45  |       const day = String(futureDate.getDate()).padStart(2, '0');
  46  |       const hours = String(futureDate.getHours()).padStart(2, '0');
  47  |       const minutes = String(futureDate.getMinutes()).padStart(2, '0');
  48  |       const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
  49  |       await page.locator('input[type="datetime-local"]').fill(formattedDate);
  50  | 
  51  |       // Enter Location
  52  |       await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('HotFut Turf, Gachibowli');
  53  | 
  54  |       // Enter Slots
  55  |       await page.locator('input[placeholder="e.g. 10"]').fill('8');
  56  | 
  57  |       // Wait for the POST response to /api/matches
  58  |       const responsePromise = page.waitForResponse(response => 
  59  |         response.url().includes('/api/matches') && response.request().method() === 'POST'
  60  |       );
  61  | 
  62  |       // Submit Match Creation
  63  |       await page.locator('button.submit-btn:has-text("Create Match")').click();
  64  | 
  65  |       const response = await responsePromise;
  66  |       console.log('API RESPONSE STATUS:', response.status());
  67  |       const responseText = await response.text();
  68  |       console.log('API RESPONSE BODY:', responseText);
  69  | 
  70  |       if (response.status() === 201) {
  71  |         const responseJson = JSON.parse(responseText);
  72  |         matchId = responseJson.id;
  73  |       }
  74  | 
  75  |       // 5. Verify Successful Creation
  76  |       await expect(page.locator('.modal-title')).not.toBeVisible({ timeout: 10000 });
  77  |       
  78  |       const matchCard = page.locator(`.match-card:has-text("${testTitle}")`).first();
  79  |       await expect(matchCard).toBeVisible({ timeout: 15000 });
  80  | 
  81  |       // 6. Open Match Details Modal
  82  |       await matchCard.click();
  83  | 
  84  |       // Verify Match Details Modal is open
  85  |       await expect(page.locator('.modal-sheet .match-title')).toHaveText(testTitle, { timeout: 10000 });
  86  | 
  87  |       // Verify that "This spot is waiting for you!" is NOT visible to the creator/host
  88  |       await expect(page.locator('.waiting-spot')).not.toBeVisible();
  89  |       await expect(page.locator('text="This spot is waiting for you!"')).not.toBeVisible();
  90  | 
  91  |       // Verify that "Match Chat" section/text is NOT visible to any user
  92  |       await expect(page.locator('.chat-section')).not.toBeVisible();
  93  |       await expect(page.locator('text="Match Chat"')).not.toBeVisible();
  94  |     } finally {
  95  |       // Clean up/Delete the created match
  96  |       if (matchId) {
  97  |         const token = await page.evaluate(() => localStorage.getItem('sportigo_token'));
  98  |         if (token) {
  99  |           const deleteResponse = await page.request.delete(`/api/matches/${matchId}`, {
  100 |             headers: {
  101 |               'Authorization': `Bearer ${token}`,
  102 |               'Accept': 'application/json',
  103 |             }
  104 |           });
  105 |           console.log(`E2E CLEANUP: Deleted match ${matchId} with status ${deleteResponse.status()}`);
  106 |         }
  107 |       }
  108 |     }
  109 |   });
  110 | 
  111 | });
  112 | 
```