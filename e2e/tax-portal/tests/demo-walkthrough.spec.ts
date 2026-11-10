/**
 * Walks through the Colorado income tax prototype the way the demo does:
 * a taxpayer files on a phone, an examiner works a flagged return, and the
 * taxpayer sees the outcome. Also scans the main pages for accessibility
 * problems.
 *
 * Needs the demo running with fresh demo data, so playwright.config.js only
 * includes it when DEMO_WALKTHROUGH=true. Use `bin/demo test` from the repo root, which
 * starts both apps, reloads the demo data and runs this file.
 */
import { Page, expect, test } from '@playwright/test';

import AxeBuilder from '@axe-core/playwright';

test.describe.configure({ mode: 'serial' });
test.setTimeout(120_000);

const signIn = async (page: Page, firstName: string) => {
  await page.goto('/');
  await page.getByRole('button', { name: `Continue as ${firstName}` }).click();
  // Wait until the sign-in has landed on the person's own start page.
  await page.waitForURL((url) => url.pathname !== '/');
};

const signOut = async (page: Page) => {
  await page.getByRole('button', { name: 'Log out' }).first().click();
  await expect(page.getByRole('heading', { name: 'Try the demo' })).toBeVisible();
};

// USWDS hides the real radio and checkbox inputs, so click their labels.
const choose = (page: Page, label: string) =>
  page
    .locator('label.usa-radio__label, label.usa-checkbox__label')
    .filter({ hasText: label })
    .first()
    .click();

const saveAndContinue = async (page: Page) => {
  const before = page.url();
  await page.getByRole('button', { name: 'Save and continue' }).click();
  await page.waitForURL((url) => url.toString() !== before);
};

const expectChecklist = (page: Page) =>
  expect(page.getByRole('heading', { name: 'Your 2025 Colorado return' })).toBeVisible();

// Fail on accessibility problems that block people; report the rest.
const expectAccessible = async (page: Page) => {
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();
  const blocking = results.violations.filter((violation) =>
    ['serious', 'critical'].includes(violation.impact ?? '')
  );
  expect(blocking.map((violation) => `${violation.id}: ${violation.nodes[0]?.target}`)).toEqual([]);
};

test.describe('Taxpayer on a phone', () => {
  test.use({ viewport: { width: 390, height: 844 } });

  test('Maya files her return and it is accepted automatically', async ({ page }) => {
    await signIn(page, 'Maya');
    await expectAccessible(page);
    await page.getByRole('button', { name: 'Start my return' }).click();
    await expectChecklist(page);
    await expectAccessible(page);

    // About you
    await page.getByRole('link', { name: 'Start: About you' }).click();
    await page.locator('#tax_return_filer_name_first').fill('Maya');
    await page.locator('#tax_return_filer_name_last').fill('Torres');
    await expectAccessible(page);
    await saveAndContinue(page);
    await page.getByLabel('Month').selectOption('3');
    await page.getByLabel('Day').fill('14');
    await page.getByLabel('Year').fill('1996');
    await page.getByLabel('Social Security number').fill('000-00-1001');
    await saveAndContinue(page);
    await page.locator('#tax_return_mailing_address_street_line_1').fill('1375 Sherman St');
    await page.locator('#tax_return_mailing_address_city').fill('Denver');
    await page.locator('#tax_return_mailing_address_state').selectOption('CO');
    await page.locator('#tax_return_mailing_address_zip_code').fill('80261');
    await saveAndContinue(page);
    await choose(page, 'Yes');
    await saveAndContinue(page);
    await expectChecklist(page);

    // Your family: no filing status question, just plain ones
    await page.getByRole('link', { name: 'Start: Your family' }).click();
    await expectAccessible(page);
    await choose(page, 'No, I was not married');
    await saveAndContinue(page);
    await choose(page, 'No');
    await saveAndContinue(page);
    await expectChecklist(page);

    // Your income: the W-2 is already there
    await page.getByRole('link', { name: 'Start: Your income' }).click();
    await expect(page.getByRole('heading', { name: 'Front Range Outfitters' })).toBeVisible();
    await expect(page.getByText('On file with the Department')).toBeVisible();
    await expectAccessible(page);
    await page.getByRole('button', { name: /This is correct/ }).click();
    await expect(page.getByText('You confirmed this')).toBeVisible();
    await choose(page, 'checked every income form');
    await saveAndContinue(page);
    await choose(page, 'No');
    await saveAndContinue(page);
    await choose(page, 'No');
    await saveAndContinue(page);
    await expectChecklist(page);
    await expect(page.getByTestId('estimate')).toHaveText('$250');

    // How we calculated this
    await page.getByRole('link', { name: 'See how we calculated this' }).click();
    await expect(page.getByRole('heading', { name: 'Your filing status: Single' })).toBeVisible();
    await expect(page.locator('[data-line=tax]')).toContainText('$1,419');
    await expect(page.locator('[data-line=tax]')).toContainText('4.4%');
    await expectAccessible(page);
    await page.getByRole('link', { name: 'Back' }).click();

    // Refund
    await page.getByRole('link', { name: 'Start: Refund or payment' }).click();
    await choose(page, 'Direct deposit');
    await choose(page, 'Checking');
    await page.getByLabel('Routing number').fill('102000021');
    await page.getByLabel('Account number').fill('000123456789');
    await saveAndContinue(page);

    // Review, sign, submit
    await page.getByRole('link', { name: 'Review and sign' }).click();
    await expect(page.getByText('•••• 1001')).toBeVisible();
    await expectAccessible(page);
    await choose(page, 'I agree');
    await page.getByLabel('Type your full name to sign').fill('Maya Torres');
    await page.getByRole('button', { name: 'Submit my return' }).click();

    await expect(page.getByTestId('stage')).toHaveAttribute('data-stage', 'accepted');
    await expect(page.getByTestId('result-amount')).toHaveText('$250');
    await expect(page.getByTestId('confirmation-number')).toHaveText(/^CO-2025-/);
    await expectAccessible(page);
  });

  test('Daniela sees the credits she qualifies for, and the portal in Spanish', async ({
    page,
  }) => {
    await signIn(page, 'Daniela');
    await page.getByRole('link', { name: 'See how we calculated this' }).click();
    await expect(
      page.getByRole('heading', { name: 'Your filing status: Head of household' })
    ).toBeVisible();
    for (const credit of [
      'earned_income_credit',
      'child_tax_credit',
      'family_affordability_credit',
      'child_care_credit',
    ]) {
      await expect(page.locator(`[data-line=${credit}]`)).toBeVisible();
    }
    await expect(page.getByTestId('refund')).toHaveText('$7,162');

    await page.getByRole('button', { name: 'Español' }).first().click();
    await expect(page.locator('html')).toHaveAttribute('lang', 'es-US');
    await expect(page.getByRole('heading', { level: 1 })).toHaveText(
      'Cómo calculamos su impuesto de Colorado'
    );
    await expectAccessible(page);
  });
});

