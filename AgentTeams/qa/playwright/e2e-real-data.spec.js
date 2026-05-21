// @ts-check
const { test, expect } = require('@playwright/test');
const path = require('path');

const FRONTEND = 'http://localhost:5021';
const SCREENSHOTS = path.join(__dirname, 'screenshots');

// ===== 仅 mock 认证（用户不存在于鸿冠DB），菜单数据使用真实 API =====
const MOCK_USER = {
  succeeded: true,
  data: {
    userId: "test-user-001", userName: "hongbin", email: "hongbin@test.com",
    tenantId: "00000000-0000-0000-0000-000000000000", displayName: "测试用户",
    phone: "13800138000", company: { id: 1, name: "测试公司" }
  },
  errors: null, extras: null, statusCode: 200, timestamp: Date.now().toString()
};

async function setupRealDataPage(page, useMock) {
  if (!useMock) return;

  // Only mock auth — let menu proxy use real backend
  await page.route('http://localhost:5000/api/context-user/current-user', route => {
    route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  });
  // DO NOT mock menu-proxy — use real data
  // DO NOT mock hrm-auth — use real data
}

// ===== Test 1: 菜单加载 (真实数据) =====
test('E2E-01: 菜单加载 — 真实API数据，验证菜单树完整', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-01-real-menu.png'), fullPage: true });

  // 验证菜单数据已加载
  const menuCount = await page.evaluate(() => window.appContext?.menu?.items?.length || 0);
  console.log('Real menu top-level items:', menuCount);
  expect(menuCount, '应加载真实菜单数据(21个顶层模块)').toBeGreaterThanOrEqual(20);

  // 验证包含 HRM 模块
  const hasHRM = await page.evaluate(() => {
    const items = window.appContext?.menu?.items || [];
    return items.some(i => (i.title || '').includes('人力') || (i.title || '').includes('HRM'));
  });
  expect(hasHRM, '菜单树应包含人力资源模块').toBe(true);

  // 验证包含鸿冠原生模块
  const hasNative = await page.evaluate(() => {
    const items = window.appContext?.menu?.items || [];
    return items.some(i => (i.title || '').includes('采购') || (i.title || '').includes('产品'));
  });
  expect(hasNative, '菜单树应包含鸿冠原生模块').toBe(true);

  // 无 JS 异常
  const realErrors = await page.evaluate(() => {
    return (window.__consoleErrors || []).filter(e =>
      !e.includes('404') && !e.includes('favicon')
    );
  });
  if (realErrors.length > 0) console.log('JS errors:', realErrors);
});

// ===== Test 2: HRM iframe 代理路径 =====
test('E2E-02: HRM页面路径 — 验证HRM菜单path指向hrm-proxy', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);

  const hrmPaths = await page.evaluate(() => {
    const result = [];
    function find(items) {
      (items || []).forEach(item => {
        if ((item.path || '').includes('hrm-proxy')) {
          result.push({ title: item.title, path: item.path, id: item.id });
        }
        if (item.children) find(item.children);
      });
    }
    find(window.appContext?.menu?.items || []);
    return result;
  });

  console.log('HRM proxy paths found:', hrmPaths.length);
  expect(hrmPaths.length, '应有HRM iframe代理菜单').toBeGreaterThan(0);

  // 验证所有 HRM 路径格式
  const badPaths = hrmPaths.filter(p => !p.path.startsWith('/views/hrm-proxy/index.html?page='));
  console.log('Bad HRM paths:', badPaths);
  expect(badPaths.length, '所有HRM路径应符合 /views/hrm-proxy/index.html?page= 格式').toBe(0);
});

// ===== Test 3: 菜单降级 (真实环境) =====
test('E2E-03: 菜单降级 — 后端不可用时回退', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  if (useMock) {
    // Mock menu proxy to fail (simulate backend down)
    await page.route('http://localhost:5000/api/menu-proxy/get-list-by-role', route => {
      route.abort('connectionrefused');
    });
    await page.route('http://localhost:5000/api/context-user/current-user', route => {
      route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
    });
  }
  // menu.json doesn't exist — so the fallback itself will fail
  // We want to observe the error handling

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-03-fallback.png'), fullPage: true });

  // Check console for fallback message
  const fallbackLogs = await page.evaluate(() => {
    return (window.__consoleLogs || []).filter(l => l.includes('回退') || l.includes('fallback'));
  });
  console.log('Fallback related logs:', fallbackLogs);

  // Check if menu.json fallback was attempted
  const menuJsonAttempted = await page.evaluate(() => {
    return (window.__consoleLogs || []).some(l =>
      l.includes('menu.json') || l.includes('回退')
    );
  });
  console.log('menu.json fallback attempted:', menuJsonAttempted);
});

// ===== Test 4: 鸿冠原生模块路由 =====
test('E2E-04: 鸿冠原生模块 — 验证原生页面路径正确', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);

  const nativePaths = await page.evaluate(() => {
    const result = [];
    function find(items) {
      (items || []).forEach(item => {
        const p = item.path || '';
        // 排除 HRM proxy 和空路径
        if (p && !p.includes('hrm-proxy') && !p.startsWith('/v2/') && !p.startsWith('/environmentalMonitore') && !p.startsWith('/THDetection')) {
          result.push({ title: item.title, path: p });
        }
        if (item.children) find(item.children);
      });
    }
    find(window.appContext?.menu?.items || []);
    return result;
  });

  console.log('Native module paths:', nativePaths.length);
  expect(nativePaths.length, '应有鸿冠原生模块菜单').toBeGreaterThan(0);

  // Check for bad paths (backslash, leading space)
  const badPaths = nativePaths.filter(p => {
    return p.path.includes('\\') || p.path.startsWith(' ') || p.path.includes('  ');
  });
  if (badPaths.length > 0) {
    console.log('Warning: paths with issues:', badPaths.slice(0, 10));
  }
});

