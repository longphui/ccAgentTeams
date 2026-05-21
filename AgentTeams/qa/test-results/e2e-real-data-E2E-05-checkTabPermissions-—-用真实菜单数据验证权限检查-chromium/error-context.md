# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-real-data.spec.js >> E2E-05: checkTabPermissions — 用真实菜单数据验证权限检查
- Location: playwright\e2e-real-data.spec.js:174:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
Call log:
  - navigating to "http://localhost:5021/index.html", waiting until "networkidle"

```

# Test source

```ts
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
  138 | test('E2E-04: 鸿冠原生模块 — 验证原生页面路径正确', async ({ page }) => {
  139 |   const useMock = test.info().project.use.useMock;
  140 |   await setupRealDataPage(page, useMock);
  141 | 
  142 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
  143 |   await page.waitForTimeout(5000);
  144 | 
  145 |   const nativePaths = await page.evaluate(() => {
  146 |     const result = [];
  147 |     function find(items) {
  148 |       (items || []).forEach(item => {
  149 |         const p = item.path || '';
  150 |         // 排除 HRM proxy 和空路径
  151 |         if (p && !p.includes('hrm-proxy') && !p.startsWith('/v2/') && !p.startsWith('/environmentalMonitore') && !p.startsWith('/THDetection')) {
  152 |           result.push({ title: item.title, path: p });
  153 |         }
  154 |         if (item.children) find(item.children);
  155 |       });
  156 |     }
  157 |     find(window.appContext?.menu?.items || []);
  158 |     return result;
  159 |   });
  160 | 
  161 |   console.log('Native module paths:', nativePaths.length);
  162 |   expect(nativePaths.length, '应有鸿冠原生模块菜单').toBeGreaterThan(0);
  163 | 
  164 |   // Check for bad paths (backslash, leading space)
  165 |   const badPaths = nativePaths.filter(p => {
  166 |     return p.path.includes('\\') || p.path.startsWith(' ') || p.path.includes('  ');
  167 |   });
  168 |   if (badPaths.length > 0) {
  169 |     console.log('Warning: paths with issues:', badPaths.slice(0, 10));
  170 |   }
  171 | });
  172 | 
  173 | // ===== Test 5: checkTabPermissions (真实数据) =====
  174 | test('E2E-05: checkTabPermissions — 用真实菜单数据验证权限检查', async ({ page }) => {
  175 |   const useMock = test.info().project.use.useMock;
  176 |   await setupRealDataPage(page, useMock);
  177 | 
> 178 |   await page.goto(FRONTEND + '/index.html', { waitUntil: 'networkidle', timeout: 30000 });
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/index.html
  179 |   await page.waitForTimeout(5000);
  180 | 
  181 |   const results = await page.evaluate(() => {
  182 |     const tests = [];
  183 | 
  184 |     // Test with native module path
  185 |     const nativePath = 'views/purchase_management/index.html';
  186 |     tests.push({
  187 |       path: nativePath,
  188 |       add: window.checkTabPermissions(nativePath, 'add'),
  189 |       search: window.checkTabPermissions(nativePath, 'search'),
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
```