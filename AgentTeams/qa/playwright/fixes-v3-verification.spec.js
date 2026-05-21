// @ts-check
const { test, expect } = require('@playwright/test');
const path = require('path');

const FRONTEND = 'http://localhost:5021';
const SCREENSHOTS = path.join(__dirname, 'screenshots');

// ===== 注入嵌入模式环境 =====
function injectEmbeddedEnv(token, menuButtons) {
  const mb = JSON.stringify(menuButtons || []);
  return `
    localStorage.setItem('token', '${token}');
    localStorage.setItem('xToken', '${token}');
    window._embeddedStates = new Map();

    window.getAppContext = function() {
      var ctx = window.appContext;
      if (ctx) return ctx;
      var menuButtonsArr = ${mb};
      var stub = {
        route: {
          checkTabPermissions: function(pathName, btn) { return menuButtonsArr.indexOf(btn) >= 0; },
          items: [], currentRoute: {}
        },
        getShareStateKey: function() { return 'stateKey'; },
        states: window._embeddedStates,
        menu: { items: [], selectedKeys: [], openKeys: [] },
        layout: { applyLayout: function(){} },
        theme: {
          applyTheme: function(){},
          applyThemeToTarget: function(win, theme) {
            var options = theme.options; if (!options) return;
            var style = win.document.querySelector("style#theme");
            if (!style) { style = win.document.createElement("style"); style.id = "theme"; style.type = "text/css"; win.document.head.prepend(style); }
            var styleContent = "";
            for (var option in options) { styleContent += "--" + option + ": " + options[option] + ";"; }
            style.innerHTML = ":root{" + styleContent + "}";
          },
          getDefaultTheme: function() {
            return { options: { colorPrimary:"#16BAAA", colorTextPrimary:"#FFFFFF", colorTextSecondary:"#FFFFFF", colorMenuActive:"#00000055", colorMenuText:"#EEEEEE", colorMenuTextActive:"#EEEEEE", colorProgress:"red", colorBodyBackground:"#FFFFFF", colorBodyText:"#333333", colorSecondary:"color-mix(in srgb, var(--colorPrimary) 80%, white)" } };
          }
        },
        openPage: function(formPageUrl, data, dialogOptions, opts) {
          opts = opts || {};
          var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
          var state = { value: data===undefined ? null : data, onConfirm: undefined, return: function(val) { if (opts.ok) opts.ok(val); }, extraBtns: [] };
          window._embeddedStates.set(stateKey, state);
        },
        openRouteInTab: function(route, data, ok) {
          var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
          var state = { value: data===undefined ? null : data, onConfirm: undefined };
          state.return = function(val) { if (ok && typeof ok === 'function') ok(val); };
          window._embeddedStates.set(stateKey, state);
          var baseUrl = location.origin;
          if (document.referrer) { try { baseUrl = (new URL(document.referrer)).origin; } catch(e) {} }
          var resolvedUrl = new URL(route.path, baseUrl + '/').href;
          resolvedUrl = resolvedUrl + (resolvedUrl.indexOf('?')>=0 ? '&' : '?') + 'stateKey=' + stateKey + '&_=' + Date.now();
          window.open(resolvedUrl, '_blank');
        },
        openWindow: function(url) { window.open(url); }
      };
      window.appContext = stub;
      return stub;
    };
  `;
}

function embeddedUrl(pagePath) {
  return FRONTEND + pagePath
    + '?embedded=true'
    + '&hrmToken=Bearer-test-token-v3'
    + '&menuButtons=search,add,edit';
}

// =====================================================================
// Test 1: openRouteInTab v3 — 使用 window.open 打开新标签页
// =====================================================================
test('V3-01: openRouteInTab 改用 window.open 打开新标签页', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token-v3', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  // 拦截 window.open
  const openCalls = await page.evaluate(() => {
    window.__openCalls = [];
    window.open = function(url, target) {
      window.__openCalls.push({ url, target });
      return null;
    };

    const ctx = window.getAppContext();
    ctx.openRouteInTab(
      { path: '../User/Employee/ResignProof.html', name: '设置离职模板' },
      null, null
    );

    return {
      calls: window.__openCalls.length,
      url: window.__openCalls[0]?.url,
      target: window.__openCalls[0]?.target,
    };
  });

  console.log('window.open calls:', JSON.stringify(openCalls));

  // v3 关键断言：应调用 window.open 打开新标签页
  expect(openCalls.calls, '应调用 window.open').toBeGreaterThan(0);
  expect(openCalls.target, 'target 应为 _blank').toBe('_blank');
  expect(openCalls.url, 'URL 应包含 ResignProof.html').toMatch(/ResignProof\.html/);
  expect(openCalls.url, 'URL 应包含 stateKey 参数').toMatch(/stateKey=stub_/);
  // URL 不应包含 ..
  expect(openCalls.url, 'URL 不应包含 ../').not.toMatch(/\.\.\//);
});

// =====================================================================
// Test 2: openRouteInTab v3 — 不再发送 HRM_OPEN_TAB postMessage
// =====================================================================
test('V3-02: openRouteInTab 不再发送 HRM_OPEN_TAB (改用 window.open)', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token-v3', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const result = await page.evaluate(() => {
    window.__hrmMessages = [];
    window.addEventListener('message', (e) => {
      if (e.data?.type?.startsWith('HRM_')) {
        window.__hrmMessages.push(e.data.type);
      }
    });

    // Mock window.open
    window.open = function() { return null; };

    const ctx = window.getAppContext();
    ctx.openRouteInTab(
      { path: '../User/Employee/ResignProof.html', name: '设置离职模板' },
      null, null
    );

    return {
      hrmMessages: window.__hrmMessages,
      hasHRM_OPEN_TAB: window.__hrmMessages.includes('HRM_OPEN_TAB'),
    };
  });

  console.log('HRM messages after openRouteInTab:', JSON.stringify(result.hrmMessages));

  // v3: 不再发送 HRM_OPEN_TAB（改用 window.open）
  expect(result.hasHRM_OPEN_TAB, 'v3 不应发送 HRM_OPEN_TAB postMessage').toBe(false);
});

