# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: past-date-validation.spec.js >> PlayConnect E2E Past Date Validation & Language Switcher >> should validate past date and support language switching
- Location: tests/e2e/past-date-validation.spec.js:5:3

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
  3   | test.describe('PlayConnect E2E Past Date Validation & Language Switcher', () => {
  4   | 
  5   |   test('should validate past date and support language switching', async ({ page }) => {
  6   |     // Listen to console logs and page errors
  7   |     page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  8   |     page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  9   | 
  10  |     // 1. Visit the home page
> 11  |     await page.goto('/');
      |                ^ Error: page.goto: net::ERR_EMPTY_RESPONSE at http://localhost:5173/
  12  | 
  13  |     // Verify brand title is shown
  14  |     await expect(page.locator('.brand-title')).toHaveText('PlayConnect');
  15  | 
  16  |     // 2. Perform Login
  17  |     await page.locator('input[placeholder="Enter your username"]').fill('Ajith');
  18  |     await page.locator('input[placeholder="Enter your password"]').fill('24681000');
  19  |     await page.locator('button.submit-btn:has-text("Sign In")').click();
  20  | 
  21  |     // Verify login is successful
  22  |     await expect(page.locator('.user-name')).toHaveText('Ajith', { timeout: 10000 });
  23  |     
  24  |     // 3. Open Create Match Modal
  25  |     await page.locator('button.category-create-btn:has-text("Create Match")').click();
  26  | 
  27  |     // Verify modal is open by checking header title
  28  |     await expect(page.locator('.modal-title')).toHaveText('Create New Match');
  29  | 
  30  |     // 4. Fill in Match Details with a PAST date
  31  |     await page.locator('button.sport-chip:has-text("Football")').click();
  32  | 
  33  |     await page.locator('input[placeholder="e.g. Friday Evening 5v5"]').fill('E2E Past Date Match');
  34  | 
  35  |     // Set Date & Time to 1 day in the past
  36  |     const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
  37  |     const year = pastDate.getFullYear();
  38  |     const month = String(pastDate.getMonth() + 1).padStart(2, '0');
  39  |     const day = String(pastDate.getDate()).padStart(2, '0');
  40  |     const hours = String(pastDate.getHours()).padStart(2, '0');
  41  |     const minutes = String(pastDate.getMinutes()).padStart(2, '0');
  42  |     const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
  43  |     await page.locator('input[type="datetime-local"]').fill(formattedDate);
  44  | 
  45  |     // Enter Location
  46  |     await page.locator('input[placeholder="e.g. Central Park Court 2"]').fill('Sportigo Arena, Madhapur');
  47  | 
  48  |     // Enter Slots
  49  |     await page.locator('input[placeholder="e.g. 10"]').fill('6');
  50  | 
  51  |     // Submit Match Creation (Should trigger validation error)
  52  |     await page.locator('button.submit-btn:has-text("Create Match")').click();
  53  | 
  54  |     // Verify validation error banner is visible and has correct error text
  55  |     const errorBanner = page.locator('.error-banner');
  56  |     await expect(errorBanner).toBeVisible({ timeout: 5000 });
  57  |     await expect(errorBanner).toContainText('Please select a date and time in the future');
  58  | 
  59  |     // Close Create Match Modal
  60  |     await page.locator('.close-btn').click();
  61  |     await expect(page.locator('.modal-sheet')).not.toBeVisible();
  62  | 
  63  |     // 5. Test Language Switcher on Profile Screen
  64  |     // Click on Profile tab
  65  |     await page.locator('.link-label:has-text("Profile"), .nav-label:has-text("Profile")').filter({ visible: true }).click();
  66  | 
  67  |     // Check that we are on the profile page
  68  |     await expect(page.locator('.title').first()).toContainText('Player Profile');
  69  | 
  70  |     // Open Settings Modal by clicking hamburger button
  71  |     await page.locator('.settings-nav-btn').click();
  72  |     await page.waitForSelector('.modal-title:has-text("Settings")');
  73  | 
  74  |     // Locate the language selector select dropdown
  75  |     const select = page.locator('select.language-select-dropdown');
  76  |     await expect(select).toBeVisible();
  77  | 
  78  |     // Switch to Hindi
  79  |     await select.selectOption('hi');
  80  | 
  81  |     // Verify Settings Modal title translates to "सेटिंग्स"
  82  |     await expect(page.locator('.modal-title').first()).toContainText('सेटिंग्स');
  83  | 
  84  |     // Close Settings Modal
  85  |     await page.locator('.close-btn').click();
  86  |     await page.waitForTimeout(300);
  87  | 
  88  |     // Verify translations are applied reactively on the main screen
  89  |     // Profile title should translate to "खिलाड़ी प्रोफ़ाइल"
  90  |     await expect(page.locator('.title').first()).toContainText('खिलाड़ी प्रोफ़ाइल');
  91  |     // Navigation label should translate to "होम" instead of "Home"
  92  |     await expect(page.locator('.link-label:has-text("होम"), .nav-label:has-text("होम")').filter({ visible: true })).toBeVisible();
  93  | 
  94  |     // Reopen Settings Modal to switch back to English
  95  |     await page.locator('.settings-nav-btn').click();
  96  |     await page.waitForSelector('.modal-title:has-text("सेटिंग्स")');
  97  | 
  98  |     // Switch back to English
  99  |     await select.selectOption('en');
  100 | 
  101 |     // Verify Settings Modal title translates back to "Settings"
  102 |     await expect(page.locator('.modal-title').first()).toContainText('Settings');
  103 | 
  104 |     // Close Settings Modal
  105 |     await page.locator('.close-btn').click();
  106 |     await page.waitForTimeout(300);
  107 | 
  108 |     // Verify translations revert to English
  109 |     await expect(page.locator('.title').first()).toContainText('Player Profile');
  110 |     await expect(page.locator('.link-label:has-text("Home"), .nav-label:has-text("Home")').filter({ visible: true })).toBeVisible();
  111 |   });
```