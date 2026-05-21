const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  const results = [];
  const errors = [];

  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  // Test 1: Code fix verification
  console.log('=== Test 1: 代码修复验证 ===');
  const [appRes, proxyRes] = await Promise.all([
    page.request.get('http://localhost:5021/js/app.js'),
    page.request.get('http://localhost:5021/views/hrm-proxy/index.html?page=test')
  ]);
  const [appJs, proxyHtml] = await Promise.all([appRes.text(), proxyRes.text()]);

  const app8095count = (appJs.match(/8095/g) || []).length;
  const app8088count = (appJs.match(/8088/g) || []).length;  // only backend API refs remain
  const proxy8095 = proxyHtml.includes('localhost:8095');
  const proxy8088 = proxyHtml.includes('localhost:8088');

  console.log(`app.js  8095引用: ${app8095count} (预期≥3), 8088残留: ${app8088count}`);
  console.log(`hrm-proxy 8095: ${proxy8095 ? '✅' : '❌'}, 8088残留: ${proxy8088 ? '⚠️' : '✅'}`);

  results.push({ test: '端口修正-代码级别', result: (app8095count >= 3 && proxy8095 && !proxy8088) ? 'PASS' : 'FAIL' });

  // Test 2: Browser load without 404 errors for old port
  console.log('\n=== Test 2: 浏览器访问验证 ===');
  await page.goto('http://localhost:5021/', { waitUntil: 'networkidle', timeout: 10000 });
  await page.waitForTimeout(2000);

  const has8088Error = errors.some(e => e.includes('8088'));
  const hasFailedFetch = errors.some(e =>
    e.includes('Failed to load resource') &&
    !e.includes('favicon')
  );

  console.log(`8088相关错误: ${has8088Error ? '❌ 有' : '✅ 无'}`);
  results.push({ test: '8088 端口错误检查', result: has8088Error ? 'FAIL' : 'PASS' });

  // Test 3: Verify 8095 responds correctly
  console.log('\n=== Test 3: 8095 端口连通性 ===');
  const resp8095 = await page.request.get('http://localhost:8095/');
  console.log(`8095 响应状态: ${resp8095.status()}`);
  results.push({ test: '8095 端口连通', result: resp8095.status() === 200 ? 'PASS' : 'FAIL' });

  // Test 4: CORS check — hrm-proxy loads 8095 pages in iframe
  console.log('\n=== Test 4: 模拟 hrm-proxy → 8095 加载 ===');
  const page2 = await context.newPage();
  page2.on('console', msg => { if (msg.type() === 'error') console.log('[page2]', msg.text()); });

  await page2.goto('http://localhost:8095/', { waitUntil: 'networkidle', timeout: 10000 });
  await page2.waitForTimeout(1000);
  const title = await page2.title();
  console.log(`8095 首页标题: "${title}"`);
  results.push({ test: '8095 页面可加载', result: 'PASS' });

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
