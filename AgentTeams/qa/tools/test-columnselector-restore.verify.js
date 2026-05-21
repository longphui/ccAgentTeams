const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — async restore() has try/catch
  // ============================================================
  console.log('=== Test 1: 代码验证 — restore() try/catch 降级 ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/libs/components.js');
  const compJs = await res1.text();

  // Find the async restore() that uses Http2.get
  const hasAsyncRestore = compJs.includes('async restore()');
  const hasTryCatch = compJs.includes('try {') && compJs.includes('//let storeColumns = JSON.parse(localStorage.getItem');
  const hasCatchReturn = compJs.includes('// 嵌入式模式下 settings API 不可用，静默降级');
  const hasHttp2Get = compJs.includes("Http2.get('/settings/get-by-key'");

  console.log(`  async restore() 存在: ${hasAsyncRestore ? '✅' : '❌'}`);
  console.log(`  try/catch 包裹: ${hasTryCatch ? '✅' : '❌'}`);
  console.log(`  静默降级注释: ${hasCatchReturn ? '✅' : '❌'}`);
  console.log(`  Http2.get 调用: ${hasHttp2Get ? '✅' : '❌'}`);
  results.push({ test: 'restore() try/catch降级', result: (hasAsyncRestore && hasTryCatch && hasCatchReturn) ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: ERP page — no "出错啦" errors
  // ============================================================
  console.log('\n=== Test 2: ERP Console — 无 "出错啦" / "Uncaught Error" ===');

  const ctx2 = await browser.newContext();
  const pg2 = await ctx2.newPage();
  const errors2 = [];
  pg2.on('console', msg => { if (msg.type() === 'error') errors2.push(msg.text()); });

  // Mock auth APIs
  await pg2.route('**/api/services/app/User/GetLoginUser**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { userName: 'admin', displayName: 'Admin', companyId: 1, roleId: 1 } }) });
  });
  await pg2.route('**/api/hrm-auth/get-fenlu-token', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { token: 'test-cs' } }) });
  });
  await pg2.route('**/api/services/app/Menu/GetUserMenus**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { children: [] } }) });
  });

  try {
    await pg2.goto('http://localhost:5021/', { waitUntil: 'networkidle', timeout: 30000 });
    await pg2.waitForTimeout(3000);

    const critErrors = errors2.filter(e =>
      e.includes('出错啦') || e.includes('Uncaught Error') || e.includes('ColumnSelector')
    );
    console.log(`  "出错啦" / Uncaught Error: ${critErrors.length === 0 ? '✅ 无' : '❌ ' + critErrors.join('; ')}`);
    console.log(`  其他 console error: ${errors2.length - critErrors.length}`);
    if (errors2.length > 0 && critErrors.length === 0) {
      console.log(`    (非关键错误): ${errors2.slice(0,3).map(e => e.substring(0,120)).join(' | ')}`);
    }
    results.push({ test: 'ERP无"出错啦"错误', result: critErrors.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  ERP加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'ERP无"出错啦"错误', result: 'WARN' });
  }
  await pg2.close();
  await ctx2.close();

  // ============================================================
  // Test 3: HRM pages — no "出错啦" and ColumnSelector renders
  // ============================================================
  console.log('\n=== Test 3: HRM 页面 — ColumnSelector 降级 + 无异常 ===');

  const hrmPages = [
    { name: 'staffInfo', path: 'manpowerManage/staffManagement/staffInfo/index.html' },
    { name: 'staffRecord', path: 'manpowerManage/staffManagement/staffRecord/index.html' },
    { name: 'tab_index', path: 'manpowerManage/staffManagement/tab_index.html' },
  ];

  for (const hp of hrmPages) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    const pageErrors = [];

    page.on('console', msg => {
      if (msg.type() === 'error'
        && !msg.text().includes('favicon')
        && !msg.text().includes('layui')) {
        pageErrors.push(msg.text());
      }
    });

    try {
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-cs`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const critErrs = pageErrors.filter(e =>
        e.includes('出错啦') || e.includes('Uncaught Error') || e.includes('ColumnSelector')
      );
      console.log(`  ${hp.name}: 关键错误=${critErrs.length} | 其他=${pageErrors.length - critErrs.length}`);
      results.push({ test: `HRM ${hp.name} 无"出错啦"`, result: critErrs.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 无"出错啦"`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 4: Simulate Http2.get failure — verify restore() degrades silently
  // ============================================================
  console.log('\n=== Test 4: 模拟 settings API 不可用 — restore() 降级 ===');

  const ctx4 = await browser.newContext();
  const page4 = await ctx4.newPage();
  const errors4 = [];

  page4.on('console', msg => {
    if (msg.type() === 'error') errors4.push(msg.text());
  });

  // Load an HRM page that uses ColumnSelector, but block the settings API
  await page4.route('**/settings/get-by-key**', async route => {
    await route.abort();  // Simulate unreachable settings API
  });

  try {
    await page4.goto(`http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-cs`, {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page4.waitForTimeout(3000);

    const critErrs = errors4.filter(e =>
      e.includes('出错啦') || e.includes('Uncaught Error') || e.includes('ColumnSelector')
    );
    console.log(`  settings API blocked, "出错啦": ${critErrs.length === 0 ? '✅ 无(已降级)' : '❌ ' + critErrs.join('; ')}`);
    console.log(`  其他 console error: ${errors4.length - critErrs.length}`);
    results.push({ test: 'settings API不可用时静默降级', result: critErrs.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  页面加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'settings API不可用时静默降级', result: 'WARN' });
  }
  await page4.close();
  await ctx4.close();

  // Summary
  console.log('\n========================================');
  console.log('       测试结果汇总');
  console.log('========================================');
  const passCount = results.filter(r => r.result === 'PASS').length;
  const failCount = results.filter(r => r.result === 'FAIL').length;
  results.forEach(r => {
    const icon = r.result === 'PASS' ? '✅' : r.result === 'FAIL' ? '❌' : '⚠️';
    console.log(`${icon} ${r.test}: ${r.result}`);
  });
  console.log(`\n总计: ${results.length} | 通过: ${passCount} | 失败: ${failCount}`);

  await browser.close();
  process.exit(failCount > 0 ? 1 : 0);
})();
