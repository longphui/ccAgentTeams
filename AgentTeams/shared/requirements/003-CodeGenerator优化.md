# 需求 #003：CodeGenerator 优化（三项缺陷修复 + 领域约束 + 接口简化）

- **日期**: 2026-05-15（更新 2026-05-16）
- **提出方**: Architect
- **状态**: 待分派
- **来源**: CodeGenerator 架构审查发现

---

## 一、需求概述

CodeGenerator 模块分析发现 3 个需要修复的缺陷 + 1 个设计重构：

1. **StartValue 配置被忽略** — 流水号始终从 0 开始
2. **Include Items 含软删除子项** — 已删除子项仍参与编码生成
3. **业务标识 ↔ 规则 ↔ 业务字段三者脱节 + 接口复杂** — 缺 Domain 约束 + BizContext 难用（两项合并实施）

缺陷 #1、#2 独立可修。#3 是较大的重构，涉及实体/DTO/接口/数据库。

---

## 二、缺陷 #1：StartValue 被忽略

### 2.1 现状

`CodeRuleItemDto.cs` 中 `SerialNumberProperties` 定义了起始值字段：

```csharp
public class SerialNumberProperties
{
    public long StartValue { get; set; } = 1;  // 定义了但未被使用
    public int Step { get; set; } = 1;
    public int PaddingLength { get; set; } = 4;
    public string PaddingChar { get; set; } = "0";
}
```

`CodeService.BatchGenerateCode` 直接用 Redis `StringIncrement(key, batchCount * step)` 递增。Redis 对不存在的 key 默认从 0 开始，首次生成结果始终是 `0000, 0001, 0002...`，配置的 StartValue 不起作用。

### 2.2 修复方案

在 `GenerateCode` 的 Step 1（批量获取流水号）之前，检查 Redis key 是否存在。若 key 不存在，先 `StringSet(key, StartValue - Step)` 初始化为 `起始值 - 步长`。

### 2.3 涉及文件

- `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `GenerateCode` 方法 Step 1
- `SAHG.Salt.Application/CodeService/ICodeService.cs` — 可能需要新增方法或调整调用方式

### 2.4 验证方式

1. 新建一条规则，SerialNumber 配置 `StartValue = 100, Step = 1, PaddingLength = 4`
2. 生成 3 个编码 → 预期 `0100, 0101, 0102`
3. 再次生成 3 个编码 → 预期 `0103, 0104, 0105`

---

## 三、缺陷 #2：Include Items 含软删除子项

### 3.1 现状

两处代码通过 `.Include(r => r.Items)` 加载子项，EF Include 不自动过滤 `IsDeleted == true`：

```csharp
// GetRuleDetails
var rule = repoRule.GetAll()
    .Where(r => r.IsDeleted != true && r.Id == id)
    .Include(r => r.Items)   // ← 已删除的子项也会被加载
    .FirstOrDefault();

// GenerateCode
var rule = repoRule.GetAll()
    .Where(r => r.IsDeleted != true && r.Status && r.Id == bizCode.CodeRuleId)
    .Include(r => r.Items)   // ← 同上
    .FirstOrDefault();
```

`SaveRule` 删除子项仅标记 `IsDeleted = true`（软删除），数据库记录仍在。

### 3.2 修复方案

Include 后在内存中过滤 `IsDeleted == true` 的子项（子项数量少，性能无影响）。

### 3.3 涉及文件

- `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs`
  - `GetRuleDetails` 方法
  - `GenerateCode` 方法

### 3.4 验证方式

1. 创建规则，添加 3 个子项 → 编辑删除 1 个（确认 DB 中 IsDeleted = true）
2. 调用 `GetRuleDetails` → 预期 2 个子项
3. 用该规则生成编码 → 预期 2 个子项参与拼接

---

## 四、缺陷 #3：BizFieldDefinition 重构 + Domain 约束 + 接口简化

### 4.1 现状问题

**问题 A — 三者脱节**：

```
BizCodeIdentifier (CodeSign=ProductCode, 商品编码)
    └── CodeRuleId → CodeRule
        └── Items → BusinessField → BizFieldDefinition (SourceTable=Employees, 员工表)
```

无任何约束阻止"商品编码拼入员工部门"。

**问题 B — BizContext 难用**：

```csharp
// 当前接口：调用方需要先知道内部 ID
public Dictionary<int, long> BizContext { get; set; }  // Key = BizFieldDefinition.Id（数据库内部ID）

