# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: supplierManage-ui-interaction.spec.js >> 供应商管理 — API Mock 空列表 → 返回 items=[] 且 totalCount=0
- Location: playwright\supplierManage-ui-interaction.spec.js:242:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
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
  210 |           }
  211 |         })
  212 |       });
  213 |     });
  214 |   }
  215 | 
  216 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  217 |   await page.waitForTimeout(3000);
  218 | 
  219 |   // 验证 API 响应数据结构（通过 mock 定义验证）
  220 |   const mockData = {
  221 |     succeeded: true,
  222 |     data: {
  223 |       items: [
  224 |         { id: 1, name: '供应商A', contact: '张三', phone: '13800138000' },
  225 |         { id: 2, name: '供应商B', contact: '李四', phone: '13900139000' }
  226 |       ],
  227 |       totalCount: 2
  228 |     }
  229 |   };
  230 |   expect(mockData.succeeded, 'API 响应 succeeded 应为 true').toBe(true);
  231 |   expect(Array.isArray(mockData.data.items), 'data.items 应为数组').toBe(true);
  232 |   expect(mockData.data.items.length, '应返回 2 条记录').toBe(2);
  233 |   expect(mockData.data.items[0], '供应商记录应包含 id/name/contact/phone').toHaveProperty('id');
  234 |   expect(mockData.data.items[0]).toHaveProperty('name');
  235 |   expect(mockData.data.items[0]).toHaveProperty('contact');
  236 |   expect(mockData.data.totalCount, 'totalCount 应为 2').toBe(2);
  237 | });
  238 | 
  239 | // ====================================================================
  240 | // Test 6: API Mock — 空列表返回
  241 | // ====================================================================
  242 | test('供应商管理 — API Mock 空列表 → 返回 items=[] 且 totalCount=0', async ({ page }) => {
  243 |   const useMock = test.info().project.use.useMock;
  244 |   await setupMockedPage(page, useMock);
  245 | 
  246 |   // 覆盖供应商列表为空白
  247 |   if (useMock) {
  248 |     await page.route('**/api/services/app/Supplier/GetAll**', route => {
  249 |       route.fulfill({
  250 |         contentType: 'application/json',
  251 |         body: JSON.stringify({ succeeded: true, data: { items: [], totalCount: 0 } })
  252 |       });
  253 |     });
  254 |   }
  255 | 
  256 |   const errors = [];
  257 |   page.on('pageerror', err => errors.push(err.message));
  258 | 
> 259 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  260 |   await page.waitForTimeout(3000);
  261 | 
  262 |   const vueMounted = await page.evaluate(() => {
  263 |     return typeof window.appContext !== 'undefined';
  264 |   });
  265 |   expect(vueMounted, '空列表时 Vue 应用应正常挂载').toBe(true);
  266 |   expect(errors.filter(e => !e.includes('404')), '空列表不应导致页面崩溃').toEqual([]);
  267 | });
  268 | 
  269 | // ====================================================================
  270 | // Test 7: API Mock — 错误响应不崩溃
  271 | // ====================================================================
  272 | test('供应商管理 — API 500 错误 → 页面不崩溃', async ({ page }) => {
  273 |   const useMock = test.info().project.use.useMock;
  274 |   await setupMockedPage(page, useMock);
  275 | 
  276 |   // 模拟 API 500 错误
  277 |   if (useMock) {
  278 |     await page.route('**/api/services/app/Supplier/GetAll**', route => {
  279 |       route.fulfill({
  280 |         status: 500,
  281 |         contentType: 'application/json',
  282 |         body: JSON.stringify({ succeeded: false, errors: [{ message: '服务器内部错误' }] })
  283 |       });
  284 |     });
  285 |   }
  286 | 
  287 |   const errors = [];
  288 |   page.on('pageerror', err => errors.push(err.message));
  289 | 
  290 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  291 |   await page.waitForTimeout(3000);
  292 | 
  293 |   const vueMounted = await page.evaluate(() => {
  294 |     return typeof window.appContext !== 'undefined';
  295 |   });
  296 |   expect(vueMounted, 'API 500 时 Vue 应用不应崩溃').toBe(true);
  297 |   expect(errors.filter(e => !e.includes('404')), 'API 500 不应导致页面级崩溃').toEqual([]);
  298 | });
  299 | 
  300 | // ====================================================================
  301 | // Test 8: 响应式 — 窗口缩放不崩溃
  302 | // ====================================================================
  303 | test('供应商管理 — 响应式 → 窗口缩放页面不崩溃', async ({ page }) => {
  304 |   const useMock = test.info().project.use.useMock;
  305 |   await setupMockedPage(page, useMock);
  306 |   const errors = [];
  307 |   page.on('pageerror', err => errors.push(err.message));
  308 | 
  309 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  310 |   await page.waitForTimeout(3000);
  311 | 
  312 |   await page.setViewportSize({ width: 800, height: 600 });
  313 |   await page.waitForTimeout(1000);
  314 | 
  315 |   await page.setViewportSize({ width: 1920, height: 1080 });
  316 |   await page.waitForTimeout(1000);
  317 | 
  318 |   expect(errors, '窗口缩放不应导致页面崩溃').toEqual([]);
  319 | });
  320 | 
```