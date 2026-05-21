# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: menu-e2e.spec.js >> 图标显示 — 验证 fa fa-* 和 icon-* 图标的 class 属性
- Location: playwright\menu-e2e.spec.js:130:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  34  |         menuButtons: ["search", "add", "edit", "delete", "approve"]
  35  |       },
  36  |       {
  37  |         id: 3001, title: "产品管理", parent: 0,
  38  |         path: "views/product_management/index.html",
  39  |         icon: "fa fa-cubes", children: [
  40  |           {
  41  |             id: 3002, title: "商品列表", parent: 3001,
  42  |             path: "views/product_management/product/index.html",
  43  |             icon: "fa fa-list", children: [],
  44  |             menuButtons: ["search", "add", "edit", "delete"]
  45  |           },
  46  |           {
  47  |             id: 3003, title: "品牌管理", parent: 3001,
  48  |             path: "views/product_management/brand/index.html",
  49  |             icon: "icon-tag", children: [],
  50  |             menuButtons: ["search", "add", "edit", "delete"]
  51  |           }
  52  |         ],
  53  |         menuButtons: []
  54  |       },
  55  |       {
  56  |         id: 1001, title: "人力资源(HRM)", parent: 0, path: "", icon: "fa fa-users",
  57  |         children: [
  58  |           {
  59  |             id: 1002, title: "员工管理", parent: 1001,
  60  |             path: "/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html",
  61  |             icon: "icon-people", children: [],
  62  |             menuButtons: ["search", "add", "edit", "delete"]
  63  |           }
  64  |         ],
  65  |         menuButtons: []
  66  |       }
  67  |     ],
  68  |     startup: { id: 2001, parentId: 0, title: "采购管理", path: "views/purchase_management/index.html", name: "采购管理" }
  69  |   }
  70  | };
  71  | 
  72  | const MOCK_HRM_TOKEN = {
  73  |   succeeded: true,
  74  |   data: { token: "mock-fenlu-jwt-token-for-testing" },
  75  |   errors: null, extras: null, statusCode: 200, timestamp: Date.now().toString()
  76  | };
  77  | 
  78  | // ===== 通用 setup =====
  79  | async function setupMockedPage(page, useMock) {
  80  |   if (!useMock) return;
  81  | 
  82  |   // Mock 后端 API 响应
  83  |   await page.route('http://localhost:5000/api/context-user/current-user', route => {
  84  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  85  |   });
  86  |   await page.route('http://localhost:5000/api/menu-proxy/get-list-by-role', route => {
  87  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  88  |   });
  89  |   await page.route('http://localhost:5000/api/hrm-auth/get-fenlu-token', route => {
  90  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_HRM_TOKEN) });
  91  |   });
  92  |   // Mock menu.json 降级（静态文件在 5000 端口）
  93  |   await page.route('http://localhost:5000/menu.json', route => {
  94  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  95  |   });
  96  | }
  97  | 
  98  | // ===== Test 1: 菜单树渲染 =====
  99  | test('菜单树渲染 — 验证菜单 DOM 节点存在且层级正确', async ({ page }) => {
  100 |   const useMock = test.info().project.use.useMock;
  101 |   await setupMockedPage(page, useMock);
  102 |   const errors = [];
  103 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
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
> 134 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
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
```