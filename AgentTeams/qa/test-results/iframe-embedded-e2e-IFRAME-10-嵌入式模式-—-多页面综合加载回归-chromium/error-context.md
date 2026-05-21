# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: iframe-embedded-e2e.spec.js >> IFRAME-10: 嵌入式模式 — 多页面综合加载回归
- Location: playwright\iframe-embedded-e2e.spec.js:595:1

# Error details

```
Error: "员工信息列表" 应加载成功

expect(received).toBe(expected) // Object.is equality

Expected: true
Received: false
```

# Test source

```ts
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
  591 | 
  592 | // ==========================================================================
  593 | // Test 10: 多页面加载 — 嵌入式模式综合回归
  594 | // ==========================================================================
  595 | test('IFRAME-10: 嵌入式模式 — 多页面综合加载回归', async ({ page }) => {
  596 |   const pages = [
  597 |     { name: '员工信息列表', url: '/v2/views/manpowerManage/staffManagement/staffInfo/index.html' },
  598 |     { name: '员工入职登记', url: '/v2/views/manpowerManage/staffManagement/staffInfo/create_edit.html' },
  599 |     { name: '离职员工', url: '/v2/views/manpowerManage/staffManagement/staffDimission/index.html' },
  600 |   ];
  601 | 
  602 |   const results = [];
  603 | 
  604 |   for (const testPage of pages) {
  605 |     const errors = [];
  606 |     page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  607 | 
  608 |     await page.addInitScript(injectEmbeddedEnv(HRM_TOKEN, ['search', 'add', 'edit']));
  609 | 
  610 |     try {
  611 |       await page.goto(embeddedUrl(testPage.url), { waitUntil: 'networkidle', timeout: 30000 });
  612 |       await page.waitForTimeout(3000);
  613 | 
  614 |       // 验证页面非空
  615 |       const bodyTextLen = await page.evaluate(() => document.body?.innerText?.length || 0);
  616 | 
  617 |       // 验证 getAppContext 可用
  618 |       const ctxOk = await page.evaluate(() => {
  619 |         const ctx = window.getAppContext();
  620 |         return !!ctx && typeof ctx.openPage === 'function';
  621 |       });
  622 | 
  623 |       // 验证 appConfig 正确
  624 |       const baseUrl = await page.evaluate(() => window.appConfig?.baseUrl1);
  625 | 
  626 |       const criticalErrors = errors.filter(e =>
  627 |         (e.includes('Uncaught') || e.includes('TypeError') || e.includes('ReferenceError'))
  628 |         && !e.includes('favicon') && !e.includes('404')
  629 |       );
  630 | 
  631 |       results.push({
  632 |         page: testPage.name,
  633 |         loaded: true,
  634 |         hasContent: bodyTextLen > 0,
  635 |         ctxOk,
  636 |         baseUrl,
  637 |         errorCount: criticalErrors.length,
  638 |       });
  639 | 
  640 |       await page.screenshot({
  641 |         path: path.join(SCREENSHOTS, 'iframe-10-' + testPage.name.replace(/[^\w]/g, '-') + '.png'),
  642 |         fullPage: true
  643 |       });
  644 |     } catch (e) {
  645 |       results.push({ page: testPage.name, loaded: false, error: e.message });
  646 |     }
  647 |   }
  648 | 
  649 |   console.log('Multi-page results:');
  650 |   results.forEach(r => console.log('  ', r.page,
  651 |     r.loaded ? 'LOADED' : 'FAILED',
  652 |     r.ctxOk ? 'CTX' : 'NOCTX',
  653 |     r.baseUrl ? r.baseUrl : 'NOURL',
  654 |     r.errorCount ? 'errs:' + r.errorCount : ''
  655 |   ));
  656 | 
  657 |   // 所有页面应加载成功
  658 |   results.forEach(r => {
> 659 |     expect(r.loaded, `"${r.page}" 应加载成功`).toBe(true);
      |                                           ^ Error: "员工信息列表" 应加载成功
  660 |     expect(r.ctxOk, `"${r.page}" getAppContext 应可用`).toBe(true);
  661 |     expect(r.baseUrl, `"${r.page}" appConfig.baseUrl1 应存在`).toBeTruthy();
  662 |   });
  663 | });
  664 | 
```