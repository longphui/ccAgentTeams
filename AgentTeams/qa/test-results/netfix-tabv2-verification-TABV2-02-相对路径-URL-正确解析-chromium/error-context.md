# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: netfix-tabv2-verification.spec.js >> TABV2-02: 相对路径 URL 正确解析
- Location: playwright\netfix-tabv2-verification.spec.js:305:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit", waiting until "networkidle"

```

# Test source

```ts
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
  222 |     waitUntil: 'networkidle', timeout: 30000
  223 |   });
  224 |   await page.waitForTimeout(4000);
  225 | 
  226 |   // 直接执行 baseService.js 中的 base-path 设置逻辑
  227 |   const result = await page.evaluate(() => {
  228 |     const appConfig = window.appConfig;
  229 | 
  230 |     // 模拟 baseService.js 嵌入模式的 base-path 设置逻辑
  231 |     if (!localStorage.getItem('base-path')) {
  232 |       const bp = (appConfig && appConfig.baseUrl1)
  233 |         || (appConfig && appConfig.newFenluApiBase) || '';
  234 |       localStorage.setItem('base-path', bp);
  235 |     }
  236 | 
  237 |     return {
  238 |       basePath: localStorage.getItem('base-path'),
  239 |       expectedFromBaseUrl1: appConfig?.baseUrl1,
  240 |       expectedFromNewApi: appConfig?.newFenluApiBase,
  241 |     };
  242 |   });
  243 | 
  244 |   console.log('base-path logic result:', JSON.stringify(result));
  245 | 
  246 |   // base-path 应被正确设置
  247 |   expect(result.basePath, 'base-path 应被设置').toBeTruthy();
  248 |   // 逻辑: 优先使用 baseUrl1 → 其次 newFenluApiBase → 最后 fallback ''
  249 |   expect(result.basePath, 'base-path 应为 baseUrl1 的值 (8088)')
  250 |     .toBe('http://localhost:8088');
  251 | });
  252 | 
  253 | // =====================================================================
  254 | // Test 4: openRouteInTab v2 — HRM_OPEN_TAB postMessage
  255 | // =====================================================================
  256 | test('TABV2-01: openRouteInTab 发送 HRM_OPEN_TAB postMessage', async ({ page }) => {
  257 |   await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));
  258 | 
  259 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
  260 |     waitUntil: 'networkidle', timeout: 30000
  261 |   });
  262 |   await page.waitForTimeout(4000);
  263 | 
  264 |   // 设置 postMessage 监听
  265 |   await page.evaluate(() => {
  266 |     window.__hrmMessages = [];
  267 |     window.addEventListener('message', (e) => {
  268 |       if (e.data?.type?.startsWith('HRM_')) {
  269 |         window.__hrmMessages.push({
  270 |           type: e.data.type,
  271 |           url: e.data.url,
  272 |           title: e.data.title,
  273 |         });
  274 |       }
  275 |     });
  276 |   });
  277 | 
  278 |   // 模拟点击"设置离职模板"按钮 → 调用 openRouteInTab
  279 |   const result = await page.evaluate(() => {
  280 |     const ctx = window.getAppContext();
  281 |     const route = {
  282 |       path: '../User/Employee/ResignProof.html',
  283 |       name: '设置离职模板'
  284 |     };
  285 |     ctx.openRouteInTab(route, { templateId: 123 }, null);
  286 |     return { called: true };
  287 |   });
  288 |   console.log('openRouteInTab called:', result.called);
  289 |   expect(result.called).toBe(true);
  290 | 
  291 |   await page.waitForTimeout(500);
  292 | 
  293 |   // 验证 HRM_OPEN_TAB 消息
  294 |   const messages = await page.evaluate(() => window.__hrmMessages || []);
  295 |   console.log('HRM messages:', JSON.stringify(messages));
  296 | 
  297 |   const openTabMsg = messages.find(m => m.type === 'HRM_OPEN_TAB');
  298 |   expect(openTabMsg, '应发送 HRM_OPEN_TAB postMessage').toBeTruthy();
  299 |   expect(openTabMsg.title, '消息 title 应为"设置离职模板"').toBe('设置离职模板');
  300 | });
  301 | 
  302 | // =====================================================================
  303 | // Test 5: openRouteInTab v2 — URL 解析正确
  304 | // =====================================================================
  305 | test('TABV2-02: 相对路径 URL 正确解析', async ({ page }) => {
  306 |   await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));
  307 | 
