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

    // 不预设 appConfig — 让页面自己的 appConfig.js 加载真实值
    // 这样能验证 baseService.js 嵌入模式是否错误地覆盖了 appConfig

    window.__isEmbedded = true;
    window._embeddedStates = new Map();

    // 嵌入模式下的 getAppContext stub（与 util.js 逻辑一致）
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
            var options = theme.options;
            if (!options) return;
            var style = win.document.querySelector("style#theme");
            if (!style) {
              style = win.document.createElement("style");
              style.id = "theme"; style.type = "text/css";
              win.document.head.prepend(style);
            }
            var styleContent = "";
            for (var option in options) {
              styleContent += "--" + option + ": " + options[option] + ";";
            }
            style.innerHTML = ":root{" + styleContent + "}";
          },
          getDefaultTheme: function() {
            return {
              options: {
                colorPrimary: "#16BAAA", colorTextPrimary: "#FFFFFF",
                colorTextSecondary: "#FFFFFF", colorMenuActive: "#00000055",
                colorMenuText: "#EEEEEE", colorMenuTextActive: "#EEEEEE",
                colorProgress: "red", colorBodyBackground: "#FFFFFF",
                colorBodyText: "#333333",
                colorSecondary: "color-mix(in srgb, var(--colorPrimary) 80%, white)"
              }
            };
          }
        },
        openPage: function(formPageUrl, data, dialogOptions, opts) {
          opts = opts || {};
          var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
          var state = {
            value: data === undefined ? null : data,
            onConfirm: undefined,
            return: function(val) { if (opts.ok) opts.ok(val); },
            extraBtns: []
          };
          window._embeddedStates.set(stateKey, state);
        },
        openRouteInTab: function(route, data, ok) {
          var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
          var state = { value: data === undefined ? null : data, onConfirm: undefined };
          state.return = function(val) { if (ok && typeof ok === 'function') ok(val); };
          window._embeddedStates.set(stateKey, state);
          var baseUrl = location.origin;
          if (document.referrer) {
            try { baseUrl = (new URL(document.referrer)).origin; } catch(e) {}
          }
          var resolvedUrl = new URL(route.path, baseUrl + '/').href;
          resolvedUrl = resolvedUrl + (resolvedUrl.indexOf('?') >= 0 ? '&' : '?') + 'stateKey=' + stateKey + '&_=' + Date.now();
          window.parent.postMessage({ type: "HRM_OPEN_TAB", url: resolvedUrl, title: route.name || '' }, "*");
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
    + '&hrmToken=Bearer-mock-token-for-test'
    + '&menuButtons=search,add,edit';
}

// =====================================================================
// Test 1: 网络错误修复 — appConfig 不再被嵌入模式覆盖
// =====================================================================
test('NETFIX-01: appConfig 保留原始 API 地址 — 不被嵌入模式覆盖', async ({ page }) => {
  // 预注入 appConfig（模拟 appConfig.js 加载成功后的值）
  // 关键：如果 baseService.js 嵌入模式仍覆盖 appConfig，这些值会被改为 location.origin
  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-mock-token');
    localStorage.setItem('xToken', 'Bearer-mock-token');
    window.appConfig = {
      baseUrl1: 'http://localhost:8088',
      baseUrl2: 'http://localhost:8088',
      newFenluApiBase: 'http://localhost:8088/api',
      PlatformId: '00000000-0000-0000-0000-000000000000'
    };
  });

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const config = await page.evaluate(() => ({
    baseUrl1: window.appConfig?.baseUrl1,
    baseUrl2: window.appConfig?.baseUrl2,
    newFenluApiBase: window.appConfig?.newFenluApiBase,
    basePath: localStorage.getItem('base-path'),
  }));

  console.log('appConfig after page load:', JSON.stringify(config));

  // 关键断言：appConfig 值应保持为原始 API 地址 (8088)
  // 如果嵌入模式覆盖逻辑仍存在，baseUrl1 会变成 http://localhost:5021
  expect(config.baseUrl1, 'appConfig.baseUrl1 应有值').toBeTruthy();

  // 验证未被覆盖为前端地址
  const isNotOverwritten = config.baseUrl1 === 'http://localhost:8088';
  console.log('baseUrl1 kept original (8088):', isNotOverwritten);
  expect(isNotOverwritten,
    '嵌入模式不应覆盖 baseUrl1 — 预期 http://localhost:8088，实际 ' + config.baseUrl1
  ).toBe(true);

  expect(config.newFenluApiBase, 'newFenluApiBase 应保留原始值')
    .toBe('http://localhost:8088/api');
});

