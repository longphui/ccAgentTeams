const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const results = [];

  // Test 1: Code fix verification (static analysis)
  console.log('=== Test 1: 代码修复验证 ===');
  const bsRes = await (await browser.newPage()).request.get('http://localhost:8095/v2/baseService.js');
  const bsSource = await bsRes.text();

  const checks = {
    embeddedCheck: bsSource.includes('embedded=true'),
    hrmTokenExtract: bsSource.includes('params.get("hrmToken")'),
    replaceState: bsSource.includes('replaceState'),
    cleanUrl: bsSource.includes('cleanUrl'),
    setToken: bsSource.includes('localStorage.setItem("token", hrmToken)'),
    tokenExpiredHandler: bsSource.includes('HRM_TOKEN_EXPIRED'),
  };
  Object.entries(checks).forEach(([k, v]) => console.log(`  ${k}: ${v ? '✅' : '❌'}`));
  results.push({ test: '代码修复完整性', result: Object.values(checks).every(Boolean) ? 'PASS' : 'FAIL' });

  // Test 2: Functional test with the main 8095 index page
  console.log('\n=== Test 2: 8095 首页嵌入模式功能验证 ===');
  const page = await context.newPage();
  const errors = [];
  const navHistory = [];

  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('framenavigated', frame => {
    if (frame === page.mainFrame()) navHistory.push(frame.url());
  });

  const testToken = 'Bearer_test_fix_verify_2026';
  await page.goto(
    `http://localhost:8095/?embedded=true&hrmToken=${encodeURIComponent(testToken)}`,
    { waitUntil: 'networkidle', timeout: 15000 }
  );
  await page.waitForTimeout(2000);

  // Check URL cleanup
  const url = page.url();
  const hrmTokenInUrl = url.includes('hrmToken');
  const embeddedKept = url.includes('embedded=true');
  console.log(`  URL: ${url}`);
  console.log(`  hrmToken 残留: ${hrmTokenInUrl ? '❌' : '✅'}`);
  console.log(`  embedded=true 保留: ${embeddedKept ? '✅' : '❌'}`);

  // Check localStorage
  const token = await page.evaluate(() => ({
    token: localStorage.getItem('token'),
    xToken: localStorage.getItem('xToken'),
  }));
  console.log(`  localStorage token: ${token.token ? '✅ ' + token.token.substring(0,30)+'...' : '⚠️ 未设置'}`);
  console.log(`  localStorage xToken: ${token.xToken ? '✅ ' + token.xToken.substring(0,30)+'...' : '⚠️ 未设置'}`);

  // Check for loop (multiple navigations in short time)
  const navCount = navHistory.length;
  console.log(`  导航次数 (2s): ${navCount} ${navCount > 3 ? '❌ 循环!' : '✅ 正常'}`);

  // Check errors
  const relevantErrors = errors.filter(e => !e.includes('favicon'));
  console.log(`  运行时错误: ${relevantErrors.length === 0 ? '✅ 无' : '⚠️ ' + relevantErrors.length + '个'}`);
  if (relevantErrors.length > 0) console.log('  错误:', relevantErrors.slice(0, 3));

  results.push({ test: 'hrmToken URL 清理', result: !hrmTokenInUrl ? 'PASS' : 'FAIL' });
  results.push({ test: 'localStorage token 写入', result: token.token ? 'PASS' : 'FAIL' });
  results.push({ test: '页面无循环', result: navCount <= 3 ? 'PASS' : 'FAIL' });
  results.push({ test: '无运行时错误', result: relevantErrors.length === 0 ? 'PASS' : 'WARN' });

  // Test 3: Verify the HRM proxy flow (天津宏观世纪端)
  console.log('\n=== Test 3: 天津宏观世纪端 hrm-proxy 流程验证 ===');

  // Simulate the top-level window with HRM context listener
  const page2 = await context.newPage();
  await page2.goto('about:blank');
  await page2.evaluate(() => {
    window.addEventListener('message', (e) => {
      if (e.data?.type === 'HRM_GET_CONTEXT') {
        e.source.postMessage({
          type: 'HRM_CONTEXT',
          token: 'Bearer_test_context_token',
          xToken: 'Bearer_test_context_token',
          baseUrl1: 'http://localhost:8095',
          baseUrl2: 'http://localhost:8095',
          newFenluApiBase: 'http://localhost:8095',
        }, '*');
      }
      if (e.data?.type === 'HRM_TOKEN_EXPIRED') {
        window.__hrmTokenExpired = true;
      }
    });
    window.__hrmTokenExpired = false;
  });

  // Load hrm-proxy in iframe
  await page2.evaluate(() => {
    return new Promise(resolve => {
      const iframe = document.createElement('iframe');
      iframe.src = 'http://localhost:5021/views/hrm-proxy/index.html?page=test/page.html';
      iframe.style.cssText = 'width:100%;height:100vh;border:none;';
      document.body.appendChild(iframe);
      iframe.onload = resolve;
    });
  });
  await page2.waitForTimeout(2000);

  // Check for TokenExpired signal (should NOT fire in normal flow)
  const tokenExpired = await page2.evaluate(() => window.__hrmTokenExpired);
  console.log(`  TokenExpired 信号: ${tokenExpired ? '⚠️ 已触发(可能是循环)' : '✅ 未触发'}`);
  results.push({ test: '无 TokenExpired 循环信号', result: !tokenExpired ? 'PASS' : 'FAIL' });

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
