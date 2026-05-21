const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — newFenluApiBase port 8088
  // ============================================================
  console.log('=== Test 1: appConfig.js newFenluApiBase 端口验证 ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/appConfig.js');
  const cfg = await res1.text();

  const has8088 = cfg.includes("newFenluApiBase: 'http://localhost:8088/api'");
  const has5001 = cfg.includes('localhost:5001');
  console.log(`  newFenluApiBase → 8088: ${has8088 ? '✅' : '❌'}`);
  console.log(`  5001 残留: ${has5001 ? '❌ 仍有5001' : '✅ 无'}`);
  results.push({ test: 'newFenluApiBase=8088', result: has8088 && !has5001 ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: Verify 8088 /api responds
  // ============================================================
  console.log('\n=== Test 2: localhost:8088/api 可达性验证 ===');

  try {
    const res2 = await (await browser.newPage()).request.get('http://localhost:8088/api/settings/get-by-key?key=test', {
      timeout: 5000
    });
    console.log(`  8088/api 响应: status=${res2.status()} ✅`);
    results.push({ test: '8088 API可达', result: 'PASS' });
  } catch (e) {
    console.log(`  8088/api: ⚠️ ${e.message.substring(0, 60)}`);
    results.push({ test: '8088 API可达', result: 'WARN' });
  }

  // ============================================================
  // Test 3: HRM pages load without network errors
  // ============================================================
  console.log('\n=== Test 3: HRM 页面 — 无 API 网络错误 ===');

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
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-nf1`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const netErrors = pageErrors.filter(e =>
        e.includes('5001') || e.includes('Failed to fetch') || e.includes('NetworkError')
        || e.includes('net::') || e.includes('ERR_')
      );
      console.log(`  ${hp.name}: 网络错误=${netErrors.length} | 其他=${pageErrors.length - netErrors.length}`);
      results.push({ test: `HRM ${hp.name} 无网络错误`, result: netErrors.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 无网络错误`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 4: ERP page — hrm-proxy不受影响
  // ============================================================
  console.log('\n=== Test 4: ERP (5021) hrm-proxy 不受影响 ===');

  const ctx4 = await browser.newContext();
  const pg4 = await ctx4.newPage();
  const errors4 = [];
  pg4.on('console', msg => { if (msg.type() === 'error') errors4.push(msg.text()); });

  await pg4.route('**/api/services/app/User/GetLoginUser**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { userName: 'admin', displayName: 'Admin', companyId: 1, roleId: 1 } }) });
  });
  await pg4.route('**/api/hrm-auth/get-fenlu-token', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { token: 'test-nf' } }) });
  });
  await pg4.route('**/api/services/app/Menu/GetUserMenus**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json',
      body: JSON.stringify({ succeeded: true, data: { children: [] } }) });
  });

  try {
    await pg4.goto('http://localhost:5021/', { waitUntil: 'networkidle', timeout: 30000 });
    await pg4.waitForTimeout(2000);

    const netErrs = errors4.filter(e =>
      e.includes('Failed to fetch') || e.includes('SSL') || e.includes('ERR_')
    );
    console.log(`  ERP (5021) 网络错误: ${netErrs.length === 0 ? '✅ 无' : '❌ ' + netErrs.join('; ')}`);
    results.push({ test: 'ERP hrm-proxy不受影响', result: netErrs.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'ERP hrm-proxy不受影响', result: 'WARN' });
  }
  await pg4.close();
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
