# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: match-flow.spec.js >> PlayConnect E2E Match Flow >> should log in and create a new sports match successfully
- Location: tests/e2e/match-flow.spec.js:5:3

# Error details

```
Error: expect(locator).toHaveText(expected) failed

Locator:  locator('.brand-title')
Expected: "PlayConnect"
Received: "PLAYCONNECT"
Timeout:  5000ms

Call log:
  - Expect "toHaveText" with timeout 5000ms
  - waiting for locator('.brand-title')
    14 × locator resolved to <h1 data-v-b2e8fdd0="" class="brand-title">PLAYCONNECT</h1>
       - unexpected value "PLAYCONNECT"

```

```yaml
- img "PlayConnect Logo"
- text: PlayConnect
- heading "Your Next Match Is Just a Click Away" [level=1]
- paragraph: Join the ultimate sports matchmaking community. Discover local friendly games, book slots, coordinate with players, and get on the court today.
- text: 5,000+ Active Players 120+ Matches Daily 15+ Venues Mapped
- button "Sign In"
- button "Sign Up"
- heading "Welcome Back" [level=2]
- paragraph: Sign in to join your next match
- textbox
- textbox
- text: Username
- img
- textbox "Enter your username"
- text: Password
- img
- textbox "Enter your password"
- button:
  - img
- link "Forgot Password?":
  - /url: "#"
- button "Sign In"
- text: or continue with
- iframe
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
  14  |       await page.goto('/');
  15  | 
  16  |       // Verify brand title is shown
> 17  |       await expect(page.locator('.brand-title')).toHaveText('PlayConnect');
      |                                                  ^ Error: expect(locator).toHaveText(expected) failed
  18  | 
  19  |       // 2. Perform Login
  20  |       await page.locator('input[placeholder="Enter your username"]').click();
  21  |       await page.locator('input[placeholder="Enter your username"]').fill('Ajith');
  22  |       await page.locator('input[placeholder="Enter your password"]').click();
  23  |       await page.locator('input[placeholder="Enter your password"]').fill('24681000');
  24  |       
  25  |       // Click Sign In button
  26  |       await page.locator('button.submit-btn:has-text("Sign In")').click();
  27  | 
  28  |       // Verify login is successful
  29  |       await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
  30  |       
  31  |       // 3. Open Create Match Modal
  32  |       await page.locator('button.category-create-btn:has-text("Create Match")').click();
  33  | 
  34  |       // Verify modal is open by checking header title
  35  |       await expect(page.locator('.modal-title')).toHaveText('Create New Match');
  36  | 
  37  |       // 4. Fill in Match Details
  38  |       await page.locator('button.sport-chip:has-text("Football")').click();
  39  | 
  40  |       const testTitle = `E2E Playwright Football Match ${Date.now()}`;
  41  |       await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill(testTitle);
  42  | 
  43  |       // Set Date & Time (using standard ISO format)
  44  |       const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in the future
  45  |       const year = futureDate.getFullYear();
  46  |       const month = String(futureDate.getMonth() + 1).padStart(2, '0');
  47  |       const day = String(futureDate.getDate()).padStart(2, '0');
  48  |       const hours = String(futureDate.getHours()).padStart(2, '0');
  49  |       const minutes = String(futureDate.getMinutes()).padStart(2, '0');
  50  |       const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
  51  |       await page.locator('input[type="datetime-local"]').fill(formattedDate);
  52  | 
  53  |       // Enter Location
  54  |       await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('HotFut Turf, Gachibowli');
  55  | 
  56  |       // Enter Slots
  57  |       await page.locator('input[placeholder="e.g. 10"]').fill('8');
  58  | 
  59  |       // Wait for the POST response to /api/matches
  60  |       const responsePromise = page.waitForResponse(response => 
  61  |         response.url().includes('/api/matches') && response.request().method() === 'POST'
  62  |       );
  63  | 
  64  |       // Submit Match Creation
  65  |       await page.locator('button.submit-btn:has-text("Create Match")').click();
  66  | 
  67  |       const response = await responsePromise;
  68  |       console.log('API RESPONSE STATUS:', response.status());
  69  |       const responseText = await response.text();
  70  |       console.log('API RESPONSE BODY:', responseText);
  71  | 
  72  |       if (response.status() === 201) {
  73  |         const responseJson = JSON.parse(responseText);
  74  |         matchId = responseJson.id;
  75  |       }
  76  | 
  77  |       // 5. Verify Successful Creation
  78  |       await page.waitForTimeout(500); // Allow reactivity to catch up
  79  |       await page.evaluate(() => {
  80  |         const matches = window.store?.state?.matches || [];
  81  |         console.log('E2E STORE MATCHES COUNT:', matches.length);
  82  |         console.log('E2E STORE MATCH TITLES:', matches.map(m => `${m.title} (${m.dateTime || m.date_time})`).join(', '));
  83  |       });
  84  | 
  85  |       await expect(page.locator('.modal-title')).not.toBeVisible({ timeout: 10000 });
  86  |       
  87  |       const matchCard = page.locator(`.match-card:has-text("${testTitle}")`).first();
  88  |       await expect(matchCard).toBeVisible({ timeout: 15000 });
  89  | 
  90  |       // 6. Open Match Details Modal
  91  |       await matchCard.click();
  92  | 
  93  |       // Verify Match Details Modal is open
  94  |       await expect(page.locator('.modal-sheet .match-title')).toHaveText(testTitle, { timeout: 10000 });
  95  | 
  96  |       // Verify that "This spot is waiting for you!" is NOT visible to the creator/host
  97  |       await expect(page.locator('.waiting-spot')).not.toBeVisible();
  98  |       await expect(page.locator('text="This spot is waiting for you!"')).not.toBeVisible();
  99  | 
  100 |       // Verify that "Match Chat" section/text is NOT visible to any user
  101 |       await expect(page.locator('.chat-section')).not.toBeVisible();
  102 |       await expect(page.locator('text="Match Chat"')).not.toBeVisible();
  103 |     } finally {
  104 |       // Clean up/Delete the created match
  105 |       if (matchId) {
  106 |         const token = await page.evaluate(() => sessionStorage.getItem('sportigo_token') || localStorage.getItem('sportigo_token'));
  107 |         if (token) {
  108 |           const deleteResponse = await page.request.delete(`/api/matches/${matchId}`, {
  109 |             headers: {
  110 |               'Authorization': `Bearer ${token}`,
  111 |               'Accept': 'application/json',
  112 |             }
  113 |           });
  114 |           console.log(`E2E CLEANUP: Deleted match ${matchId} with status ${deleteResponse.status()}`);
  115 |         }
  116 |       }
  117 |     }
```