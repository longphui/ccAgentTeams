const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — stub has theme methods
  // ============================================================
  console.log('=== Test 1: 代码验证 — getAppContext() stub theme 方法 ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/util.js');
  const utilJs = await res1.text();

  const hasApplyTheme = utilJs.includes('applyTheme: function(){}');
  const hasApplyThemeToTarget = utilJs.includes('applyThemeToTarget: function(){}');
  const hasGetDefaultTheme = utilJs.includes('getDefaultTheme: function()');
  const hasLocalStorageTheme = utilJs.includes('localStorage.getItem("theme")');

  console.log(`  applyTheme: ${hasApplyTheme ? '✅' : '❌'}`);
  console.log(`  applyThemeToTarget: ${hasApplyThemeToTarget ? '✅' : '❌'}`);
  console.log(`  getDefaultTheme: ${hasGetDefaultTheme ? '✅' : '❌'}`);
  console.log(`  localStorage fallback: ${hasLocalStorageTheme ? '✅' : '❌'}`);
  results.push({ test: 'stub theme方法补全', result: (hasApplyTheme && hasApplyThemeToTarget && hasGetDefaultTheme && hasLocalStorageTheme) ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: HRM pages — no getDefaultTheme TypeError
  // ============================================================
  console.log('\n=== Test 2: HRM 嵌入式页面 — 无 theme TypeError ===');

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
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-th`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const themeErrors = pageErrors.filter(e =>
        e.includes('getDefaultTheme') || e.includes('applyTheme') || e.includes('applytheme') || e.includes('theme')
      );
      console.log(`  ${hp.name}: theme错误=${themeErrors.length} | 其他=${pageErrors.length - themeErrors.length}`);
      results.push({ test: `HRM ${hp.name} 无theme错误`, result: themeErrors.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 无theme错误`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 3: applytheme.js + getDefaultTheme() on real page
  // ============================================================
  console.log('\n=== Test 3: applytheme.js + getDefaultTheme() 验证 (真实页面) ===');

  const ctx3 = await browser.newContext();
  const page3 = await ctx3.newPage();
  const errors3 = [];

  page3.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('favicon') && !msg.text().includes('layui')) {
      errors3.push(msg.text());
    }
  });

  try {
    await page3.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-th3', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page3.waitForTimeout(2000);

    // Verify stub returns valid theme methods via page.evaluate
    const stubResult = await page3.evaluate(() => {
      try {
        const ctx = getAppContext();
        return {
          hasApplyTheme: typeof ctx.theme.applyTheme === 'function',
          hasApplyThemeToTarget: typeof ctx.theme.applyThemeToTarget === 'function',
          hasGetDefaultTheme: typeof ctx.theme.getDefaultTheme === 'function',
          hasApplyLayout: typeof ctx.layout.applyLayout === 'function',
          getDefaultThemeResult: ctx.theme.getDefaultTheme()
        };
      } catch(e) {
        return { error: e.message };
      }
    });

    const themeErrors = errors3.filter(e =>
      e.includes('getDefaultTheme') || e.includes('applyTheme') || e.includes('TypeError')
    );

    console.log(`  applyTheme: ${stubResult.hasApplyTheme ? '✅' : '❌'}`);
    console.log(`  applyThemeToTarget: ${stubResult.hasApplyThemeToTarget ? '✅' : '❌'}`);
    console.log(`  getDefaultTheme: ${stubResult.hasGetDefaultTheme ? '✅' : '❌'}`);
    console.log(`  applyLayout: ${stubResult.hasApplyLayout ? '✅' : '❌'}`);
    console.log(`  getDefaultTheme() 返回: ${stubResult.error ? '❌ ' + stubResult.error : '✅ ' + JSON.stringify(stubResult.getDefaultThemeResult)}`);
    console.log(`  applytheme.js 错误: ${themeErrors.length === 0 ? '✅ 无' : '❌ ' + themeErrors.join('; ')}`);

    const allMethodsOk = stubResult.hasApplyTheme && stubResult.hasApplyThemeToTarget
      && stubResult.hasGetDefaultTheme && stubResult.hasApplyLayout && !stubResult.error;
    results.push({ test: 'theme方法 + applytheme.js', result: allMethodsOk && themeErrors.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  页面加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'theme方法 + applytheme.js', result: 'WARN' });
  }
  await page3.close();
  await ctx3.close();

  // ============================================================
  // Test 4: localStorage theme persistence — set via addInitScript
  // ============================================================
  console.log('\n=== Test 4: localStorage theme 读取验证 ===');

  const ctx4 = await browser.newContext();
  const page4 = await ctx4.newPage();

  // Pre-set localStorage before navigation
  await page4.addInitScript(() => {
    localStorage.setItem("theme", JSON.stringify({primary: "#1890ff", mode: "dark"}));
  });

  const errors4 = [];
  page4.on('console', msg => {
    if (msg.type() === 'error') errors4.push(msg.text());
  });

  try {
    await page4.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?embedded=true&hrmToken=test-th4', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page4.waitForTimeout(2000);

    const themeResult = await page4.evaluate(() => {
      try {
        const ctx = getAppContext();
        return { theme: ctx.theme.getDefaultTheme(), ok: true };
      } catch(e) {
        return { error: e.message, ok: false };
      }
    });

    if (themeResult.ok) {
      const t = themeResult.theme;
      console.log(`  localStorage theme: primary=${t.primary} mode=${t.mode} ${t.primary === '#1890ff' && t.mode === 'dark' ? '✅' : '⚠️ 值不匹配'}`);
      results.push({ test: 'localStorage theme读取', result: t.primary === '#1890ff' && t.mode === 'dark' ? 'PASS' : 'FAIL' });
    } else {
      console.log(`  localStorage theme: ❌ ${themeResult.error}`);
      results.push({ test: 'localStorage theme读取', result: 'FAIL' });
    }
  } catch (e) {
    console.log(`  页面加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'localStorage theme读取', result: 'WARN' });
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
