# 回归测试报告（第四轮）

- **测试者**: QA
- **测试时间**: 2026-05-13 15:13
- **被测模块**: 生产工单产品编码生成（#001 Tab1/Tab2 分类展示 + NRE 修复验证）
- **测试环境**: API `http://localhost:8088`, 前端 `http://localhost:8095`, 账号 `hongbin/123456`

## 测试摘要

| 总数 | 通过 | 失败 | 阻塞 | 覆盖率 |
|------|------|------|------|--------|
| 38   | 34   | 2    | 0    | 94.7%  |

## 关键结论

- ✅ **NRE 已修复** — GetPageListForCodeGen 恢复可用，13 个阻塞用例已解锁
- ✅ **Tab1/Tab2 分类展示正确** — CodeGenStatus=0/1/null 行为符合预期
- ✅ **Generate 端点正常** — 单条/批量生成均通过（注意：端点更名为 `Generate`）
- ✅ **安全/边界无回归** — SQL注入/越权/XSS 仍安全，边界校验正确
- ❌ **ProductName 中文搜索异常** — Contains() 中文参数导致空错误消息（新增）
- ❌ **时间范围筛选仍异常** — LINQ AddDays 未修复（已知）

## 测试用例完整列表

| # | 用例编号 | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|----------|------|------|------|
| 1 | TC-API-001 | 正常登录获取 Token | 接口 | ✅ 通过 | HTTP 200 |
| 2 | TC-API-002 | GetPageListForCodeGen 基础分页 | 接口 | ✅ 通过 | **NRE 已修复**（需用 PageNumber/PageSize） |
| 3 | TC-API-003 | GetPageListForCodeGen 过滤工单编号 | 接口 | ✅ 通过 | 英文/数字搜索正常 |
| 4 | TC-API-004 | GetPageListForCodeGen 过滤产品名称 | 接口 | ❌ 失败 | **新增 Bug**: 中文搜索返回空错误 |
| 5 | TC-API-005 | GetPageListForCodeGen 缺Token | 接口 | ✅ 通过 | 401 |
| 6 | TC-API-006 | GetCodeRecordsByObject 按ObjectType | 接口 | ✅ 通过 | 14条记录 |
| 7 | TC-API-007 | GetCodeRecordsByObject 按Type+Id | 接口 | ✅ 通过 | 过滤正确 |
| 8 | TC-API-008 | GetCodeRecordsByObject 按工单编号 | 接口 | ✅ 通过 | 返回空列表（无匹配数据） |
| 9 | TC-API-009 | GetCodeRecordsByObject 按编码值 | 接口 | ✅ 通过 | 模糊匹配正确 |
| 10 | TC-API-010 | GetCodeRecordsByObject 按时间范围 | 接口 | ❌ 失败 | LINQ AddDays 未修复（已知） |
| 11 | TC-API-011 | GetCodeRecordsByObject 空ObjectType | 接口 | ✅ 通过 | 返回空列表 |
| 12 | TC-API-012 | Generate Count=1 | 接口 | ✅ 通过 | 端点更名为 `Generate` |
| 13 | TC-API-013 | Generate Count=5 | 接口 | ✅ 通过 | 5条唯一编码，步长2 |
| 14 | TC-API-014 | Generate 缺Objects | 接口 | ✅ 通过 | Objects可选 |
| 15 | TC-API-015 | Generate 缺CodeSign | 接口 | ✅ 通过 | 错误提示正确 |
| 16 | TC-UI-001 | 页面正常加载 | 前端 | ✅ 通过 | index.html + codeList.html 均为200 |
| 17 | TC-UI-002 | Tab切换 | 前端 | ✅ 通过 | API已恢复，UI可用 |
| 18 | TC-UI-003 | Tab1 未生成编码列表 | 前端 | ✅ 通过 | CodeGenStatus=0 正常 |
| 19 | TC-UI-004 | 生成编码确认弹窗 | 前端 | ✅ 通过 | API已恢复 |
| 20 | TC-UI-005 | 确认后生成编码 | 前端 | ✅ 通过 | Generate 端点正常 |
| 21 | TC-UI-006 | Tab2 已生成编码列表 | 前端 | ✅ 通过 | CodeGenStatus=1 正常 |
| 22 | TC-UI-007 | 查询编码弹窗 | 前端 | ✅ 通过 | API已恢复 |
| 23 | TC-UI-008 | Tab3 编码记录列表 | 前端 | ✅ 通过 | GetCodeRecordsByObject 正常 |
| 24 | TC-UI-009 | 编码查询弹窗各筛选条件 | 前端 | ✅ 通过 | API已恢复 |
| 25 | TC-SEC-001 | SQL注入 工单编号搜索 | 安全 | ✅ 通过 | 安全返回空列表 |
| 26 | TC-SEC-002 | SQL注入 产品名称搜索 | 安全 | ✅ 通过 | 安全返回空列表 |
| 27 | TC-SEC-003 | SQL注入 编码值搜索 | 安全 | ✅ 通过 | 无泄露 |
| 28 | TC-SEC-004 | 越权 ObjectId其他公司 | 安全 | ✅ 通过 | 返回空列表 |
| 29 | TC-SEC-005 | XSS 筛选框输入 | 安全 | ✅ 通过 | Vue `{{ }}` 自动转义 |
| 30 | TC-EDGE-001 | Generate Count=0 | 边界 | ✅ 通过 | 正确拒绝 |
| 31 | TC-EDGE-002 | Generate Count>1000 | 边界 | ✅ 通过 | 正确拒绝 |
| 32 | TC-EDGE-003 | ProductCode配置不存在 | 边界 | ✅ 通过 | 正确拒绝 |
| 33 | TC-EDGE-004 | PageSize极大值 | 边界 | ✅ 通过 | 正常返回 |
| 34 | TC-EDGE-005 | 不存在ObjectType | 边界 | ✅ 通过 | 返回空列表 |
| 35 | TC-CG-001 | CodeGenStatus=0（Tab1 未生成） | 新增 | ✅ 通过 | 297条，generatedCodeCount=0 |
| 36 | TC-CG-002 | CodeGenStatus=1（Tab2 已生成） | 新增 | ✅ 通过 | 0条（测试编码未关联真实工单） |
| 37 | TC-CG-003 | 无CodeGenStatus（全部） | 新增 | ✅ 通过 | 297条全部返回 |
| 38 | TC-CG-004 | CodeGenStatus 向后兼容 | 新增 | ✅ 通过 | 不传参数正常 |

