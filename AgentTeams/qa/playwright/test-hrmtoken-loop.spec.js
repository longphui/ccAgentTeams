const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  const results = [];
  const errors = [];

  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  // Test 1: Verify baseService.js served correctly with the fix
  console.log('=== Test 1: 代码修复验证 ===');
  const bsRes = await page.request.get('http://localhost:8095/v2/baseService.js');
  const bsSource = await bsRes.text();

  const hasEmbeddedCheck = bsSource.includes('embedded=true');
  const hasHrmTokenExtract = bsSource.includes('hrmToken');
  const hasReplaceState = bsSource.includes('replaceState');
  const hasCleanUrl = bsSource.includes('cleanUrl');
  const hasSetItem = bsSource.includes('localStorage.setItem("token", hrmToken)');
  const hasOnTokenExpired = bsSource.includes('HRM_TOKEN_EXPIRED');

  console.log(`embedded 检测: ${hasEmbeddedCheck ? '✅' : '❌'}`);
  console.log(`hrmToken 提取: ${hasHrmTokenExtract ? '✅' : '❌'}`);
  console.log(`replaceState URL清理: ${hasReplaceState ? '✅' : '❌'}`);
  console.log(`cleanUrl 变量: ${hasCleanUrl ? '✅' : '❌'}`);
  console.log(`token 存入 localStorage: ${hasSetItem ? '✅' : '❌'}`);
  console.log(`HRM_TOKEN_EXPIRED 通知: ${hasOnTokenExpired ? '✅' : '❌'}`);

  const codeFixOk = hasEmbeddedCheck && hasReplaceState && hasSetItem;
  results.push({ test: 'hrmToken 循环修复-代码级别', result: codeFixOk ? 'PASS' : 'FAIL' });

  // Test 2: Verify URL cleanup works (token removal from address bar)
  console.log('\n=== Test 2: URL hrmToken 清理验证 ===');
  const page2 = await context.newPage();
  const testToken = 'test-token-abc123';
  const testUrl = `http://localhost:8095/v2/views/dashbord/index.html?embedded=true&hrmToken=${encodeURIComponent(testToken)}`;

  page2.on('console', msg => { if (msg.type() === 'error') console.log('[page2 error]', msg.text()); });

  await page2.goto(testUrl, { waitUntil: 'networkidle', timeout: 15000 });
  await page2.waitForTimeout(1500);

  // Check URL after load (should be cleaned)
  const currentUrl = page2.url();
  const hasHrmTokenInUrl = currentUrl.includes('hrmToken');
  console.log(`加载后 URL: ${currentUrl}`);
  console.log(`URL 残留 hrmToken: ${hasHrmTokenInUrl ? '❌ 是' : '✅ 否'}`);

  // Check localStorage
  const storedToken = await page2.evaluate(() => localStorage.getItem('token'));
  console.log(`localStorage token: ${storedToken ? '✅ 已存储' : '⚠️ 未存储'}`);

  results.push({ test: 'URL hrmToken 清理', result: !hasHrmTokenInUrl ? 'PASS' : 'FAIL' });
  results.push({ test: 'localStorage token 写入', result: storedToken ? 'PASS' : 'WARN' });

  // Test 3: Verify no JS runtime errors
  console.log('\n=== Test 3: 脚本错误检查 ===');
  const relevantErrors = errors.filter(e =>
    !e.includes('favicon') && !e.includes('layui')
  );
  console.log(`运行时错误: ${relevantErrors.length === 0 ? '✅ 无' : '⚠️ ' + relevantErrors.join('; ')}`);
  results.push({ test: '脚本运行时错误', result: relevantErrors.length === 0 ? 'PASS' : 'WARN' });

  // Test 4: Verify no infinite loop (reload detection)
  console.log('\n=== Test 4: 循环检测 ===');
  const navHistory = [];
  page2.on('framenavigated', frame => {
    if (frame === page2.mainFrame()) {
      navHistory.push(frame.url());
    }
  });

  // Wait to detect any re-navigations
  await page2.waitForTimeout(3000);

  const navCount = navHistory.length;
  console.log(`${navCount > 5 ? '❌' : '✅'} 3秒内导航次数: ${navCount} ${navCount > 5 ? '(循环!)' : '(正常)'}`);
  results.push({ test: '页面循环检测', result: navCount <= 5 ? 'PASS' : 'FAIL' });

  // Test 5: Verify hrm-proxy page loads embedded page correctly via 8095
  console.log('\n=== Test 5: 分路 8095 嵌入模式验证 ===');
  const page3 = await context.newPage();
  page3.on('console', msg => { if (msg.type() === 'error') console.log('[page3 error]', msg.text()); });

  // Access 8095 directly with embedded=true
  await page3.goto('http://localhost:8095/v2/views/dashbord/index.html?embedded=true&hrmToken=test-token-xyz', {
    waitUntil: 'networkidle', timeout: 15000
  });
  await page3.waitForTimeout(1000);

  const url3 = page3.url();
  console.log(`嵌入页面 URL 已清理: ${!url3.includes('hrmToken') ? '✅' : '❌'}`);
  results.push({ test: '嵌入模式 URL 清理', result: !url3.includes('hrmToken') ? 'PASS' : 'FAIL' });

  // Summary
  console.log('\n========================================');
  console.log('       测试结果汇总');
  console.log('========================================');
  const passCount = results.filter(r => r.result === 'PASS').length;
  const failCount = results.filter(r => r.result === 'FAIL').length;
  const warnCount = results.filter(r => r.result === 'WARN').length;
  results.forEach(r => {
    const icon = r.result === 'PASS' ? '✅' : r.result === 'FAIL' ? '❌' : '⚠️';
    console.log(`${icon} ${r.test}: ${r.result}`);
  });
  console.log(`\n总计: ${results.length} | 通过: ${passCount} | 失败: ${failCount} | 警告: ${warnCount}`);

  await browser.close();
  process.exit(failCount > 0 ? 1 : 0);
})();
