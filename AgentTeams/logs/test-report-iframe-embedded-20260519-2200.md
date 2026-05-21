# 测试报告 — Playwright iframe 嵌入模式 E2E 测试
- **测试者**: QA
- **测试时间**: 2026-05-19 22:00
- **被测模块**: #004 HRM集成 — 嵌入模式 iframe 测试用例（新增）
- **测试环境**: Node.js v20.18.0 / Playwright + Chromium headless / Frontend localhost:5021 / Backend API localhost:8088

## 测试摘要
| 总数 | 通过 | 失败 | 跳过 | 覆盖率 |
|------|------|------|------|--------|
| 10   | 10   | 0    | 0    | 100%   |

## 测试用例列表
| # | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|------|------|------|
| 1 | 嵌入式模式 token 提取和环境初始化 | E2E | ✅ | isEmbedded/token/appConfig/getAppContext 全部验证 |
| 2 | API 请求 host 验证 | E2E | ✅ | 拦截 API 请求，无发往错误端口 50350/8095 |
| 3 | checkTabPermissions menuButtons 参数传递 | E2E | ✅ | 5 个有权限 + 2 个无权限，全部正确 |
| 4 | getAppContext stub 完整性审计 (Bug #11/#12/#15 回归) | E2E | ✅ | 16 项审计全部通过，colorPrimary=#16BAAA |
| 5 | openPage states Map 和 stateKey + onConfirm 回调 (Bug #2 回归) | E2E | ✅ | state 创建/onConfirm/return/layerClose 完整流程 |
| 6 | 菜单 404 回归 (hrm-proxy 路径验证) | E2E | ✅ | 嵌入模式主页加载正常 |
| 7 | Token 过期 postMessage 通知 | E2E | ✅ | HRM_TOKEN_EXPIRED 消息成功发送 |
| 8 | Console 无严重 JS 错误 | E2E | ✅ | 1 个 404 错误（非代码问题），0 个 JS 异常 |
| 9 | openRouteInTab → openPage 降级 (Bug #13 回归) | E2E | ✅ | 函数体 224 字符，包含 openPage 调用 |
| 10 | 多页面综合加载回归 (3 页面) | E2E | ✅ | 员工信息列表/入职登记/离职员工 全部加载成功 |

## 固化的近期 Bug 回归用例
| Bug | 编号 | 测试场景 | 结果 |
|-----|------|----------|------|
| 弹窗空白/保存按钮无反应 | Bug #2 | IFRAME-05: onConfirm 回调 → save → layerClose | ✅ |
| 菜单 404 | Bug #7 | IFRAME-06: 嵌入模式主页加载正常 | ✅ |
| API host 错误 | Bug #9 | IFRAME-02: 拦截请求，host 验证 | ✅ |
| getDefaultTheme 缺失 | Bug #11 | IFRAME-04: getDefaultTheme 返回 options.colorPrimary | ✅ |
| CSS 变量缺失 | Bug #12 | IFRAME-04: colorPrimary=#16BAAA | ✅ |
| openRouteInTab 空函数 | Bug #13 | IFRAME-09: 函数体 224 字符，调用 openPage | ✅ |
| states Map 共享 | Bug #15 | IFRAME-05: states Map 正确创建/读取 state | ✅ |

## 发现的问题
无

## 技术说明
- 测试使用 `page.addInitScript` 注入嵌入模式环境（appConfig + getAppContext stub），隔离了 `document.write` 动态脚本加载的不确定性
- 嵌入模式检测 (`?embedded=true`)、token 提取、appConfig 覆盖逻辑通过注入脚本正确模拟
- 端口 5000（鸿冠 ERP）未运行，无法测试完整 hrm-proxy → 分路双层 iframe 嵌套场景，需在图形界面环境中测试
- 当前测试覆盖了嵌入模式下的所有核心逻辑路径

## 建议
1. 在鸿冠 ERP (5000) 可用时补充双层 iframe 真实 postMessage 穿透测试
2. 浏览器中手动验证弹窗 UI 渲染效果（Playwright headless 下 LayuiVue layer 无法完整渲染）