// 调用方每次都要：
// 1. 调 GetBizFieldList 查有哪些字段
// 2. 找到对应的 BizFieldDefinition.Id
// 3. 用内部 Id 作 Key 传参
```

API 契约暴露数据库实现细节，规则配置一变，调用方代码也得改。

### 4.2 修复方案

#### 4.2.1 BizFieldDefinition 重构

**去掉**：`SourceTable`、`SourceField`、`Format`、`DefaultValue`

**新增**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `DomainCode` | `string` | 业务领域标识（如 Product / Order），由开发人员设定，全系统唯一 |
| `DomainName` | `string` | 业务领域显示名称（如 商品 / 订单） |
| `FieldSql` | `string` | 开发者配置的 SQL，接收参数 `@domainId`，返回一个字符串 |

> **Domain 数据源控制**：`BizFieldDefinition` 是 Domain 的**唯一定义来源**（由开发人员创建时设定 DomainCode + DomainName）。`CodeRule` 和 `BizCodeIdentifier` 的 Domain 字段只能通过下拉选择已有 DomainCode，不允许用户自由输入，以此保证三者 Domain 值严格一致。

**FieldSql 约定**：
- 由开发人员在管理后台配置
- 模板中必须使用参数 `@domainId`
- 返回单行单列的字符串值，无结果返回空串
- 格式化和默认值逻辑由开发者自行在 SQL 中处理

```sql
-- 示例：商品编码 → 查商品名称
SELECT ProductName FROM Products WHERE Id = @domainId

-- 示例：含默认值 + 格式化
SELECT ISNULL(FORMAT(ProductId, 'D6'), '000000') FROM Products WHERE Id = @domainId
```

#### 4.2.2 三个实体加 Domain

```
BizFieldDefinition.DomainCode = "Product"   ← 开发人员定义，唯一数据源
BizFieldDefinition.DomainName = "商品"

CodeRule.Domain             = "Product"      ← 下拉选择，不可手输
BizCodeIdentifier.Domain    = "Product"      ← 下拉选择，不可手输
```

**Domain 的流转**：
```
开发人员创建 BizFieldDefinition 时设定 DomainCode + DomainName
    │
    ├── 前端 CodeRule 页面：查询 DISTINCT DomainCode, DomainName FROM BizFieldDefinition 做下拉选项
    │   → 用户选择后，CodeRule.Domain 存入 DomainCode 值
    │
    └── 前端 BizCodeIdentifier 页面：同上，下拉选择
        → 用户选择后，BizCodeIdentifier.Domain 存入 DomainCode 值
```

**校验规则**：
- `SaveRule`：BusinessField 子项引用的 `BizFieldDefinition.DomainCode == CodeRule.Domain`
- `GenerateCode`：运行时校验引用一致性
- `DomainCode = "General"` 不受限制，用于跨领域公共字段（如公司Id、创建时间等基础字段）

#### 4.2.3 编码规则添加子项的前端交互约束

**问题**：当前 codeRule 页面点击"添加子项"时，未检查是否已选择 Domain，也未对业务字段下拉列表做过滤，导致可选到其他领域的字段。

**约束 1 — Domain 前置检查**：
- 用户点击"添加子项"时，前端先检查 `rule.Domain` 是否有值
- 若为空 → 弹出提示「请先选择业务领域」，阻止打开子项弹框
- 若已选择 → 继续打开子项弹框

**约束 2 — 业务字段过滤**：
- 子项弹框中"业务字段"下拉列表仅显示以下字段：
  - `DomainCode == rule.Domain`（当前领域字段）
  - `DomainCode == "General"`（基础领域字段，所有领域共用）
- 其他领域的字段不显示

```
示例：rule.Domain = "Product"
  下拉显示：
    ✅ ProductName   (DomainCode = "Product")
    ✅ ProductCode   (DomainCode = "Product")
    ✅ CompanyId     (DomainCode = "General")
    ❌ EmployeeName  (DomainCode = "Employee")  ← 不显示
