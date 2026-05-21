# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: netfix-tabv2-verification.spec.js >> NETFIX-01: appConfig 保留原始 API 地址 — 不被嵌入模式覆盖
- Location: playwright\netfix-tabv2-verification.spec.js:107:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit", waiting until "networkidle"

```

# Test source

```ts
  21  |     // 嵌入模式下的 getAppContext stub（与 util.js 逻辑一致）
  22  |     window.getAppContext = function() {
  23  |       var ctx = window.appContext;
  24  |       if (ctx) return ctx;
  25  |       var menuButtonsArr = ${mb};
  26  |       var stub = {
  27  |         route: {
  28  |           checkTabPermissions: function(pathName, btn) { return menuButtonsArr.indexOf(btn) >= 0; },
  29  |           items: [], currentRoute: {}
  30  |         },
  31  |         getShareStateKey: function() { return 'stateKey'; },
  32  |         states: window._embeddedStates,
  33  |         menu: { items: [], selectedKeys: [], openKeys: [] },
  34  |         layout: { applyLayout: function(){} },
  35  |         theme: {
  36  |           applyTheme: function(){},
  37  |           applyThemeToTarget: function(win, theme) {
  38  |             var options = theme.options;
  39  |             if (!options) return;
  40  |             var style = win.document.querySelector("style#theme");
  41  |             if (!style) {
  42  |               style = win.document.createElement("style");
  43  |               style.id = "theme"; style.type = "text/css";
  44  |               win.document.head.prepend(style);
  45  |             }
  46  |             var styleContent = "";
  47  |             for (var option in options) {
  48  |               styleContent += "--" + option + ": " + options[option] + ";";
  49  |             }
  50  |             style.innerHTML = ":root{" + styleContent + "}";
  51  |           },
  52  |           getDefaultTheme: function() {
  53  |             return {
  54  |               options: {
  55  |                 colorPrimary: "#16BAAA", colorTextPrimary: "#FFFFFF",
  56  |                 colorTextSecondary: "#FFFFFF", colorMenuActive: "#00000055",
  57  |                 colorMenuText: "#EEEEEE", colorMenuTextActive: "#EEEEEE",
  58  |                 colorProgress: "red", colorBodyBackground: "#FFFFFF",
  59  |                 colorBodyText: "#333333",
  60  |                 colorSecondary: "color-mix(in srgb, var(--colorPrimary) 80%, white)"
  61  |               }
  62  |             };
  63  |           }
  64  |         },
  65  |         openPage: function(formPageUrl, data, dialogOptions, opts) {
  66  |           opts = opts || {};
  67  |           var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
  68  |           var state = {
  69  |             value: data === undefined ? null : data,
  70  |             onConfirm: undefined,
  71  |             return: function(val) { if (opts.ok) opts.ok(val); },
  72  |             extraBtns: []
  73  |           };
  74  |           window._embeddedStates.set(stateKey, state);
  75  |         },
  76  |         openRouteInTab: function(route, data, ok) {
  77  |           var stateKey = 'stub_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
  78  |           var state = { value: data === undefined ? null : data, onConfirm: undefined };
  79  |           state.return = function(val) { if (ok && typeof ok === 'function') ok(val); };
  80  |           window._embeddedStates.set(stateKey, state);
  81  |           var baseUrl = location.origin;
  82  |           if (document.referrer) {
  83  |             try { baseUrl = (new URL(document.referrer)).origin; } catch(e) {}
  84  |           }
  85  |           var resolvedUrl = new URL(route.path, baseUrl + '/').href;
  86  |           resolvedUrl = resolvedUrl + (resolvedUrl.indexOf('?') >= 0 ? '&' : '?') + 'stateKey=' + stateKey + '&_=' + Date.now();
  87  |           window.parent.postMessage({ type: "HRM_OPEN_TAB", url: resolvedUrl, title: route.name || '' }, "*");
  88  |         },
  89  |         openWindow: function(url) { window.open(url); }
  90  |       };
  91  |       window.appContext = stub;
  92  |       return stub;
  93  |     };
  94  |   `;
  95  | }
  96  | 
  97  | function embeddedUrl(pagePath) {
  98  |   return FRONTEND + pagePath
  99  |     + '?embedded=true'
  100 |     + '&hrmToken=Bearer-mock-token-for-test'
  101 |     + '&menuButtons=search,add,edit';
  102 | }
  103 | 
  104 | // =====================================================================
  105 | // Test 1: 网络错误修复 — appConfig 不再被嵌入模式覆盖
  106 | // =====================================================================
  107 | test('NETFIX-01: appConfig 保留原始 API 地址 — 不被嵌入模式覆盖', async ({ page }) => {
  108 |   // 预注入 appConfig（模拟 appConfig.js 加载成功后的值）
  109 |   // 关键：如果 baseService.js 嵌入模式仍覆盖 appConfig，这些值会被改为 location.origin
  110 |   await page.addInitScript(() => {
  111 |     localStorage.setItem('token', 'Bearer-mock-token');
  112 |     localStorage.setItem('xToken', 'Bearer-mock-token');
  113 |     window.appConfig = {
  114 |       baseUrl1: 'http://localhost:8088',
  115 |       baseUrl2: 'http://localhost:8088',
  116 |       newFenluApiBase: 'http://localhost:8088/api',
  117 |       PlatformId: '00000000-0000-0000-0000-000000000000'
  118 |     };
  119 |   });
  120 | 
> 121 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
  122 |     waitUntil: 'networkidle', timeout: 30000
  123 |   });
  124 |   await page.waitForTimeout(4000);
  125 | 
  126 |   const config = await page.evaluate(() => ({
  127 |     baseUrl1: window.appConfig?.baseUrl1,
  128 |     baseUrl2: window.appConfig?.baseUrl2,
  129 |     newFenluApiBase: window.appConfig?.newFenluApiBase,
  130 |     basePath: localStorage.getItem('base-path'),
  131 |   }));
  132 | 
  133 |   console.log('appConfig after page load:', JSON.stringify(config));
  134 | 
  135 |   // 关键断言：appConfig 值应保持为原始 API 地址 (8088)
  136 |   // 如果嵌入模式覆盖逻辑仍存在，baseUrl1 会变成 http://localhost:5021
  137 |   expect(config.baseUrl1, 'appConfig.baseUrl1 应有值').toBeTruthy();
  138 | 
  139 |   // 验证未被覆盖为前端地址
  140 |   const isNotOverwritten = config.baseUrl1 === 'http://localhost:8088';
  141 |   console.log('baseUrl1 kept original (8088):', isNotOverwritten);
  142 |   expect(isNotOverwritten,
  143 |     '嵌入模式不应覆盖 baseUrl1 — 预期 http://localhost:8088，实际 ' + config.baseUrl1
  144 |   ).toBe(true);
  145 | 
  146 |   expect(config.newFenluApiBase, 'newFenluApiBase 应保留原始值')
  147 |     .toBe('http://localhost:8088/api');
  148 | });
  149 | 
  150 | // =====================================================================
  151 | // Test 2: API 请求 host — 验证请求发往 8088 而非前端 origin
  152 | // =====================================================================
  153 | test('NETFIX-02: API 请求直连 8088 — 不经过前端代理', async ({ page }) => {
  154 |   const useMock = test.info().project.use.useMock;
  155 |   const apiHosts = [];
  156 | 
  157 |   if (useMock) {
  158 |     await page.route('**/api/**', (route, request) => {
  159 |       const url = new URL(request.url());
  160 |       apiHosts.push({ host: url.host, pathname: url.pathname, fullUrl: request.url() });
  161 |       route.fulfill({
  162 |         contentType: 'application/json',
  163 |         body: JSON.stringify({ success: true, result: { totalCount: 0, items: [] } })
  164 |       });
  165 |     });
  166 | 
  167 |     // 放行静态资源
  168 |     await page.route('**/*.html*', route => route.continue());
  169 |     await page.route('**/*.js', route => route.continue());
  170 |     await page.route('**/*.css', route => route.continue());
  171 |   }
  172 | 
  173 |   await page.addInitScript(() => {
  174 |     localStorage.setItem('token', 'Bearer-mock-token');
  175 |     localStorage.setItem('xToken', 'Bearer-mock-token');
  176 |   });
  177 | 
  178 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
  179 |     waitUntil: 'networkidle', timeout: 30000
  180 |   });
  181 |   await page.waitForTimeout(4000);
  182 | 
  183 |   console.log('API requests:', apiHosts.length);
  184 |   apiHosts.forEach(r => console.log('  ', r.host, r.pathname));
  185 | 
  186 |   // 关键断言：API 请求不应发往 8095（HRM 前端地址）
  187 |   const badHosts = apiHosts.filter(r =>
  188 |     r.host.includes('8095') || r.host.includes('50350')
  189 |   );
  190 |   expect(badHosts.length, 'API 请求不应发往 8095 或 50350').toBe(0);
  191 | 
  192 |   // 如果有 API 请求，host 应一致
  193 |   const uniqueHosts = [...new Set(apiHosts.map(r => r.host))];
  194 |   console.log('Unique API hosts:', uniqueHosts);
  195 |   expect(uniqueHosts.length, '所有 API 请求应在同一 host').toBeLessThanOrEqual(2);
  196 | });
  197 | 
  198 | // =====================================================================
  199 | // Test 3: base-path 设置 — 弹窗页面资源路径
  200 | // =====================================================================
  201 | test('NETFIX-03: base-path 设置逻辑验证 — 代码审查确认', async ({ page }) => {
  202 |   // 验证 baseService.js 嵌入模式中 base-path 设置逻辑正确
  203 |   // baseService.js 代码 (line 21-23):
  204 |   //   if (!localStorage.getItem("base-path")) {
  205 |   //     localStorage.setItem("base-path",
  206 |   //       (appConfig && appConfig.baseUrl1) ||
  207 |   //       (appConfig && appConfig.newFenluApiBase) || '');
  208 |   //   }
  209 | 
  210 |   await page.addInitScript(() => {
  211 |     localStorage.setItem('token', 'Bearer-mock-token');
  212 |     localStorage.setItem('xToken', 'Bearer-mock-token');
  213 |     localStorage.removeItem('base-path');
  214 |     window.appConfig = {
  215 |       baseUrl1: 'http://localhost:8088',
  216 |       baseUrl2: 'http://localhost:8088',
  217 |       newFenluApiBase: 'http://localhost:8088/api',
  218 |     };
  219 |   });
  220 | 
  221 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/create_edit.html'), {
```