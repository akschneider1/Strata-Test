import baseConfig from '../playwright.config';
import { deepMerge } from '../lib/util';
import { defineConfig } from '@playwright/test';

export default defineConfig(
  deepMerge(baseConfig, {
    // The demo walkthrough needs the demo apps running with fresh demo data,
    // so it only runs when asked for (see bin/demo test).
    testIgnore: process.env.DEMO_WALKTHROUGH === 'true' ? [] : ['**/demo-walkthrough.spec.ts'],
    use: {
      baseURL: baseConfig.use.baseURL || 'localhost:3100',
      // Use an already installed Chromium instead of Playwright's download,
      // e.g. E2E_CHROMIUM_PATH=/usr/bin/chromium
      launchOptions: process.env.E2E_CHROMIUM_PATH
        ? { executablePath: process.env.E2E_CHROMIUM_PATH }
        : {},
    },
  })
);