test.describe('Examiner', () => {
  test.use({ viewport: { width: 1280, height: 900 } });

  test('Priya reviews the flagged return with the taxpayer, and Marcus confirms the adjustment', async ({
    page,
  }) => {
    await signIn(page, 'Priya');
    await expect(page.getByRole('heading', { name: 'Examiner dashboard' })).toBeVisible();
    await expectAccessible(page);

    await page.getByRole('button', { name: 'Pick up next return' }).click();
    await expect(page.getByRole('heading', { name: 'Jordan Lee' })).toBeVisible();
    await expect(page.locator('[data-flag=withholding_higher_than_record]')).toContainText(
      '$2,900'
    );
    await expectAccessible(page);

    // Ask the taxpayer
    await page
      .getByRole('textbox', { name: 'Question' })
      .fill(
        'Your W-2 from Summit Logistics shows $2,900 of Colorado tax withheld, but your return says $3,900. Which is on your copy?'
      );
    await page.getByRole('button', { name: 'Send question' }).click();
    await expect(page.getByTestId('case-step')).toHaveAttribute('data-step', 'provide_information');
    await signOut(page);

    // The taxpayer answers
    await signIn(page, 'Jordan');
    await expect(page.getByTestId('stage')).toHaveAttribute('data-stage', 'needs_information');
    await expectAccessible(page);
    await page
      .getByLabel('Your answer')
      .fill('You are right. I read it off a pay stub. My W-2 says $2,900.');
    await page.getByRole('button', { name: 'Send answer' }).click();
    await expect(page.getByTestId('stage')).toHaveAttribute('data-stage', 'in_review');
    await signOut(page);

    // The examiner adjusts and accepts
    await signIn(page, 'Priya');
    await page
      .getByRole('link', { name: /^Open CO-/ })
      .first()
      .click();
    await expect(page.getByTestId('taxpayer-answer')).toContainText('My W-2 says $2,900');
    await page.getByLabel('Amount to change').selectOption('colorado_tax_withheld');
    await page.getByLabel('New amount (in dollars)').fill('2900');
    await page
      .getByRole('textbox', { name: 'Reason', exact: true })
      .fill('Changed to the amount on the W-2 your employer filed, which you confirmed.');
    await page.getByRole('button', { name: 'Change and recalculate' }).click();
    await expect(page.getByTestId('current-result')).toHaveText('refund $705');
    await expect(page.getByTestId('second-approval-note')).toContainText('a second examiner');
    await page.getByRole('button', { name: 'Accept with adjustments' }).click();
    await expect(page.getByTestId('case-step')).toHaveAttribute('data-step', 'second_review');
    await signOut(page);

    // A change this large takes a second examiner
    await signIn(page, 'Marcus');
    await page.getByRole('button', { name: 'Pick up next return' }).click();
    await expect(page.getByRole('heading', { name: 'Jordan Lee' })).toBeVisible();
    await expect(page.getByTestId('proposal')).toContainText('Priya Shah proposes accepting');
    await expectAccessible(page);
    await page.getByRole('button', { name: 'Confirm' }).click();
    await expect(page.getByTestId('case-step')).toHaveAttribute('data-step', 'end');
    await expect(page.getByTestId('history').locator('li')).toHaveCount(8);

    // The service measures reflect the review
    await page.getByRole('link', { name: 'Service measures' }).click();
    await expect(page.getByRole('heading', { name: 'Service measures', level: 1 })).toBeVisible();
    await expect(page.getByTestId('flags')).toContainText(
      'Withholding higher than reported by payer'
    );
    await expect(page.getByTestId('net-change')).toHaveText('$1,000 less in total');
    await expectAccessible(page);
    await signOut(page);

    // The taxpayer sees the outcome and why
    await signIn(page, 'Jordan');
    await expect(page.getByTestId('stage')).toHaveAttribute('data-stage', 'accepted');
    await expect(page.getByTestId('result-amount')).toHaveText('$705');
    await expect(page.getByText('Colorado tax withheld: $3,900 changed to $2,900')).toBeVisible();
  });

  test('a taxpayer cannot open the examiner portal', async ({ page }) => {
    await signIn(page, 'Walter');
    await page.goto('/staff');
    await expect(page.getByRole('heading', { name: 'Your 2025 Colorado return' })).toBeVisible();
    await expect(page.getByTestId('stage')).toHaveAttribute('data-stage', 'accepted');
  });
});
