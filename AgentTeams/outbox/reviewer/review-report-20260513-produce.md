# 代码审查报告 — 生产工单产品编码生成

- **审查者**: Reviewer
- **审查时间**: 2026-05-13
- **审查范围**: 10 files (4 new + 6 modified)
- **总体评价**: **需修改** — 1个严重功能缺陷 + 1个高优先级功能问题 + 2个低风险项

---

## 审查文件清单

### NEW (4 files)
| # | 文件 | 说明 |
|---|------|------|
| 1 | `SAHG.Salt.Application/Produce/Dto/WorkOrderCodeGenOutput.cs` | DTO 继承 ProduceWorkOrderOutput，新增 GeneratedCodeCount |
| 2 | `SAHG.Salt.Application/CodeGenerator/Dto/CodeRecordSearchInput.cs` | 多维度编码记录查询入参 |
| 3 | `v2/views/productionManage/commonProductionStages/index.html` | 三 Tab 主页面（未生成/已生成/编码记录） |
| 4 | `v2/views/productionManage/commonProductionStages/codeList.html` | 编码查询弹窗 |

### MODIFIED (6 files)
| # | 文件 | 变更内容 |
|---|------|----------|
| 5 | `.../CodeGenerator/ICodeGeneratorService.cs` | 接口新增 `GetCodeRecordsByObject` |
| 6 | `.../CodeGenerator/CodeGeneratorService.cs` | 新增 `GetCodeRecordsByObject` + `BuildCodeRecordPagedResult` |
| 7 | `.../CodeGenerator/Controllers/CodeGeneratorController.cs` | 新增 `GetCodeRecordsByObject` Action |
| 8 | `.../Produce/IProduceWorkOrderService.cs` | 接口新增 `GetPageListForCodeGen` |
| 9 | `.../Produce/ProduceWorkOrderService.cs` | 新增 `GetPageListForCodeGen` 实现 |
| 10 | `.../Produce/Controllers/ProduceWorkOrderController.cs` | 新增 `GetPageListForCodeGen` Action |

---

## 发现问题

| # | 类别 | 严重度 | 文件:行号 | 描述 | 建议 |
|---|------|--------|-----------|------|------|
| 1 | 功能缺陷 | **critical** | `codeList.html:14` | `staticFilter` 已定义但未通过 `:static-filter` prop 绑定到 `lay-page-view`，导致 `ObjectType` 和 `ObjectId` 未随请求发送。后端 `GetCodeRecordsByObject` 依赖 `ObjectType` 做初始过滤（`where o.ObjectType == input.ObjectType`），`ObjectType` 为 null 时生成 `WHERE ObjectType IS NULL`，永远返回空结果。**弹窗页码永远为空。** | 在 `<lay-page-view>` 上添加 `:static-filter="staticFilter"` |
| 2 | 功能缺陷 | **high** | `index.html:17,30` | Tab1「未生成编码」和 Tab2「已生成编码」调用完全相同的 API `/api/Produce/ProduceWorkOrder/GetPageListForCodeGen`，无任何参数区分。后端 `GetPageListForCodeGen` 返回所有工单（含 `generatedCodeCount`），不做 codeGenStatus 过滤。两个 Tab 显示完全相同的数据，失去了分类展示的意义。 | 方案A: 后端新增 `CodeGenStatus` 参数（0=未生成, 1=已生成），在 Linq 中过滤 `generatedCodeCount == 0` vs `> 0`。方案B: 前端在 `filters` 中传入区分参数，由 `lay-page-view` 自带的分页请求携带。推荐方案A，保证分页准确性。 |
| 3 | 代码健壮性 | **low** | `index.html:181` | `codeListUrl` 中 `row.workOrderNo` 直接拼接 URL，未使用 `encodeURIComponent`。工单编号若含特殊字符（`&`, `=`, `#` 等）会导致 URL 解析错误。 | 改为 `encodeURIComponent(row.workOrderNo \|\| row.factoryNo)` |
| 4 | 代码健壮性 | **low** | `ProduceWorkOrderController.cs:339-342` | `GetPageListForCodeGen` 未对 `input` / `input.Data` 做 null 检查，直接访问 `input.Data.CompanyId`。若调用方不传 body，抛 `NullReferenceException` 而非明确的参数校验错误。同一 Controller 中其他 Action（如 `GetList`、`GetPageList`）同样缺少此检查，属于项目既有模式。 | 建议添加 `if (input?.Data == null) throw new ArgumentNullException(nameof(input.Data));`（可顺带统一修复同类 Action） |

---

## 审查维度详情

### 🔒 安全检查 — 通过

- **SQL 注入**: `GetCodeRecordsByObject` 全程使用 Linq-to-Entities 表达式树，`ObjectType`、`WorkOrderNo` 等用户输入通过 `==`、`Contains` 等操作符生成参数化 SQL，无字符串拼接。`GetPageListForCodeGen` 使用 `Contains` 批量查询，同样参数化。**未引入新的 SQL 注入风险。**
- **租户隔离**: 两个新增 Controller Action 均设置 `input.Data.CompanyId = CurrentCompanyId`，与模块内其他 Action 一致。
- **认证/授权**: 继承 `SaltControllerBase`，复用框架级权限校验。
- **敏感信息**: 日志属性使用 `[PPMLog]` / `[CommonLog]`，遵循项目约定，无敏感数据打印。

### ⚡ 性能检查 — 通过

- **`GetPageListForCodeGen`**: 单次 `Contains` 批量查询 `CodeRecordObjects`（按 `workOrderIds` 过滤），`.ToListAsync()` 异步执行，group-by 在数据库侧完成。一次 COUNT + 一次分页查询 + 一次批量关联查询 = 3 次 DB 往返。✅
- **`GetCodeRecordsByObject`**: 双路径设计合理。WorkOrderNo/ProductName 路径走 JOIN + DISTINCT 子查询，无 WorkOrder 过滤时走简单路径。分页在 DB 侧完成（`Skip().Take().ToList()`）。`BuildCodeRecordPagedResult` 用两次批量 `Contains` 查询获取关联 Rule/BizCode，消除 N+1。✅
- **无 N+1 查询、无循环内 DB 调用、无阻塞 I/O。**

### 📐 代码规范检查 — 通过（含小建议）

- **DTO 设计**: `WorkOrderCodeGenOutput : ProduceWorkOrderOutput` 继承合理；`CodeRecordSearchInput : BaseInput` 遵循项目约定。✅
- **命名**: `GetPageListForCodeGen` 与模块内 `GetPageList*` 命名一致；`BuildCodeRecordPagedResult`（private helper）语义清晰。✅
- **注释**: 中文 XML doc 完整覆盖所有新增 public 方法/DTO，无冗余行内注释。✅
- **日志属性**: Produce 模块用 `[PPMLog]`，CodeGenerator 模块用 `[CommonLog]`，各自一致。✅
- **Controller 返回类型**: `GetPageListForCodeGen` 返回 `dynamic`，与 `GetPageList`、`GetPageListNew` 等同类方法一致。✅

---

## 总结

- 后端实现质量良好：Linq-to-Entities 全参数化查询，无 SQL 注入风险；批量查询消除 N+1；租户隔离到位。
- **1 个 critical 缺陷必须修复**：`codeList.html` 缺少 `:static-filter="staticFilter"` 导致弹窗永远为空。
- **1 个 high 问题需确认**：Tab1/Tab2 分类展示无实际区分逻辑——需与产品确认是前端 client-side 过滤还是后端加参数。
- 2 个 low 建议可顺带处理。