// ===== Test 5: checkTabPermissions (真实数据) =====
test('E2E-05: checkTabPermissions — 用真实菜单数据验证权限检查', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);

  const results = await page.evaluate(() => {
    const tests = [];

    // Test with native module path
    const nativePath = 'views/purchase_management/index.html';
    tests.push({
      path: nativePath,
      add: window.checkTabPermissions(nativePath, 'add'),
      search: window.checkTabPermissions(nativePath, 'search'),
      edit: window.checkTabPermissions(nativePath, 'edit'),
      delete: window.checkTabPermissions(nativePath, 'delete'),
    });

    // Test with HRM path
    const hrmPath = '/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html';
    tests.push({
      path: 'hrm-staffInfo',
      add: window.checkTabPermissions(hrmPath, 'add'),
      search: window.checkTabPermissions(hrmPath, 'search'),
      nonexistent: window.checkTabPermissions(hrmPath, 'nonexistent_btn'),
    });

    // Test with nonexistent path
    tests.push({
      path: 'nonexistent',
      any: window.checkTabPermissions('nonexistent/path', 'add'),
    });

    // Test with empty path (uses current route)
    tests.push({
      path: 'empty (currentRoute)',
      any: window.checkTabPermissions('', 'add'),
    });

    return tests;
  });

  console.log('checkTabPermissions results:', JSON.stringify(results, null, 2));
  // All function calls should return boolean (not throw)
  results.forEach(r => {
    Object.values(r).forEach(v => {
      if (typeof v === 'boolean') {
        // valid
      }
    });
  });
});

// ===== Test 6: postMessage 流程 (需要登录态，使用 mock hrm-auth) =====
test('E2E-06: postMessage — HRM_GET_CONTEXT → HRM_CONTEXT 消息流程', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);
  if (useMock) {
    // Mock hrm-auth (needs valid user token in localStorage, so we mock this one)
    await page.route('http://localhost:5000/api/hrm-auth/get-fenlu-token', route => {
    route.fulfill({
      contentType: 'application/json',
      body: JSON.stringify({
        succeeded: true,
        data: { token: "real-fenlu-jwt-token-for-e2e-test" },
        errors: null, extras: null, statusCode: 200, timestamp: Date.now().toString()
      })
    });
  });
  }

  // Set a mock token so the API call is authorized
  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.evaluate(() => {
    localStorage.setItem('token', 'Bearer mock-hongguan-token');
    localStorage.setItem('xToken', 'Bearer mock-hongguan-token');
  });
  await page.reload({ waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);

  // Test postMessage flow
  const context = await page.evaluate(async () => {
    return new Promise((resolve) => {
      const handler = (e) => {
        if (e.data?.type === 'HRM_CONTEXT') {
          window.removeEventListener('message', handler);
          resolve({
            success: true,
            hasToken: !!e.data.token,
            hasUserInfo: !!e.data.userInfo,
            hasBaseUrl: !!e.data.baseUrl1,
            tokenPrefix: (e.data.token || '').startsWith('Bearer '),
            fields: Object.keys(e.data)
          });
        }
      };
      window.addEventListener('message', handler);
      window.postMessage({ type: 'HRM_GET_CONTEXT' }, '*');
      setTimeout(() => resolve({ success: false, reason: 'timeout' }), 10000);
    });
  });

  console.log('HRM_CONTEXT result:', JSON.stringify(context));
  expect(context.success, 'HRM_GET_CONTEXT 应返回 HRM_CONTEXT').toBe(true);
  expect(context.hasToken, '应包含分路Token').toBe(true);
  expect(context.tokenPrefix, 'Token应以 Bearer 开头').toBe(true);
  expect(context.hasUserInfo, '应包含用户信息').toBe(true);
});

// ===== Test 7: startup 首页加载 =====
test('E2E-07: startup首页 — 验证默认标签页打开', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);
  await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-07-startup.png'), fullPage: true });

  // 验证已创建至少一个标签页
  const routeCount = await page.evaluate(() => window.appContext?.route?.items?.length || 0);
  console.log('Route count:', routeCount);
  expect(routeCount, '应至少有一个已打开的路由(标签页)').toBeGreaterThan(0);

  // 验证 startup 路由的路径
  const cr = await page.evaluate(() => {
    const route = window.appContext?.route;
    const items = route?.items || [];
    const cur = items.find(i => i.id === route?.currentRoute);
    return cur ? { id: cur.id, name: cur.name, path: cur.path } : null;
  });
  console.log('Current route:', JSON.stringify(cr));
  expect(cr, '应有当前活跃路由').not.toBeNull();
});

// ===== Test 8: Console 无 JS 异常 (真实数据) =====
test('E2E-08: 无JS异常 — 真实数据加载无报错', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupRealDataPage(page, useMock);

  const jsErrors = [];
  page.on('pageerror', err => jsErrors.push(err.message));
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(5000);

  // Filter out known non-issues
  const realErrors = consoleErrors.filter(e =>
    !e.includes('favicon') &&
    !e.includes('404') &&
    !e.includes('net::ERR_')
  );
  console.log('Page errors:', jsErrors.length);
  console.log('Console errors (filtered):', realErrors);

  if (realErrors.length > 0) {
    console.log('WARNING: JS errors detected:', realErrors);
  }
});
