# 测试报告（第二轮）

- **测试者**: QA
- **测试时间**: 2026-05-13 11:40
- **被测模块**: 生产工单产品编码生成
- **测试环境**: API `http://localhost:8088`, 前端 `http://localhost:8095`, 账号 `hongbin/123456`

## 测试摘要

| 总数 | 通过 | 失败 | 阻塞 | 覆盖率 |
|------|------|------|------|--------|
| 34   | 3    | 0    | 31   | 9%     |

## 测试用例列表

| # | 用例编号 | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|----------|------|------|------|
| 1 | TC-API-001 | 正常登录获取 Token | 接口 | ✅ PASS | HTTP 200, token 正常返回 |
| 2 | TC-API-002 | GetPageListForCodeGen 基础分页 | 接口 | ⛔ 阻塞 | EF模型变更 |
| 3 | TC-API-003 | GetPageListForCodeGen 过滤工单编号 | 接口 | ⛔ 阻塞 | 同上 |
| 4 | TC-API-004 | GetPageListForCodeGen 过滤产品名称 | 接口 | ⛔ 阻塞 | 同上 |
| 5 | TC-API-005 | GetPageListForCodeGen 缺Token | 接口 | ✅ PASS | HTTP 200, code=401 "Authorization参数异常" |
| 6 | TC-API-006 | GetCodeRecordsByObject 按ObjectType | 接口 | ⛔ 阻塞 | EF模型变更 |
| 7 | TC-API-007 | GetCodeRecordsByObject 按Type+Id | 接口 | ⛔ 阻塞 | 同上 |
| 8 | TC-API-008 | GetCodeRecordsByObject 按工单编号 | 接口 | ⛔ 阻塞 | 同上 |
| 9 | TC-API-009 | GetCodeRecordsByObject 按编码值 | 接口 | ⛔ 阻塞 | 同上 |
| 10 | TC-API-010 | GetCodeRecordsByObject 按时间范围 | 接口 | ⛔ 阻塞 | 同上 |
| 11 | TC-API-011 | GetCodeRecordsByObject 空ObjectType | 接口 | ⛔ 阻塞 | 同上 |
| 12 | TC-API-012 | GenerateCode 正常生成Count=1 | 接口 | ⛔ 阻塞 | 同上 |
| 13 | TC-API-013 | GenerateCode 批量生成Count=5 | 接口 | ⛔ 阻塞 | 同上 |
| 14 | TC-API-014 | GenerateCode 缺Objects | 接口 | ⛔ 阻塞 | 同上 |
| 15 | TC-API-015 | GenerateCode 缺CodeSign | 接口 | ⛔ 阻塞 | 同上 |
| 16 | TC-UI-001 | 页面正常加载 | 前端 | ✅ PASS | HTTP 200, 标题"生产工单编码管理", 三Tab+按钮均存在 |
| 17 | TC-UI-002 | Tab切换 | 前端 | ⛔ 阻塞 | 依赖API |
| 18 | TC-UI-003 | Tab1 未生成编码列表 | 前端 | ⛔ 阻塞 | 依赖API |
| 19 | TC-UI-004 | 生成编码确认弹窗 | 前端 | ⛔ 阻塞 | 依赖API |
| 20 | TC-UI-005 | 确认后生成编码 | 前端 | ⛔ 阻塞 | 依赖API |
| 21 | TC-UI-006 | Tab2 已生成编码列表 | 前端 | ⛔ 阻塞 | 依赖API |
| 22 | TC-UI-007 | 查询编码弹窗 | 前端 | ⛔ 阻塞 | 依赖API |
| 23 | TC-UI-008 | Tab3 编码记录列表 | 前端 | ⛔ 阻塞 | 依赖API |
| 24 | TC-UI-009 | 编码查询弹窗各筛选条件 | 前端 | ⛔ 阻塞 | 依赖API |
| 25 | TC-SEC-001 | SQL注入 工单编号搜索 | 安全 | ⛔ 阻塞 | EF模型变更 |
| 26 | TC-SEC-002 | SQL注入 产品名称搜索 | 安全 | ⛔ 阻塞 | 同上 |
| 27 | TC-SEC-003 | SQL注入 编码值搜索 | 安全 | ⛔ 阻塞 | 同上 |
| 28 | TC-SEC-004 | 越权 ObjectId访其他公司 | 安全 | ⛔ 阻塞 | 同上 |
| 29 | TC-SEC-005 | XSS 编码查询弹窗输入 | 安全 | ⛔ 阻塞 | 同上 |
| 30 | TC-EDGE-001 | GenerateCode Count=0 | 边界 | ⛔ 阻塞 | 同上 |
| 31 | TC-EDGE-002 | GenerateCode Count>1000 | 边界 | ⛔ 阻塞 | 同上 |
| 32 | TC-EDGE-003 | ProductCode配置不存在 | 边界 | ⛔ 阻塞 | 同上 |
| 33 | TC-EDGE-004 | PageSize极大值 | 边界 | ⛔ 阻塞 | 同上 |
| 34 | TC-EDGE-005 | 不存在ObjectType | 边界 | ⛔ 阻塞 | 同上 |

## 发现的 Bug

| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 1 | **critical** | EF 模型变更导致 SaltDbContext 初始化失败 — 除 Login 外所有 API 不可用 | 🔴 已报告（第二轮确认） |

## 详情

### ✅ 可确认正常的部分
- **Login API** — 正常返回 Token，HTTP 200
- **认证拦截** — 缺 Token 正确返回 401
- **前端页面部署** — `index.html` 和 `codeList.html` 就位，页面可访问（HTTP 200）
- **前端 UI 元素** — 标题"生产工单编码管理"，三 Tab（未生成编码/已生成编码/编码记录），按钮（生成编码/查询编码/确认生成）全部存在

### ❌ EF 模型变更影响范围
```
已验证不可用的接口：
- /api/Produce/ProduceWorkOrder/GetPageListForCodeGen → EF 错误
- /api/Produce/ProduceWorkOrder/GetPageList → EF 错误（现有接口也受影响）
- /api/HRM/Dic/GetPageList → EF 错误（现有接口也受影响）
- /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject → EF 错误
- /api/CodeGenerator/CodeGenerator/Generate → EF 错误

唯一可用的接口：
- /api/Common/Account/Login → 正常
```

## 建议

1. **优先修复 EF 模型变更问题** — 执行 Migration 或手工添加新表
2. 修复后 QA 可快速重新执行全量测试
3. 排查首次 TC-API-002 返回的 NullReferenceException 是否有次级 bug
