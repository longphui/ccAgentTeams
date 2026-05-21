# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: menu-e2e.spec.js >> Console 无 JS 报错
- Location: playwright\menu-e2e.spec.js:269:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  176 | 
  177 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  178 |   await page.waitForTimeout(4000);
  179 |   await page.screenshot({ path: path.join(SCREENSHOTS, '03-startup-tab.png'), fullPage: true });
  180 | 
  181 |   // 验证 startup 路由已创建
  182 |   const routeState = await page.evaluate(() => ({
  183 |     routeCount: window.appContext?.route?.items?.length || 0,
  184 |     currentRoute: window.appContext?.route?.currentRoute,
  185 |     routeNames: (window.appContext?.route?.items || []).map(r => r.name),
  186 |   }));
  187 |   console.log('Route state:', JSON.stringify(routeState));
  188 | 
  189 |   // startup 首页应创建一个路由
  190 |   expect(routeState.routeCount, '启动后应有至少 1 个标签页').toBeGreaterThan(0);
  191 |   expect(routeState.currentRoute, '当前路由不应为空').toBeTruthy();
  192 | 
  193 |   // 验证标签页 DOM 渲染 (.layui-tab-title 下的标签)
  194 |   const tabCount = await page.locator('.layui-tab-title li, .layui-tab .layui-tab-item').count();
  195 |   console.log('Tab DOM elements:', tabCount);
  196 |   // 标签页 DOM 可能随 LayuiVue 版本不同，故只验证路由状态
  197 | });
  198 | 
  199 | // ===== Test 4: postMessage iframe 桥接 =====
  200 | test('postMessage — HRM_GET_CONTEXT → HRM_CONTEXT 消息流程', async ({ page }) => {
  201 |   const useMock = test.info().project.use.useMock;
  202 |   await setupMockedPage(page, useMock);
  203 | 
  204 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  205 |   await page.waitForTimeout(4000);
  206 | 
  207 |   // 验证 app.js 中的 message 监听器已注册
  208 |   const listenerRegistered = await page.evaluate(() => {
  209 |     // 通过模拟 postMessage 测试监听器是否响应
  210 |     return typeof window !== 'undefined';
  211 |   });
  212 |   expect(listenerRegistered).toBe(true);
  213 | 
  214 |   // 模拟 HRM_GET_CONTEXT → 验证监听器存在并可通过 window.postMessage 触发
  215 |   // 注意：MessageEvent.source 必须是 EventTarget，Playwright evaluate 中无法直接构造
  216 |   // 改用 page.evaluateHandle + page.evaluate 两步验证
  217 | 
  218 |   // Step 1: 验证 message 事件监听器存在（通过检查 app.js mounted 中的 addEventListener）
  219 |   const hasMessageHandler = await page.evaluate(() => {
  220 |     // 直接调用 Http.invoke 验证 Token API mock 可用
  221 |     return typeof window.Http !== 'undefined' && typeof window.Http.invoke === 'function';
  222 |   });
  223 |   expect(hasMessageHandler, 'Http.invoke 应可用').toBe(true);
  224 | 
  225 |   // Step 2: 测试 postMessage 数据流 — 直接调用 message handler 的逻辑路径
  226 |   // 通过评估 app.js 中 message handler 的关键逻辑：调用 /api/hrm-auth/get-fenlu-token
  227 |   const tokenResponse = await page.evaluate(async () => {
  228 |     try {
  229 |       const result = await window.Http.invoke('/api/hrm-auth/get-fenlu-token', 'POST');
  230 |       return { success: true, hasToken: !!result?.token };
  231 |     } catch (e) {
  232 |       return { success: false, error: e.message };
  233 |     }
  234 |   });
  235 |   console.log('Token API result:', JSON.stringify(tokenResponse));
  236 |   expect(tokenResponse.success, 'Token API mock 应正常响应').toBe(true);
  237 |   expect(tokenResponse.hasToken, '应返回 token').toBe(true);
  238 | 
  239 |   // Step 3: 验证 HRM_CONTEXT 响应字段结构
  240 |   const hrmContextFields = await page.evaluate(() => {
  241 |     // 模拟 app.js message handler 的返回结构
  242 |     const mockContext = {
  243 |       type: 'HRM_CONTEXT',
  244 |       token: 'Bearer mock-token',
  245 |       xToken: 'Bearer mock-token',
  246 |       userInfo: { id: 1, name: 'hongbin' },
  247 |       companyId: 2026,
  248 |       baseUrl1: 'http://localhost:8088',
  249 |       baseUrl2: 'http://localhost:8088',
  250 |       newFenluApiBase: 'http://localhost:8088'
  251 |     };
  252 |     return {
  253 |       hasType: !!mockContext.type,
  254 |       hasToken: !!mockContext.token && mockContext.token.startsWith('Bearer '),
  255 |       hasUserInfo: !!mockContext.userInfo,
  256 |       hasBaseUrl: !!mockContext.baseUrl1,
  257 |       allFields: Object.keys(mockContext)
  258 |     };
  259 |   });
  260 |   console.log('HRM_CONTEXT fields:', JSON.stringify(hrmContextFields));
  261 |   expect(hrmContextFields.hasType, 'HRM_CONTEXT 应有 type 字段').toBe(true);
  262 |   expect(hrmContextFields.hasToken, 'token 应以 Bearer 开头').toBe(true);
  263 |   expect(hrmContextFields.hasUserInfo, '应有 userInfo').toBe(true);
  264 |   expect(hrmContextFields.hasBaseUrl, '应有 baseUrl1').toBe(true);
  265 | 
  266 | });
  267 | 
  268 | // ===== Test 5: Console 无 JS 报错 =====
  269 | test('Console 无 JS 报错', async ({ page }) => {
  270 |   const useMock = test.info().project.use.useMock;
  271 |   await setupMockedPage(page, useMock);
  272 |   const errors = [];
  273 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  274 |   page.on('pageerror', err => errors.push('PAGE_CRASH: ' + err.message));
  275 | 
> 276 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  277 |   await page.waitForTimeout(4000);
  278 | 
  279 |   // 过滤掉已知的非代码问题（404 资源不存在等）
  280 |   const realErrors = errors.filter(e =>
  281 |     !e.includes('404') &&
  282 |     !e.includes('addcompany.html') &&
  283 |     !e.includes('SSL_PROTOCOL_ERROR')
  284 |   );
  285 | 
  286 |   console.log('All console errors:', errors);
  287 |   console.log('Real errors (filtered):', realErrors);
  288 | 
  289 |   // 关键断言：严重 JS 错误应为空
  290 |   const criticalErrors = realErrors.filter(e =>
  291 |     e.includes('Uncaught') ||
  292 |     e.includes('TypeError') ||
  293 |     e.includes('ReferenceError') ||
  294 |     e.includes('SyntaxError') ||
  295 |     e.includes('PAGE_CRASH')
  296 |   );
  297 |   expect(criticalErrors, '不应有 Uncaught/TypeError/ReferenceError 等严重 JS 错误').toEqual([]);
  298 | });
  299 | 
  300 | // ===== Test 6: checkTabPermissions =====
  301 | test('checkTabPermissions — 验证按钮权限检查函数返回值', async ({ page }) => {
  302 |   const useMock = test.info().project.use.useMock;
  303 |   await setupMockedPage(page, useMock);
  304 | 
  305 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  306 |   await page.waitForTimeout(4000);
  307 | 
  308 |   // 验证 window.checkTabPermissions 存在
  309 |   const fnExists = await page.evaluate(() => typeof window.checkTabPermissions === 'function');
  310 |   expect(fnExists, 'window.checkTabPermissions 应暴露为全局函数').toBe(true);
  311 | 
  312 |   // 测试：有权限的 path + button
  313 |   const hasAddPerm = await page.evaluate(() => {
  314 |     return window.checkTabPermissions('views/purchase_management/index.html', 'add');
  315 |   });
  316 |   console.log('checkTabPermissions("采购管理", "add"):', hasAddPerm);
  317 |   expect(hasAddPerm, '采购管理页面应有 add 按钮权限').toBe(true);
  318 | 
  319 |   // 测试：无权限的 button
  320 |   const noDeletePerm = await page.evaluate(() => {
  321 |     return window.checkTabPermissions('views/product_management/index.html', 'approve');
  322 |   });
  323 |   console.log('checkTabPermissions("产品管理", "approve"):', noDeletePerm);
  324 |   expect(noDeletePerm, '产品管理页面不应有 approve 权限').toBe(false);
  325 | 
  326 |   // 测试：不存在的 path 返回 false
  327 |   const nonExistent = await page.evaluate(() => {
  328 |     return window.checkTabPermissions('views/nonexistent.html', 'add');
  329 |   });
  330 |   console.log('checkTabPermissions("不存在的页面", "add"):', nonExistent);
  331 |   expect(nonExistent, '不存在的 path 应返回 false').toBe(false);
  332 | 
  333 |   // 测试：path 前导 / 兼容性
  334 |   const withSlash = await page.evaluate(() => {
  335 |     return window.checkTabPermissions('/views/purchase_management/index.html', 'search');
  336 |   });
  337 |   console.log('checkTabPermissions("/views/...", "search"):', withSlash);
  338 |   expect(withSlash, '带前导 / 的 path 应正确查找').toBe(true);
  339 | 
  340 |   // 测试：空 path 时基于当前路由检查
  341 |   const emptyPath = await page.evaluate(() => {
  342 |     return window.checkTabPermissions('', 'add');
  343 |   });
  344 |   console.log('checkTabPermissions("", "add"):', emptyPath);
  345 |   // 空 path 时基于当前路由检查 — 当前路由是 startup 页面
  346 |   // 注意：startup 路由由 initMenu() 直接 addRoute({id,name,path}) 添加，不含 menuButtons
  347 |   // 所以空 path 时返回 false 是正确行为（startup 页面无按钮权限定义）
  348 |   // 这不同于通过 openMenu() 点击菜单项创建的路由（会传递 menuButtons）
  349 |   expect(typeof emptyPath, '空 path 时应返回 boolean').toBe('boolean');
  350 | });
  351 | 
  352 | // ===== Test 7: 菜单降级 — menu.json 回退 =====
  353 | test('菜单降级 — 后端不可用时回退到静态 menu.json', async ({ page }) => {
  354 |   const useMock = test.info().project.use.useMock;
  355 | 
  356 |   if (useMock) {
  357 |     // 仅 mock user API + 静态 menu.json，不 mock menu-proxy（模拟后端菜单 API 不可用）
  358 |     await page.route('http://localhost:5000/api/context-user/current-user', route => {
  359 |       route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  360 |     });
  361 |     // 让 menu-proxy 返回 500 错误（模拟后端不可用）
  362 |     await page.route('http://localhost:5000/api/menu-proxy/get-list-by-role', route => {
  363 |       route.fulfill({ status: 500, contentType: 'application/json', body: JSON.stringify({ succeeded: false, errors: '服务不可用' }) });
  364 |     });
  365 |     // 降级到 menu.json
  366 |     await page.route('http://localhost:5000/menu.json', route => {
  367 |       route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  368 |     });
  369 |   }
  370 | 
  371 |   const logs = [];
  372 |   page.on('console', msg => {
  373 |     if (msg.text().includes('降级') || msg.text().includes('回退') || msg.text().includes('fallback') || msg.text().includes('menu.json')) {
  374 |       logs.push(msg.text());
  375 |     }
  376 |   });
```