```

#### 4.2.4 GenerateCodeInput 简化

**去掉**：`Dictionary<int, long> BizContext`

**改为**：`long DomainId`

```csharp
// 重构后
public class GenerateCodeInput
{
    public int CompanyId { get; set; }
    public string CodeSign { get; set; }
    public List<AssignObjectInfo> Objects { get; set; }
    public int Count { get; set; } = 1;
    public long DomainId { get; set; }   // ← 替代 BizContext
}
```

调用方只需传业务聚合根 ID：
```csharp
// 生成商品编码
input.CodeSign = "ProductCode";
input.DomainId = 456;  // 产品 Id
```

#### 4.2.5 ResolveBusinessField 简化

```csharp
// 重构前：需要查 BizFieldDefinition → 从 BizContext 取 bizId → 动态拼接 SQL
// 重构后：直接执行 FieldSql + @domainId
private string ResolveBusinessField(string fieldSql, long domainId)
{
    if (string.IsNullOrWhiteSpace(fieldSql))
        return string.Empty;
    var result = context.Database.SqlQuery<string>(fieldSql,
        new SqlParameter("@domainId", domainId)).FirstOrDefault();
    return result ?? string.Empty;
}
```

参数化查询防注入，且 SQL 是开发人员在管理后台配置的（受信来源）。

### 4.3 数据迁移

旧 `BizFieldDefinition` 数据需迁移：

```
SourceTable + SourceField + Format + DefaultValue  →  FieldSql
```

格式映射示例：

| 旧配置 | 新 FieldSql |
|--------|------------|
| `SourceTable=Products, SourceField=ProductName` | `SELECT ProductName FROM Products WHERE Id = @domainId` |
| 含 DefaultValue | `SELECT ISNULL(ProductName, '默认值') FROM Products WHERE Id = @domainId` |
| 含 Format `{0:D6}` | `SELECT FORMAT(ProductId, 'D6') FROM Products WHERE Id = @domainId` |

注意：
- 迁移后的 FieldSql 仍需人工审核确认正确性
- 历史记录的 `DomainCode` 和 `DomainName` 为空，需由开发人员手动补充（或将所有历史记录统一归入 `DomainCode = "General"`）

### 4.4 涉及文件

**实体层（Core）**：
- `BizFieldDefinition.cs` — ~~删除~~ SourceTable/SourceField/Format/DefaultValue，新增 DomainCode、DomainName、FieldSql
- `CodeRule.cs` — 新增 Domain
- `BizCodeIdentifier.cs` — 新增 Domain

**DTO 层（Application）**：
- `BizFieldDefinitionDto.cs` — 同步字段变更（DomainCode + DomainName + FieldSql），CheckData 改为校验 FieldSql + DomainCode 非空
- `CodeRuleDto.cs` — 新增 Domain，CheckData 中校验 Domain 一致性
- `BizCodeIdentifierDto.cs` — 新增 Domain
- `GenerateCodeInput.cs` — BizContext 改为 DomainId

**服务层（Application）**：
- `ICodeGeneratorService.cs` — 接口新增 `GetDomainList` 方法声明
- `CodeGeneratorService.cs`
  - `ResolveBusinessField` — 简化：直接用 FieldSql + @domainId
  - `GenerateCode` — 用 DomainId 替代 BizContext，预解析阶段适配
  - `SaveRule` — 新增 Domain 校验
  - `SaveBizField` — 适配新字段
  - `GetDomainList` — **新增**：查 `DISTINCT DomainCode, DomainName FROM BizFieldDefinition WHERE IsDeleted != true`，供前端下拉选项（CodeRule 和 BizCodeIdentifier 页面共用）

**控制器层**：
- `CodeGeneratorController.cs` — 新增 `GetDomainList` Action（HttpGet），返回 `List<{DomainCode, DomainName}>`

**映射（Application）**：
- `CodeGeneratorDtoMapping.cs` — 更新映射，去掉旧字段、加入新字段

**数据库迁移**：
- `BizFieldDefinition` 表：删 4 列、加 3 列（DomainCode + DomainName + FieldSql）
- `CodeRule` 表：加 1 列（Domain）
- `BizCodeIdentifier` 表：加 1 列（Domain）

**前端**（仓库 `caikuangzi.fenluwebproject`，根路径 `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\views\CodeGenerator\`）：
- `bizField/` — 表单改造：去掉 SourceTable/SourceField/Format/DefaultValue（4 个字段），新增 DomainCode（文本框）、DomainName（文本框）、FieldSql（多行文本框）。DomainCode 和 DomainName 由开发人员自由输入，不通过下拉选择
- `codeRule/` — 表单加 Domain 下拉（调 GetDomainList 接口获取选项），用户不可手输。添加子项时：未选 Domain 先提示「请先选择业务领域」阻止弹框；业务字段下拉仅显示当前 Domain + General 的字段
- `bizCode/` — 表单加 Domain 下拉（同上）
- `generate/` — 参数适配：去掉 BizContext（字典输入），改为 DomainId（数字输入框）

### 4.5 验证方式

1. 在 BizFieldDefinition 管理中创建一条记录：`DomainCode = "Product", DomainName = "商品"`，FieldSql = `SELECT ProductName FROM Products WHERE Id = @domainId`
2. 在 BizCodeIdentifier 管理中新建，Domain 下拉选择 `Product` → 预期保存成功
3. 在 CodeRule 管理中新建，Domain 下拉选择 `Product`，添加 BusinessField 子项，引用第 1 步的 BizFieldDefinition → 预期保存成功
4. 第 3 步的 CodeRule 中尝试引用 `DomainCode = "Employee"` 的 BizFieldDefinition → 预期后端校验不通过
5. 调用 GenerateCode：`CodeSign="ProductCode", DomainId=456` → 预期编码中包含对应 ProductName
6. 调用 GenerateCode：不需传 BizContext（旧字段已去掉），仅传 DomainId → 预期正常
7. CodeRule 和 BizCodeIdentifier 的 Domain 下拉框中不能手动输入，只能从已有 Domain 中选择 → 预期一致
8. CodeRule 未选 Domain 时点击"添加子项" → 预期弹出提示「请先选择业务领域」，不打开子项弹框
9. CodeRule 选择 Domain="Product"后点击"添加子项" → 业务字段下拉仅显示 DomainCode="Product" 和 "General" 的字段

---

## 五、实施顺序

| 阶段 | 内容 | 依赖 |
|------|------|------|
| **阶段 1** | 缺陷 #1（StartValue）+ 缺陷 #2（软删除过滤） | 无依赖，可并行 |
| **阶段 2** | 数据库迁移 + 实体层改字段 | 阶段 1 完成 |
| **阶段 3** | DTO + Service + 校验逻辑 | 阶段 2 完成 |
| **阶段 4** | 前端四页面适配（bizField / codeRule / bizCode / generate） | 阶段 3 完成 |

缺陷 #1 和 #2 可以先修，快速交付。#3 是重构，需要完整链路验证。
