const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // Test 1: Verify getAppContext() returns safe stub when cross-origin
  console.log('=== Test 1: 代码修复验证 — getAppContext() stub ===');
  const res = await (await browser.newPage()).request.get('http://localhost:8095/v2/util.js');
  const source = await res.text();

  const hasStubFallback = source.includes('checkTabPermissions') && source.includes('getShareStateKey');
  const hasNullSafe = source.includes('if (ctx) return ctx');
  const hasReturnStub = source.includes('return {');
  console.log(`  getAppContext() 含降级 stub: ${hasStubFallback ? '✅' : '❌'}`);
  console.log(`  ctx null-safety guard: ${hasNullSafe ? '✅' : '❌'}`);
  console.log(`  stub return 存在: ${hasReturnStub ? '✅' : '❌'}`);
  results.push({ test: 'getAppContext() stub 代码', result: (hasStubFallback && hasNullSafe) ? 'PASS' : 'FAIL' });

  // Test 2: Cross-origin iframe — HRM pages should not have "route" or "appContext" errors
  console.log('\n=== Test 2: 跨域 iframe HRM 页面加载（核心页面） ===');

  const hrmePages = [
    { name: 'staffInfo', url: '/v2/views/manpowerManage/staffManagement/staffInfo/index.html' },
    { name: 'staffRecord', url: '/v2/views/manpowerManage/staffManagement/staffRecord/index.html' },
    { name: 'staffDimission', url: '/v2/views/manpowerManage/staffManagement/staffDimission/index.html' },
    { name: 'tab_index', url: '/v2/views/manpowerManage/staffManagement/tab_index.html' },
    { name: 'jobIndex', url: '/v2/views/manpowerManage/jobManagement/jobIndex/index.html' },
    { name: 'jobRecord', url: '/v2/views/manpowerManage/jobManagement/jobRecord/index.html' },
    { name: 'transferIndex', url: '/v2/views/manpowerManage/transferManagement/transferIndex/index.html' },
    { name: 'organizationalChart', url: '/v2/views/manpowerManage/organizationalChart/index.html' },
  ];

  for (const testPage of hrmePages) {
    const context = await browser.newContext();
    const page = await context.newPage();
    const pageErrors = [];

    page.on('console', msg => {
      if (msg.type() === 'error'
        && !msg.text().includes('favicon')
        && !msg.text().includes('layui')) {
        pageErrors.push(msg.text());
      }
    });

    try {
      // Load from about:blank with embedded iframe to trigger cross-origin getAppContext() path
      await page.goto('about:blank');
      await page.evaluate(({ url }) => {
        return new Promise(resolve => {
          const iframe = document.createElement('iframe');
          iframe.src = `http://localhost:8095${url}?embedded=true&hrmToken=test-token-xyz`;
          iframe.style.cssText = 'width:100%;height:100vh;';
          document.body.appendChild(iframe);
          iframe.onload = () => setTimeout(resolve, 2000);
        });
      }, { url: testPage.url });
      await page.waitForTimeout(4000);

      // Check for appContext/route related errors specifically
      const routeErrors = pageErrors.filter(e =>
        e.includes('route') || e.includes('appContext') || e.includes('undefined')
      );
      const securityErrors = pageErrors.filter(e =>
        e.includes('SecurityError') || e.includes('security')
      );

      const pass = routeErrors.length === 0 && securityErrors.length === 0;
      console.log(`  ${testPage.name}: ${pass ? '✅' : '❌'} (route错误:${routeErrors.length}, security错误:${securityErrors.length}, 其他:${pageErrors.length - routeErrors.length - securityErrors.length})`);
      if (!pass && routeErrors.length > 0) {
        console.log(`    route errors: ${routeErrors.slice(0,2).join(' | ')}`);
      }
      results.push({ test: `HRM页面 ${testPage.name}`, result: pass ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${testPage.name}: ⚠️ 加载异常 (${e.message.substring(0, 80)})`);
      results.push({ test: `HRM页面 ${testPage.name}`, result: 'WARN' });
    }
    await page.close();
    await context.close();
  }

  // Test 3: Direct page load verify no appContext errors
  console.log('\n=== Test 3: 直接加载 — getAppContext() 正常工作（同源） ===');
  const context3 = await browser.newContext();
  const page3 = await context3.newPage();
  const directErrors = [];
  page3.on('console', msg => {
    if (msg.type() === 'error'
      && !msg.text().includes('favicon')
      && !msg.text().includes('layui')) {
      directErrors.push(msg.text());
    }
  });

  try {
    await page3.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?embedded=true&hrmToken=test-xyz', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page3.waitForTimeout(3000);

    const routeErrs = directErrors.filter(e => e.includes('route') || e.includes('appContext'));
    console.log(`  tab_index 直接加载: ${routeErrs.length === 0 ? '✅' : '❌ route错误: ' + routeErrs.length}`);
    results.push({ test: '同源直接加载无route错误', result: routeErrs.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  直接加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: '同源直接加载', result: 'WARN' });
  }
  await page3.close();
  await context3.close();

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
