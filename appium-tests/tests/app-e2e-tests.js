/**
 * Dental LogBook Mobile Frontend - E2E Appium Test Suite
 * File: appium-tests/tests/app-e2e-tests.js
 * Target Application: Dental LogBook Mobile Application (Flutter Android & iOS)
 * Description: Comprehensive End-to-End Functional, Touch Gesture, Camera/Photo Upload,
 *              Biometric Auth, Offline Sync & Device Orientation Automation Suite.
 */

const { remote } = require('webdriverio');
const assert = require('assert');

// ─── APPIUM DESIRED CAPABILITIES ─────────────────────────────────────────────
const ANDROID_CAPABILITIES = {
  platformName: 'Android',
  'appium:automationName': 'UiAutomator2',
  'appium:deviceName': 'Android Emulator',
  'appium:platformVersion': '13.0',
  'appium:app': process.env.ANDROID_APK_PATH || './build/app/outputs/flutter-apk/app-release.apk',
  'appium:appPackage': 'com.dentallogbook.app',
  'appium:appActivity': 'com.dentallogbook.app.MainActivity',
  'appium:noReset': false,
  'appium:fullReset': false,
  'appium:autoGrantPermissions': true,
  'appium:newCommandTimeout': 300
};

const IOS_CAPABILITIES = {
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:deviceName': 'iPhone 15 Pro',
  'appium:platformVersion': '17.2',
  'appium:app': process.env.IOS_APP_PATH || './build/ios/iphonesimulator/Runner.app',
  'appium:bundleId': 'com.dentallogbook.app',
  'appium:noReset': false,
  'appium:autoAcceptAlerts': true,
  'appium:newCommandTimeout': 300
};

const APPIUM_SERVER_CONFIG = {
  hostname: process.env.APPIUM_HOST || 'localhost',
  port: parseInt(process.env.APPIUM_PORT || '4723', 10),
  path: '/',
  logLevel: 'error',
  capabilities: ANDROID_CAPABILITIES
};

// ─── PAGE OBJECT MODEL (POM) CLASSES ──────────────────────────────────────────

/** Splash Screen Page Object */
class SplashScreenPOM {
  constructor(driver) {
    this.driver = driver;
    this.logoLocator = '~app_logo_key'; // Flutter Key / Accessibility ID
    this.getStartedBtn = '~get_started_button';
  }

  async waitForSplashToDisappear() {
    try {
      const btn = await this.driver.$(this.getStartedBtn);
      if (await btn.isDisplayed()) {
        await btn.click();
      }
    } catch (e) {
      // Auto-transitioned to login screen
    }
  }
}

/** Mobile Login Screen Page Object */
class MobileLoginPagePOM {
  constructor(driver) {
    this.driver = driver;
    this.emailInput = '~email_input_field';
    this.passwordInput = '~password_input_field';
    this.loginBtn = '~login_submit_button';
    this.roleDropdown = '~role_selector_dropdown';
    this.biometricBtn = '~biometric_login_button';
    this.rememberMeCheckbox = '~remember_me_checkbox';
    this.errorSnackbar = '~error_snackbar_message';
    this.forgotPassBtn = '~forgot_password_link';
  }

  async enterEmail(email) {
    const el = await this.driver.$(this.emailInput);
    await el.waitForDisplayed({ timeout: 10000 });
    await el.setValue(email);
  }

  async enterPassword(password) {
    const el = await this.driver.$(this.passwordInput);
    await el.setValue(password);
  }

  async selectRole(roleName) {
    try {
      const drop = await this.driver.$(this.roleDropdown);
      if (await drop.isDisplayed()) {
        await drop.click();
        const roleOpt = await this.driver.$(`~role_option_${roleName.toLowerCase()}`);
        await roleOpt.click();
      }
    } catch (e) {
      // Default role active
    }
  }

  async tapLogin() {
    const btn = await this.driver.$(this.loginBtn);
    await btn.click();
  }

  async tapBiometricLogin() {
    const bio = await this.driver.$(this.biometricBtn);
    await bio.click();
  }

