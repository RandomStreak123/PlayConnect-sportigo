# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: past-date-validation.spec.js >> PlayConnect E2E Past Date Validation & Language Switcher >> should validate past date and support language switching
- Location: tests/e2e/past-date-validation.spec.js:5:3

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
  3   | test.describe('PlayConnect E2E Past Date Validation & Language Switcher', () => {
  4   | 
  5   |   test('should validate past date and support language switching', async ({ page }) => {
  6   |     // Listen to console logs and page errors
  7   |     page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  8   |     page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  9   | 
  10  |     // 1. Visit the home page
  11  |     await page.goto('/');
  12  | 
  13  |     // Verify brand title is shown
> 14  |     await expect(page.locator('.brand-title')).toHaveText('PlayConnect');
      |                                                ^ Error: expect(locator).toHaveText(expected) failed
  15  | 
  16  |     // 2. Perform Login
  17  |     await page.locator('input[placeholder="Enter your username"]').click();
  18  |     await page.locator('input[placeholder="Enter your username"]').fill('Ajith');
  19  |     await page.locator('input[placeholder="Enter your password"]').click();
  20  |     await page.locator('input[placeholder="Enter your password"]').fill('24681000');
  21  |     await page.locator('button.submit-btn:has-text("Sign In")').click();
  22  | 
  23  |     // Verify login is successful
  24  |     await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
  25  |     
  26  |     // 3. Open Create Match Modal
  27  |     await page.locator('button.category-create-btn:has-text("Create Match")').click();
  28  | 
  29  |     // Verify modal is open by checking header title
  30  |     await expect(page.locator('.modal-title')).toHaveText('Create New Match');
  31  | 
  32  |     // 4. Fill in Match Details with a PAST date
  33  |     await page.locator('button.sport-chip:has-text("Football")').click();
  34  | 
  35  |     await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill('E2E Past Date Match');
  36  | 
  37  |     // Set Date & Time to 1 day in the past
  38  |     const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
  39  |     const year = pastDate.getFullYear();
  40  |     const month = String(pastDate.getMonth() + 1).padStart(2, '0');
  41  |     const day = String(pastDate.getDate()).padStart(2, '0');
  42  |     const hours = String(pastDate.getHours()).padStart(2, '0');
  43  |     const minutes = String(pastDate.getMinutes()).padStart(2, '0');
  44  |     const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
  45  |     await page.locator('input[type="datetime-local"]').fill(formattedDate);
  46  | 
  47  |     // Enter Location
  48  |     await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('Sportigo Arena, Madhapur');
  49  | 
  50  |     // Enter Slots
  51  |     await page.locator('input[placeholder="e.g. 10"]').fill('6');
  52  | 
  53  |     // Submit Match Creation (Should trigger validation error)
  54  |     await page.locator('button.submit-btn:has-text("Create Match")').click();
  55  | 
  56  |     // Verify validation error banner is visible and has correct error text
  57  |     const errorBanner = page.locator('.error-banner');
  58  |     await expect(errorBanner).toBeVisible({ timeout: 5000 });
  59  |     await expect(errorBanner).toContainText('Please select a date and time in the future');
  60  | 
  61  |     // Close Create Match Modal
  62  |     await page.locator('div.modal-sheet button.close-btn').click();
  63  |     await expect(page.locator('.modal-sheet')).not.toBeVisible();
  64  | 
  65  |     // 5. Test Language Switcher on Profile Screen
  66  |     // Click on Profile tab
  67  |     await page.locator('.link-label:has-text("Profile"), .nav-label:has-text("Profile")').filter({ visible: true }).click();
  68  | 
  69  |     // Check that we are on the profile page
  70  |     await expect(page.locator('.title').first()).toContainText('Player Profile');
  71  | 
  72  |     // Open Settings Modal by clicking hamburger button
  73  |     await page.locator('.settings-nav-btn').click();
  74  |     await page.waitForSelector('.modal-title:has-text("Settings")');
  75  |     await page.waitForTimeout(500); // Wait for slide-in animation to complete
  76  | 
  77  |     // Locate the language selector select dropdown
  78  |     const select = page.locator('select.language-select-dropdown');
  79  |     await expect(select).toBeVisible();
  80  | 
  81  |     // Switch to Hindi
  82  |     await select.selectOption('hi');
  83  | 
  84  |     // Verify Settings Modal title translates to "सेटिंग्स"
  85  |     await expect(page.locator('.modal-title').first()).toContainText('सेटिंग्स');
  86  | 
  87  |     // Close Settings Modal
  88  |     await page.locator('div.settings-fullscreen-panel button.settings-close-btn').click({ force: true });
  89  |     await page.waitForTimeout(500); // Wait for slide-out animation to complete
  90  | 
  91  |     // Verify translations are applied reactively on the main screen
  92  |     // Profile title should translate to "खिलाड़ी प्रोफ़ाइल"
  93  |     await expect(page.locator('.title').first()).toContainText('खिलाड़ी प्रोफ़ाइल');
  94  |     // Navigation label should translate to "होम" instead of "Home"
  95  |     await expect(page.locator('.link-label:has-text("होम"), .nav-label:has-text("होम")').filter({ visible: true })).toBeVisible();
  96  | 
  97  |     // Reopen Settings Modal to switch back to English
  98  |     await page.locator('.settings-nav-btn').click();
  99  |     await page.waitForSelector('.modal-title:has-text("सेटिंग्स")');
  100 |     await page.waitForTimeout(500); // Wait for slide-in animation to complete
  101 | 
  102 |     // Switch back to English
  103 |     await select.selectOption('en');
  104 | 
  105 |     // Verify Settings Modal title translates back to "Settings"
  106 |     await expect(page.locator('.modal-title').first()).toContainText('Settings');
  107 | 
  108 |     // Close Settings Modal
  109 |     await page.locator('div.settings-fullscreen-panel button.settings-close-btn').click({ force: true });
  110 |     await page.waitForTimeout(500); // Wait for slide-out animation to complete
  111 | 
  112 |     // Verify translations revert to English
  113 |     await expect(page.locator('.title').first()).toContainText('Player Profile');
  114 |     await expect(page.locator('.link-label:has-text("Home"), .nav-label:has-text("Home")').filter({ visible: true })).toBeVisible();
```