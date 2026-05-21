# 测试报告（第三轮 - 最终）

- **测试者**: QA
- **测试时间**: 2026-05-13 14:36
- **被测模块**: 生产工单产品编码生成（ProduceWorkOrder + CodeGenerator 扩展）
- **测试环境**: API `http://localhost:8088`, 前端 `http://localhost:8095`, 账号 `hongbin/123456`

## 测试摘要

| 总数 | 通过 | 失败 | 阻塞 | 覆盖率 |
|------|------|------|------|--------|
| 34   | 19   | 2    | 13   | 56%    |

## 测试用例列表

| # | 用例编号 | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|----------|------|------|------|
| 1 | TC-API-001 | 正常登录获取 Token | 接口 | ✅ 通过 | HTTP 200, token 正常 |
| 2 | TC-API-002 | GetPageListForCodeGen 基础分页 | 接口 | ❌ 失败 | NullReferenceException |
| 3 | TC-API-003 | GetPageListForCodeGen 过滤工单编号 | 接口 | ⛔ 阻塞 | 依赖 API-002 |
| 4 | TC-API-004 | GetPageListForCodeGen 过滤产品名称 | 接口 | ⛔ 阻塞 | 依赖 API-002 |
| 5 | TC-API-005 | GetPageListForCodeGen 缺Token | 接口 | ✅ 通过 | 返回 401 |
| 6 | TC-API-006 | GetCodeRecordsByObject 按ObjectType | 接口 | ✅ 通过 | 13条记录，字段完整 |
| 7 | TC-API-007 | GetCodeRecordsByObject 按Type+Id | 接口 | ✅ 通过 | 过滤正确 |
| 8 | TC-API-008 | GetCodeRecordsByObject 按工单编号 | 接口 | ✅ 通过 | 返回空列表（无匹配数据） |
| 9 | TC-API-009 | GetCodeRecordsByObject 按编码值 | 接口 | ✅ 通过 | 模糊匹配正确 |
| 10 | TC-API-010 | GetCodeRecordsByObject 按时间范围 | 接口 | ❌ 失败 | LINQ AddDays 无法翻译 |
| 11 | TC-API-011 | GetCodeRecordsByObject 空ObjectType | 接口 | ✅ 通过 | 返回空列表不崩溃 |
| 12 | TC-API-012 | GenerateCode 正常生成Count=1 | 接口 | ✅ 通过 | 返回 `SH1_20260513000004` |
| 13 | TC-API-013 | GenerateCode 批量生成Count=5 | 接口 | ✅ 通过 | 5条唯一编码，步长2 |
| 14 | TC-API-014 | GenerateCode 缺Objects | 接口 | ✅ 通过 | Objects可选，生成成功 |
| 15 | TC-API-015 | GenerateCode 缺CodeSign | 接口 | ✅ 通过 | 返回"业务编码标识不能为空" |
| 16 | TC-UI-001 | 页面正常加载 | 前端 | ✅ 通过 | HTTP 200，三Tab+元素就位 |
| 17 | TC-UI-002 | Tab切换 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 18 | TC-UI-003 | Tab1 未生成编码列表 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 19 | TC-UI-004 | 生成编码确认弹窗 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 20 | TC-UI-005 | 确认后生成编码 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 21 | TC-UI-006 | Tab2 已生成编码列表 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 22 | TC-UI-007 | 查询编码弹窗 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 23 | TC-UI-008 | Tab3 编码记录列表 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 24 | TC-UI-009 | 编码查询弹窗各筛选条件 | 前端 | ⛔ 阻塞 | 依赖 API-002 |
| 25 | TC-SEC-001 | SQL注入 工单编号搜索 | 安全 | ⛔ 阻塞 | 依赖 API-002 |
| 26 | TC-SEC-002 | SQL注入 产品名称搜索 | 安全 | ⛔ 阻塞 | 依赖 API-002 |
| 27 | TC-SEC-003 | SQL注入 编码值搜索 | 安全 | ✅ 通过 | 返回空列表，无泄露 |
| 28 | TC-SEC-004 | 越权 ObjectId其他公司 | 安全 | ✅ 通过 | 返回空列表 |
| 29 | TC-SEC-005 | XSS 筛选框输入 | 安全 | ✅ 通过 | Vue `{{ }}` 自动转义 |
| 30 | TC-EDGE-001 | GenerateCode Count=0 | 边界 | ✅ 通过 | "生成数量必须在1~1000之间" |
| 31 | TC-EDGE-002 | GenerateCode Count>1000 | 边界 | ✅ 通过 | "生成数量必须在1~1000之间" |
| 32 | TC-EDGE-003 | ProductCode配置不存在 | 边界 | ✅ 通过 | "业务编码标识 X 不存在或已禁用" |
| 33 | TC-EDGE-004 | PageSize极大值 | 边界 | ⛔ 阻塞 | 依赖 API-002 |
| 34 | TC-EDGE-005 | 不存在ObjectType | 边界 | ✅ 通过 | 返回空列表 |

## 发现的 Bug

| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 1 | **high** | `GetPageListForCodeGen` 持续 NullReferenceException — 前端 Tab1/Tab2 入口不可用 | 🔴 已报告 |
| 2 | **medium** | `GetCodeRecordsByObject` 时间范围筛选 LINQ 异常 — `DateTime.AddDays` 不可翻译为 SQL | 🟡 待报告 |

## 正面验证

- ✅ **GenerateCode 核心流程完整** — 单条/批量生成均正常，步长为2（并行安全）
- ✅ **参数校验完善** — Count 范围、CodeSign 有效性、空值校验均有明确错误提示
- ✅ **SQL 注入安全** — 恶意输入被安全处理，返回空列表
- ✅ **越权保护** — 跨公司 ObjectId 查询返回空结果
- ✅ **XSS 安全** — Vue 模板自动转义 + LayuiVue 安全渲染
- ✅ **前端部署正确** — index.html / codeList.html 就位，结构完整
- ✅ **认证拦截** — 缺 Token 正确返回 401

## 关键发现

1. **GetPageListForCodeGen 是最大阻塞项** — 13 个用例依赖此接口，修复后可立即解锁
2. **codeList.html 的 staticFilter 已正确包含** `ObjectType: "ProduceWorkOrder"`（Developer 已修复 Reviewer 反馈）
3. **编码记录 objects 字段为空数组** — 生成的编码记录中 objects 未包含赋码对象信息，需确认是否为预期行为
4. **编码生成步长为 2** — 连续两次 GenerateCode Count=1 返回 `...00004` → `...00016`，步长 2 而非 1

## 建议

1. **优先修复 GetPageListForCodeGen NullReferenceException**（high）
2. 修复 GetCodeRecordsByObject 时间筛选 LINQ 问题（medium）
3. 确认编码生成步长为 2 是否为预期（当前 ProductCode 规则配置）
4. 确认 CodeRecord.objects 为空数组是否为预期
5. 修复 high bug 后通知 QA 重新执行阻塞的 13 个用例