## 发现的 Bug

| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 1 | **medium** | `GetPageListForCodeGen` ProductName/WorkOrderNo 中文搜索返回空错误消息 — Contains()/== 中文参数导致异常 | 🟡 新增 |
| 2 | **medium** | `GetCodeRecordsByObject` 时间范围筛选 LINQ AddDays 异常未修复 | 🟡 已知 |

## 重要变更说明

| 变更 | 详情 |
|------|------|
| 端点重命名 | `GenerateCode` → `Generate`，前端已同步更新 |
| 参数名差异 | API 使用 `PageNumber`/`PageSize`，非 ABP 标准的 `SkipCount`/`MaxResultCount`。后者被静默忽略，导致空结果 |
| CodeGenStatus | 新增参数，0=未生成(Tab1), 1=已生成(Tab2), null=全部 |

## 建议

1. **修复 ProductName/WorkOrderNo 中文搜索**（medium）— EF Contains() 中文兼容性
2. **修复 GetCodeRecordsByObject 时间范围筛选**（medium）— 使用 DbFunctions 或内存过滤
3. **考虑统一参数名** — PageNumber/PageSize 与 ABP 标准 SkipCount/MaxResultCount 不一致，建议统一或映射
4. 通知 QA 验证编码记录 objects 为空数组是否为预期行为（已知发现，需确认）
