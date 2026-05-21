// @ts-check
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './playwright',
  timeout: 60000,
  retries: 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: './playwright/html-report' }],
    ['list']
  ],
  use: {
    baseURL: 'http://localhost:5021',
    headless: true,
    screenshot: 'only-on-failure',
    ignoreHTTPSErrors: true,
    actionTimeout: 10000,
    useMock: process.env.USE_MOCK !== 'false',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
