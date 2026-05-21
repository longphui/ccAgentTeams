# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: supplierManage-ui-interaction.spec.js >> 供应商管理 — Tab 切换 → 点击标签切换内容
- Location: playwright\supplierManage-ui-interaction.spec.js:106:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
  9   | const MOCK_USER = {
  10  |   succeeded: true,
  11  |   data: {
  12  |     userId: 'qa-test-001', userName: 'hongbin', displayName: 'QA测试',
  13  |     tenantId: '00000000-0000-0000-0000-000000000000',
  14  |     company: { id: 1, name: '测试公司' }
  15  |   }
  16  | };
  17  | 
  18  | const MOCK_MENU = {
  19  |   succeeded: true,
  20  |   data: {
  21  |     children: [
  22  |       {
  23  |         id: 4001, title: '采购管理', parent: 0,
  24  |         path: 'views/purchasingManagement/purchaseDD/index.html',
  25  |         icon: 'fa fa-shopping-cart', children: [
  26  |           {
  27  |             id: 4002, title: '供应商管理', parent: 4001,
  28  |             path: 'views/purchasingManagement/supplierManage/index.html',
  29  |             icon: 'icon-truck', children: [],
  30  |             menuButtons: ['search', 'add', 'edit', 'delete', 'export']
  31  |           }
  32  |         ],
  33  |         menuButtons: []
  34  |       }
  35  |     ],
  36  |     startup: { id: 4002, parentId: 4001, title: '供应商管理',
  37  |       path: 'views/purchasingManagement/supplierManage/index.html' }
  38  |   }
  39  | };
  40  | 
  41  | // Mock 供应商列表 API
  42  | function mockSupplierApi(page, overrides = {}) {
  43  |   const defaults = {
  44  |     items: [
  45  |       { id: 1, name: '测试供应商A', contact: '张三', phone: '13800138000' },
  46  |       { id: 2, name: '测试供应商B', contact: '李四', phone: '13900139000' }
  47  |     ],
  48  |     totalCount: 2
  49  |   };
  50  |   const data = { ...defaults, ...overrides };
  51  | 
  52  |   return page.route('**/api/services/app/Supplier/GetAll**', route => {
  53  |     route.fulfill({
  54  |       contentType: 'application/json',
  55  |       body: JSON.stringify({ succeeded: true, data: { items: data.items, totalCount: data.totalCount } })
  56  |     });
  57  |   });
  58  | }
  59  | 
  60  | // ===== 通用 setup =====
  61  | async function setupMockedPage(page, useMock) {
  62  |   if (!useMock) return;
  63  | 
  64  |   await page.route('**/api/context-user/current-user', route => {
  65  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  66  |   });
  67  |   await page.route('**/api/menu-proxy/get-list-by-role', route => {
  68  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  69  |   });
  70  |   await page.route('**/menu.json', route => {
  71  |     route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  72  |   });
  73  |   await mockSupplierApi(page);
  74  | }
  75  | 
  76  | // ====================================================================
  77  | // Test 1: 页面加载 — 供应商管理页正常渲染
  78  | // ====================================================================
  79  | test('供应商管理 — 页面加载 → iframe-tab 渲染成功', async ({ page }) => {
  80  |   const useMock = test.info().project.use.useMock;
  81  |   await setupMockedPage(page, useMock);
  82  |   const errors = [];
  83  |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  84  | 
  85  |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  86  |   await page.waitForTimeout(4000);
  87  |   await page.screenshot({ path: path.join(SCREENSHOTS, 'supplier-page-load.png'), fullPage: true });
  88  | 
  89  |   const hasSupplierMenu = await page.evaluate(() => {
  90  |     return (window.appContext?.menu?.items || []).some(m =>
  91  |       (m.path || '').includes('supplierManage') ||
  92  |       (m.children || []).some(c => (c.path || '').includes('supplierManage'))
  93  |     );
  94  |   });
  95  |   expect(hasSupplierMenu, '菜单应包含供应商管理').toBe(true);
  96  | 
  97  |   const criticalErrors = errors.filter(e =>
  98  |     e.includes('Uncaught') || e.includes('TypeError') || e.includes('ReferenceError')
  99  |   );
  100 |   expect(criticalErrors, '不应有严重 JS 错误').toEqual([]);
  101 | });
  102 | 
  103 | // ====================================================================
  104 | // Test 2: Tab 切换 — iframe-tab 标签切换功能
  105 | // ====================================================================
  106 | test('供应商管理 — Tab 切换 → 点击标签切换内容', async ({ page }) => {
  107 |   const useMock = test.info().project.use.useMock;
  108 |   await setupMockedPage(page, useMock);
> 109 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  110 |   await page.waitForTimeout(3000);
  111 | 
  112 |   const tabState = await page.evaluate(() => {
  113 |     const tabHeaders = document.querySelectorAll('[role="tab"], .layui-tab-title li, .layui-tabs-header-item');
  114 |     const activeTab = document.querySelector('[role="tab"][aria-selected="true"], .layui-tab-title .layui-this, .layui-tabs-header-item.layui-this');
  115 |     return {
  116 |       activeTabText: activeTab?.textContent?.trim() || '',
  117 |       tabCount: tabHeaders.length
  118 |     };
  119 |   });
  120 |   console.log('Tab state:', JSON.stringify(tabState));
  121 |   expect(tabState.tabCount, '应有至少 1 个标签页').toBeGreaterThan(0);
  122 | });
  123 | 
  124 | // ====================================================================
  125 | // Test 3: 按钮权限 — menuButtons 数据验证
  126 | // ====================================================================
  127 | test('供应商管理 — 按钮权限 → menuButtons 包含 search/add/edit/delete/export', async ({ page }) => {
  128 |   const useMock = test.info().project.use.useMock;
  129 |   await setupMockedPage(page, useMock);
  130 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  131 |   await page.waitForTimeout(3000);
  132 | 
  133 |   const supplierPerms = await page.evaluate(() => {
  134 |     const items = window.appContext?.menu?.items || [];
  135 |     for (const m of items) {
  136 |       if (m.children) {
  137 |         for (const c of m.children) {
  138 |           if ((c.path || '').includes('supplierManage')) {
  139 |             return c.menuButtons || [];
  140 |           }
  141 |         }
  142 |       }
  143 |     }
  144 |     return [];
  145 |   });
  146 |   console.log('Supplier menuButtons:', supplierPerms);
  147 |   expect(supplierPerms).toContain('search');
  148 |   expect(supplierPerms).toContain('add');
  149 |   expect(supplierPerms).toContain('edit');
  150 |   expect(supplierPerms).toContain('delete');
  151 | });
  152 | 
  153 | // ====================================================================
  154 | // Test 4: 权限联动 — 无 add 权限时新增按钮应隐藏
  155 | // ====================================================================
  156 | test('供应商管理 — 权限联动 → 无 add 权限时新增按钮不可见', async ({ page }) => {
  157 |   const useMock = test.info().project.use.useMock;
  158 |   await setupMockedPage(page, useMock);
  159 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  160 |   await page.waitForTimeout(3000);
  161 | 
  162 |   const permModified = await page.evaluate(() => {
  163 |     const items = window.appContext?.menu?.items || [];
  164 |     for (const m of items) {
  165 |       if (m.children) {
  166 |         for (const c of m.children) {
  167 |           if ((c.path || '').includes('supplierManage')) {
  168 |             c.menuButtons = ['search', 'edit', 'delete']; // 不含 add
  169 |             return true;
  170 |           }
  171 |         }
  172 |       }
  173 |     }
  174 |     return false;
  175 |   });
  176 |   expect(permModified, '权限应被修改').toBe(true);
  177 | 
  178 |   const hasAddPerm = await page.evaluate(() => {
  179 |     return window.checkTabPermissions('views/purchasingManagement/supplierManage/index.html', 'add');
  180 |   });
  181 |   expect(hasAddPerm, '修改后 checkTabPermissions 应返回 false').toBe(false);
  182 | 
  183 |   const hasSearchPerm = await page.evaluate(() => {
  184 |     return window.checkTabPermissions('views/purchasingManagement/supplierManage/index.html', 'search');
  185 |   });
  186 |   expect(hasSearchPerm, 'search 权限应仍然存在').toBe(true);
  187 | });
  188 | 
  189 | // ====================================================================
  190 | // Test 5: API Mock 验证 — 供应商列表 API 正常响应
  191 | // ====================================================================
  192 | test('供应商管理 — API Mock → 供应商列表返回正确数据结构', async ({ page }) => {
  193 |   const useMock = test.info().project.use.useMock;
  194 |   await setupMockedPage(page, useMock);
  195 |   let capturedBody = null;
  196 | 
  197 |   if (useMock) {
  198 |     await page.route('**/api/services/app/Supplier/GetAll**', route => {
  199 |       capturedBody = route.request().postDataJSON();
  200 |       route.fulfill({
  201 |         contentType: 'application/json',
  202 |         body: JSON.stringify({
  203 |           succeeded: true,
  204 |           data: {
  205 |             items: [
  206 |               { id: 1, name: '供应商A', contact: '张三', phone: '13800138000' },
  207 |               { id: 2, name: '供应商B', contact: '李四', phone: '13900139000' }
  208 |             ],
  209 |             totalCount: 2
```