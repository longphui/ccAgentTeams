# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: iframe-embedded-e2e.spec.js >> IFRAME-05: openPage 弹窗 — states Map 和 stateKey 流程验证
- Location: playwright\iframe-embedded-e2e.spec.js:346:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport", waiting until "networkidle"

```

# Test source

```ts
  249 |   expect(badHosts.length, 'API 请求不应发往错误的端口 (50350/8095)').toBe(0);
  250 | 
  251 |   const uniqueHosts = [...new Set(apiRequests.map(r => r.host))];
  252 |   console.log('Unique API hosts:', uniqueHosts);
  253 |   expect(uniqueHosts.length, '所有 API 请求 host 应一致').toBeLessThanOrEqual(2);
  254 | });
  255 | 
  256 | // ==========================================================================
  257 | // Test 3: checkTabPermissions — menuButtons 权限验证
  258 | // ==========================================================================
  259 | test('IFRAME-03: checkTabPermissions — menuButtons 参数传递验证', async ({ page }) => {
  260 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add', 'edit', 'export']));
  261 | 
  262 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
  263 |     waitUntil: 'networkidle', timeout: 30000
  264 |   });
  265 |   await page.waitForTimeout(3000);
  266 | 
  267 |   const permResults = await page.evaluate(() => {
  268 |     const ctx = window.getAppContext();
  269 |     const checkFn = ctx.route.checkTabPermissions;
  270 |     const results = {};
  271 |     ['search', 'add', 'edit', 'export', 'delete', 'approve'].forEach(btn => {
  272 |       results['has_' + btn] = checkFn('any/path', btn);
  273 |     });
  274 |     return results;
  275 |   });
  276 | 
  277 |   console.log('Permission check results:', JSON.stringify(permResults));
  278 | 
  279 |   // menuButtons 包含的按钮应有权限
  280 |   expect(permResults.has_search, 'search 应有权限 → true').toBe(true);
  281 |   expect(permResults.has_add, 'add 应有权限 → true').toBe(true);
  282 |   expect(permResults.has_edit, 'edit 应有权限 → true').toBe(true);
  283 |   expect(permResults.has_export, 'export 应有权限 → true').toBe(true);
  284 | 
  285 |   // 不在 menuButtons 中的按钮应无权限
  286 |   expect(permResults.has_delete, 'delete 无权限 → false').toBe(false);
  287 |   expect(permResults.has_approve, 'approve 无权限 → false').toBe(false);
  288 | });
  289 | 
  290 | // ==========================================================================
  291 | // Test 4: getAppContext stub — 完整性审计 (Bug #11/#12 回归)
  292 | // ==========================================================================
  293 | test('IFRAME-04: getAppContext stub — 所有方法和属性完整性', async ({ page }) => {
  294 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add']));
  295 | 
  296 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
  297 |     waitUntil: 'networkidle', timeout: 30000
  298 |   });
  299 |   await page.waitForTimeout(3000);
  300 | 
  301 |   const audit = await page.evaluate(() => {
  302 |     const ctx = window.getAppContext();
  303 |     const theme = ctx.theme;
  304 |     const defaultTheme = theme.getDefaultTheme();
  305 | 
  306 |     return {
  307 |       route_type: typeof ctx.route,
  308 |       route_hasCheckTabPermissions: typeof ctx.route.checkTabPermissions === 'function',
  309 |       theme_hasApplyTheme: typeof theme.applyTheme === 'function',
  310 |       theme_hasApplyThemeToTarget: typeof theme.applyThemeToTarget === 'function',
  311 |       theme_hasGetDefaultTheme: typeof theme.getDefaultTheme === 'function',
  312 |       defaultTheme_hasOptions: !!defaultTheme?.options,
  313 |       defaultTheme_hasColorPrimary: !!defaultTheme?.options?.colorPrimary,
  314 |       defaultTheme_colorPrimary: defaultTheme?.options?.colorPrimary,
  315 |       openPage_type: typeof ctx.openPage,
  316 |       openRouteInTab_type: typeof ctx.openRouteInTab,
  317 |       openWindow_type: typeof ctx.openWindow,
  318 |       states_isMap: ctx.states instanceof Map,
  319 |       getShareStateKey_type: typeof ctx.getShareStateKey,
  320 |       menu_hasItems: Array.isArray(ctx.menu?.items),
  321 |       layout_hasApplyLayout: typeof ctx.layout?.applyLayout === 'function',
  322 |     };
  323 |   });
  324 | 
  325 |   console.log('Stub audit:', JSON.stringify(audit, null, 2));
  326 | 
  327 |   expect(audit.route_type).toBe('object');
  328 |   expect(audit.route_hasCheckTabPermissions).toBe(true);
  329 |   expect(audit.theme_hasApplyTheme, 'theme.applyTheme 应存在').toBe(true);
  330 |   expect(audit.theme_hasApplyThemeToTarget, 'theme.applyThemeToTarget 应存在 (Bug #11)').toBe(true);
  331 |   expect(audit.theme_hasGetDefaultTheme, 'theme.getDefaultTheme 应存在').toBe(true);
  332 |   expect(audit.defaultTheme_hasOptions, 'getDefaultTheme 应返回 options').toBe(true);
  333 |   expect(audit.defaultTheme_hasColorPrimary, 'getDefaultTheme 应有 colorPrimary (Bug #12)').toBe(true);
  334 |   expect(audit.defaultTheme_colorPrimary, 'colorPrimary 应为 #16BAAA').toBe('#16BAAA');
  335 |   expect(audit.openPage_type, 'openPage 应为 function').toBe('function');
  336 |   expect(audit.openRouteInTab_type, 'openRouteInTab 应为 function').toBe('function');
  337 |   expect(audit.openWindow_type, 'openWindow 应为 function').toBe('function');
  338 |   expect(audit.states_isMap, 'states 应为 Map (Bug #15)').toBe(true);
  339 |   expect(audit.getShareStateKey_type, 'getShareStateKey 应为 function').toBe('function');
  340 |   expect(audit.layout_hasApplyLayout, 'layout.applyLayout 应存在').toBe(true);
  341 | });
  342 | 
  343 | // ==========================================================================
  344 | // Test 5: openPage 弹窗 — states 创建和 state.onConfirm 流程验证
  345 | // ==========================================================================
  346 | test('IFRAME-05: openPage 弹窗 — states Map 和 stateKey 流程验证', async ({ page }) => {
  347 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add', 'edit']));
  348 | 
> 349 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
  350 |     waitUntil: 'networkidle', timeout: 30000
  351 |   });
  352 |   await page.waitForTimeout(4000);
  353 | 
  354 |   // 调用 openPage，验证 state 创建和 stateKey 生成
  355 |   const openResult = await page.evaluate(() => {
  356 |     try {
  357 |       const ctx = window.getAppContext();
  358 |       const statesBefore = ctx.states.size;
  359 |       ctx.openPage(
  360 |         '/v2/views/manpowerManage/staffManagement/staffInfo/create_edit.html',
  361 |         { name: 'test-user', id: 42 },
  362 |         { title: '测试弹窗 — 嵌入模式', area: ['70%', '80%'] },
  363 |         { noBtn: true }
  364 |       );
  365 |       const statesAfter = ctx.states.size;
  366 | 
  367 |       // 获取新创建的 state
  368 |       let lastState = null;
  369 |       let lastStateKey = null;
  370 |       ctx.states.forEach((value, key) => {
  371 |         lastState = value;
  372 |         lastStateKey = key;
  373 |       });
  374 | 
  375 |       return {
  376 |         success: true,
  377 |         statesBefore,
  378 |         statesAfter,
  379 |         stateCreated: statesAfter > statesBefore,
  380 |         hasStateKey: typeof lastStateKey === 'string' && lastStateKey.startsWith('stub_'),
  381 |         stateHasValue: lastState?.value?.name === 'test-user',
  382 |         stateHasReturn: typeof lastState?.return === 'function',
  383 |         stateOnConfirmUndefined: lastState?.onConfirm === undefined,
  384 |         stateHasExtraBtns: Array.isArray(lastState?.extraBtns),
  385 |         error: null
  386 |       };
  387 |     } catch(e) {
  388 |       return { success: false, error: e.message };
  389 |     }
  390 |   });
  391 | 
  392 |   console.log('openPage result:', JSON.stringify(openResult));
  393 |   expect(openResult.success, 'openPage 调用应成功').toBe(true);
  394 |   expect(openResult.stateCreated, 'states Map 应新增一条记录').toBe(true);
  395 |   expect(openResult.hasStateKey, 'stateKey 应以 stub_ 开头').toBe(true);
  396 |   expect(openResult.stateHasValue, 'state.value 应包含传入的 data').toBe(true);
  397 |   expect(openResult.stateHasReturn, 'state.return 应为函数').toBe(true);
  398 |   expect(openResult.stateOnConfirmUndefined, 'state.onConfirm 初始应为 undefined').toBe(true);
  399 |   expect(openResult.stateHasExtraBtns, 'state.extraBtns 应为数组').toBe(true);
  400 | 
  401 |   // 验证 onConfirm 回调流程 (Bug #2 回归: 保存按钮无反应)
  402 |   const confirmResult = await page.evaluate(() => {
  403 |     const ctx = window.getAppContext();
  404 |     let lastState = null;
  405 |     ctx.states.forEach((value) => { lastState = value; });
  406 | 
  407 |     if (!lastState) return { error: 'no state found' };
  408 | 
  409 |     // 模拟表单页面调用 state.onConfirm = this.save
  410 |     let saveResult = null;
  411 |     lastState.onConfirm = function() {
  412 |       saveResult = { saved: true, data: this.value };
  413 |       return true; // 同步返回 true → 关闭弹窗
  414 |     };
  415 | 
  416 |     // 触发确定按钮逻辑（模拟 openPage 中的确认按钮 callback）
  417 |     let closed = false;
  418 |     const mockLayer = {
  419 |       close: function(id) { closed = true; }
  420 |     };
  421 |     const state = lastState;
  422 |     const id = 1;
  423 | 
  424 |     // 执行 openPage stub 中"确定"按钮的 callback 逻辑
  425 |     if (state.onConfirm && typeof state.onConfirm === 'function') {
  426 |       var res = state.onConfirm();
  427 |       if (res === true) {
  428 |         mockLayer.close(id);
  429 |       } else if (res && typeof res.then === 'function') {
  430 |         // Promise 分支 — 不在本次测试
  431 |       } else {
  432 |         mockLayer.close(id);
  433 |       }
  434 |     }
  435 | 
  436 |     return {
  437 |       saveCalled: saveResult?.saved === true,
  438 |       saveData: saveResult?.data,
  439 |       layerClosed: closed,
  440 |     };
  441 |   });
  442 | 
  443 |   console.log('Confirm callback:', JSON.stringify(confirmResult));
  444 |   expect(confirmResult.saveCalled, 'onConfirm 回调应触发 save 方法').toBe(true);
  445 |   expect(confirmResult.layerClosed, '同步返回 true 应关闭弹窗').toBe(true);
  446 | 
  447 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'iframe-05-openpage-states.png'), fullPage: true });
  448 | });
  449 | 
```