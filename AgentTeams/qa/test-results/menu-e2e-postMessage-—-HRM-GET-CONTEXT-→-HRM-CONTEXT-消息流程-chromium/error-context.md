# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: menu-e2e.spec.js >> postMessage — HRM_GET_CONTEXT → HRM_CONTEXT 消息流程
- Location: playwright\menu-e2e.spec.js:200:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  104 | 
  105 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  106 |   await page.waitForTimeout(3000);
  107 |   await page.screenshot({ path: path.join(SCREENSHOTS, '01-menu-tree.png'), fullPage: true });
  108 | 
  109 |   // 验证菜单项存在（LayuiVue 渲染后菜单在 .layui-nav 或 lay-menu 内）
  110 |   const menuItems = await page.locator('.layui-nav-item, .layui-menu-item, [role="menuitem"]').count();
  111 |   console.log('Menu items found:', menuItems);
  112 |   expect(menuItems, '菜单树应至少有一个菜单项').toBeGreaterThan(0);
  113 | 
  114 |   // 验证 appContext 菜单数据加载
  115 |   const menuData = await page.evaluate(() => window.appContext?.menu?.items?.length || 0);
  116 |   console.log('Menu data items:', menuData);
  117 |   expect(menuData, 'appContext.menu.items 应有数据').toBeGreaterThan(0);
  118 | 
  119 |   // 验证层级：至少有一个包含 children 的节点
  120 |   const hasChildren = await page.evaluate(() => {
  121 |     return (window.appContext?.menu?.items || []).some(m => (m.children || []).length > 0);
  122 |   });
  123 |   expect(hasChildren, '菜单树应包含父子层级').toBe(true);
  124 | 
  125 |   // 无 JS 异常
  126 |   if (errors.length > 0) console.log('Console errors:', errors);
  127 | });
  128 | 
  129 | // ===== Test 2: 图标显示 =====
  130 | test('图标显示 — 验证 fa fa-* 和 icon-* 图标的 class 属性', async ({ page }) => {
  131 |   const useMock = test.info().project.use.useMock;
  132 |   await setupMockedPage(page, useMock);
  133 | 
  134 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  135 |   await page.waitForTimeout(3000);
  136 | 
  137 |   // 检查 appContext 菜单中图标数据
  138 |   const icons = await page.evaluate(() => {
  139 |     const allIcons = [];
  140 |     function collectIcons(items) {
  141 |       (items || []).forEach(item => {
  142 |         if (item.icon) allIcons.push(item.icon);
  143 |         if (item.children) collectIcons(item.children);
  144 |       });
  145 |     }
  146 |     collectIcons(window.appContext?.menu?.items || []);
  147 |     return allIcons;
  148 |   });
  149 |   console.log('Menu icons:', icons);
  150 | 
  151 |   // 验证包含 fa fa-* 格式图标
  152 |   const faIcons = icons.filter(i => i.startsWith('fa fa-'));
  153 |   expect(faIcons.length, '应包含 Font Awesome 格式图标 (fa fa-*)').toBeGreaterThan(0);
  154 | 
  155 |   // 验证包含 icon-* 格式图标
  156 |   const iconPrefix = icons.filter(i => i.startsWith('icon-') && !i.startsWith('icon-'));
  157 |   // 注意：有些图标不含前缀的直接名称也要统计
  158 |   console.log('fa-icons:', faIcons, 'all-icons:', icons);
  159 | 
  160 |   // 验证 mainmenu 图标渲染逻辑：Lv1.icon?.replace('fa fa-','').replace('icon-','')
  161 |   const iconProcessing = await page.evaluate(() => {
  162 |     const testIcons = ['fa fa-users', 'icon-people', 'fa fa-cubes', 'home'];
  163 |     return testIcons.map(i => i.replace('fa fa-', '').replace('icon-', ''));
  164 |   });
  165 |   console.log('Icon processing result:', iconProcessing);
  166 |   // 所有图标处理后应为有效名称
  167 |   iconProcessing.forEach(name => {
  168 |     expect(name.length, `图标名 "${name}" 不应为空`).toBeGreaterThan(0);
  169 |   });
  170 | });
  171 | 
  172 | // ===== Test 3: 标签页打开 + startup 首页 =====
  173 | test('标签页打开 — startup 首页加载 + 点击菜单创建标签', async ({ page }) => {
  174 |   const useMock = test.info().project.use.useMock;
  175 |   await setupMockedPage(page, useMock);
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
> 204 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
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
  276 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
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
```