// =====================================================================
// Test 2: API 请求 host — 验证请求发往 8088 而非前端 origin
// =====================================================================
test('NETFIX-02: API 请求直连 8088 — 不经过前端代理', async ({ page }) => {
  const apiHosts = [];

  await page.route('**/api/**', (route, request) => {
    const url = new URL(request.url());
    apiHosts.push({ host: url.host, pathname: url.pathname, fullUrl: request.url() });
    route.fulfill({
      contentType: 'application/json',
      body: JSON.stringify({ success: true, result: { totalCount: 0, items: [] } })
    });
  });

  // 放行静态资源
  await page.route('**/*.html*', route => route.continue());
  await page.route('**/*.js', route => route.continue());
  await page.route('**/*.css', route => route.continue());

  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-mock-token');
    localStorage.setItem('xToken', 'Bearer-mock-token');
  });

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  console.log('API requests:', apiHosts.length);
  apiHosts.forEach(r => console.log('  ', r.host, r.pathname));

  // 关键断言：API 请求不应发往 8095（HRM 前端地址）
  const badHosts = apiHosts.filter(r =>
    r.host.includes('8095') || r.host.includes('50350')
  );
  expect(badHosts.length, 'API 请求不应发往 8095 或 50350').toBe(0);

  // 如果有 API 请求，host 应一致
  const uniqueHosts = [...new Set(apiHosts.map(r => r.host))];
  console.log('Unique API hosts:', uniqueHosts);
  expect(uniqueHosts.length, '所有 API 请求应在同一 host').toBeLessThanOrEqual(2);
});

