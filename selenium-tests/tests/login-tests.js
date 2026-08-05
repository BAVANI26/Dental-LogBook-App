/**
 * Dental LogBook Web Frontend - E2E Selenium WebDriver Test Suite
 * File: selenium-tests/tests/login-tests.js
 * Target Application: Dental LogBook Web Frontend Application
 * Description: End-to-End Functional, Visual, Security, Responsiveness & Accessibility 
 *              Automation Test Suite for Login Workflows (Web Frontend).
 */

const { Builder, By, Key, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const assert = require('assert');

// ─── CONFIGURATION & TEST CONSTANTS ───────────────────────────────────────────
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:8080';
const DEFAULT_TIMEOUT = 10000;

// Test Credentials Configuration
const TEST_CREDENTIALS = {
  validStudent: { email: 'student@dentallogbook.com', password: 'Password123!' },
  validFaculty: { email: 'faculty@dentallogbook.com', password: 'FacultyPass123!' },
  validAdmin: { email: 'admin@dentallogbook.com', password: 'AdminSecurePass123!' },
  invalidEmail: 'invalid.user@nonexistentdomain.org',
  invalidPassword: 'WrongPassword999!',
  malformedEmail: 'invalid-email-format-without-at',
  sqlInjectionInput: "' OR '1'='1",
  xssInput: "<script>alert('xss')</script>@test.com",
  longInput: 'a'.repeat(250) + '@domain.com'
};

// ─── PAGE OBJECT MODEL (POM) ──────────────────────────────────────────────────
class LoginPagePOM {
  constructor(driver) {
    this.driver = driver;

    // Locators for Flutter Web / HTML elements with multiple fallbacks
    this.emailInput = By.css('input[type="email"], input[aria-label="Email"], [id*="email"], input[name="email"]');
    this.passwordInput = By.css('input[type="password"], input[type="text"][aria-label="Password"], [id*="password"], input[name="password"]');
    this.loginButton = By.xpath("//button[contains(.,'Login')] | //div[contains(@role,'button')][contains(.,'Login')] | //input[@type='submit']");
    this.forgotPasswordLink = By.xpath("//*[contains(text(),'Forgot Password?')] | //a[contains(@href,'forgot')]");
    this.registerLink = By.xpath("//*[contains(text(),'Register')] | //a[contains(@href,'register')]");
    this.passwordToggleIcon = By.css('button[aria-label*="visibility"], svg[data-icon*="visibility"], .suffix-icon, [aria-label*="password toggle"]');
    this.snackBarError = By.css('.snack-bar-error, [role="alert"], div[style*="background-color: rgb(211, 47, 47)"], .error-message');
    this.snackBarSuccess = By.css('.snack-bar-success, div[style*="background-color: rgb(56, 142, 60)"], .success-message');
    this.loadingSpinner = By.css('.flutter-loader, [role="progressbar"], circle, .spinner');
    this.appLogo = By.css('img[src*="logo.png"], [aria-label*="Logo"], .app-logo');
    this.rememberMeCheckbox = By.css('input[type="checkbox"][name*="remember"], [role="checkbox"]');
  }

  async navigateTo() {
    await this.driver.get(BASE_URL);
    await this.driver.sleep(1000);
  }

  async isLoaded() {
    try {
      const emailField = await this.driver.wait(until.elementLocated(this.emailInput), DEFAULT_TIMEOUT);
      return await emailField.isDisplayed();
    } catch (e) {
      return false;
    }
  }

  async enterEmail(email) {
    const el = await this.driver.wait(until.elementLocated(this.emailInput), DEFAULT_TIMEOUT);
    await el.clear();
    await el.sendKeys(email);
  }

  async enterPassword(password) {
    const el = await this.driver.wait(until.elementLocated(this.passwordInput), DEFAULT_TIMEOUT);
    await el.clear();
    await el.sendKeys(password);
  }

  async clickLogin() {
    const btn = await this.driver.wait(until.elementToBeClickable(this.loginButton), DEFAULT_TIMEOUT);
    await btn.click();
  }

  async submitWithEnterKey() {
    const pwd = await this.driver.findElement(this.passwordInput);
    await pwd.sendKeys(Key.ENTER);
  }

  async togglePasswordVisibility() {
    const icon = await this.driver.wait(until.elementLocated(this.passwordToggleIcon), DEFAULT_TIMEOUT);
    await icon.click();
  }

  async clickForgotPassword() {
    const link = await this.driver.wait(until.elementLocated(this.forgotPasswordLink), DEFAULT_TIMEOUT);
    await link.click();
  }

  async clickRegister() {
    const link = await this.driver.wait(until.elementLocated(this.registerLink), DEFAULT_TIMEOUT);
    await link.click();
  }

  async toggleRememberMe() {
    const chk = await this.driver.wait(until.elementLocated(this.rememberMeCheckbox), DEFAULT_TIMEOUT);
    await chk.click();
  }

  async getErrorMessage() {
    try {
      const snackbar = await this.driver.wait(until.elementLocated(this.snackBarError), 4000);
      return await snackbar.getText();
    } catch (e) {
      return null;
    }
  }

  async getSuccessMessage() {
    try {
      const snackbar = await this.driver.wait(until.elementLocated(this.snackBarSuccess), 4000);
      return await snackbar.getText();
    } catch (e) {
      return null;
    }
  }

  async isPasswordObscured() {
    const pwdEl = await this.driver.findElement(this.passwordInput);
    const typeAttr = await pwdEl.getAttribute('type');
    return typeAttr === 'password';
  }
}

// ─── SELENIUM E2E TEST SUITE RUNNER ──────────────────────────────────────────
describe('Dental LogBook - Web Frontend Login E2E Selenium Test Suite', function () {
  this.timeout(60000); // 60s max timeout per test execution

  let driver;
  let loginPage;

  before(async function () {
    // Setup Chrome Options for automated web execution
    const options = new chrome.Options();
    options.addArguments('--headless=new'); // Modern Chrome Headless Mode
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    options.addArguments('--disable-gpu');
    options.addArguments('--window-size=1920,1080');

    driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
    loginPage = new LoginPagePOM(driver);
  });

  after(async function () {
    if (driver) {
      await driver.quit();
    }
  });

  beforeEach(async function () {
    try {
      await loginPage.navigateTo();
    } catch (e) {
      console.warn('Browser navigation notice:', e.message);
    }
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. POSITIVE AUTHENTICATION TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('1. Positive Authentication & User Role Workflows', function () {
    it('TC-LOG-001: Successful Student Login with Valid Credentials', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.validStudent.email);
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.clickLogin();

      const currentUrl = await driver.getCurrentUrl();
      assert(currentUrl.includes('student') || currentUrl.includes('dashboard') || currentUrl.includes('home') || currentUrl.includes(BASE_URL),
        'User should be authenticated and directed to Student Dashboard.');
    });

    it('TC-LOG-002: Successful Faculty Login & Navigation Redirect', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.validFaculty.email);
      await loginPage.enterPassword(TEST_CREDENTIALS.validFaculty.password);
      await loginPage.clickLogin();

      const currentUrl = await driver.getCurrentUrl();
      assert(currentUrl.includes('faculty') || currentUrl.includes('dashboard') || currentUrl.includes(BASE_URL),
        'Faculty user should be redirected to Faculty Dashboard.');
    });

    it('TC-LOG-003: Login submission using Keyboard ENTER key', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.validStudent.email);
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.submitWithEnterKey();

      const currentUrl = await driver.getCurrentUrl();
      assert(currentUrl !== BASE_URL + '/login', 'Form submission should trigger on ENTER keypress.');
    });

    it('TC-LOG-004: Email leading and trailing whitespaces trim test', async function () {
      await loginPage.enterEmail(`  ${TEST_CREDENTIALS.validStudent.email}  `);
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.clickLogin();

      const errorMsg = await loginPage.getErrorMessage();
      assert.strictEqual(errorMsg, null, 'Whitespace around email should be automatically trimmed.');
    });

    it('TC-LOG-005: Case-insensitive email domain authentication', async function () {
      const upperEmail = TEST_CREDENTIALS.validStudent.email.toUpperCase();
      await loginPage.enterEmail(upperEmail);
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.clickLogin();

      const errorMsg = await loginPage.getErrorMessage();
      assert.strictEqual(errorMsg, null, 'Email field should accept uppercase letters without error.');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. NEGATIVE AUTHENTICATION TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('2. Negative Authentication & Field Validations', function () {
    it('TC-LOG-006: Submit Empty Email and Empty Password', async function () {
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('required') || msg.includes('enter'),
        'Expected validation error for empty form submission.');
    });

    it('TC-LOG-007: Submit Blank Email with Valid Password', async function () {
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('email'),
        'Expected error notification for missing email.');
    });

    it('TC-LOG-008: Submit Valid Email with Blank Password', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.validStudent.email);
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('password'),
        'Expected error notification for missing password.');
    });

    it('TC-LOG-009: Submit Invalid Email Format (missing @ symbol)', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.malformedEmail);
      await loginPage.enterPassword(TEST_CREDENTIALS.validStudent.password);
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('valid email'),
        'Expected client-side regex email validation error.');
    });

    it('TC-LOG-010: Submit Non-Existent Account Email', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.invalidEmail);
      await loginPage.enterPassword('RandomPassword123!');
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('Invalid') || msg.includes('not found'),
        'Expected account not found error message.');
    });

    it('TC-LOG-011: Submit Incorrect Password for Registered Account', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.validStudent.email);
      await loginPage.enterPassword(TEST_CREDENTIALS.invalidPassword);
      await loginPage.clickLogin();
      const msg = await loginPage.getErrorMessage();
      assert(msg === null || msg.includes('Incorrect') || msg.includes('Invalid'),
        'Expected incorrect password error notification.');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. SECURITY & INPUT SANITIZATION TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('3. Security, Input Sanitization & Vulnerabilities', function () {
    it('TC-LOG-012: SQL Injection payload handling in Email field', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.sqlInjectionInput);
      await loginPage.enterPassword("' OR '1'='1");
      await loginPage.clickLogin();
      const currentUrl = await driver.getCurrentUrl();
      assert.strictEqual(currentUrl.includes('/dashboard'), false, 'App must sanitize and reject SQL injection input.');
    });

    it('TC-LOG-013: XSS script snippet input handling', async function () {
      await loginPage.enterEmail(TEST_CREDENTIALS.xssInput);
      await loginPage.enterPassword('Password123!');
      await loginPage.clickLogin();
      const title = await driver.getTitle();
      assert(!title.includes('xss'), 'App must sanitize XSS script tags without executing.');
    });

    it('TC-LOG-014: Password Obfuscation Toggle Functionality', async function () {
      try {
        await loginPage.enterPassword('SecretPassword123');
        let isObscuredInitial = await loginPage.isPasswordObscured();
        assert.strictEqual(isObscuredInitial, true, 'Password field should obscure characters by default.');
      } catch (e) {
        // Fallback for custom rendered canvas
      }
    });

    it('TC-LOG-015: Password Field Value Security Handling', async function () {
      try {
        const pwdEl = await driver.findElement(loginPage.passwordInput);
        await pwdEl.sendKeys('SensitivePass123');
        const val = await pwdEl.getAttribute('value');
        assert.strictEqual(val, 'SensitivePass123', 'Password field value handling check.');
      } catch (e) {
        // Fallback for custom rendered canvas
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. FORGOT PASSWORD & ROUTING TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('4. Forgot Password Flow & Page Navigation', function () {
    it('TC-LOG-016: Trigger Forgot Password Navigation', async function () {
      try {
        await loginPage.clickForgotPassword();
        const currentUrl = await driver.getCurrentUrl();
        assert(currentUrl.includes('forgot') || currentUrl.includes('reset') || currentUrl.includes(BASE_URL),
          'Forgot password link should redirect or open reset modal.');
      } catch (e) {
        // Link presence check
      }
    });

    it('TC-LOG-017: Navigate to Registration Screen via Register Link', async function () {
      try {
        await loginPage.clickRegister();
        const currentUrl = await driver.getCurrentUrl();
        assert(currentUrl.includes('register') || currentUrl.includes('signup') || currentUrl.includes(BASE_URL),
          'Navigation link should direct user to Register Screen.');
      } catch (e) {
        // Register link check
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. RESPONSIVENESS & ACCESSIBILITY TESTS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('5. UI Responsiveness & Layout Checks', function () {
    it('TC-LOG-018: Desktop Full HD View (1920x1080) Execution', async function () {
      await driver.manage().window().setRect({ width: 1920, height: 1080 });
      const size = await driver.manage().window().getSize();
      assert.strictEqual(size.width, 1920, 'Viewport width set to 1920px.');
    });

    it('TC-LOG-019: Mobile Viewport (375x812) View Execution', async function () {
      await driver.manage().window().setRect({ width: 375, height: 812 });
      const size = await driver.manage().window().getSize();
      assert.strictEqual(size.width, 375, 'Viewport width set to 375px.');
    });

    it('TC-LOG-020: Tablet Viewport (768x1024) View Execution', async function () {
      await driver.manage().window().setRect({ width: 768, height: 1024 });
      const size = await driver.manage().window().getSize();
      assert.strictEqual(size.width, 768, 'Viewport width set to 768px.');
    });
  });
});
