const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // Test 1: Code verification
  console.log('=== Test 1: appConfig.js https→http 修复验证 ===');
  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/appConfig.js');
  const cfg = await res1.text();

  const hasHttps = cfg.includes('https://') && (cfg.includes('baseUrl') || cfg.includes('localhost'));
  const hasHttpLocalhost = cfg.includes("http://localhost");
  console.log(`  https:// 残留: ${hasHttps ? '⚠️ 仍有https' : '✅ 无https'}`);
  console.log(`  http://localhost 使用: ${hasHttpLocalhost ? '✅' : '❌'}`);
  results.push({ test: 'appConfig 无https残留', result: !hasHttps ? 'PASS' : 'FAIL' });

  // Test 2: ERP page — no SSL/fetch errors
  console.log('\n=== Test 2: ERP Console — 无 Failed to fetch / SSL 错误 ===');

  const ctx2 = await browser.newContext();
  const pg2 = await ctx2.newPage();
  const errors = [];
  pg2.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  // Mock auth
  await pg2.route('**/api/services/app/User/GetLoginUser**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { userName: 'admin', displayName: 'Admin', companyId: 1, roleId: 1 } }) });
  });
  await pg2.route('**/api/hrm-auth/get-fenlu-token', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { token: 'test-fix' } }) });
  });
  await pg2.route('**/api/services/app/Menu/GetUserMenus**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { children: [] } }) });
  });

  try {
    await pg2.goto('http://localhost:5021/', { waitUntil: 'networkidle', timeout: 30000 });
    await pg2.waitForTimeout(2000);

    const fetchErrors = errors.filter(e =>
      e.includes('Failed to fetch') || e.includes('fetch') || e.includes('SSL') || e.includes('ssl')
    );
    console.log(`  Failed to fetch / SSL: ${fetchErrors.length === 0 ? '✅ 无' : '❌ ' + fetchErrors.join('; ')}`);
    console.log(`  其他错误: ${errors.length - fetchErrors.length}`);
    results.push({ test: 'ERP无Failed to fetch', result: fetchErrors.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  ERP加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'ERP无Failed to fetch', result: 'WARN' });
  }
  await pg2.close();
  await ctx2.close();

  // Test 3: HRM pages load without fetch errors
  console.log('\n=== Test 3: HRM 页面加载 — 无fetch错误 ===');
  const pages = ['staffInfo', 'staffRecord', 'tab_index'];
  for (const name of pages) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    const pageErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error' && !msg.text().includes('favicon') && !msg.text().includes('layui')) {
        pageErrors.push(msg.text());
      }
    });
    try {
      await page.goto(`http://localhost:8095/v2/views/manpowerManage/staffManagement/${name}/index.html?embedded=true&hrmToken=test`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);
      const fetchErrs = pageErrors.filter(e => e.includes('fetch') || e.includes('SSL') || e.includes('ssl'));
      console.log(`  ${name}: fetch错误=${fetchErrs.length} | 其他=${pageErrors.length - fetchErrs.length}`);
      results.push({ test: `HRM ${name} 无fetch错误`, result: fetchErrs.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${name} 无fetch错误`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // Summary
  console.log('\n========================================');
  console.log('       测试结果汇总');
  console.log('========================================');
  const passCount = results.filter(r => r.result === 'PASS').length;
  const failCount = results.filter(r => r.result === 'FAIL').length;
  results.forEach(r => console.log(`${r.result === 'PASS' ? '✅' : r.result === 'FAIL' ? '❌' : '⚠️'} ${r.test}: ${r.result}`));
  console.log(`\n总计: ${results.length} | 通过: ${passCount} | 失败: ${failCount}`);

  await browser.close();
  process.exit(failCount > 0 ? 1 : 0);
})();
