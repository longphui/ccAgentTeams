# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-real-data.spec.js >> E2E-01: 菜单加载 — 真实API数据，验证菜单树完整
- Location: playwright\e2e-real-data.spec.js:31:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  1   | // @ts-check
  2   | const { test, expect } = require('@playwright/test');
  3   | const path = require('path');
  4   | 
  5   | const FRONTEND = 'http://localhost:5021';
  6   | const SCREENSHOTS = path.join(__dirname, 'screenshots');
  7   | 
  8   | // ===== 仅 mock 认证（用户不存在于鸿冠DB），菜单数据使用真实 API =====
  9   | const MOCK_USER = {
  10  |   succeeded: true,
  11  |   data: {
  12  |     userId: "test-user-001", userName: "hongbin", email: "hongbin@test.com",
  13  |     tenantId: "00000000-0000-0000-0000-000000000000", displayName: "测试用户",
  14  |     phone: "13800138000", company: { id: 1, name: "测试公司" }
  15  |   },
  16  |   errors: null, extras: null, statusCode: 200, timestamp: Date.now().toString()
  17  | };
  18  | 
  19  | async function setupRealDataPage(page, useMock) {
  20  |   if (!useMock) return;
  21  | 
  22  |   // Only mock auth — let menu proxy use real backend
  23  |   await page.route('http://localhost:5000/api/context-user/current-user', route => {
  24  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  25  |   });
  26  |   // DO NOT mock menu-proxy — use real data
  27  |   // DO NOT mock hrm-auth — use real data
  28  | }
  29  | 
  30  | // ===== Test 1: 菜单加载 (真实数据) =====
  31  | test('E2E-01: 菜单加载 — 真实API数据，验证菜单树完整', async ({ page }) => {
  32  |   const useMock = test.info().project.use.useMock;
  33  |   await setupRealDataPage(page, useMock);
  34  |   const errors = [];
  35  |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  36  | 
> 37  |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  38  |   await page.waitForTimeout(5000);
  39  |   await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-01-real-menu.png'), fullPage: true });
  40  | 
  41  |   // 验证菜单数据已加载
  42  |   const menuCount = await page.evaluate(() => window.appContext?.menu?.items?.length || 0);
  43  |   console.log('Real menu top-level items:', menuCount);
  44  |   expect(menuCount, '应加载真实菜单数据(21个顶层模块)').toBeGreaterThanOrEqual(20);
  45  | 
  46  |   // 验证包含 HRM 模块
  47  |   const hasHRM = await page.evaluate(() => {
  48  |     const items = window.appContext?.menu?.items || [];
  49  |     return items.some(i => (i.title || '').includes('人力') || (i.title || '').includes('HRM'));
  50  |   });
  51  |   expect(hasHRM, '菜单树应包含人力资源模块').toBe(true);
  52  | 
  53  |   // 验证包含鸿冠原生模块
  54  |   const hasNative = await page.evaluate(() => {
  55  |     const items = window.appContext?.menu?.items || [];
  56  |     return items.some(i => (i.title || '').includes('采购') || (i.title || '').includes('产品'));
  57  |   });
  58  |   expect(hasNative, '菜单树应包含鸿冠原生模块').toBe(true);
  59  | 
  60  |   // 无 JS 异常
  61  |   const realErrors = await page.evaluate(() => {
  62  |     return (window.__consoleErrors || []).filter(e =>
  63  |       !e.includes('404') && !e.includes('favicon')
  64  |     );
  65  |   });
  66  |   if (realErrors.length > 0) console.log('JS errors:', realErrors);
  67  | });
  68  | 
  69  | // ===== Test 2: HRM iframe 代理路径 =====
  70  | test('E2E-02: HRM页面路径 — 验证HRM菜单path指向hrm-proxy', async ({ page }) => {
  71  |   const useMock = test.info().project.use.useMock;
  72  |   await setupRealDataPage(page, useMock);
  73  | 
  74  |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  75  |   await page.waitForTimeout(5000);
  76  | 
  77  |   const hrmPaths = await page.evaluate(() => {
  78  |     const result = [];
  79  |     function find(items) {
  80  |       (items || []).forEach(item => {
  81  |         if ((item.path || '').includes('hrm-proxy')) {
  82  |           result.push({ title: item.title, path: item.path, id: item.id });
  83  |         }
  84  |         if (item.children) find(item.children);
  85  |       });
  86  |     }
  87  |     find(window.appContext?.menu?.items || []);
  88  |     return result;
  89  |   });
  90  | 
  91  |   console.log('HRM proxy paths found:', hrmPaths.length);
  92  |   expect(hrmPaths.length, '应有HRM iframe代理菜单').toBeGreaterThan(0);
  93  | 
  94  |   // 验证所有 HRM 路径格式
  95  |   const badPaths = hrmPaths.filter(p => !p.path.startsWith('/views/hrm-proxy/index.html?page='));
  96  |   console.log('Bad HRM paths:', badPaths);
  97  |   expect(badPaths.length, '所有HRM路径应符合 /views/hrm-proxy/index.html?page= 格式').toBe(0);
  98  | });
  99  | 
  100 | // ===== Test 3: 菜单降级 (真实环境) =====
  101 | test('E2E-03: 菜单降级 — 后端不可用时回退', async ({ page }) => {
  102 |   const useMock = test.info().project.use.useMock;
  103 |   const errors = [];
  104 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  105 | 
  106 |   if (useMock) {
  107 |     // Mock menu proxy to fail (simulate backend down)
  108 |     await page.route('http://localhost:5000/api/menu-proxy/get-list-by-role', route => {
  109 |       route.abort('connectionrefused');
  110 |     });
  111 |     await page.route('http://localhost:5000/api/context-user/current-user', route => {
  112 |       route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  113 |     });
  114 |   }
  115 |   // menu.json doesn't exist — so the fallback itself will fail
  116 |   // We want to observe the error handling
  117 | 
  118 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  119 |   await page.waitForTimeout(5000);
  120 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-03-fallback.png'), fullPage: true });
  121 | 
  122 |   // Check console for fallback message
  123 |   const fallbackLogs = await page.evaluate(() => {
  124 |     return (window.__consoleLogs || []).filter(l => l.includes('回退') || l.includes('fallback'));
  125 |   });
  126 |   console.log('Fallback related logs:', fallbackLogs);
  127 | 
  128 |   // Check if menu.json fallback was attempted
  129 |   const menuJsonAttempted = await page.evaluate(() => {
  130 |     return (window.__consoleLogs || []).some(l =>
  131 |       l.includes('menu.json') || l.includes('回退')
  132 |     );
  133 |   });
  134 |   console.log('menu.json fallback attempted:', menuJsonAttempted);
  135 | });
  136 | 
  137 | // ===== Test 4: 鸿冠原生模块路由 =====
```