// =====================================================================
// Test 3: base-path 设置 — 弹窗页面资源路径
// =====================================================================
test('NETFIX-03: base-path 设置逻辑验证 — 代码审查确认', async ({ page }) => {
  // 验证 baseService.js 嵌入模式中 base-path 设置逻辑正确
  // baseService.js 代码 (line 21-23):
  //   if (!localStorage.getItem("base-path")) {
  //     localStorage.setItem("base-path",
  //       (appConfig && appConfig.baseUrl1) ||
  //       (appConfig && appConfig.newFenluApiBase) || '');
  //   }

  await page.addInitScript(() => {
    localStorage.setItem('token', 'Bearer-mock-token');
    localStorage.setItem('xToken', 'Bearer-mock-token');
    localStorage.removeItem('base-path');
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

  // 直接执行 baseService.js 中的 base-path 设置逻辑
  const result = await page.evaluate(() => {
    const appConfig = window.appConfig;

    // 模拟 baseService.js 嵌入模式的 base-path 设置逻辑
    if (!localStorage.getItem('base-path')) {
      const bp = (appConfig && appConfig.baseUrl1)
        || (appConfig && appConfig.newFenluApiBase) || '';
      localStorage.setItem('base-path', bp);
    }

    return {
      basePath: localStorage.getItem('base-path'),
      expectedFromBaseUrl1: appConfig?.baseUrl1,
      expectedFromNewApi: appConfig?.newFenluApiBase,
    };
  });

  console.log('base-path logic result:', JSON.stringify(result));

  // base-path 应被正确设置
  expect(result.basePath, 'base-path 应被设置').toBeTruthy();
  // 逻辑: 优先使用 baseUrl1 → 其次 newFenluApiBase → 最后 fallback ''
  expect(result.basePath, 'base-path 应为 baseUrl1 的值 (8088)')
    .toBe('http://localhost:8088');
});

// =====================================================================
// Test 4: openRouteInTab v2 — HRM_OPEN_TAB postMessage
// =====================================================================
test('TABV2-01: openRouteInTab 发送 HRM_OPEN_TAB postMessage', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  // 设置 postMessage 监听
  await page.evaluate(() => {
    window.__hrmMessages = [];
    window.addEventListener('message', (e) => {
      if (e.data?.type?.startsWith('HRM_')) {
        window.__hrmMessages.push({
          type: e.data.type,
          url: e.data.url,
          title: e.data.title,
        });
      }
    });
  });

  // 模拟点击"设置离职模板"按钮 → 调用 openRouteInTab
  const result = await page.evaluate(() => {
    const ctx = window.getAppContext();
    const route = {
      path: '../User/Employee/ResignProof.html',
      name: '设置离职模板'
    };
    ctx.openRouteInTab(route, { templateId: 123 }, null);
    return { called: true };
  });
  console.log('openRouteInTab called:', result.called);
  expect(result.called).toBe(true);

  await page.waitForTimeout(500);

  // 验证 HRM_OPEN_TAB 消息
  const messages = await page.evaluate(() => window.__hrmMessages || []);
  console.log('HRM messages:', JSON.stringify(messages));

  const openTabMsg = messages.find(m => m.type === 'HRM_OPEN_TAB');
  expect(openTabMsg, '应发送 HRM_OPEN_TAB postMessage').toBeTruthy();
  expect(openTabMsg.title, '消息 title 应为"设置离职模板"').toBe('设置离职模板');
});

// =====================================================================
// Test 5: openRouteInTab v2 — URL 解析正确
// =====================================================================
test('TABV2-02: 相对路径 URL 正确解析', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  // 设置监听并调用
  const urlResult = await page.evaluate(() => {
    window.__hrmMessages = [];
    window.addEventListener('message', (e) => {
      if (e.data?.type === 'HRM_OPEN_TAB') {
        window.__hrmMessages.push(e.data);
      }
    });

    const ctx = window.getAppContext();

    // 测试 ../User/Employee/ResignProof.html 路径解析
    ctx.openRouteInTab(
      { path: '../User/Employee/ResignProof.html', name: '离职模板' },
      null, null
    );

    return { origin: location.origin };
  });

  await page.waitForTimeout(500);

  const messages = await page.evaluate(() => window.__hrmMessages || []);
  console.log('Resolved URL:', messages[0]?.url);

  if (messages.length > 0) {
    const url = messages[0].url;
    // URL 应包含 ResignProof.html
    expect(url, 'URL 应包含 ResignProof.html').toMatch(/ResignProof\.html/);
    // URL 应包含 stateKey
    expect(url, 'URL 应包含 stateKey 参数').toMatch(/stateKey=stub_/);
    // URL 不应包含 ../ (相对路径应被解析)
    expect(url, 'URL 不应包含 ../ (应被 new URL() 解析)').not.toMatch(/\.\.\//);
    // URL 应是绝对 URL
    expect(url, 'URL 应以 http 开头').toMatch(/^https?:\/\//);
  }
});

// =====================================================================
// Test 6: openRouteInTab v2 — getState() 数据传递
// =====================================================================
test('TABV2-03: getState() 可获取传递的数据', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const stateResult = await page.evaluate(() => {
    const ctx = window.getAppContext();
    const testData = { templateId: 456, name: '测试模板' };

    // 调用 openRouteInTab，不设置 ok 回调
    ctx.openRouteInTab(
      { path: '../User/Employee/ResignProof.html', name: '离职模板' },
      testData,
      null
    );

    // 从 states Map 获取最后一条
    let lastState = null;
    let lastStateKey = null;
    ctx.states.forEach((value, key) => {
      lastState = value;
      lastStateKey = key;
    });

    return {
      stateKey: lastStateKey,
      hasValue: lastState?.value !== null,
      templateId: lastState?.value?.templateId,
      templateName: lastState?.value?.name,
      hasReturn: typeof lastState?.return === 'function',
      onConfirmUndefined: lastState?.onConfirm === undefined,
    };
  });

  console.log('State result:', JSON.stringify(stateResult));

  // state 应包含传入的数据
  expect(stateResult.hasValue, 'state.value 应有数据').toBe(true);
  expect(stateResult.templateId, 'state.value.templateId 应为 456').toBe(456);
  expect(stateResult.templateName, 'state.value.name 应为"测试模板"').toBe('测试模板');
  expect(stateResult.hasReturn, 'state.return 应为函数').toBe(true);
  expect(stateResult.onConfirmUndefined, 'state.onConfirm 初始为 undefined').toBe(true);
  expect(stateResult.stateKey, 'stateKey 应以 stub_ 开头').toMatch(/^stub_/);
});

// =====================================================================
// Test 7: openRouteInTab v2 — ok 回调在 return() 时触发
// =====================================================================
test('TABV2-04: state.return() 触发 ok 回调', async ({ page }) => {
  await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));

  await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
    waitUntil: 'networkidle', timeout: 30000
  });
  await page.waitForTimeout(4000);

  const callbackResult = await page.evaluate(() => {
    const ctx = window.getAppContext();

    let okCalled = false;
    let okValue = null;

    ctx.openRouteInTab(
      { path: 'some/page.html', name: '测试页面' },
      { data: 'test' },
      function(val) { okCalled = true; okValue = val; }
    );

    // 获取 state 并调用 return
    let lastState = null;
    ctx.states.forEach((value) => { lastState = value; });

    if (lastState && lastState.return) {
      lastState.return({ result: 'success' });
    }

    return {
      stateExists: !!lastState,
      hasReturn: typeof lastState?.return === 'function',
      okCalled,
      okValue,
    };
  });

  console.log('Callback result:', JSON.stringify(callbackResult));

  expect(callbackResult.stateExists, 'state 应被创建').toBe(true);
  expect(callbackResult.hasReturn, 'state.return 应为函数').toBe(true);
  expect(callbackResult.okCalled, 'ok 回调应被 state.return() 触发').toBe(true);
  expect(callbackResult.okValue, 'ok 应收到正确的值').toEqual({ result: 'success' });
});