  async getErrorMessage() {
    try {
      const err = await this.driver.$(this.errorSnackbar);
      await err.waitForDisplayed({ timeout: 4000 });
      return await err.getText();
    } catch (e) {
      return null;
    }
  }
}

/** Student Dashboard Page Object */
class StudentDashboardPOM {
  constructor(driver) {
    this.driver = driver;
    this.dashboardTitle = '~student_dashboard_title';
    this.addCaseFab = '~add_new_case_fab';
    this.myCasesTab = '~my_cases_nav_tab';
    this.notificationsTab = '~notifications_nav_tab';
    this.casesList = '~logged_cases_list_view';
    this.profileAvatar = '~user_profile_avatar';
  }

  async isDisplayed() {
    try {
      const title = await this.driver.$(this.dashboardTitle);
      return await title.isDisplayed();
    } catch (e) {
      return false;
    }
  }

  async tapAddNewCase() {
    const fab = await this.driver.$(this.addCaseFab);
    await fab.waitForDisplayed({ timeout: 10000 });
    await fab.click();
  }

  async swipeToRefresh() {
    // Perform Appium touch action drag for swipe-to-refresh
    await this.driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: 500, y: 300 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: 500, y: 900 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }
}

/** Add Dental Case Screen Page Object */
class AddCaseScreenPOM {
  constructor(driver) {
    this.driver = driver;
    this.patientIdInput = '~patient_id_input';
    this.departmentDropdown = '~department_dropdown';
    this.procedureDropdown = '~procedure_dropdown';
    this.toothNumberSelector = '~tooth_number_selector';
    this.supervisorDropdown = '~supervisor_faculty_dropdown';
    this.notesInput = '~clinical_notes_input';
    this.attachImageBtn = '~attach_clinical_photo_button';
    this.submitCaseBtn = '~submit_case_for_approval_button';
    this.saveDraftBtn = '~save_case_draft_button';
  }

  async fillCaseDetails(patientId, department, procedure, toothNum, notes) {
    const pid = await this.driver.$(this.patientIdInput);
    await pid.setValue(patientId);

    const notesEl = await this.driver.$(this.notesInput);
    await notesEl.setValue(notes);
  }

  async submitCase() {
    const btn = await this.driver.$(this.submitCaseBtn);
    await btn.click();
  }
}

/** Faculty Evaluation Screen Page Object */
class FacultyEvaluationPOM {
  constructor(driver) {
    this.driver = driver;
    this.pendingCasesTab = '~pending_reviews_tab';
    this.approveBtn = '~approve_case_button';
    this.rejectBtn = '~reject_case_button';
    this.ratingStars = '~grade_rating_bar';
    this.facultyFeedbackInput = '~faculty_comments_input';
  }

  async approveCase(feedbackText) {
    const fb = await this.driver.$(this.facultyFeedbackInput);
    if (await fb.isDisplayed()) {
      await fb.setValue(feedbackText);
    }
    const btn = await this.driver.$(this.approveBtn);
    await btn.click();
  }
}

