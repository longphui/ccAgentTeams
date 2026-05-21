# 生产工单产品编码生成 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在生产工单列表页新增「编码生成」功能——点击「生成编码」按钮，调 GenerateCode API 为每个产品生成唯一编码（一物一码，Count = PlannedProductionNum），并支持按 Tab 分类查看和按条件查询已生成的编码记录。

**Architecture:** 后端新增两个接口：GetPageListForCodeGen（工单列表含编码数量）、GetCodeRecordsByObject（多维度编码记录查询）。前端新建 `commonProductionStages/generatorProductCodes/` 目录，包含三 Tab 主页面 `index.html` 和编码查询弹窗 `codeList.html`。复用已有 GenerateCode API。

**Tech Stack:** Backend: .NET Framework 4.8 + ABP + EF6. Frontend: Vue 3 全局构建 + LayuiVue 2.22.2 + layui 原生 CSS.

---

## Task 1: 后端 DTO

**Files:**
- Create: `SAHG.Salt.Application/Produce/Dto/WorkOrderCodeGenOutput.cs`
- Create: `SAHG.Salt.Application/CodeGenerator/Dto/CodeRecordSearchInput.cs`

**规格:**

1. **WorkOrderCodeGenOutput**
   - 继承 `ProduceWorkOrderOutput`（已包含 WorkOrderNo / ProductName / ProductId / PlannedProductionNum / Status / StatusName 等字段）
   - 无新增字段（原 GeneratedCodeCount 已移除：编码数量无中间态，无需显示）

2. **CodeRecordSearchInput**
   - 继承 `BaseInput`（已有 SkipCount / MaxResultCount / CompanyId）
   - 新增字段：`string ObjectType`（赋码对象类型，如 "ProduceWorkOrder"）、`int ObjectId`（赋码对象 ID，0 表示不过滤）、`string WorkOrderNo`、`string ProductName`、`string CodeValue`（模糊匹配）、`DateTime? StartTime`、`DateTime? EndTime`
   - `ObjectType` 为必填（查询入口），其余均可选

3. **CodeRecordDto 扩展**
   - 原有字段：CompanyId / BizCodeIdentifierId / CodeRuleId / BizCodeName / RuleName / CodeValue / Objects / CreationTime
   - 新增字段：`string WorkOrderNo`、`int ProductId`、`string ProductName`、`string ProductSpec` — 用于 Tab3 编码记录列表展示

---

