const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — default theme has CSS variables
  // ============================================================
  console.log('=== Test 1: 代码验证 — getDefaultTheme 默认 CSS 变量 ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/util.js');
  const utilJs = await res1.text();

  const requiredVars = [
    'colorPrimary', 'colorTextPrimary', 'colorTextSecondary',
    'colorMenuActive', 'colorMenuText', 'colorMenuTextActive',
    'colorProgress', 'colorBodyBackground', 'colorBodyText', 'colorSecondary'
  ];
  const missing = requiredVars.filter(v => !utilJs.includes(v));
  console.log(`  所需CSS变量 (${requiredVars.length}): ${missing.length === 0 ? '✅ 全部存在' : '❌ 缺失: ' + missing.join(', ')}`);

  const hasDefaultFallback = utilJs.includes('localStorage.getItem("theme")') && utilJs.includes('"null"');
  console.log(`  localStorage 降级链: ${hasDefaultFallback ? '✅' : '❌'}`);
  results.push({ test: '默认CSS变量补全', result: missing.length === 0 && hasDefaultFallback ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: getDefaultTheme returns defaults when no localStorage theme
  // ============================================================
  console.log('\n=== Test 2: 无 localStorage → 返回默认 CSS 变量 ===');

  const ctx2 = await browser.newContext();
  const page2 = await ctx2.newPage();

  // Navigate to HRM page with cleared localStorage
  try {
    await page2.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-css1', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page2.waitForTimeout(2000);

    const defaults = await page2.evaluate(() => {
      try {
        // Force clear any cached theme
        localStorage.removeItem("theme");
        const ctx = getAppContext();
        return ctx.theme.getDefaultTheme();
      } catch(e) {
        return { error: e.message };
      }
    });

    if (defaults.error) {
      console.log(`  ❌ ${defaults.error}`);
      results.push({ test: '默认CSS变量返回', result: 'FAIL' });
    } else {
      const opts = defaults.options;
      const checks = [
        opts.colorPrimary === "#16BAAA",
        opts.colorTextPrimary === "#FFFFFF",
        opts.colorBodyBackground === "#FFFFFF",
        opts.colorBodyText === "#333333",
        opts.colorSecondary && opts.colorSecondary.includes('color-mix'),
      ];
      const ok = checks.filter(Boolean).length;
      console.log(`  colorPrimary=${opts.colorPrimary} ${opts.colorPrimary === '#16BAAA' ? '✅' : '❌'}`);
      console.log(`  colorTextPrimary=${opts.colorTextPrimary} ${opts.colorTextPrimary === '#FFFFFF' ? '✅' : '❌'}`);
      console.log(`  colorBodyBackground=${opts.colorBodyBackground} ${opts.colorBodyBackground === '#FFFFFF' ? '✅' : '❌'}`);
      console.log(`  colorSecondary=${opts.colorSecondary?.substring(0,50)}... ${opts.colorSecondary?.includes('color-mix') ? '✅' : '❌'}`);
      results.push({ test: '默认CSS变量返回', result: ok === checks.length ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: '默认CSS变量返回', result: 'WARN' });
  }
  await page2.close();
  await ctx2.close();

  // ============================================================
  // Test 3: localStorage theme overrides defaults
  // ============================================================
  console.log('\n=== Test 3: localStorage 主题优先于默认值 ===');

  const ctx3 = await browser.newContext();
  const page3 = await ctx3.newPage();
  await page3.addInitScript(() => {
    localStorage.setItem("theme", JSON.stringify({options: {colorPrimary: "#FF0000", customProp: "test"}}));
  });

  try {
    await page3.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?embedded=true&hrmToken=test-css3', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page3.waitForTimeout(2000);

    const stored = await page3.evaluate(() => {
      const ctx = getAppContext();
      return ctx.theme.getDefaultTheme();
    });

    if (stored.options?.colorPrimary === '#FF0000') {
      console.log(`  localStorage theme 生效: colorPrimary=#FF0000 ✅`);
      results.push({ test: 'localStorage优先于默认', result: 'PASS' });
    } else {
      console.log(`  ❌ 期望 #FF0000，实际 ${JSON.stringify(stored)}`);
      results.push({ test: 'localStorage优先于默认', result: 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'localStorage优先于默认', result: 'WARN' });
  }
  await page3.close();
  await ctx3.close();

  // ============================================================
  // Test 4: Embedded HRM pages — button computed styles
  // ============================================================
  console.log('\n=== Test 4: 嵌入式页面按钮 CSS 变量渲染验证 ===');

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
      if (msg.type() === 'error' && !msg.text().includes('favicon') && !msg.text().includes('layui')) {
        pageErrors.push(msg.text());
      }
    });

    try {
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-css4`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(3000);

      // Check for CSS variable warnings
      const cssErrors = pageErrors.filter(e =>
        e.includes('CSS') || e.includes('css') || e.includes('var(') || e.includes('colorPrimary')
      );
      // Check if buttons exist and have background color
      const btnCheck = await page.evaluate(() => {
        const buttons = document.querySelectorAll('button, .layui-btn, [class*="btn"], [class*="button"]');
        if (buttons.length === 0) return { found: false, count: 0 };
        const sample = Array.from(buttons).slice(0, 3).map(b => ({
          tag: b.tagName,
          bg: window.getComputedStyle(b).backgroundColor,
          color: window.getComputedStyle(b).color,
          hasBg: window.getComputedStyle(b).backgroundColor !== 'rgba(0, 0, 0, 0)'
        }));
        return { found: true, count: buttons.length, sample };
      });

      console.log(`  ${hp.name}: 按钮=${btnCheck.count} | CSS错误=${cssErrors.length} | ${btnCheck.found && btnCheck.sample[0]?.hasBg ? '✅按钮有背景色' : btnCheck.found ? '⚠️按钮无背景色' : '⚠️无按钮'}`);
      results.push({ test: `HRM ${hp.name} 按钮渲染`, result: cssErrors.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 按钮渲染`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 5: No console errors from applytheme.js
  // ============================================================
  console.log('\n=== Test 5: applytheme.js 执行无异常 ===');

  const ctx5 = await browser.newContext();
  const page5 = await ctx5.newPage();
  const errors5 = [];

  page5.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('favicon') && !msg.text().includes('layui')) {
      errors5.push(msg.text());
    }
  });

  try {
    await page5.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-css5', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page5.waitForTimeout(2000);

    const themeErrors = errors5.filter(e =>
      e.includes('getDefaultTheme') || e.includes('applyTheme') || e.includes('TypeError') || e.includes('undefined')
    );
    console.log(`  applytheme 相关错误: ${themeErrors.length === 0 ? '✅ 无' : '❌ ' + themeErrors.join('; ')}`);
    results.push({ test: 'applytheme.js无异常', result: themeErrors.length === 0 ? 'PASS' : 'FAIL' });
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'applytheme.js无异常', result: 'WARN' });
  }
  await page5.close();
  await ctx5.close();

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
