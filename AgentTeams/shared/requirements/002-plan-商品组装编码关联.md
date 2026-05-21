# 商品组装编码关联 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 将半成品实物编码与成品进行组装关联，支持手动组装。前提：一物一码，成品和半成品都有通过 #001 生成的实物编码。

> ⚠️ **2026-05-14 更新**：一键自动组合功能暂停开发，等待需求重新梳理。后端 AutoAssemble 接口已移除，前端按钮已隐藏。恢复时重新评估设计方案。

**Architecture:** 在 Core/Produce 下新建 ProductComponents（BasicEntity）和 ProductComponentCodes（SaltEntity）两个实体，新建完整 Service + Controller（[PPMLog]）。前端在 `commonProductionStages/ProductComponents/` 下建三个页面：列表（可展开）、手动组装、一键自动组合。

**Tech Stack:** Backend: .NET Framework 4.8 + ABP + EF6. Frontend: Vue 3 全局构建 + LayuiVue 2.22.2.

---

### Task 1: 新建实体 — ProductComponents + ProductComponentCodes

**Files:**
- Create: `SAHG.Salt.Core/Produce/ProductComponents.cs`
- Create: `SAHG.Salt.Core/Produce/ProductComponentCodes.cs`

**规范:**
- ProductComponents 继承 `BasicEntity`（含 Id, CompanyId, IsDeleted, CreationTime, CreationUserId 等审计字段）
- ProductComponentCodes 继承 `SaltEntity`
- ProductComponents 含 `ICollection<ProductComponentCodes> Codes` 导航属性
- 字段参见需求文档 4.1 节

---

### Task 2: 新建 DTO — 输入/输出/列表

**Files:**
- Create: `SAHG.Salt.Application/Produce/Dto/ProductComponentsDto.cs`
- Create: `SAHG.Salt.Application/Produce/Dto/ProductComponentsInput.cs`

**规范:**
- ProductComponentsDto 继承 `HRM_CompanyEntityDto`，含 Codes 集合 + 成品名称/半成品名称等展示冗余字段
- ProductComponentsInput 用于新增/修改，包含组件编码选择
- 列表需要分组结构：成品信息 + 子组件列表（用于前端展开）

---

### Task 3: 新建 Service 接口 + 实现

**Files:**
- Create: `SAHG.Salt.Application/Produce/IProductComponentsService.cs`
- Create: `SAHG.Salt.Application/Produce/ProductComponentsService.cs`

**方法:**
| 方法 | 返回 | 说明 |
|------|------|------|
| `GetPageList(BaseInput)` | `PagedListOutput<Dto>` | 列表，按成品分组 |
| `GetDetails(int id)` | `Dto` | 单条详情，含组件编码 |
| `Save(Input)` | `OutDto` | 手动组装：写入 ProductComponents + Codes，校验编码未被使用 |
| `AutoAssemble(Input)` | `OutDto` | ⛔ 暂停：一键组合，需求待重新梳理 |
| `Delete(int id, string modifier)` | `OutDto` | 软删除（含子表 Codes） |
| `GetAvailableCodes(int productId)` | `List<string>` | 获取某半成品未被使用的编码 |

**关键逻辑:**
- `Save`: 遍历每个组件行的编码，先查 ProductComponentCodes 是否已有该编码 → 重复则报错 → 批量 AddRange
- `AutoAssemble`: 按组件半成品 ID + 数量，从未使用编码池随机取 N 个 → 组装后展示 → 用户确认 → 批量保存
- `GetPageList`: 关联 Product 表获取成品名称，子查询组件数量；按 CompanyId 过滤
- 所有查询带 `IsDeleted != true && CompanyId == input.CompanyId`

---

### Task 4: 新建 Controller

**Files:**
- Create: `SAHG.Salt.WebAppApi/Areas/Produce/Controllers/ProductComponentsController.cs`

**规范:**
- 继承 `SaltControllerBase`
- 构造函数注入 `IProductComponentsService`
- 所有 Action 使用 `[PPMLog("操作描述")]`
- 入参 `[FromBody] SaltRequest<T>`
- 路由自动映射 `api/Produce/ProductComponents/{Action}`

---

### Task 5: 注册 DbContext + AutoMapper

**Files:**
- Modify: `SAHG.Salt.EntityFramework/EntityFramework/SaltDbContext.cs` — 添加 `public virtual IDbSet<ProductComponents> ProductComponents { get; set; }` 和 `ProductComponentCodes`
- Modify: `SAHG.Salt.Application/.../HRM_DtoMapping.cs` — `CreateMapping()` 中注册 `ProductComponents ↔ ProductComponentsDto` 双向映射

---

### Task 6: 前端 — 列表页 index.html

**Files:**
- Create: `v2/views/productionManage/commonProductionStages/ProductComponents/index.html`

**规范:**
- `importresloader` 加载 → `loadLayuiVue`
- `<lay-page-view>` 调用 `GetPageList`，`PageMaper: { totalCount: 'count' }`
- 列表按成品分组展示，LayuiVue Table expand 展开显示组件明细（半成品名、数量、编码列表）
- 工具栏：`lay-link-button` → `create_edit.html`（target="_popup"），`lay-link-button` → `autoAssembly.html`
- 操作列：编辑按钮（`lay-link-button` target="_popup" 传 row）、删除按钮（`layer.confirm`）
- 权限控制：`appContext.route.checkTabPermissions(pathName, 'add'/'update'/'delete')`
- 注释：区块 + 权限 + 分页映射

---

### Task 7: 前端 — 手动组装 create_edit.html

**Files:**
- Create: `v2/views/productionManage/commonProductionStages/ProductComponents/create_edit.html`

**规范:**
- 弹窗页面，`getState()` 获取传入数据，区分新增/编辑模式
- 成品选择区：下拉选成品 → 下拉/输入选成品编码（从未使用的成品编码池）
- 组件列表区：动态添加/删除组件行
  - 每行：半成品下拉 + 数量输入 + 编码选择（逐个，从未使用池）
  - 「+ 添加组件」按钮追加行
- 编码选择器：调 GetAvailableCodes API 获取可选编码列表，渲染为下拉框
- 保存：调 Save API → `state.return()` 关闭弹窗刷新列表
- 注释：区块清晰标注各区域用途

---

### Task 8: 前端 — 一键自动组合 autoAssembly.html （⛔ 暂停）

> **状态：暂停开发。** 后端接口已移除，前端按钮已隐藏。需求重新梳理后恢复。

---

### Task 9: 编译 + 部署验证 + SVN

- [ ] MSBuild 编译通过
- [ ] 重启 IIS 应用池（`8088_fenluapi`）
- [ ] curl 测试各接口
- [ ] 浏览器验证三个页面
- [ ] SVN 提交：`[生产管理] 新增商品组装编码关联功能`
