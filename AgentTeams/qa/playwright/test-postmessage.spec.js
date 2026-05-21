const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  const results = [];
  const errors = [];

  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text());
  });

  // Test 1: 验证 hrm-proxy 页面加载 + 检查 window.top 引用（不依赖 ERP 容器）
  console.log('=== Test 1: hrm-proxy 页面独立加载 ===');

  // 拦截 postMessage 请求，验证使用的是 window.top
  let postMessageCalls = [];
  await page.exposeFunction('recordPostMessage', (detail) => {
    postMessageCalls.push(detail);
  });

  await page.goto('http://localhost:5021/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html', {
    waitUntil: 'networkidle'
  });

  // Check that the page used window.top (not window.parent) by evaluating
  const usesTopPostMessage = await page.evaluate(() => {
    const html = document.documentElement.outerHTML;
    // Count occurrences
    const topCount = (html.match(/window\.top\.postMessage/g) || []).length;
    const parentCount = (html.match(/window\.parent\.postMessage/g) || []).length;
    return { topCount, parentCount };
  });

  console.log('postMessage 引用检查:', JSON.stringify(usesTopPostMessage));

  if (usesTopPostMessage.topCount >= 2 && usesTopPostMessage.parentCount === 0) {
    console.log('✅ PASS: 使用 window.top.postMessage (2处), 不使用 window.parent');
    results.push({ test: 'postMessage 修复验证', result: 'PASS' });
  } else {
    console.log(`❌ FAIL: top=${usesTopPostMessage.topCount}, parent=${usesTopPostMessage.parentCount}`);
    results.push({ test: 'postMessage 修复验证', result: 'FAIL' });
  }

  // Wait for timeout message (no parent context available in this test)
  await page.waitForTimeout(5500);

  const pageText = await page.textContent('body');
  if (pageText.includes('HRM 认证超时')) {
    console.log('ℹ️  INFO: 独立加载时显示"HRM 认证超时"（预期行为 — 无 ERP 容器提供 context）');
  }

  // Check JS errors
  const relevantErrors = errors.filter(e =>
    !e.includes('favicon') && !e.includes('HRM 认证超时')
  );
  if (relevantErrors.length === 0) {
    console.log('✅ PASS: 无 JS 运行时错误');
    results.push({ test: '脚本错误检查', result: 'PASS' });
  } else {
    console.log(`⚠️  JS 错误: ${relevantErrors.join('; ')}`);
    results.push({ test: '脚本错误检查', result: 'WARN', detail: relevantErrors });
  }

  // Test 2: 模拟 ERP 容器环境 — 测试 postMessage 通信路径
  console.log('\n=== Test 2: 模拟双层 iframe postMessage 通信 ===');

  const page2 = await context.newPage();
  await page2.goto('about:blank');

  // 创建模拟的 ERP 页面，监听 HRM_GET_CONTEXT 消息
  await page2.evaluate(() => {
    window.addEventListener('message', (e) => {
      if (e.data?.type === 'HRM_GET_CONTEXT') {
        window.__receivedContextRequest = true;
        e.source.postMessage({
          type: 'HRM_CONTEXT',
          token: 'test-token-12345',
          baseUrl1: 'http://localhost:8088'
        }, '*');
      }
    });
    window.__receivedContextRequest = false;
  });

  // 在 page2 中创建嵌套 iframe 加载 hrm-proxy
  await page2.evaluate(() => {
    return new Promise((resolve) => {
      // 创建外层 iframe（模拟 Tab 内容）
      const outerFrame = document.createElement('iframe');
      outerFrame.id = 'tabContent';
      outerFrame.style.cssText = 'width:100%;height:100vh;border:none;';
      document.body.appendChild(outerFrame);

      outerFrame.onload = () => {
        // 在外层 iframe 中创建 hrm-proxy iframe
        const innerDoc = outerFrame.contentDocument;
        const innerFrame = document.createElement('iframe');
        innerFrame.id = 'hrmProxy';
        innerFrame.style.cssText = 'width:100%;height:100vh;border:none;';
        innerFrame.src = 'http://localhost:5021/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html';
        innerDoc.body.appendChild(innerFrame);

        innerFrame.onload = () => {
          resolve();
        };
      };
    });
  });

  // 等待通信完成
  await page2.waitForTimeout(2000);

  // 检查顶层窗口是否收到了 HRM_GET_CONTEXT
  const receivedRequest = await page2.evaluate(() => window.__receivedContextRequest);

  if (receivedRequest) {
    console.log('✅ PASS: 顶层窗口成功收到 HRM_GET_CONTEXT 消息（穿透两层 iframe）');
    results.push({ test: '双层 iframe postMessage 穿透', result: 'PASS' });
  } else {
    console.log('❌ FAIL: 顶层窗口未收到 HRM_GET_CONTEXT 消息');
    results.push({ test: '双层 iframe postMessage 穿透', result: 'FAIL' });
  }

  // Summary
  console.log('\n========================================');
  console.log('       测试结果汇总');
  console.log('========================================');
  const passCount = results.filter(r => r.result === 'PASS').length;
  const failCount = results.filter(r => r.result === 'FAIL').length;
  results.forEach(r => {
    const icon = r.result === 'PASS' ? '✅' : r.result === 'FAIL' ? '❌' : '⚠️';
    console.log(`${icon} ${r.test}: ${r.result}`);
  });
  console.log(`\n总计: ${results.length} | 通过: ${passCount} | 失败: ${failCount}`);

  await browser.close();

  // Exit code based on results
  process.exit(failCount > 0 ? 1 : 0);
})();
