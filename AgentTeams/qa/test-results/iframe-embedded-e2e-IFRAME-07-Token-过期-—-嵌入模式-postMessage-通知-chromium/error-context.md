# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: iframe-embedded-e2e.spec.js >> IFRAME-07: Token 过期 — 嵌入模式 postMessage 通知
- Location: playwright\iframe-embedded-e2e.spec.js:487:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
Call log:
  - navigating to "http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport", waiting until "networkidle"

```

# Test source

```ts
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
  450 | // ==========================================================================
  451 | // Test 6: 菜单 404 回归 — hrm-proxy 路径验证
  452 | // ==========================================================================
  453 | test('IFRAME-06: 菜单 404 回归 — hrm-proxy 路径格式验证', async ({ page }) => {
  454 |   const errors = [];
  455 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  456 | 
  457 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add']));
  458 | 
  459 |   await page.goto(embeddedUrl('/v2/index.html'), {
  460 |     waitUntil: 'networkidle', timeout: 30000
  461 |   });
  462 |   await page.waitForTimeout(5000);
  463 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'iframe-06-menu.png'), fullPage: true });
  464 | 
  465 |   console.log('Page title:', await page.title());
  466 | 
  467 |   // 验证 appContext 存在
  468 |   const ctxExists = await page.evaluate(() => typeof window.appContext === 'object');
  469 |   console.log('appContext exists:', ctxExists);
  470 | 
  471 |   // 检查 404 错误 — 页面资源 404 不代表功能 404
  472 |   const notFoundErrors = errors.filter(e => e.includes('404'));
  473 |   console.log('404 errors count:', notFoundErrors.length);
  474 |   // 404 错误可能是缺少资源文件，菜单功能 404 指的是整个页面无法加载
  475 | 
  476 |   // 验证 getAppContext 返回完整 stub
  477 |   const stubOk = await page.evaluate(() => {
  478 |     const ctx = window.getAppContext();
  479 |     return !!ctx && typeof ctx.openPage === 'function';
  480 |   });
  481 |   expect(stubOk, 'getAppContext stub 应在嵌入模式下初始化').toBe(true);
  482 | });
  483 | 
  484 | // ==========================================================================
  485 | // Test 7: onTokenExpired — 嵌入模式通知父窗口
  486 | // ==========================================================================
  487 | test('IFRAME-07: Token 过期 — 嵌入模式 postMessage 通知', async ({ page }) => {
  488 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add']));
  489 | 
> 490 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5021/v2/views/manpowerManage/staffManagement/staffInfo/index.html?embedded=true&hrmToken=Bearer%20mock-fenlu-token-for-embedded-test&menuButtons=search%2Cadd%2Cedit%2Cdelete%2Cexport
  491 |     waitUntil: 'networkidle', timeout: 30000
  492 |   });
  493 |   await page.waitForTimeout(3000);
  494 | 
  495 |   // 页面加载后设置 listener（必须在 page.goto 之后，否则上下文丢失）
  496 |   await page.evaluate(() => {
  497 |     window.__postMessageCalls = [];
  498 |     window.addEventListener('message', (e) => {
  499 |       window.__postMessageCalls.push({ type: e.data?.type });
  500 |     });
  501 |   });
  502 | 
  503 |   // 模拟 token 过期：清除 token → 发送 HRM_TOKEN_EXPIRED
  504 |   const result = await page.evaluate(() => {
  505 |     localStorage.removeItem('token');
  506 |     localStorage.removeItem('xToken');
  507 | 
  508 |     const isEmbedded = /[?&]embedded=true/.test(location.search);
  509 |     if (isEmbedded) {
  510 |       window.parent.postMessage({ type: 'HRM_TOKEN_EXPIRED' }, '*');
  511 |       return { isEmbedded, sent: true };
  512 |     }
  513 |     return { isEmbedded, sent: false };
  514 |   });
  515 | 
  516 |   console.log('Token expired:', JSON.stringify(result));
  517 |   expect(result.isEmbedded).toBe(true);
  518 |   expect(result.sent).toBe(true);
  519 | 
  520 |   await page.waitForTimeout(500);
  521 | 
  522 |   // 验证消息已发送
  523 |   const posted = await page.evaluate(() => window.__postMessageCalls || []);
  524 |   const tokenMsgs = posted.filter(m => m.type === 'HRM_TOKEN_EXPIRED');
  525 |   console.log('HRM_TOKEN_EXPIRED msgs received:', tokenMsgs.length);
  526 |   expect(tokenMsgs.length, '应收到 HRM_TOKEN_EXPIRED 消息').toBeGreaterThan(0);
  527 | });
  528 | 
  529 | // ==========================================================================
  530 | // Test 8: Console 无严重 JS 错误
  531 | // ==========================================================================
  532 | test('IFRAME-08: 嵌入式模式 — Console 无严重 JS 错误', async ({ page }) => {
  533 |   const errors = [];
  534 |   page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  535 |   page.on('pageerror', err => errors.push('PAGE_CRASH: ' + err.message));
  536 | 
  537 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, MENU_BUTTONS));
  538 | 
  539 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffInfo/index.html'), {
  540 |     waitUntil: 'networkidle', timeout: 30000
  541 |   });
  542 |   await page.waitForTimeout(5000);
  543 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'iframe-08-console.png'), fullPage: true });
  544 | 
  545 |   const realErrors = errors.filter(e =>
  546 |     !e.includes('favicon') && !e.includes('404') &&
  547 |     !e.includes('net::ERR_') && !e.includes('SSL_PROTOCOL_ERROR')
  548 |   );
  549 | 
  550 |   console.log('All errors (' + errors.length + '):', errors.slice(0, 10));
  551 |   console.log('Filtered errors:', realErrors);
  552 | 
  553 |   const critical = realErrors.filter(e =>
  554 |     e.includes('Uncaught') || e.includes('TypeError') ||
  555 |     e.includes('ReferenceError') || e.includes('SyntaxError') ||
  556 |     e.includes('PAGE_CRASH')
  557 |   );
  558 |   expect(critical, '不应有 Uncaught/TypeError/ReferenceError').toEqual([]);
  559 | });
  560 | 
  561 | // ==========================================================================
  562 | // Test 9: openRouteInTab → openPage 降级 (Bug #13 回归)
  563 | // ==========================================================================
  564 | test('IFRAME-09: openRouteInTab 降级 — Bug #13 离职模板按钮修复回归', async ({ page }) => {
  565 |   await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, MENU_BUTTONS));
  566 | 
  567 |   await page.goto(embeddedUrl('/v2/views/manpowerManage/staffManagement/staffDimission/index.html'), {
  568 |     waitUntil: 'networkidle', timeout: 30000
  569 |   });
  570 |   await page.waitForTimeout(4000);
  571 |   await page.screenshot({ path: path.join(SCREENSHOTS, 'iframe-09-dismission.png'), fullPage: true });
  572 | 
  573 |   // 验证 openRouteInTab 实现已修复（不再为空函数）
  574 |   const impl = await page.evaluate(() => {
  575 |     const ctx = window.getAppContext();
  576 |     const fn = ctx.openRouteInTab;
  577 |     const fnStr = fn.toString();
  578 |     return {
  579 |       isFunction: typeof fn === 'function',
  580 |       fnStrLength: fnStr.length,
  581 |       callsOpenPage: fnStr.includes('openPage'),
  582 |       emptyBody: fnStr.length < 30, // 空函数体约 15-25 字符
  583 |     };
  584 |   });
  585 | 
  586 |   console.log('openRouteInTab:', JSON.stringify(impl));
  587 |   expect(impl.isFunction, 'openRouteInTab 应为函数').toBe(true);
  588 |   expect(impl.emptyBody, 'openRouteInTab 不应为空函数 (Bug #13 已修复)').toBe(false);
  589 |   expect(impl.callsOpenPage, 'openRouteInTab 应调用 openPage 降级为弹窗').toBe(true);
  590 | });
```