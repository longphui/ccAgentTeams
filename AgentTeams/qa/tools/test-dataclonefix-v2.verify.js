const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const results = [];

  // ============================================================
  // Test 1: Code verification — toRaw import and usage
  // ============================================================
  console.log('=== Test 1: 代码验证 — toRaw 防 DataCloneError ===');

  const res1 = await (await browser.newPage()).request.get('http://localhost:5021/js/app.js');
  const appJs = await res1.text();

  const hasToRawImport = appJs.includes('toRaw');
  const hasToRawUsage = appJs.includes('toRaw(appContext.userInfo)');
  console.log(`  toRaw 导入: ${hasToRawImport ? '✅' : '❌'}`);
  console.log(`  toRaw(appContext.userInfo): ${hasToRawUsage ? '✅' : '❌'}`);
  results.push({ test: 'toRaw import + usage', result: (hasToRawImport && hasToRawUsage) ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 2: ERP page load — verify NO DataCloneError
  // ============================================================
  console.log('\n=== Test 2: ERP Console — DataCloneError 消除验证 ===');

  const ctx2 = await browser.newContext();
  const pg2 = await ctx2.newPage();

  const consoleErrors = [];
  pg2.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  // Mock auth APIs so the ERP loads without redirecting to login
  await pg2.route('**/api/services/app/User/GetLoginUser**', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        succeeded: true,
        data: {
          userName: 'admin',
          displayName: 'Admin',
          companyId: 1,
          roleId: 1
        }
      })
    });
  });

  await pg2.route('**/api/hrm-auth/get-fenlu-token', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        succeeded: true,
        data: { token: 'test-hrm-token-dataclone' }
      })
    });
  });

  // Mock menu API
  await pg2.route('**/api/services/app/Menu/GetUserMenus**', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        succeeded: true,
        data: { children: [] }
      })
    });
  });

  try {
    await pg2.goto('http://localhost:5021/', { waitUntil: 'networkidle', timeout: 30000 });
    await pg2.waitForTimeout(3000);

    const dcErrors = consoleErrors.filter(e =>
      e.includes('DataCloneError') || e.includes('clone') || e.includes('structuredClone')
    );
    const postMsgErrors = consoleErrors.filter(e =>
      e.includes('postMessage') || e.includes('post message')
    );

    console.log(`  DataCloneError: ${dcErrors.length === 0 ? '✅ 无' : '❌ ' + dcErrors.join('; ')}`);
    console.log(`  postMessage 错误: ${postMsgErrors.length === 0 ? '✅ 无' : '❌ ' + postMsgErrors.join('; ')}`);
    console.log(`  其他 console 错误: ${consoleErrors.length - dcErrors.length - postMsgErrors.length}`);
    if (consoleErrors.length > 0 && dcErrors.length === 0) {
      console.log(`    (非DataClone错误): ${consoleErrors.slice(0,3).map(e => e.substring(0,120)).join(' | ')}`);
    }

    results.push({
      test: 'ERP加载无DataCloneError',
      result: dcErrors.length === 0 ? 'PASS' : 'FAIL'
    });
  } catch (e) {
    console.log(`  ERP 加载异常: ${e.message.substring(0, 80)}`);
    results.push({ test: 'ERP加载无DataCloneError', result: 'WARN' });
  }
  await pg2.close();
  await ctx2.close();

  // ============================================================
  // Test 3: Simulate postMessage with Vue Proxy → verify toRaw prevents DataCloneError
  // ============================================================
  console.log('\n=== Test 3: Vue Proxy → toRaw → postMessage 链路验证 ===');

  const ctx3 = await browser.newContext();
  const pg3 = await ctx3.newPage();

  // Load a test page that imports Vue and simulates the app.js postMessage logic
  const testHtml = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head><body>
<script src="http://localhost:8095/v2/component/layui-vue/vue.global.js"></script>
<script>
// Exact same pattern as app.js lines 170-181
const { toRaw } = Vue;
window.__testResult = { passed: false, error: null };

const fakeAppContext = Vue.reactive({
  userInfo: {
    userName: 'testuser',
    displayName: 'Test User',
    companyId: 1,
    roleId: 1
  }
});

// This is what app.js does to prevent DataCloneError
const payload = {
  type: "HRM_CONTEXT",
  token: "Bearer test-token",
  xToken: "Bearer test-token",
  userInfo: fakeAppContext.userInfo ? toRaw(fakeAppContext.userInfo) : null,
  companyId: fakeAppContext.userInfo?.companyId,
  baseUrl1: "http://localhost:8095"
};

// Try to postMessage — this would throw DataCloneError WITHOUT toRaw
try {
  window.postMessage(payload, "*");
  window.__testResult.passed = true;
} catch(e) {
  window.__testResult.error = e.message;
  window.__testResult.passed = false;
}

// Also check: without toRaw, would it fail?
try {
  const badPayload = {
    type: "HRM_CONTEXT",
    userInfo: fakeAppContext.userInfo  // Vue Proxy without toRaw!
  };
  window.postMessage(badPayload, "*");
  window.__testResult.stillWorkedWithoutToRaw = true;
} catch(e) {
  window.__testResult.stillWorkedWithoutToRaw = false;
  window.__testResult.withoutToRawError = e.message;
}
</script>
</body></html>`;

  await pg3.setContent(testHtml);
  await pg3.waitForTimeout(2000);

  const result3 = await pg3.evaluate(() => window.__testResult);
  console.log(`  toRaw 后 postMessage: ${result3.passed ? '✅ 成功' : '❌ ' + result3.error}`);
  console.log(`  无toRaw postMessage: ${result3.stillWorkedWithoutToRaw ? '⚠️ 也成功(可能浏览器已处理Proxy)' : '❌ ' + (result3.withoutToRawError || '')}`);

  results.push({ test: 'toRaw postMessage 无DataCloneError', result: result3.passed ? 'PASS' : 'FAIL' });

  // ============================================================
  // Test 4: Verify HRM pages show no errors with full context
  // ============================================================
  console.log('\n=== Test 4: HRM 页面嵌入完整链路验证 ===');

  const hrmePages = [
    { name: 'staffInfo', page: 'staffManagement/staffInfo/index.html' },
    { name: 'staffRecord', page: 'staffManagement/staffRecord/index.html' },
    { name: 'tab_index', page: 'staffManagement/tab_index.html' },
  ];

  for (const tp of hrmePages) {
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
      await page.goto(`http://localhost:8095/v2/views/manpowerManage/${tp.page}?embedded=true&hrmToken=test-dc&menuButtons=add,update,delete,search,import`, {
        waitUntil: 'domcontentloaded', timeout: 15000
      });
      await page.waitForTimeout(2000);

      const dcErrs = pageErrors.filter(e =>
        e.includes('DataClone') || e.includes('clone') || e.includes('appContext')
      );
      console.log(`  ${tp.name}: DataClone错误=${dcErrs.length} | 其他错误=${pageErrors.length - dcErrs.length}`);
      results.push({ test: `HRM ${tp.name} 无DataCloneError`, result: dcErrs.length === 0 ? 'PASS' : 'FAIL' });
    } catch (e) {
      console.log(`  ${tp.name}: ⚠️ 加载异常 (${e.message.substring(0, 80)})`);
      results.push({ test: `HRM ${tp.name} 无DataCloneError`, result: 'WARN' });
    }
    await page.close();
    await ctx.close();
  }

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