## Task 2: CodeGenerator 模块 — GetCodeRecordsByObject 重构

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/CodeRecordSearchInput.cs` — 改入参
- Modify: `SAHG.Salt.Application/CodeGenerator/ICodeGeneratorService.cs` — 更新方法签名
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — 重写查询逻辑
- Modify: `SAHG.Salt.WebAppApi/Areas/CodeGenerator/Controllers/CodeGeneratorController.cs` — 更新 Action

**规格:**

1. **入参 CodeRecordSearchInput：**
   - 新增 `ObjectPair[] Objects`（`{string ObjectType, int ObjectId}` 数组）
   - 移除：ObjectType（单个）、ObjectId（单个）、WorkOrderNo、ProductName
   - 保留：CodeValue（模糊）、StartTime、EndTime

2. **查询逻辑：**
   - 通过 CodeRecord 的 Objects 属性（而非 CodeRecordObjects 表）关联匹配
   - Objects 数组中任一匹配即满足条件
   - CodeValue 模糊匹配、CreationTime 范围过滤
   - 排序：CreationTime DESC

3. **DTO 填充：** 批量填充 RuleName、BizCodeName、WorkOrderNo、ProductId、ProductName、ProductSpec，避免 N+1

4. **Controller:** POST `/api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject`

5. **业务封装（调用方处理）：**
   - 弹窗（单工单）→ 直接传 `[{ObjectType:"ProduceWorkOrder", ObjectId: workOrderId}]`
   - Tab3（多条件）→ 先将 WorkOrderNo/ProductName 转为 ProduceWorkOrder Id → 构造 Objects 数组

---

## Task 3: ProduceWorkOrder 模块 — GetPageListForCodeGen

**Files:**
- Modify: `SAHG.Salt.Application/Produce/IProduceWorkOrderService.cs` — 添加方法签名
- Modify: `SAHG.Salt.Application/Produce/ProduceWorkOrderService.cs` — 实现
- Modify: `SAHG.Salt.WebAppApi/Areas/Produce/Controllers/ProduceWorkOrderController.cs` — 添加 Action

**规格:**

1. **方法签名:** `Task<dynamic> GetPageListForCodeGen(WorkOrderProductionPageSearchInput input)`

2. **设计决策（2026-05-13）:** **不调用 GetWorkOrderPage**。理由：
   - GetWorkOrderPage 关联了排产（Plans）/ 任务（Tasks）/ 批次（Batches）等大量表，性能浪费
   - GetWorkOrderPage 内部有工单分类逻辑，不适用于「查询所有工单」的需求
   - 编码管理页面仅需 ProduceWorkOrder 表的字段，无需那些关联数据

3. **查询逻辑:**
   - **直接查 ProduceWorkOrder 表**，条件：`!IsDeleted`
   - 可选过滤：WorkOrderNo（Contains）、ProductName（Contains）、Statuss（精确匹配 Status 字段）
   - **不过滤工单状态**（Statuss 为空时查全部）
   - **CodeGenStatus 过滤：** CodeGenStatus=0 → 用 `NOT EXISTS (SELECT 1 FROM CodeRecordObjects WHERE ObjectType='ProduceWorkOrder' AND ObjectId = wo.Id AND !IsDeleted)` 筛选未生成编码的工单；CodeGenStatus=1 → 用 `EXISTS` 筛选已生成的。未传 CodeGenStatus 时不过滤
   - 排序：Id DESC，分页：Skip + Take
   - 使用 EF6 async 方法（ToListAsync / CountAsync）

4. **输出组装:**
   - 返回 `WorkOrderCodeGenOutput` 列表，必含字段：Id、WorkOrderNo、ProductName、ProductId、PlannedProductionNum、Status、StatusName（由 Status 枚举转换）
   - 确保 StatusName 不遗漏（该字段不在 ProduceWorkOrder 实体上，需手动赋值）

5. **返回格式:** `{ count: 总数, list: WorkOrderCodeGenOutput[] }`

6. **Controller Action:** POST `/api/Produce/ProduceWorkOrder/GetPageListForCodeGen`，入参包裹在 `SaltRequest<T>` 中

7. **已实现（2026-05-13）：** 代码见项目文件。

---

## Task 4: 前端 — 三 Tab 主页面 index.html

**Files:**
- Create: `v2/views/productionManage/commonProductionStages/generatorProductCodes/index.html`

**规格:**

1. **页面结构:**
   - 三个 Tab：未生成编码 / 已生成编码 / 编码记录
   - Tab 切换正常，默认显示 Tab1

2. **Tab1 — 未生成编码:**
   - API: `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen`
   - staticFilter: `{ CodeGenStatus: 0 }`
   - 筛选字段：工单编号（input）、产品名称（input）、工单状态（select 多选，枚举：待生产=0/生产中=1/已完成=2/已入库=3/已取消=4/已结束=6）
   - 列：序号 | 工单编号 | 产品名称 | 生产数量 | 工单状态 | 操作
   - 操作列：「生成编码」按钮，调用 `layer.confirm("确认要生成（N）个编码吗？")`，确认后调 POST `/api/CodeGenerator/CodeGenerator/Generate`
   - Generate 入参：`{ CodeSign: "ProductCode", Count: row.plannedProductionNum, Objects: [{ ObjectType: "ProduceWorkOrder", ObjectId: row.id }, { ObjectType: "Product", ObjectId: row.productId }] }`
   - **约束：ObjectId 必须是工单/商品的实际 Id 值，不能是固定值 1。GetPageListForCodeGen 返回的 row.id 和 row.productId 必须正确。GenerateCode 后端必须将 Objects 数组中的 ObjectType 和 ObjectId 原样持久化到 CodeRecordObjects 表。**

3. **Tab2 — 已生成编码:**
   - API: 同 Tab1
   - staticFilter: `{ CodeGenStatus: 1 }`
   - 筛选字段：工单编号、产品名称
   - 列：同 Tab1（不含编码数量列）
   - 操作列：「查询编码」按钮，以弹窗方式打开 codeList.html（传入 workOrderId + workOrderNo 参数）

4. **Tab3 — 编码记录（全部工单，多条件筛选）:**
   - API: 新增一个业务层端点，接受 WorkOrderNo/ProductName/CodeValue/StartTime/EndTime，内部将 WorkOrderNo/ProductName 解析为 ProduceWorkOrder Id → 构造 Objects[] → 调 GetCodeRecordsByObject
   - 筛选字段：工单编号（input）、商品名称（input）、编码值（input）、生成时间范围（起止 date）
   - 列：序号 | 工单号 | 商品Id | 商品名称 | 商品规格 | 编码值 | 生成时间
   - 注意：不使用「规则名称」和「业务编码」列（对用户无意义）

5. **交互细节:**
   - Tab 切换时通过 `this.$nextTick` + `this.$refs.pageX.fetchPage()` 触发首次加载
   - 生成编码成功后，刷新三个 Tab 的列表（`retryCurrentPage()`）
   - 分页映射：`PageMaper: { totalCount: 'count' }`

---

## Task 5: 前端 — 编码查询弹窗 codeList.html

**Files:**
- Create: `v2/views/productionManage/commonProductionStages/generatorProductCodes/codeList.html`

**规格:**

1. **入口:** 从 Tab2「查询编码」按钮以弹窗方式打开，URL 参数传入 workOrderId 和 workOrderNo

2. **API:** `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject`

3. **staticFilter:** `{ ObjectType: "ProduceWorkOrder", ObjectId: parseInt(workOrderId) }` — 固定只查该工单的编码

4. **筛选字段:** 编码值（input）

5. **列:** 序号 | 编码值 | 生成时间

---

## Task 6: 编译与 SVN

**要求:**
- 编译: 0 Error（用 MSBuild 或 Visual Studio）
- 新 .cs 文件：svn add + csproj 注册 `<Compile Include>`
- 新 .html 文件：svn add
- SVN 提交 message 格式: `[生产管理] {变更描述}`
