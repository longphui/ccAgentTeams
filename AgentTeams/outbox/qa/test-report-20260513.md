# 测试报告

- **测试者**: QA
- **测试时间**: 2026-05-13 11:35
- **被测模块**: 生产工单产品编码生成（ProduceWorkOrder + CodeGenerator 扩展）
- **测试环境**: API `http://localhost:8088`, 前端 `http://localhost:8095`, 账号 `hongbin/123456`

## 测试摘要

| 总数 | 通过 | 失败 | 跳过 | 阻塞 | 覆盖率 |
|------|------|------|------|------|--------|
| 34   | 0    | 0    | 0    | 34   | 0%     |

## ⛔ 阻塞原因

**CRITICAL BUG**: EF 模型变更导致 `SaltDbContext` 初始化失败。

```
InvalidOperationException: The model backing the 'SaltDbContext' context has changed
since the database was created. Consider using Code First Migrations to update the database.
```

- **错误位置**: `SAHG.Salt.EntityFramework/EntityFramework/SaltDbContext.cs:1407`
- **影响**: 所有 API 接口（包括 Login）均返回 500，应用完全不可用
- **ALERT 已发送**: `inbox/developer/msg-20260513-1135-a1b2.msg.json`
- **Bug 报告**: `outbox/qa/bug-report-20260513-001.md`

## 测试用例列表

| # | 用例编号 | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|----------|------|------|------|
| 1 | TC-API-001 | 正常登录获取 Token | 接口 | ⏸️ 阻塞 | EF模型变更 |
| 2 | TC-API-002 | GetPageListForCodeGen 基础分页 | 接口 | ⏸️ 阻塞 | 同上 |
| 3 | TC-API-003 | GetPageListForCodeGen 过滤工单编号 | 接口 | ⏸️ 阻塞 | 同上 |
| 4 | TC-API-004 | GetPageListForCodeGen 过滤产品名称 | 接口 | ⏸️ 阻塞 | 同上 |
| 5 | TC-API-005 | GetPageListForCodeGen 缺Token | 接口 | ⏸️ 阻塞 | 同上 |
| 6 | TC-API-006 | GetCodeRecordsByObject 按ObjectType | 接口 | ⏸️ 阻塞 | 同上 |
| 7 | TC-API-007 | GetCodeRecordsByObject 按Type+Id | 接口 | ⏸️ 阻塞 | 同上 |
| 8 | TC-API-008 | GetCodeRecordsByObject 按工单编号 | 接口 | ⏸️ 阻塞 | 同上 |
| 9 | TC-API-009 | GetCodeRecordsByObject 按编码值 | 接口 | ⏸️ 阻塞 | 同上 |
| 10 | TC-API-010 | GetCodeRecordsByObject 按时间范围 | 接口 | ⏸️ 阻塞 | 同上 |
| 11 | TC-API-011 | GetCodeRecordsByObject 空ObjectType | 接口 | ⏸️ 阻塞 | 同上 |
| 12 | TC-API-012 | GenerateCode 正常生成Count=1 | 接口 | ⏸️ 阻塞 | 同上 |
| 13 | TC-API-013 | GenerateCode 批量生成Count=5 | 接口 | ⏸️ 阻塞 | 同上 |
| 14 | TC-API-014 | GenerateCode 缺Objects | 接口 | ⏸️ 阻塞 | 同上 |
| 15 | TC-API-015 | GenerateCode 缺CodeSign | 接口 | ⏸️ 阻塞 | 同上 |
| 16 | TC-UI-001 | 页面正常加载 | 前端 | ⏸️ 阻塞 | 同上 |
| 17 | TC-UI-002 | Tab切换 | 前端 | ⏸️ 阻塞 | 同上 |
| 18 | TC-UI-003 | Tab1 未生成编码列表 | 前端 | ⏸️ 阻塞 | 同上 |
| 19 | TC-UI-004 | 生成编码确认弹窗 | 前端 | ⏸️ 阻塞 | 同上 |
| 20 | TC-UI-005 | 确认后生成编码 | 前端 | ⏸️ 阻塞 | 同上 |
| 21 | TC-UI-006 | Tab2 已生成编码列表 | 前端 | ⏸️ 阻塞 | 同上 |
| 22 | TC-UI-007 | 查询编码弹窗 | 前端 | ⏸️ 阻塞 | 同上 |
| 23 | TC-UI-008 | Tab3 编码记录列表 | 前端 | ⏸️ 阻塞 | 同上 |
| 24 | TC-UI-009 | 编码查询弹窗各筛选条件 | 前端 | ⏸️ 阻塞 | 同上 |
| 25 | TC-SEC-001 | SQL注入 工单编号搜索 | 安全 | ⏸️ 阻塞 | 同上 |
| 26 | TC-SEC-002 | SQL注入 产品名称搜索 | 安全 | ⏸️ 阻塞 | 同上 |
| 27 | TC-SEC-003 | SQL注入 编码值搜索 | 安全 | ⏸️ 阻塞 | 同上 |
| 28 | TC-SEC-004 | 越权 ObjectId访其他公司 | 安全 | ⏸️ 阻塞 | 同上 |
| 29 | TC-SEC-005 | XSS 编码查询弹窗输入 | 安全 | ⏸️ 阻塞 | 同上 |
| 30 | TC-EDGE-001 | GenerateCode Count=0 | 边界 | ⏸️ 阻塞 | 同上 |
| 31 | TC-EDGE-002 | GenerateCode Count>1000 | 边界 | ⏸️ 阻塞 | 同上 |
| 32 | TC-EDGE-003 | ProductCode配置不存在 | 边界 | ⏸️ 阻塞 | 同上 |
| 33 | TC-EDGE-004 | PageSize极大值 | 边界 | ⏸️ 阻塞 | 同上 |
| 34 | TC-EDGE-005 | 不存在ObjectType | 边界 | ⏸️ 阻塞 | 同上 |

## 发现的 Bug

| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 1 | **critical** | EF 模型变更导致 SaltDbContext 初始化失败，整个应用不可用 | 🔴 已报告 |

## 建议

1. 执行 EF Code First Migration 更新数据库 schema（`Update-Database` 或手动建表）
2. 修复后验证 Login API 可用再通知 QA 重新测试
3. 考虑在 CI/CD 中加入 Migration 检查步骤，避免遗漏

## 下一步

等待 Developer 修复 EF Migration 问题后重新执行全量测试。