> 308 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
  309 |     waitUntil: 'networkidle', timeout: 30000
  310 |   });
  311 |   await page.waitForTimeout(4000);
  312 | 
  313 |   // 设置监听并调用
  314 |   const urlResult = await page.evaluate(() => {
  315 |     window.__hrmMessages = [];
  316 |     window.addEventListener('message', (e) => {
  317 |       if (e.data?.type === 'HRM_OPEN_TAB') {
  318 |         window.__hrmMessages.push(e.data);
  319 |       }
  320 |     });
  321 | 
  322 |     const ctx = window.getAppContext();
  323 | 
  324 |     // 测试 ../User/Employee/ResignProof.html 路径解析
  325 |     ctx.openRouteInTab(
  326 |       { path: '../User/Employee/ResignProof.html', name: '离职模板' },
  327 |       null, null
  328 |     );
  329 | 
  330 |     return { origin: location.origin };
  331 |   });
  332 | 
  333 |   await page.waitForTimeout(500);
  334 | 
  335 |   const messages = await page.evaluate(() => window.__hrmMessages || []);
  336 |   console.log('Resolved URL:', messages[0]?.url);
  337 | 
  338 |   if (messages.length > 0) {
  339 |     const url = messages[0].url;
  340 |     // URL 应包含 ResignProof.html
  341 |     expect(url, 'URL 应包含 ResignProof.html').toMatch(/ResignProof\.html/);
  342 |     // URL 应包含 stateKey
  343 |     expect(url, 'URL 应包含 stateKey 参数').toMatch(/stateKey=stub_/);
  344 |     // URL 不应包含 ../ (相对路径应被解析)
  345 |     expect(url, 'URL 不应包含 ../ (应被 new URL() 解析)').not.toMatch(/\.\.\//);
  346 |     // URL 应是绝对 URL
  347 |     expect(url, 'URL 应以 http 开头').toMatch(/^https?:\/\//);
  348 |   }
  349 | });
  350 | 
  351 | // =====================================================================
  352 | // Test 6: openRouteInTab v2 — getState() 数据传递
  353 | // =====================================================================
  354 | test('TABV2-03: getState() 可获取传递的数据', async ({ page }) => {
  355 |   await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));
  356 | 
  357 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
  358 |     waitUntil: 'networkidle', timeout: 30000
  359 |   });
  360 |   await page.waitForTimeout(4000);
  361 | 
  362 |   const stateResult = await page.evaluate(() => {
  363 |     const ctx = window.getAppContext();
  364 |     const testData = { templateId: 456, name: '测试模板' };
  365 | 
  366 |     // 调用 openRouteInTab，不设置 ok 回调
  367 |     ctx.openRouteInTab(
  368 |       { path: '../User/Employee/ResignProof.html', name: '离职模板' },
  369 |       testData,
  370 |       null
  371 |     );
  372 | 
  373 |     // 从 states Map 获取最后一条
  374 |     let lastState = null;
  375 |     let lastStateKey = null;
  376 |     ctx.states.forEach((value, key) => {
  377 |       lastState = value;
  378 |       lastStateKey = key;
  379 |     });
  380 | 
  381 |     return {
  382 |       stateKey: lastStateKey,
  383 |       hasValue: lastState?.value !== null,
  384 |       templateId: lastState?.value?.templateId,
  385 |       templateName: lastState?.value?.name,
  386 |       hasReturn: typeof lastState?.return === 'function',
  387 |       onConfirmUndefined: lastState?.onConfirm === undefined,
  388 |     };
  389 |   });
  390 | 
  391 |   console.log('State result:', JSON.stringify(stateResult));
  392 | 
  393 |   // state 应包含传入的数据
  394 |   expect(stateResult.hasValue, 'state.value 应有数据').toBe(true);
  395 |   expect(stateResult.templateId, 'state.value.templateId 应为 456').toBe(456);
  396 |   expect(stateResult.templateName, 'state.value.name 应为"测试模板"').toBe('测试模板');
  397 |   expect(stateResult.hasReturn, 'state.return 应为函数').toBe(true);
  398 |   expect(stateResult.onConfirmUndefined, 'state.onConfirm 初始为 undefined').toBe(true);
  399 |   expect(stateResult.stateKey, 'stateKey 应以 stub_ 开头').toMatch(/^stub_/);
  400 | });
  401 | 
  402 | // =====================================================================
  403 | // Test 7: openRouteInTab v2 — ok 回调在 return() 时触发
  404 | // =====================================================================
  405 | test('TABV2-04: state.return() 触发 ok 回调', async ({ page }) => {
  406 |   await page.addInitScript(injectEmbeddedEnv('Bearer-test-token', ['search', 'add']));
  407 | 
  408 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
```