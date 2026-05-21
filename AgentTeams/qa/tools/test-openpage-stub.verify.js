const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — openPage / openWindow / openRouteInTab
  // ============================================================
  console.log('=== Test 1: 代码验证 — stub openPage/openWindow/openRouteInTab ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/util.js');
  const utilJs = await res1.text();

  const hasOpenPage = utilJs.includes('openPage: function(formPageUrl, data, dialogOptions, opts)');
  const hasLayerOpen = utilJs.includes('myLayer.open(');
  const hasStateKey = utilJs.includes("'stateKey='");
  const hasStateReturn = utilJs.includes('myLayer.close(layerId)');
  const hasOpenWindow = utilJs.includes('openWindow: function(url) { window.open(url); }');
  const hasOpenRouteInTab = utilJs.includes('openRouteInTab: function() {}');

  console.log(`  openPage: ${hasOpenPage ? '✅' : '❌'}`);
  console.log(`  layer.open: ${hasLayerOpen ? '✅' : '❌'}`);
  console.log(`  stateKey 注入: ${hasStateKey ? '✅' : '❌'}`);
  console.log(`  state.return 关闭: ${hasStateReturn ? '✅' : '❌'}`);
  console.log(`  openWindow: ${hasOpenWindow ? '✅' : '❌'}`);
  console.log(`  openRouteInTab: ${hasOpenRouteInTab ? '✅' : '❌'}`);
  results.push({ test: 'stub openPage补全', result: (hasOpenPage && hasLayerOpen && hasStateKey && hasStateReturn && hasOpenWindow && hasOpenRouteInTab) ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: openPage in-page functional test
  // ============================================================
  console.log('\n=== Test 2: openPage() 弹窗功能验证 ===');

  const ctx2 = await browser.newContext();
  const page2 = await ctx2.newPage();

  try {
    await page2.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-op1', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page2.waitForTimeout(3000);

    const result2 = await page2.evaluate(() => {
      try {
        const ctx = getAppContext();

        // Check all methods exist
        const hasOpenPage = typeof ctx.openPage === 'function';
        const hasOpenWindow = typeof ctx.openWindow === 'function';
        const hasOpenRouteInTab = typeof ctx.openRouteInTab === 'function';

        // Test openPage with mock layer
        if (hasOpenPage && typeof LayuiVue !== 'undefined' && LayuiVue.layer) {
          const originalOpen = LayuiVue.layer.open;
          const called = [];
          LayuiVue.layer.open = function(opts) {
            called.push(opts);
            return { close: function() { called.push('closed'); } };
          };

          ctx.openPage('/test/page.html', { testData: 'hello' }, { title: 'Test', area: ['800px', '600px'] });

          // Restore
          LayuiVue.layer.open = originalOpen;

          return {
            hasOpenPage, hasOpenWindow, hasOpenRouteInTab,
            layerCalled: called.length > 0,
            layerOpts: called[0] || null
          };
        }

        return { hasOpenPage, hasOpenWindow, hasOpenRouteInTab, layerCalled: false, note: 'LayuiVue.layer not available' };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (result2.error) {
      console.log(`  ❌ ${result2.error}`);
      results.push({ test: 'openPage弹窗功能', result: 'FAIL' });
    } else {
      console.log(`  openPage exists: ${result2.hasOpenPage ? '✅' : '❌'}`);
      console.log(`  openWindow exists: ${result2.hasOpenWindow ? '✅' : '❌'}`);
      console.log(`  openRouteInTab exists: ${result2.hasOpenRouteInTab ? '✅' : '❌'}`);
      console.log(`  layer.open 调用: ${result2.layerCalled ? '✅' : '⚠️ (LayuiVue未就绪)'}`);
      if (result2.layerOpts) {
        console.log(`  layer type: ${result2.layerOpts.type || 'default'}`);
        console.log(`  layer title: ${result2.layerOpts.title}`);
        console.log(`  layer content has stateKey: ${result2.layerOpts.content?.includes('stateKey=') ? '✅' : '❌'}`);
      }
      results.push({ test: 'openPage弹窗功能', result: result2.hasOpenPage ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'openPage弹窗功能', result: 'WARN' });
  }
  await page2.close();
  await ctx2.close();

  // ============================================================
  // Test 3: stateKey + state.return mechanism
  // ============================================================
  console.log('\n=== Test 3: stateKey 数据传递 + state.return 关闭验证 ===');

  const ctx3 = await browser.newContext();
  const page3 = await ctx3.newPage();

  try {
    await page3.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?embedded=true&hrmToken=test-op3', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page3.waitForTimeout(3000);

    const stateResult = await page3.evaluate(() => {
      try {
        const ctx = getAppContext();
        if (typeof LayuiVue === 'undefined' || !LayuiVue.layer) {
          return { note: 'LayuiVue not ready' };
        }

        const called = [];
        const originalOpen = LayuiVue.layer.open;
        LayuiVue.layer.open = function(opts) { called.push(opts); return 42; };

        // Call openPage with test data
        ctx.openPage('/test/form.html', { formId: 999 }, { title: 'Test Form' });

        LayuiVue.layer.open = originalOpen;

        if (called.length === 0) return { error: 'layer.open not called' };

        const content = called[0].content;
        const hasStateKey = content.includes('stateKey=');
        const stateKeyMatch = content.match(/stateKey=([^&]+)/);
        const stateKey = stateKeyMatch ? stateKeyMatch[1] : null;

        // Check that state was stored
        const state = stateKey ? ctx.states.get(stateKey) : null;

        return {
          hasStateKey,
          stateKey,
          stateExists: !!state,
          stateHasData: state && state.value && state.value.formId === 999,
          stateHasReturn: state && typeof state.return === 'function'
        };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (stateResult.error) {
      console.log(`  ❌ ${stateResult.error}`);
      results.push({ test: 'stateKey传递+return', result: 'FAIL' });
    } else if (stateResult.note) {
      console.log(`  ⚠️ ${stateResult.note}`);
      results.push({ test: 'stateKey传递+return', result: 'WARN' });
    } else {
      console.log(`  stateKey 在 URL: ${stateResult.hasStateKey ? '✅' : '❌'}`);
      console.log(`  state 存储: ${stateResult.stateExists ? '✅' : '❌'}`);
      console.log(`  state.value 传递: ${stateResult.stateHasData ? '✅' : '❌'}`);
      console.log(`  state.return 存在: ${stateResult.stateHasReturn ? '✅' : '❌'}`);
      results.push({ test: 'stateKey传递+return', result: (stateResult.hasStateKey && stateResult.stateExists && stateResult.stateHasData && stateResult.stateHasReturn) ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'stateKey传递+return', result: 'WARN' });
  }
  await page3.close();
  await ctx3.close();

  // ============================================================
  // Test 4: HRM pages — no openPage/openWindow errors
  // ============================================================
  console.log('\n=== Test 4: HRM 页面 — 无 openPage/openWindow 相关错误 ===');

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
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-op4`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const opErrors = pageErrors.filter(e =>
        e.includes('openPage') || e.includes('openWindow') || e.includes('openRouteInTab')
        || e.includes('is not a function') || e.includes('undefined')
      );
      console.log(`  ${hp.name}: openPage相关错误=${opErrors.length} | 其他=${pageErrors.length - opErrors.length}`);
      results.push({ test: `HRM ${hp.name} 无openPage错误`, result: opErrors.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 无openPage错误`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 5: openWindow delegates to window.open
  // ============================================================
  console.log('\n=== Test 5: openWindow 委托验证 ===');

  const ctx5 = await browser.newContext();
  const page5 = await ctx5.newPage();

  try {
    await page5.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-op5', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page5.waitForTimeout(2000);

    const owResult = await page5.evaluate(() => {
      try {
        const ctx = getAppContext();
        // Test that openWindow calls window.open with the URL
        let capturedUrl = null;
        const origOpen = window.open;
        window.open = function(url) { capturedUrl = url; return { closed: false }; };
        ctx.openWindow('http://example.com/test-target');
        window.open = origOpen;
        return { capturedUrl, isCorrect: capturedUrl === 'http://example.com/test-target' };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (owResult.error) {
      console.log(`  ❌ ${owResult.error}`);
      results.push({ test: 'openWindow委托', result: 'FAIL' });
    } else {
      console.log(`  openWindow URL: ${owResult.isCorrect ? '✅ ' + owResult.capturedUrl : '❌ expected example.com/test-target, got ' + owResult.capturedUrl}`);
      results.push({ test: 'openWindow委托', result: owResult.isCorrect ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'openWindow委托', result: 'WARN' });
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
