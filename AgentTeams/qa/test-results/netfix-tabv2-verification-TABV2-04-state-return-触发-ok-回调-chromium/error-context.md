# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: netfix-tabv2-verification.spec.js >> TABV2-04: state.return() 触发 ok 回调
- Location: playwright\netfix-tabv2-verification.spec.js:405:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit", waiting until "networkidle"

```

# Test source

```ts
  308 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
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
> 408 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffDimission/index.html?embedded=true&hrmToken=Bearer-mock-token-for-test&menuButtons=search,add,edit
  409 |     waitUntil: 'networkidle', timeout: 30000
  410 |   });
  411 |   await page.waitForTimeout(4000);
  412 | 
  413 |   const callbackResult = await page.evaluate(() => {
  414 |     const ctx = window.getAppContext();
  415 | 
  416 |     let okCalled = false;
  417 |     let okValue = null;
  418 | 
  419 |     ctx.openRouteInTab(
  420 |       { path: 'some/page.html', name: '测试页面' },
  421 |       { data: 'test' },
  422 |       function(val) { okCalled = true; okValue = val; }
  423 |     );
  424 | 
  425 |     // 获取 state 并调用 return
  426 |     let lastState = null;
  427 |     ctx.states.forEach((value) => { lastState = value; });
  428 | 
  429 |     if (lastState && lastState.return) {
  430 |       lastState.return({ result: 'success' });
  431 |     }
  432 | 
  433 |     return {
  434 |       stateExists: !!lastState,
  435 |       hasReturn: typeof lastState?.return === 'function',
  436 |       okCalled,
  437 |       okValue,
  438 |     };
  439 |   });
  440 | 
  441 |   console.log('Callback result:', JSON.stringify(callbackResult));
  442 | 
  443 |   expect(callbackResult.stateExists, 'state 应被创建').toBe(true);
  444 |   expect(callbackResult.hasReturn, 'state.return 应为函数').toBe(true);
  445 |   expect(callbackResult.okCalled, 'ok 回调应被 state.return() 触发').toBe(true);
  446 |   expect(callbackResult.okValue, 'ok 应收到正确的值').toEqual({ result: 'success' });
  447 | });
  448 | 
```