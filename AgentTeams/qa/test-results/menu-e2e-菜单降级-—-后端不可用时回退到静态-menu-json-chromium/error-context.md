# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: menu-e2e.spec.js >> 菜单降级 — 后端不可用时回退到静态 menu.json
- Location: playwright\menu-e2e.spec.js:353:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
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
  377 | 
> 378 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  379 |   await page.waitForTimeout(4000);
  380 |   await page.screenshot({ path: path.join(SCREENSHOTS, '07-menu-fallback.png'), fullPage: true });
  381 | 
  382 |   // 验证菜单仍能加载（降级到 menu.json）
  383 |   const menuLoaded = await page.evaluate(() => (window.appContext?.menu?.items?.length || 0) > 0);
  384 |   expect(menuLoaded, '即使后端不可用，菜单应通过静态 menu.json 加载').toBe(true);
  385 | 
  386 |   // 验证降级日志
  387 |   console.log('Fallback logs:', logs);
  388 |   const hasFallbackLog = logs.some(l => l.includes('降级') || l.includes('menu.json') || l.includes('回退'));
  389 |   console.log('Has fallback log:', hasFallbackLog);
  390 |   // 降级日志可能因日志格式不同而不触发，主要验证菜单数据已加载
  391 | });
  392 | 
  393 | // ===== Test 8: appContext 基础状态 =====
  394 | test('appContext 状态 — 验证全局上下文初始化正确', async ({ page }) => {
  395 |   const useMock = test.info().project.use.useMock;
  396 |   await setupMockedPage(page, useMock);
  397 | 
  398 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  399 |   await page.waitForTimeout(4000);
  400 | 
  401 |   const state = await page.evaluate(() => ({
  402 |     hasAppContext: typeof window.appContext === 'object',
  403 |     hasMenu: typeof window.appContext?.menu === 'object',
  404 |     hasRoute: typeof window.appContext?.route === 'object',
  405 |     hasTheme: typeof window.appContext?.theme === 'object',
  406 |     hasLayout: typeof window.appContext?.layout === 'object',
  407 |     hasNotify: typeof window.appContext?.notify === 'object',
  408 |     hasUtils: typeof window.appContext?.utils === 'object',
  409 |     menuItemsCount: window.appContext?.menu?.items?.length || 0,
  410 |     routeItemsCount: window.appContext?.route?.items?.length || 0,
  411 |     menuItemsSample: (window.appContext?.menu?.items || []).slice(0, 3).map(m => ({
  412 |       id: m.id, title: m.title, icon: m.icon, path: m.path,
  413 |       hasMenuButtons: Array.isArray(m.menuButtons),
  414 |       childrenCount: (m.children || []).length
  415 |     })),
  416 |   }));
  417 | 
  418 |   console.log('AppContext state:', JSON.stringify(state, null, 2));
  419 | 
  420 |   expect(state.hasAppContext, 'window.appContext 应存在').toBe(true);
  421 |   expect(state.hasMenu, 'appContext.menu 应存在').toBe(true);
  422 |   expect(state.hasRoute, 'appContext.route 应存在').toBe(true);
  423 |   expect(state.menuItemsCount, '菜单 items 应非空').toBeGreaterThan(0);
  424 |   expect(state.routeItemsCount, '路由 items 应有 startup 路由').toBeGreaterThan(0);
  425 | 
  426 |   // 验证菜单项结构
  427 |   state.menuItemsSample.forEach(item => {
  428 |     expect(item.id, '菜单项应有 id').toBeTruthy();
  429 |     expect(item.title, '菜单项应有 title').toBeTruthy();
  430 |     expect(item.hasMenuButtons, '菜单项 menuButtons 应为数组').toBe(true);
  431 |   });
  432 | });
  433 | 
```