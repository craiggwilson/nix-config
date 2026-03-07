# E2E Testing

## Playwright

```typescript
import { test, expect } from '@playwright/test';

test('user can login', async ({ page }) => {
  await page.goto('/login');
  
  await page.fill('[name="email"]', 'user@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('h1')).toContainText('Welcome');
});

test('user can create order', async ({ page }) => {
  // Login first
  await page.goto('/login');
  await page.fill('[name="email"]', 'user@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  // Create order
  await page.click('text=New Order');
  await page.fill('[name="product"]', 'Widget');
  await page.fill('[name="quantity"]', '5');
  await page.click('button:has-text("Submit")');
  
  await expect(page.locator('.success')).toBeVisible();
});
```

## Page Object Model

```typescript
// pages/login.page.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.fill('[name="email"]', email);
    await this.page.fill('[name="password"]', password);
    await this.page.click('button[type="submit"]');
  }
}

// tests/login.spec.ts
test('login flow', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password');
  
  await expect(page).toHaveURL('/dashboard');
});
```

## Cypress

```javascript
describe('Login', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('should login successfully', () => {
    cy.get('[name="email"]').type('user@example.com');
    cy.get('[name="password"]').type('password');
    cy.get('button[type="submit"]').click();
    
    cy.url().should('include', '/dashboard');
    cy.contains('Welcome').should('be.visible');
  });

  it('should show error for invalid credentials', () => {
    cy.get('[name="email"]').type('wrong@example.com');
    cy.get('[name="password"]').type('wrong');
    cy.get('button[type="submit"]').click();
    
    cy.contains('Invalid credentials').should('be.visible');
  });
});
```

## Best Practices

- Use data-testid attributes
- Implement Page Object Model
- Run in CI with headless mode
- Use fixtures for test data
- Clean up test data after runs
- Avoid flaky selectors
- Wait for elements properly
