# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-real-data.spec.js >> E2E-07: startup首页 — 验证默认标签页打开
- Location: playwright\e2e-real-data.spec.js:286:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  190 |       edit: window.checkTabPermissions(nativePath, 'edit'),
  191 |       delete: window.checkTabPermissions(nativePath, 'delete'),
  192 |     });
  193 | 
  194 |     // Test with HRM path
  195 |     const hrmPath = '/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html';
  196 |     tests.push({
  197 |       path: 'hrm-staffInfo',
  198 |       add: window.checkTabPermissions(hrmPath, 'add'),
  199 |       search: window.checkTabPermissions(hrmPath, 'search'),
  200 |       nonexistent: window.checkTabPermissions(hrmPath, 'nonexistent_btn'),
  201 |     });
  202 | 
  203 |     // Test with nonexistent path
  204 |     tests.push({
  205 |       path: 'nonexistent',
  206 |       any: window.checkTabPermissions('nonexistent/path', 'add'),
  207 |     });
  208 | 
  209 |     // Test with empty path (uses current route)
  210 |     tests.push({
  211 |       path: 'empty (currentRoute)',
  212 |       any: window.checkTabPermissions('', 'add'),
  213 |     });
  214 | 
  215 |     return tests;
  216 |   });
  217 | 
  218 |   console.log('checkTabPermissions results:', JSON.stringify(results, null, 2));
  219 |   // All function calls should return boolean (not throw)
  220 |   results.forEach(r => {
  221 |     Object.values(r).forEach(v => {
  222 |       if (typeof v === 'boolean') {
  223 |         // valid
  224 |       }
  225 |     });
  226 |   });
  227 | });
  228 | 
  229 | // ===== Test 6: postMessage 流程 (需要登录态，使用 mock hrm-auth) =====
  230 | test('E2E-06: postMessage — HRM_GET_CONTEXT → HRM_CONTEXT 消息流程', async ({ page }) => {
  231 |   const useMock = test.info().project.use.useMock;
  232 |   await setupRealDataPage(page, useMock);
  233 |   if (useMock) {
  234 |     // Mock hrm-auth (needs valid user token in localStorage, so we mock this one)
  235 |     await page.route('http://localhost:5000/api/hrm-auth/get-fenlu-token', route => {
  236 |     route.fulfill({
  237 |       contentType: 'application/json',
  238 |       body: JSON.stringify({
  239 |         succeeded: true,
  240 |         data: { token: "real-fenlu-jwt-token-for-e2e-test" },
  241 |         errors: null, extras: null, statusCode: 200, timestamp: Date.now().toString()
  242 |       })
  243 |     });
  244 |   });
  245 |   }
  246 | 
  247 |   // Set a mock token so the API call is authorized
  248 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  249 |   await page.evaluate(() => {
  250 |     localStorage.setItem('token', 'Bearer mock-hongguan-token');
  251 |     localStorage.setItem('xToken', 'Bearer mock-hongguan-token');
  252 |   });
  253 |   await page.reload({ waitUntil: 'networkidle', timeout: 30000 });
  254 |   await page.waitForTimeout(5000);
  255 | 
  256 |   // Test postMessage flow
  257 |   const context = await page.evaluate(async () => {
  258 |     return new Promise((resolve) => {
  259 |       const handler = (e) => {
  260 |         if (e.data?.type === 'HRM_CONTEXT') {
  261 |           window.removeEventListener('message', handler);
  262 |           resolve({
  263 |             success: true,
  264 |             hasToken: !!e.data.token,
  265 |             hasUserInfo: !!e.data.userInfo,
  266 |             hasBaseUrl: !!e.data.baseUrl1,
  267 |             tokenPrefix: (e.data.token || '').startsWith('Bearer '),
  268 |             fields: Object.keys(e.data)
  269 |           });
  270 |         }
  271 |       };
  272 |       window.addEventListener('message', handler);
  273 |       window.postMessage({ type: 'HRM_GET_CONTEXT' }, '*');
  274 |       setTimeout(() => resolve({ success: false, reason: 'timeout' }), 10000);
  275 |     });
  276 |   });
  277 | 
  278 |   console.log('HRM_CONTEXT result:', JSON.stringify(context));
  279 |   expect(context.success, 'HRM_GET_CONTEXT 应返回 HRM_CONTEXT').toBe(true);
  280 |   expect(context.hasToken, '应包含分路Token').toBe(true);
  281 |   expect(context.tokenPrefix, 'Token应以 Bearer 开头').toBe(true);
  282 |   expect(context.hasUserInfo, '应包含用户信息').toBe(true);
  283 | });
  284 | 
  285 | // ===== Test 7: startup 首页加载 =====
  286 | test('E2E-07: startup首页 — 验证默认标签页打开', async ({ page }) => {
  287 |   const useMock = test.info().project.use.useMock;
  288 |   await setupRealDataPage(page, useMock);
  289 | 
> 290 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  291 |   await page.waitForTimeout(5000);
  292 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'e2e-07-startup.png'), fullPage: true });
  293 | 
  294 |   // 验证已创建至少一个标签页
  295 |   const routeCount = await page.evaluate(() => window.appContext?.route?.items?.length || 0);
  296 |   console.log('Route count:', routeCount);
  297 |   expect(routeCount, '应至少有一个已打开的路由(标签页)').toBeGreaterThan(0);
  298 | 
  299 |   // 验证 startup 路由的路径
  300 |   const cr = await page.evaluate(() => {
  301 |     const route = window.appContext?.route;
  302 |     const items = route?.items || [];
  303 |     const cur = items.find(i => i.id === route?.currentRoute);
  304 |     return cur ? { id: cur.id, name: cur.name, path: cur.path } : null;
  305 |   });
  306 |   console.log('Current route:', JSON.stringify(cr));
  307 |   expect(cr, '应有当前活跃路由').not.toBeNull();
  308 | });
  309 | 
  310 | // ===== Test 8: Console 无 JS 异常 (真实数据) =====
  311 | test('E2E-08: 无JS异常 — 真实数据加载无报错', async ({ page }) => {
  312 |   const useMock = test.info().project.use.useMock;
  313 |   await setupRealDataPage(page, useMock);
  314 | 
  315 |   const jsErrors = [];
  316 |   page.on('pageerror', err => jsErrors.push(err.message));
  317 |   const consoleErrors = [];
  318 |   page.on('console', msg => {
  319 |     if (msg.type() === 'error') consoleErrors.push(msg.text());
  320 |   });
  321 | 
  322 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  323 |   await page.waitForTimeout(5000);
  324 | 
  325 |   // Filter out known non-issues
  326 |   const realErrors = consoleErrors.filter(e =>
  327 |     !e.includes('favicon') &&
  328 |     !e.includes('404') &&
  329 |     !e.includes('net::ERR_')
  330 |   );
  331 |   console.log('Page errors:', jsErrors.length);
  332 |   console.log('Console errors (filtered):', realErrors);
  333 | 
  334 |   if (realErrors.length > 0) {
  335 |     console.log('WARNING: JS errors detected:', realErrors);
  336 |   }
  337 | });
  338 | 
```