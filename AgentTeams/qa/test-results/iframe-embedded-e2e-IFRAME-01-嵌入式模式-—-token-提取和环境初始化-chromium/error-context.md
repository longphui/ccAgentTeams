# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: iframe-embedded-e2e.spec.js >> IFRAME-01: 嵌入式模式 — token 提取和环境初始化
- Location: playwright\iframe-embedded-e2e.spec.js:146:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport", waiting until "networkidle"

```

# Test source

```ts
  53  |             if (!options) return;
  54  |             var style = win.document.querySelector("style#theme");
  55  |             if (!style) {
  56  |               style = win.document.createElement("style");
  57  |               style.id = "theme";
  58  |               style.type = "text/css";
  59  |               win.document.head.prepend(style);
  60  |             }
  61  |             var styleContent = "";
  62  |             for (var option in options) {
  63  |               styleContent += "--" + option + ": " + options[option] + ";";
  64  |             }
  65  |             style.innerHTML = ":root{" + styleContent + "}";
  66  |           },
  67  |           getDefaultTheme: function() {
  68  |             return {
  69  |               options: {
  70  |                 colorPrimary: "#16BAAA",
  71  |                 colorTextPrimary: "#FFFFFF",
  72  |                 colorTextSecondary: "#FFFFFF",
  73  |                 colorMenuActive: "#00000055",
  74  |                 colorMenuText: "#EEEEEE",
  75  |                 colorMenuTextActive: "#EEEEEE",
  76  |                 colorProgress: "red",
  77  |                 colorBodyBackground: "#FFFFFF",
  78  |                 colorBodyText: "#333333",
  79  |                 colorSecondary: "color-mix(in srgb, var(--colorPrimary) 80%, white)"
  80  |               }
  81  |             };
  82  |           }
  83  |         },
  84  |         openPage: function(formPageUrl, data, dialogOptions, opts) {
  85  |           opts = opts || {};
  86  |           var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
  87  |           var state = {
  88  |             value: data === undefined ? null : data,
  89  |             onConfirm: undefined,
  90  |             return: function(val) {
  91  |               if (opts.ok && typeof opts.ok === 'function') opts.ok(val);
  92  |             },
  93  |             extraBtns: []
  94  |           };
  95  |           window._embeddedStates.set(stateKey, state);
  96  |           formPageUrl = formPageUrl + (formPageUrl.indexOf('?') >= 0 ? '&' : '?') + 'stateKey=' + stateKey + '&_=' + Date.now();
  97  |           if (typeof LayuiVue !== 'undefined' && LayuiVue.layer) {
  98  |             LayuiVue.layer.open({
  99  |               type: opts.type || 'iframe',
  100 |               title: (dialogOptions && dialogOptions.title) || '弹窗',
  101 |               area: (dialogOptions && dialogOptions.area) || ['100%', '100%'],
  102 |               shadeClose: dialogOptions && dialogOptions.shadeClose,
  103 |               maxmin: true,
  104 |               content: formPageUrl,
  105 |               btn: opts.noBtn ? [] : [
  106 |                 { text: (dialogOptions && dialogOptions.yesText) || '确定', callback: function(id) {
  107 |                   if (state.onConfirm && typeof state.onConfirm === 'function') {
  108 |                     var res = state.onConfirm();
  109 |                     if (res === true) { LayuiVue.layer.close(id); if (opts.ok) opts.ok(res); }
  110 |                     else if (res && typeof res.then === 'function') { res.then(function(r) { if (r) { LayuiVue.layer.close(id); if (opts.ok) opts.ok(r); } }); }
  111 |                     else { LayuiVue.layer.close(id); if (opts.ok) opts.ok(res); }
  112 |                   } else { LayuiVue.layer.close(id); if (opts.ok) opts.ok(); }
  113 |                 }},
  114 |                 { text: '取消', callback: function(id) { LayuiVue.layer.close(id); } }
  115 |               ]
  116 |             });
  117 |           }
  118 |         },
  119 |         openRouteInTab: function(route, data, ok) {
  120 |           // Bug #13 修复：嵌入模式降级为弹窗
  121 |           var dialogOptions = { title: route.name || '页面', area: ['70%', '80%'] };
  122 |           this.openPage(route.path, data, dialogOptions, { ok: ok });
  123 |         },
  124 |         openWindow: function(url) { window.open(url); }
  125 |       };
  126 |       window.appContext = stub;
  127 |       return stub;
  128 |     };
  129 | 
  130 |     // 注入 onTokenExpired（模拟 baseService.js）
  131 |     window.__onTokenExpiredCalled = false;
  132 |   `;
  133 | }
  134 | 
  135 | // ===== 辅助: 加载分路页面（嵌入模式）=====
  136 | function embeddedUrl(pagePath) {
  137 |   return FRONTEND + pagePath
  138 |     + '?embedded=true'
  139 |     + '&hrmToken=' + encodeURIComponent(HRM_TOKEN)
  140 |     + '&menuButtons=' + encodeURIComponent(MENU_BUTTONS.join(','));
  141 | }
  142 | 
  143 | // ==========================================================================
  144 | // Test 1: 嵌入式模式基础加载 — token 提取、环境初始化
  145 | // ==========================================================================
  146 | test('IFRAME-01: 嵌入式模式 — token 提取和环境初始化', async ({ page }) => {
  147 |   const errors = [];
  148 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  149 |   page.on('pageerror', err => errors.push('PAGE_CRASH: ' + err.message));
  150 | 
  151 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, MENU_BUTTONS));
  152 | 
> 153 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
  154 |     waitUntil: 'networkidle', timeout: 30000
  155 |   });
  156 |   await page.waitForTimeout(3000);
  157 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'iframe-01-embedded-init.png'), fullPage: true });
  158 | 
  159 |   const state = await page.evaluate(() => ({
  160 |     isEmbedded: (function() {
  161 |       var m = location.search.match(/[?&]embedded=true/);
  162 |       return !!m;
  163 |     })(),
  164 |     hasToken: !!localStorage.getItem('token'),
  165 |     tokenValue: localStorage.getItem('token'),
  166 |     appConfig_baseUrl1: window.appConfig?.baseUrl1,
  167 |     appConfig_newFenluApiBase: window.appConfig?.newFenluApiBase,
  168 |     hasGetAppContext: typeof window.getAppContext === 'function',
  169 |   }));
  170 | 
  171 |   console.log('State:', JSON.stringify(state));
  172 | 
  173 |   expect(state.isEmbedded, 'URL 应包含 embedded=true').toBe(true);
  174 |   expect(state.hasToken, 'localStorage 应有 token').toBe(true);
  175 |   expect(state.appConfig_baseUrl1, 'appConfig.baseUrl1 应为 5021').toMatch(/5021/);
  176 |   expect(state.appConfig_newFenluApiBase, 'appConfig.newFenluApiBase 应包含 /api').toMatch(/\/api/);
  177 |   expect(state.hasGetAppContext, 'getAppContext 应为全局函数').toBe(true);
  178 | 
  179 |   // 验证 getAppContext stub 可用
  180 |   const stubState = await page.evaluate(() => {
  181 |     const ctx = window.getAppContext();
  182 |     return {
  183 |       hasRoute: !!ctx?.route,
  184 |       hasTheme: !!ctx?.theme,
  185 |       hasOpenPage: typeof ctx?.openPage === 'function',
  186 |       hasOpenRouteInTab: typeof ctx?.openRouteInTab === 'function',
  187 |       hasStates: ctx?.states instanceof Map,
  188 |     };
  189 |   });
  190 |   console.log('Stub state:', JSON.stringify(stubState));
  191 |   expect(stubState.hasRoute, 'getAppContext 应有 route').toBe(true);
  192 |   expect(stubState.hasTheme, 'getAppContext 应有 theme').toBe(true);
  193 |   expect(stubState.hasOpenPage, 'getAppContext 应有 openPage').toBe(true);
  194 |   expect(stubState.hasOpenRouteInTab, 'getAppContext 应有 openRouteInTab').toBe(true);
  195 |   expect(stubState.hasStates, 'getAppContext states 应为 Map').toBe(true);
  196 | 
  197 |   const critical = errors.filter(e =>
  198 |     e.includes('Uncaught') || e.includes('TypeError') || e.includes('ReferenceError') || e.includes('PAGE_CRASH')
  199 |   );
  200 |   if (critical.length) console.log('Critical errors:', critical);
  201 |   expect(critical, '不应有严重 JS 错误').toEqual([]);
  202 | });
  203 | 
  204 | // ==========================================================================
  205 | // Test 2: API 请求 host 验证
  206 | // ==========================================================================
  207 | test('IFRAME-02: API 请求 host — 验证请求不指向错误地址', async ({ page }) => {
  208 |   const useMock = test.info().project.use.useMock;
  209 |   const apiRequests = [];
  210 | 
  211 |   if (useMock) {
  212 |     await page.route('**/api/**', (route, request) => {
  213 |       const url = new URL(request.url());
  214 |       apiRequests.push({ host: url.host, pathname: url.pathname, method: request.method() });
  215 |       route.fulfill({
  216 |         contentType: 'application/json',
  217 |         body: JSON.stringify({ success: true, result: { totalCount: 0, items: [] } })
  218 |       });
  219 |     });
  220 | 
  221 |     // Mock 分路 API login 避免 401 错误
  222 |     await page.route('**/api/Common/Account/Login', route => {
  223 |       route.fulfill({
  224 |         contentType: 'application/json',
  225 |         body: JSON.stringify({ success: true, result: { token: HRM_TOKEN.replace('Bearer ', ''), userId: 1 } })
  226 |       });
  227 |     });
  228 | 
  229 |     // 放行非 API 资源
  230 |     await page.route('**/*.html*', route => route.continue());
  231 |     await page.route('**/*.js', route => route.continue());
  232 |     await page.route('**/*.css', route => route.continue());
  233 |   }
  234 | 
  235 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, MENU_BUTTONS));
  236 | 
  237 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
  238 |     waitUntil: 'networkidle', timeout: 30000
  239 |   });
  240 |   await page.waitForTimeout(4000);
  241 | 
  242 |   console.log('API requests captured:', apiRequests.length);
  243 |   apiRequests.forEach(r => console.log('  ', r.method, r.host + r.pathname));
  244 | 
  245 |   // 关键断言：API 请求不应发往 50350 或 8095
  246 |   const badHosts = apiRequests.filter(r =>
  247 |     r.host.includes('50350') || r.host.includes('8095')
  248 |   );
  249 |   expect(badHosts.length, 'API 请求不应发往错误的端口 (50350/8095)').toBe(0);
  250 | 
  251 |   const uniqueHosts = [...new Set(apiRequests.map(r => r.host))];
  252 |   console.log('Unique API hosts:', uniqueHosts);
  253 |   expect(uniqueHosts.length, '所有 API 请求 host 应一致').toBeLessThanOrEqual(2);
```