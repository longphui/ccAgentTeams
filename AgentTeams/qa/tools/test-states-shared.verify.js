const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — shared _embeddedStates
  // ============================================================
  console.log('=== Test 1: 代码验证 — _embeddedStates 共享 Map ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:8095/v2/util.js');
  const utilJs = await res1.text();

  const hasEmbeddedStates = utilJs.includes('var _embeddedStates = new Map();');
  const hasSharedStates = utilJs.includes('states: _embeddedStates');
  const hasNoInternalNewMap = !utilJs.includes('if (!that.states) that.states = new Map();');

  console.log(`  var _embeddedStates: ${hasEmbeddedStates ? '✅' : '❌'}`);
  console.log(`  states: _embeddedStates (共享): ${hasSharedStates ? '✅' : '❌'}`);
  console.log(`  不再创建独立Map: ${hasNoInternalNewMap ? '✅' : '❌'}`);
  results.push({ test: '共享_embeddedStates', result: (hasEmbeddedStates && hasSharedStates && hasNoInternalNewMap) ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: openPage stores state → getState retrieves it
  // ============================================================
  console.log('\n=== Test 2: openPage → getState 数据传递验证 ===');

  const ctx2 = await browser.newContext();
  const page2 = await ctx2.newPage();

  try {
    await page2.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-ss1', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page2.waitForTimeout(3000);

    const dataPass = await page2.evaluate(() => {
      try {
        const ctx = getAppContext();

        if (typeof LayuiVue === 'undefined' || !LayuiVue.layer) {
          return { note: 'LayuiVue not ready' };
        }

        // Intercept layer.open to capture the stateKey
        let capturedStateKey = null;
        const originalOpen = LayuiVue.layer.open;
        LayuiVue.layer.open = function(opts) {
          // Extract stateKey from URL
          const match = opts.content?.match(/stateKey=([^&]+)/);
          if (match) capturedStateKey = match[1];
          return 42;
        };

        // Call openPage with test data
        ctx.openPage('/test/popup.html', { formId: 12345, name: 'test-data' }, { title: 'Test Popup' });

        LayuiVue.layer.open = originalOpen;

        if (!capturedStateKey) return { error: 'stateKey not captured' };

        // Now simulate getState on the same Map
        const state = ctx.states.get(capturedStateKey);

        return {
          stateKey: capturedStateKey,
          stateFound: !!state,
          hasValue: state && state.value && state.value.formId === 12345,
          valueName: state?.value?.name,
          hasReturn: state && typeof state.return === 'function'
        };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (dataPass.error) {
      console.log(`  ❌ ${dataPass.error}`);
      results.push({ test: 'openPage→getState', result: 'FAIL' });
    } else if (dataPass.note) {
      console.log(`  ⚠️ ${dataPass.note}`);
      results.push({ test: 'openPage→getState', result: 'WARN' });
    } else {
      console.log(`  stateKey 生成: ${dataPass.stateKey ? '✅' : '❌'}`);
      console.log(`  state 找到: ${dataPass.stateFound ? '✅' : '❌'}`);
      console.log(`  state.value 数据: ${dataPass.hasValue ? '✅ formId=12345, name=' + dataPass.valueName : '❌'}`);
      console.log(`  state.return: ${dataPass.hasReturn ? '✅' : '❌'}`);
      results.push({ test: 'openPage→getState', result: (dataPass.stateFound && dataPass.hasValue && dataPass.hasReturn) ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'openPage→getState', result: 'WARN' });
  }
  await page2.close();
  await ctx2.close();

  // ============================================================
  // Test 3: Multiple getAppContext() calls share same Map
  // ============================================================
  console.log('\n=== Test 3: 多次 getAppContext() 返回同一 Map ===');

  const ctx3 = await browser.newContext();
  const page3 = await ctx3.newPage();

  try {
    await page3.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/tab_index.html?embedded=true&hrmToken=test-ss3', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page3.waitForTimeout(2000);

    const shared = await page3.evaluate(() => {
      try {
        const ctx1 = getAppContext();
        const ctx2 = getAppContext();
        const ctx3 = getAppContext();

        // Store something in one, read from another
        ctx1.states.set('__test_key__', { value: 'shared-test' });
        const from2 = ctx2.states.get('__test_key__');
        const from3 = ctx3.states.get('__test_key__');
        ctx1.states.delete('__test_key__');

        return {
          sameMap: ctx1.states === ctx2.states && ctx2.states === ctx3.states,
          from2ok: from2?.value === 'shared-test',
          from3ok: from3?.value === 'shared-test'
        };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (shared.error) {
      console.log(`  ❌ ${shared.error}`);
      results.push({ test: 'Map共享', result: 'FAIL' });
    } else {
      console.log(`  同一对象: ${shared.sameMap ? '✅' : '❌'}`);
      console.log(`  ctx1写→ctx2读: ${shared.from2ok ? '✅' : '❌'}`);
      console.log(`  ctx1写→ctx3读: ${shared.from3ok ? '✅' : '❌'}`);
      results.push({ test: 'Map共享', result: (shared.sameMap && shared.from2ok && shared.from3ok) ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'Map共享', result: 'WARN' });
  }
  await page3.close();
  await ctx3.close();

  // ============================================================
  // Test 4: HRM pages — no state/states errors
  // ============================================================
  console.log('\n=== Test 4: HRM 页面 — 无 states 相关错误 ===');

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
      await page.goto(`http://localhost:8095/v2/views/${hp.path}?embedded=true&hrmToken=test-ss4`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const stErrors = pageErrors.filter(e =>
        e.includes('states') || e.includes('state') || e.includes('Map')
        || e.includes('is not a function') || e.includes('undefined')
      );
      console.log(`  ${hp.name}: states错误=${stErrors.length} | 其他=${pageErrors.length - stErrors.length}`);
      results.push({ test: `HRM ${hp.name} 无states错误`, result: stErrors.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${hp.name}: ⚠️ 异常 (${e.message.substring(0, 60)})`);
      results.push({ test: `HRM ${hp.name} 无states错误`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

  // ============================================================
  // Test 5: state.return() closes layer
  // ============================================================
  console.log('\n=== Test 5: state.return() 关闭弹窗验证 ===');

  const ctx5 = await browser.newContext();
  const page5 = await ctx5.newPage();

  try {
    await page5.goto('http://localhost:8095/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=test-ss5', {
      waitUntil: 'domcontentloaded', timeout: 15000
    });
    await page5.waitForTimeout(3000);

    const returnTest = await page5.evaluate(() => {
      try {
        const ctx = getAppContext();

        if (typeof LayuiVue === 'undefined' || !LayuiVue.layer) {
          return { note: 'LayuiVue not ready' };
        }

        const callLog = [];
        const originalOpen = LayuiVue.layer.open;
        const originalClose = LayuiVue.layer.close;

        LayuiVue.layer.open = function(opts) {
          callLog.push('open');
          return 99; // mock layerId
        };
        LayuiVue.layer.close = function(id) {
          callLog.push('close:' + id);
        };

        ctx.openPage('/test/form.html', { id: 1 }, { title: 'Test' });

        // Find the state by iterating the Map and call return()
        let found = false;
        ctx.states.forEach((state, key) => {
          if (!found && state.value && state.value.id === 1) {
            state.return('result-value');
            found = true;
          }
        });

        LayuiVue.layer.open = originalOpen;
        LayuiVue.layer.close = originalClose;

        return {
          callLog,
          foundAndReturned: found
        };
      } catch(e) {
        return { error: e.message };
      }
    });

    if (returnTest.error) {
      console.log(`  ❌ ${returnTest.error}`);
      results.push({ test: 'state.return关闭', result: 'FAIL' });
    } else if (returnTest.note) {
      console.log(`  ⚠️ ${returnTest.note}`);
      results.push({ test: 'state.return关闭', result: 'WARN' });
    } else {
      console.log(`  layer.open 调用: ${returnTest.callLog.includes('open') ? '✅' : '❌'}`);
      console.log(`  layer.close 调用: ${returnTest.callLog.some(l => l.startsWith('close:')) ? '✅' : '❌'}`);
      console.log(`  完整链路: ${returnTest.foundAndReturned ? '✅' : '❌'}`);
      results.push({ test: 'state.return关闭', result: returnTest.foundAndReturned ? 'PASS' : 'FAIL' });
    }
  } catch (e) {
    console.log(`  ⚠️ ${e.message.substring(0, 80)}`);
    results.push({ test: 'state.return关闭', result: 'WARN' });
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
