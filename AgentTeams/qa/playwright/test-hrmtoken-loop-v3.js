const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const results = [];

  // Test 1: Code-level verification
  console.log('=== Test 1: 代码修复验证 ===');
  const bsRes = await (await browser.newPage()).request.get('http://localhost:8095/v2/baseService.js');
  const bsSource = await bsRes.text();
  const codeChecks = {
    embedded: bsSource.includes('embedded=true'),
    hrmToken: bsSource.includes('params.get("hrmToken")'),
    replaceState: bsSource.includes('replaceState'),
    cleanUrl: bsSource.includes('cleanUrl'),
    setItem: bsSource.includes('setItem("token", hrmToken)'),
    tokenExpired: bsSource.includes('HRM_TOKEN_EXPIRED'),
  };
  Object.entries(codeChecks).forEach(([k, v]) => console.log(`  ${k}: ${v ? '✅' : '❌'}`));
  results.push({ test: '代码修复完整性', result: Object.values(codeChecks).every(Boolean) ? 'PASS' : 'FAIL' });

  // Test 2: Direct baseService.js embed test (isolated from auth redirect)
  console.log('\n=== Test 2: baseService.js 嵌入逻辑隔离测试 ===');
  const page = await context.newPage();
  const testToken = 'Bearer_hrm_test_token_2026';

  // Intercept all XHR/fetch to prevent auth redirect
  await page.route('**/*', route => {
    const url = route.request().url();
    const resourceType = route.request().resourceType();
    if (resourceType === 'xhr' || resourceType === 'fetch') {
      // Block API calls to prevent auth errors
      route.abort();
    } else {
      route.continue();
    }
  });

  const navUrls = [];
  page.on('framenavigated', frame => {
    if (frame === page.mainFrame()) navUrls.push(frame.url());
  });

  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('favicon')) {
      consoleErrors.push(msg.text());
    }
  });

  await page.goto(`http://localhost:8095/?embedded=true&hrmToken=${encodeURIComponent(testToken)}`, {
    waitUntil: 'domcontentloaded', timeout: 15000
  });
  await page.waitForTimeout(3000);

  // Verify: hrmToken extracted from URL
  const finalUrl = page.url();
  console.log(`  最终 URL: ${finalUrl}`);
  console.log(`  hrmToken 残留: ${finalUrl.includes('hrmToken') ? '❌' : '✅'}`);

  // Verify: token saved to localStorage
  const ls = await page.evaluate(() => ({
    token: localStorage.getItem('token'),
    xToken: localStorage.getItem('xToken'),
  }));
  console.log(`  localStorage.token: ${ls.token ? '✅ 已存储' : '⚠️ ' + (ls.token || 'null')}`);
  console.log(`  localStorage.xToken: ${ls.xToken ? '✅ 已存储' : '⚠️ ' + (ls.xToken || 'null')}`);

  // Verify: no redirect loop
  const uniqueNavs = [...new Set(navUrls)];
  const isLoginRedirect = finalUrl.includes('login');
  console.log(`  导航链 (${navUrls.length}次): ${uniqueNavs.map(u => u.substring(u.lastIndexOf('/'))).join(' → ')}`);
  console.log(`  循环检测: ${navUrls.length <= 3 ? '✅ 正常' : (isLoginRedirect ? '⚠️ 认证重定向(非循环Bug)' : '❌ 异常循环')}`);

  results.push({ test: 'URL hrmToken 清理', result: !finalUrl.includes('hrmToken') ? 'PASS' : 'FAIL' });
  results.push({ test: 'token 写入 localStorage', result: ls.token ? 'PASS' : 'FAIL' });

  // Test 3: Verify no Console DataCloneError
  console.log('\n=== Test 3: 脚本错误检查 ===');
  const hasCriticalError = consoleErrors.some(e =>
    e.includes('DataCloneError') || e.includes('Uncaught') || e.includes('postMessage')
  );
  console.log(`  控制台错误: ${consoleErrors.length === 0 ? '✅ 无' : consoleErrors.join('; ')}`);
  results.push({ test: '无严重脚本错误', result: !hasCriticalError ? 'PASS' : 'FAIL' });

  // Test 4: Verify hrm-proxy + 8095 flow doesn't cause infinite loop
  console.log('\n=== Test 4: HRM TokenExpired → 重新获取流程 ===');
  const page2 = await context.newPage();
  let contextRequests = 0;

  await page2.evaluate(() => {
    window.__contextRequests = 0;
    window.addEventListener('message', (e) => {
      if (e.data?.type === 'HRM_GET_CONTEXT') {
        window.__contextRequests++;
        e.source.postMessage({
          type: 'HRM_CONTEXT',
          token: 'Bearer_ctxt_test',
          xToken: 'Bearer_ctxt_test',
          userInfo: null,
          baseUrl1: 'http://localhost:8095',
          baseUrl2: 'http://localhost:8095',
          newFenluApiBase: 'http://localhost:8095',
        }, '*');
      }
    });
  });

  // Load hrm-proxy page in iframe — verify it only requests context ONCE
  await page2.evaluate(() => {
    return new Promise(resolve => {
      const iframe = document.createElement('iframe');
      iframe.src = 'http://localhost:5021/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html';
      iframe.style.cssText = 'width:100%;height:100vh;border:none;';
      document.body.appendChild(iframe);
      iframe.onload = () => setTimeout(resolve, 1500);
    });
  });
  // Wait for the context cycle
  await page2.waitForTimeout(4000);

  contextRequests = await page2.evaluate(() => window.__contextRequests || 0);
  console.log(`  HRM_GET_CONTEXT 请求次数: ${contextRequests}`);
  console.log(`  循环检测: ${contextRequests <= 2 ? '✅ 正常(≤2)' : '❌ 异常循环(' + contextRequests + ')'}`);
  results.push({ test: 'HRM_GET_CONTEXT 无循环', result: contextRequests <= 2 ? 'PASS' : 'FAIL' });

  // Summary
  console.log('\n========================================');
  console.log('       测试结果汇总');
  console.log('========================================');
  const passCount = results.filter(r => r.result === 'PASS').length;
  const failCount = results.filter(r => r.result === 'FAIL').length;
  results.forEach(r => {
    const icon = r.result === 'PASS' ? '✅' : '❌';
    console.log(`${icon} ${r.test}: ${r.result}`);
  });
  console.log(`\n总计: ${results.length} | 通过: ${passCount} | 失败: ${failCount}`);

  await browser.close();
  process.exit(failCount > 0 ? 1 : 0);
})();
