# 测试报告 — Playwright 浏览器自动化验证
- **测试者**: QA
- **测试时间**: 2026-05-18 17:05
- **被测模块**: #004 Round 2 — Playwright E2E 测试框架搭建
- **测试环境**: Node.js v20.18.0 / Playwright + Chromium headless / Frontend localhost:5021

## 测试摘要
| 总数 | 通过 | 失败 | 跳过 | 覆盖率 |
|------|------|------|------|--------|
| 8    | 8    | 0    | 0    | 100%   |

## 测试用例列表
| # | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|------|------|------|
| 1 | 菜单树渲染 — DOM + 层级 | E2E | ✅ | 3 菜单项，父子层级正确 |
| 2 | 图标显示 — fa fa-* / icon-* | E2E | ✅ | 6 个图标，两种格式兼容 |
| 3 | 标签页打开 + startup 首页 | E2E | ✅ | 1 路由 1 标签页 |
| 4 | postMessage 桥接 — Token API | E2E | ✅ | HRM_CONTEXT 字段完整 |
| 5 | Console 无 JS 报错 | E2E | ✅ | 无严重 JS 异常 |
| 6 | checkTabPermissions 权限检查 | E2E | ✅ | 5 种场景全部正确 |
| 7 | 菜单降级 menu.json 回退 | E2E | ✅ | 降级日志+菜单加载 |
| 8 | appContext 全局状态 | E2E | ✅ | 7 个子模块全部初始化 |

## 发现的问题
| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 1 | normal | startup 路由缺少 menuButtons（initMenu 中 addRoute 未传递） | 已报告 |
| 2 | env | csproj net9.0→net10.0（环境无 .NET 9.0 运行时） | 已修复 |
| 3 | env | appConfig.js https→http（后端无 HTTPS） | 已修复 |

## 建议
1. 修复 startup 路由 menuButtons 缺失问题（app.js initMenu 中 startupRoute 加 menuButtons 字段）
2. 正式环境部署前将 appConfig.js 的 baseUrl 改回 HTTPS 对应值