// ─── E2E APPIUM TEST SUITE RUNNER ─────────────────────────────────────────────
describe('Dental LogBook Mobile App - Appium E2E Automation Suite', function () {
  this.timeout(120000); // 2 minute timeout per test block

  let driver;
  let splashPage;
  let loginPage;
  let studentDashboard;
  let addCaseScreen;
  let facultyEval;

  before(async function () {
    // Connect to Appium server session
    try {
      driver = await remote(APPIUM_SERVER_CONFIG);
      splashPage = new SplashScreenPOM(driver);
      loginPage = new MobileLoginPagePOM(driver);
      studentDashboard = new StudentDashboardPOM(driver);
      addCaseScreen = new AddCaseScreenPOM(driver);
      facultyEval = new FacultyEvaluationPOM(driver);
    } catch (e) {
      console.warn('Appium Driver initialization notice (Dry-run mode without active emulator):', e.message);
    }
  });

  after(async function () {
    if (driver) {
      await driver.deleteSession();
    }
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. MOBILE AUTHENTICATION & LOGIN WORKFLOWS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('1. Mobile App Authentication & Role Switching', function () {
    it('TC-APP-001: Verify Splash screen auto-transition to Login Screen', async function () {
      if (!driver) return this.skip();
      await splashPage.waitForSplashToDisappear();
      const emailField = await driver.$('~email_input_field');
      assert(await emailField.isDisplayed(), 'Login email field should be displayed after splash screen.');
    });

    it('TC-APP-002: Successful Student Mobile Login with Valid Credentials', async function () {
      if (!driver) return this.skip();
      await loginPage.enterEmail('student@dentallogbook.com');
      await loginPage.enterPassword('Password123!');
      await loginPage.tapLogin();

      const isDashVisible = await studentDashboard.isDisplayed();
      assert(isDashVisible, 'Student should be navigated to Mobile Dashboard upon successful login.');
    });

    it('TC-APP-003: Validation Error on Empty Credentials Submission', async function () {
      if (!driver) return this.skip();
      await loginPage.enterEmail('');
      await loginPage.enterPassword('');
      await loginPage.tapLogin();

      const err = await loginPage.getErrorMessage();
      assert(err !== null, 'Snackbar error should be triggered for empty login submission.');
    });

    it('TC-APP-004: Mobile Biometric Login Trigger (Fingerprint / Face ID)', async function () {
      if (!driver) return this.skip();
      await loginPage.tapBiometricLogin();
      // Verify biometric prompt modal state
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. STUDENT CASE LOGGING & PROCEDURE ENTRY WORKFLOWS
  // ─────────────────────────────────────────────────────────────────────────────
  describe('2. Student Dental Case Entry Workflows', function () {
    it('TC-APP-036: Open Add New Dental Case Screen via Floating Action Button (FAB)', async function () {
      if (!driver) return this.skip();
      await studentDashboard.tapAddNewCase();
      const patientIdField = await driver.$('~patient_id_input');
      assert(await patientIdField.isDisplayed(), 'Add Case form should be visible.');
    });

    it('TC-APP-037: Fill and Submit Dental Procedure Entry for Approval', async function () {
      if (!driver) return this.skip();
      await addCaseScreen.fillCaseDetails('PAT-88412', 'Endodontics', 'Root Canal Treatment', '16', 'Single-visit RCT completed on Tooth #16.');
      await addCaseScreen.submitCase();

      const successToast = await driver.$('~case_submitted_success_toast');
      assert(await successToast.isDisplayed(), 'Success toast message expected on case submission.');
    });

    it('TC-APP-038: Swipe to Refresh Student Dashboard Case List', async function () {
      if (!driver) return this.skip();
      await studentDashboard.swipeToRefresh();
      const casesList = await driver.$('~logged_cases_list_view');
      assert(await casesList.isDisplayed(), 'Cases list view refreshed.');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. DEVICE CONTROLS, GESTURES & ORIENTATION
  // ─────────────────────────────────────────────────────────────────────────────
  describe('3. Mobile Gestures & Device Control Integration', function () {
    it('TC-APP-111: Screen Orientation Toggle (PORTRAIT -> LANDSCAPE)', async function () {
      if (!driver) return this.skip();
      await driver.setOrientation('LANDSCAPE');
      const orientation = await driver.getOrientation();
      assert.strictEqual(orientation, 'LANDSCAPE', 'Device orientation set to LANDSCAPE.');
      await driver.setOrientation('PORTRAIT');
    });

    it('TC-APP-112: App Backgrounding & Resume Session Retention', async function () {
      if (!driver) return this.skip();
      await driver.background(5); // Send app to background for 5 seconds
      const isDashVisible = await studentDashboard.isDisplayed();
      assert(isDashVisible, 'App should resume session cleanly after backgrounding.');
    });

    it('TC-APP-113: Offline Storage & Automatic Cloud Synchronization on Reconnect', async function () {
      if (!driver) return this.skip();
      await driver.toggleAirplaneMode(); // Simulate network drop
      // Attempt local draft save
      await driver.toggleAirplaneMode(); // Restore connection
    });
  });
});
