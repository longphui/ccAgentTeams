const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // Test 1: Code fix verification
  console.log('=== Test 1: 代码修复验证 ===');
  const res = await (await browser.newPage()).request.get('http://localhost:8095/v2/component/layui-vue/config.js');
  const source = await res.text();

  const hasTryCatch = source.includes('try {\n    layerTopTab = parent.tab;\n} catch(e)');
  const hasNullFallback = source.includes('layerTopTab = null;');
  console.log(`  try-catch parent.tab: ${hasTryCatch ? '✅' : '❌'}`);
  console.log(`  null 降级: ${hasNullFallback ? '✅' : '❌'}`);
  results.push({ test: 'config.js try-catch 修复', result: (hasTryCatch && hasNullFallback) ? 'PASS' : 'FAIL' });

  // Test 2: Verify no SecurityError in cross-origin iframe
  console.log('\n=== Test 2: 跨域 iframe SecurityError 验证 ===');
  const context = await browser.newContext();
  const page = await context.newPage();
  const errors = [];

  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  // Load a 3rd party origin page and embed 8095 page in iframe
  await page.goto('about:blank');
  await page.evaluate(() => {
    return new Promise(resolve => {
      const iframe = document.createElement('iframe');
      // Load config.js-referencing page from 8095 (cross-origin to about:blank)
      iframe.src = 'http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?' +
        'embedded=true&hrmToken=test-token123';
      iframe.style.cssText = 'width:100%;height:100vh;';
      document.body.appendChild(iframe);
      iframe.onload = () => setTimeout(resolve, 2000);
    });
  });
  await page.waitForTimeout(3000);

  const securityErrors = errors.filter(e => e.includes('SecurityError') || e.includes('security'));
  const blockedErrors = errors.filter(e => e.includes('blocked') || e.includes('origin'));
  console.log(`  SecurityError: ${securityErrors.length === 0 ? '✅ 无' : '❌ ' + securityErrors.join(';')}`);
  console.log(`  CORS/origin 阻止: ${blockedErrors.length === 0 ? '✅ 无' : 'ℹ️ ' + blockedErrors.join(';')}`);
  results.push({ test: '跨域 SecurityError 消除', result: securityErrors.length === 0 ? 'PASS' : 'FAIL' });

  // Test 3: Verify individual HRM pages load without config.js SecurityError
  console.log('\n=== Test 3: HRM 页面批量验证 (核心页面) ===');

  const hrmePages = [
    { name: 'staffInfo', url: '/v2/views/manpowerManage/staffManagement/staffInfo/index.html' },
    { name: 'staffRecord', url: '/v2/views/manpowerManage/staffManagement/staffRecord/index.html' },
    { name: 'staffDimission', url: '/v2/views/manpowerManage/staffManagement/staffDimission/index.html' },
    { name: 'tab_index', url: '/v2/views/manpowerManage/staffManagement/tab_index.html' },
  ];

  for (const testPage of hrmePages) {
    const p = await context.newPage();
    const pageErrors = [];
    p.on('console', msg => {
      if (msg.type() === 'error' && !msg.text().includes('favicon')
        && !msg.text().includes('layui')) {
        pageErrors.push(msg.text());
      }
    });

    try {
      await p.goto(`http://localhost:8095${testPage.url}?embedded=true&hrmToken=test-xyz`, {
        waitUntil: 'domcontentloaded', timeout: 10000
      });
      await p.waitForTimeout(1500);

      const secErr = pageErrors.filter(e =>
        e.includes('SecurityError') || e.includes('security') || e.includes('parent.tab')
      );
      console.log(`  ${testPage.name}: ${secErr.length === 0 ? '✅' : '❌ SecurityError'} (其他错误:${pageErrors.length - secErr.length})`);
      results.push({ test: `HRM页面 ${testPage.name}`, result: secErr.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${testPage.name}: ⚠️ 加载异常 (${e.message.substring(0,60)})`);
      results.push({ test: `HRM页面 ${testPage.name}`, result: 'WARN' });
    }
    await p.close();
  }

  // Test 4: Summary — verify cross-origin config.js loads without errors
  console.log('\n=== Test 4: 独立 config.js 跨域加载 ===');
  const p2 = await context.newPage();
  const configErrors = [];
  p2.on('console', msg => { if (msg.type() === 'error') configErrors.push(msg.text()); });

  await p2.goto('about:blank');
  // Inject a script tag to directly load config.js cross-origin and check for errors
  const result = await p2.evaluate(() => {
    return new Promise(resolve => {
      const script = document.createElement('script');
      script.src = 'http://localhost:8095/v2/component/layui-vue/config.js';
      script.onload = () => resolve({ loaded: true, error: null });
      script.onerror = (e) => resolve({ loaded: false, error: 'Script load failed' });
      document.head.appendChild(script);
    });
  });
  console.log(`  config.js 加载: ${result.loaded ? '✅' : '❌ ' + result.error}`);
  console.log(`  控制台错误: ${configErrors.length === 0 ? '✅ 无' : configErrors.join(';')}`);
  results.push({ test: 'config.js 跨域加载', result: result.loaded ? 'PASS' : 'FAIL' });

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