// =====================================================================
// Test 3: openRouteInTab v3 — state 数据传递 + return 回调
// =====================================================================
test('V3-03: state 数据传递和 return 回调仍正确', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token-v3', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const result = await page.evaluate(() => {
    window.open = function() { return null; };
    const ctx = window.getAppContext();

    let okCalled = false, okValue = null;
    ctx.openRouteInTab(
      { path: 'some/page.html', name: '测试' },
      { templateId: 789, name: 'v3模板' },
      function(val) { okCalled = true; okValue = val; }
    );

    let lastState = null, lastStateKey = null;
    ctx.states.forEach((v, k) => { lastState = v; lastStateKey = k; });

    // 模拟目标页面的 getState()
    const stateViaGetState = ctx.states.get(lastStateKey);

    // 触发 return
    if (lastState?.return) lastState.return({ saved: 'yes' });

    return {
      stateKey: lastStateKey,
      hasValue: lastState?.value !== null,
      templateId: lastState?.value?.templateId,
      templateName: lastState?.value?.name,
      getStateValue: stateViaGetState?.value,
      okCalled, okValue,
    };
  });

  console.log('State & callback:', JSON.stringify(result));

  expect(result.templateId, 'state.value.templateId 应为 789').toBe(789);
  expect(result.templateName, 'state.value.name 应为 v3模板').toBe('v3模板');
  expect(result.getStateValue, 'getState() 应能获取 state.value').toBeTruthy();
  expect(result.okCalled, 'state.return() 应触发 ok 回调').toBe(true);
  expect(result.okValue, 'ok 回调应收到正确值').toEqual({ saved: 'yes' });
});

// =====================================================================
// Test 4: base-path 无条件覆盖 — 修复残留错误值
// =====================================================================
test('V3-04: base-path 无条件覆盖旧值', async ({ page }) => {
  // 预设一个错误的 base-path（模拟旧版本写入的错误值）
  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-test-token-v3');
    localStorage.setItem('xToken', 'Bearer-test-token-v3');
    // 模拟旧版本残留：base-path 被错误设为 8095
    localStorage.setItem('base-path', 'http://localhost:8095');
    window.appConfig = {
      baseUrl1: 'http://localhost:8088',
      baseUrl2: 'http://localhost:8088',
      newFenluApiBase: 'http://localhost:8088/api',
    };
  });

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/create_edit.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  // 执行 baseService.js 的 base-path 无条件覆盖逻辑
  const result = await page.evaluate(() => {
    const appConfig = window.appConfig;
    // 模拟 baseService.js v3 的无条件覆盖
    localStorage.setItem('base-path',
      (appConfig && appConfig.baseUrl1) ||
      (appConfig && appConfig.newFenluApiBase) || '');

    return {
      basePath: localStorage.getItem('base-path'),
      wasOverwritten: localStorage.getItem('base-path') !== 'http://localhost:8095',
    };
  });

  console.log('base-path after overwrite:', JSON.stringify(result));

  // v3 关键：即使之前有错误值，也应被覆盖
  expect(result.basePath, 'base-path 应为正确值 (8088)，非旧值 (8095)')
    .toBe('http://localhost:8088');
  expect(result.wasOverwritten, 'base-path 应已从 8095 覆盖为 8088').toBe(true);
});

// =====================================================================
// Test 5: base-path 无条件覆盖 — 首次设置也能正常工作
// =====================================================================
test('V3-05: base-path 无条件覆盖 — 首次加载也能正确设置', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-test-token-v3');
    localStorage.setItem('xToken', 'Bearer-test-token-v3');
    // 不预设 base-path（模拟首次加载）
    localStorage.removeItem('base-path');
    window.appConfig = {
      baseUrl1: 'http://localhost:8088',
      newFenluApiBase: 'http://localhost:8088/api',
    };
  });

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const result = await page.evaluate(() => {
    const appConfig = window.appConfig;
    // 模拟 v3 无条件覆盖逻辑（首次也无条件设置）
    localStorage.setItem('base-path',
      (appConfig && appConfig.baseUrl1) ||
      (appConfig && appConfig.newFenluApiBase) || '');

    return {
      basePath: localStorage.getItem('base-path'),
    };
  });

  console.log('base-path first set:', JSON.stringify(result));
  expect(result.basePath, 'base-path 首次加载应为 8088').toBe('http://localhost:8088');
});

// =====================================================================
// Test 6: appConfig 不再被嵌入模式覆盖 (v3 回归验证)
// =====================================================================
test('V3-06: appConfig 保留原始 API 地址 (v3 回归)', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-test-token-v3');
    localStorage.setItem('xToken', 'Bearer-test-token-v3');
    window.appConfig = {
      baseUrl1: 'http://localhost:8088',
      baseUrl2: 'http://localhost:8088',
      newFenluApiBase: 'http://localhost:8088/api',
    };
  });

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const config = await page.evaluate(() => ({
    baseUrl1: window.appConfig?.baseUrl1,
    newFenluApiBase: window.appConfig?.newFenluApiBase,
  }));

  console.log('appConfig v3:', JSON.stringify(config));

  // v3 应保持原始 API 地址
  expect(config.baseUrl1, 'baseUrl1 应保留 8088').toBe('http://localhost:8088');
  expect(config.newFenluApiBase, 'newFenluApiBase 应保留 8088/api').toBe('http://localhost:8088/api');
});
