# CodeGenerator 优化 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复 CodeGenerator 模块 3 项缺陷——StartValue 不生效、软删除子项泄露、业务领域脱节+接口复杂，重构 BizFieldDefinition 以 FieldSql 替代四字段、以 DomainId 替代 BizContext。

**Architecture:** 分两个阶段交付。阶段 A（Task 1-2，快速修复）互不依赖可并行。阶段 B（Task 3-15，Domain 重构）必须串行：数据库迁移 → 实体 → DTO → Service → Controller → 前端。后端在 `trunk` 仓库，前端在 `caikuangzi.fenluwebproject` 仓库。

**Tech Stack:** Backend: .NET Framework 4.8 + ABP + EF6 + Redis (StackExchange.Redis). Frontend: Vue 3 + LayuiVue.

---

## 阶段 A：快速修复（可并行）

### Task 1: 修复 StartValue 不生效

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `GenerateCode` 方法 Step 1（约 Line 461-469）
- Modify: `SAHG.Salt.Application/CodeService/ICodeService.cs` — `CodeService` 类，新增 `InitCounter` 方法（约 Line 179 附近）

**关联需求:** 003-CodeGenerator优化.md 第二节

- [ ] **Step 1: CodeService 新增 InitCounter 方法**

在 `CodeService` 类中新增方法，用于初始化 Redis 计数器到指定值：

```csharp
/// <summary>
/// 初始化计数器到指定值（仅在 key 不存在时设置）
/// </summary>
public void InitCounter(string key, long value)
{
    _database.StringSet(key, value, when: When.NotExists);
}
```

同时在 `ICodeService` 接口中新增声明：

```csharp
void InitCounter(string key, long value);
```

- [ ] **Step 2: GenerateCode 中调用 InitCounter**

在 `GenerateCode` 方法的 Step 1（`var snValues = new Dictionary<int, string[]>();` 之前），新增流水号初始化逻辑。

当前代码位置（约 Line 460-469）：
```csharp
// === 第一步：批量获取流水号 ===
var snValues = new Dictionary<int, string[]>();
foreach (var item in items.Where(i => i.ItemType == "SerialNumber"))
{
    var sp = JsonConvert.DeserializeObject<SerialNumberProperties>(item.Properties);
    var redisKey = $"CodeGen_{input.CodeSign}_{item.Id}_{bizCode.CompanyId}";
    snValues[item.Id] = codeService.BatchGenerateCode(
        redisKey, count, sp.PaddingLength, sp.Step, "", "");
}
```

修改为：
```csharp
// === 第一步：批量获取流水号（含初始化） ===
var snValues = new Dictionary<int, string[]>();
foreach (var item in items.Where(i => i.ItemType == "SerialNumber"))
{
    var sp = JsonConvert.DeserializeObject<SerialNumberProperties>(item.Properties);
    var redisKey = $"CodeGen_{input.CodeSign}_{item.Id}_{bizCode.CompanyId}";
    // 若 Redis key 不存在，初始化到 StartValue - Step（确保首次增量从 StartValue 开始）
    codeService.InitCounter(redisKey, sp.StartValue - sp.Step);
    snValues[item.Id] = codeService.BatchGenerateCode(
        redisKey, count, sp.PaddingLength, sp.Step, "", "");
}
```

- [ ] **Step 3: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

预期：0 Error。

- [ ] **Step 4: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn add --depth=empty . 2>/dev/null  # 确认无新文件需添加
svn commit -m "[CodeGenerator] 修复 SerialNumber StartValue 不生效，新增 Redis InitCounter"
```

---

### Task 2: 过滤 Include 中的软删除子项

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `GetRuleDetails`（约 Line 78-83）和 `GenerateCode`（约 Line 450-457）

**关联需求:** 003-CodeGenerator优化.md 第三节

- [ ] **Step 1: GetRuleDetails 过滤 IsDeleted**

当前代码（约 Line 78-83）：
```csharp
public CodeRuleDto GetRuleDetails(int id)
{
    var rule = repoRule.GetAll()
        .Where(r => r.IsDeleted != true && r.Id == id)
        .Include(r => r.Items)
        .FirstOrDefault();
    return ObjectMapper.Map<CodeRuleDto>(rule);
}
```

修改为（Map 前过滤 Items）：
```csharp
public CodeRuleDto GetRuleDetails(int id)
{
    var rule = repoRule.GetAll()
        .Where(r => r.IsDeleted != true && r.Id == id)
        .Include(r => r.Items)
        .FirstOrDefault();
    if (rule != null)
        rule.Items = rule.Items.Where(i => !i.IsDeleted).ToList();
    return ObjectMapper.Map<CodeRuleDto>(rule);
}
```

- [ ] **Step 2: GenerateCode 过滤 IsDeleted**

当前代码（约 Line 450-457）：
```csharp
var rule = repoRule.GetAll()
    .Where(r => r.IsDeleted != true && r.Status && r.Id == bizCode.CodeRuleId)
    .Include(r => r.Items)
    .FirstOrDefault();
if (rule == null)
    throw new Exception($"编码规则不存在或已禁用");

var items = rule.Items.OrderBy(i => i.SortOrder).ToList();
```

修改为（OrderBy 前过滤）：
```csharp
var rule = repoRule.GetAll()
    .Where(r => r.IsDeleted != true && r.Status && r.Id == bizCode.CodeRuleId)
    .Include(r => r.Items)
    .FirstOrDefault();
if (rule == null)
    throw new Exception($"编码规则不存在或已禁用");

var items = rule.Items.Where(i => !i.IsDeleted).OrderBy(i => i.SortOrder).ToList();
```

- [ ] **Step 3: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

预期：0 Error。

- [ ] **Step 4: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] 过滤 Include 中的软删除子项（GetRuleDetails + GenerateCode）"
```

---

## 阶段 B：Domain 重构 + 接口简化（串行依赖）

### Task 3: 数据库迁移

**Files:**
- Create: EF Migration 文件（通过 Add-Migration 生成）

**关联需求:** 003-CodeGenerator优化.md 第四节（4.3 + 4.4 数据库部分）

- [ ] **Step 1: 更新实体字段（先改代码再生成迁移）**

按 Task 4 的要求修改三个实体文件。迁移生成命令：

```
Add-Migration CodeGenerator_AddDomainAndFieldSql
```

预期生成的迁移包含：
- `BizFieldDefinitions` 表：DropColumn("SourceTable", "SourceField", "Format", "DefaultValue") + AddColumn("DomainCode", c => c.String(maxLength: 64)) + AddColumn("DomainName", c => c.String(maxLength: 256)) + AddColumn("FieldSql", c => c.String())
- `CodeRules` 表：AddColumn("Domain", c => c.String(maxLength: 64))
- `BizCodeIdentifiers` 表：AddColumn("Domain", c => c.String(maxLength: 64))

- [ ] **Step 2: 执行迁移**

```
Update-Database -Verbose
```

- [ ] **Step 3: 数据迁移脚本（手动执行）**

历史 `BizFieldDefinition` 数据需手动转换后执行 UPDATE SQL：

```sql
-- 示例：将旧字段拼接为 FieldSql
UPDATE BizFieldDefinitions
SET FieldSql = 'SELECT ' + QUOTENAME(SourceField) + ' FROM ' + QUOTENAME(SourceTable) + ' WHERE Id = @domainId',
    DomainCode = 'General',
    DomainName = '通用'
WHERE FieldSql IS NULL;
```

- [ ] **Step 4: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn add  # 添加迁移文件
svn commit -m "[CodeGenerator] 数据库迁移：BizFieldDefinition 重构 + Domain 字段"
```

---

### Task 4: 更新 Core 实体层

**Files:**
- Modify: `SAHG.Salt.Core/CodeGenerator/BizFieldDefinition.cs`
- Modify: `SAHG.Salt.Core/CodeGenerator/CodeRule.cs`
- Modify: `SAHG.Salt.Core/CodeGenerator/BizCodeIdentifier.cs`

**关联需求:** 003-CodeGenerator优化.md 4.4 实体层

- [ ] **Step 1: 更新 BizFieldDefinition**

当前文件：
```csharp
using SAHG.Salt.HRM;
using System.ComponentModel.DataAnnotations;

namespace SAHG.Salt.CodeGenerator
{
    /// <summary>
    /// 业务字段定义 — BusinessField 子项可引用的自定义字段
    /// </summary>
    public class BizFieldDefinition : HRM_CompanyEntity
    {
        [StringLength(256)]
        public string FieldName { get; set; }

        [StringLength(256)]
        public string SourceTable { get; set; }

        [StringLength(256)]
        public string SourceField { get; set; }

        [StringLength(64)]
        public string Format { get; set; }

        [StringLength(256)]
        public string DefaultValue { get; set; }

        [StringLength(500)]
        public string Description { get; set; }
    }
}
```

修改为：
```csharp
using SAHG.Salt.HRM;
using System.ComponentModel.DataAnnotations;

namespace SAHG.Salt.CodeGenerator
{
    /// <summary>
    /// 业务字段定义 — BusinessField 子项可引用的自定义字段
    /// 开发人员配置 FieldSql（参数 @domainId），运行时动态查库获取字段值
    /// </summary>
    public class BizFieldDefinition : HRM_CompanyEntity
    {
        /// <summary>
        /// 显示名称（如 商品名称 / 员工部门）
        /// </summary>
        [StringLength(256)]
        public string FieldName { get; set; }

        /// <summary>
        /// 业务领域标识（如 Product / Order / Employee），同领域下唯一
        /// </summary>
        [StringLength(64)]
        public string DomainCode { get; set; }

        /// <summary>
        /// 业务领域显示名称（如 商品 / 订单 / 员工）
        /// </summary>
        [StringLength(256)]
        public string DomainName { get; set; }

        /// <summary>
        /// 动态查询 SQL，接收参数 @domainId，返回单个字符串值
        /// 示例：SELECT ProductName FROM Products WHERE Id = @domainId
        /// </summary>
        public string FieldSql { get; set; }

        /// <summary>
        /// 描述
        /// </summary>
        [StringLength(500)]
        public string Description { get; set; }
    }
}
```

- [ ] **Step 2: 更新 CodeRule（新增 Domain）**

在 `CodeRule` 类中新增：
```csharp
/// <summary>
/// 所属业务领域标识（对应 BizFieldDefinition.DomainCode）
/// </summary>
[StringLength(64)]
public string Domain { get; set; }
```

插入位置：`public bool Status { get; set; }` 之后。

- [ ] **Step 3: 更新 BizCodeIdentifier（新增 Domain）**

在 `BizCodeIdentifier` 类中新增：
```csharp
/// <summary>
/// 所属业务领域标识（对应 BizFieldDefinition.DomainCode）
/// </summary>
[StringLength(64)]
public string Domain { get; set; }
```

插入位置：`public bool Status { get; set; }` 之后。

- [ ] **Step 4: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Core\SAHG.Salt.Core.csproj" //t:Build //p:Configuration=Debug //v:q
```

- [ ] **Step 5: 注册新文件到 csproj + svn**

无新文件（仅修改已有文件），跳过。

- [ ] **Step 6: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] Core 实体：BizFieldDefinition 重构 + CodeRule/BizCodeIdentifier 加 Domain"
```

---

### Task 5: 更新 DTO 层

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/BizFieldDefinitionDto.cs`
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/CodeRuleDto.cs`
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/BizCodeIdentifierDto.cs`
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/GenerateCodeInput.cs`

**关联需求:** 003-CodeGenerator优化.md 4.4 DTO 层

- [ ] **Step 1: 更新 BizFieldDefinitionDto**

当前文件需同步实体字段变更。改为：

```csharp
using SAHG.Salt.HRM.Dto;
using System;

namespace SAHG.Salt.CodeGenerator.Dto
{
    /// <summary>
    /// 业务字段定义 — BusinessField 子项可引用的自定义字段
    /// </summary>
    public class BizFieldDefinitionDto : HRM_CompanyEntityDto
    {
        /// <summary>显示名称</summary>
        public string FieldName { get; set; }

        /// <summary>业务领域标识</summary>
        public string DomainCode { get; set; }

        /// <summary>业务领域显示名称</summary>
        public string DomainName { get; set; }

        /// <summary>动态查询 SQL，参数 @domainId</summary>
        public string FieldSql { get; set; }

        /// <summary>描述</summary>
        public string Description { get; set; }

        public override void CheckData()
        {
            if (string.IsNullOrWhiteSpace(FieldName))
                throw new ArgumentException("字段名称不能为空");
            if (string.IsNullOrWhiteSpace(DomainCode))
                throw new ArgumentException("业务领域标识不能为空");
            if (string.IsNullOrWhiteSpace(FieldSql))
                throw new ArgumentException("FieldSql 不能为空");
        }
    }
}
```

- [ ] **Step 2: 更新 CodeRuleDto**

在 `CodeRuleDto` 中新增 `Domain` 属性，并在 `CheckData` 中加入 Domain 校验逻辑（非空 + 与 BusinessField 子项引用的 BizFieldDefinition.DomainCode 一致性）。注意：Domain 校验需在 Service 层做（需要 DB 查询），DTO 的 CheckData 只校验非空。

新增属性（插入 `Status` 之后）：
```csharp
/// <summary>所属业务领域标识</summary>
public string Domain { get; set; }
```

CheckData 中增加（在 `if (!Items.Any(i => i.ItemType == "SerialNumber"))` 之后）：
```csharp
if (string.IsNullOrWhiteSpace(Domain))
    throw new ArgumentException("业务领域不能为空");
```

- [ ] **Step 3: 更新 BizCodeIdentifierDto**

新增属性（插入 `Status` 之后）：
```csharp
/// <summary>所属业务领域标识</summary>
public string Domain { get; set; }
```

- [ ] **Step 4: 更新 GenerateCodeInput**

```csharp
using System.Collections.Generic;

namespace SAHG.Salt.CodeGenerator.Dto
{
    /// <summary>
    /// 生成编码入参
    /// </summary>
    public class GenerateCodeInput
    {
        /// <summary>所属公司Id</summary>
        public int CompanyId { get; set; }

        /// <summary>业务编码标识（对应 BizCodeIdentifier.CodeSign）</summary>
        public string CodeSign { get; set; }

        /// <summary>赋码对象信息</summary>
        public List<AssignObjectInfo> Objects { get; set; }

        /// <summary>批量生成数量，默认1</summary>
        public int Count { get; set; } = 1;

        /// <summary>
        /// 业务领域聚合根 Id，用于 BusinessField 子项的 FieldSql 参数 @domainId
        /// </summary>
        public long DomainId { get; set; }
    }
}
```

去掉 `BizContext` 字段（`Dictionary<int, long>`）。

- [ ] **Step 5: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

预期：0 Error。

- [ ] **Step 6: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] DTO 层适配：BizFieldDefinition 重构 + Domain + BizContext→DomainId"
```

---

### Task 6: 更新 AutoMapper 映射

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/Dto/CodeGeneratorDtoMapping.cs`

**关联需求:** 003-CodeGenerator优化.md 4.4 映射

- [ ] **Step 1: 更新映射配置**

当前映射中 `BizFieldDefinition ↔ BizFieldDefinitionDto` 的双向映射已存在，但旧字段名变更后 AutoMapper 会按约定自动匹配。确认映射配置无需变更（字段名相同则自动映射），新字段 DomainCode/DomainName/FieldSql 自动覆盖，旧字段 SourceTable/SourceField/Format/DefaultValue 自动忽略。

**无需改动映射代码**。标准双向映射 `CreateMap<BizFieldDefinition, BizFieldDefinitionDto>()` 和反向映射会自动处理同名字段。

- [ ] **Step 2: Commit**

```bash
# 无代码变更，跳过或合并到 Task 5 的 commit
```

*此 Task 无独立改动，可与 Task 5 合并提交。*

---

### Task 7: 重写 ResolveBusinessField + 适配 GenerateCode

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `ResolveBusinessField` 方法（约 Line 564-592）和 `GenerateCode` 方法（约 Line 432-558）

**关联需求:** 003-CodeGenerator优化.md 4.2.3 + 4.2.4

- [ ] **Step 1: 重写 ResolveBusinessField**

当前方法：
```csharp
private string ResolveBusinessField(int bizFieldDefinitionId, CodeRule rule, GenerateCodeInput input)
{
    var def = repoBizField.GetAll()
        .FirstOrDefault(f => f.IsDeleted != true && f.Id == bizFieldDefinitionId);
    if (def == null)
        throw new Exception($"未找到业务字段定义: Id={bizFieldDefinitionId}");

    if (input.BizContext == null || !input.BizContext.TryGetValue(bizFieldDefinitionId, out var bizId))
        throw new Exception($"业务字段 Id={bizFieldDefinitionId} 需要调用方传入对应的业务Id");

    var sql = $"SELECT [{def.SourceField}] FROM [{def.SourceTable}] WHERE Id = @p0";
    var result = context.Database.SqlQuery<string>(sql, bizId).FirstOrDefault();

    if (result == null)
    {
        if (!string.IsNullOrWhiteSpace(def.DefaultValue))
            return def.DefaultValue;
        throw new Exception($"根据业务字段 Id={bizFieldDefinitionId} 查不到数据（表 {def.SourceTable}，Id={bizId}）");
    }

    if (!string.IsNullOrWhiteSpace(def.Format))
        result = string.Format(def.Format, result);

    return result;
}
```

重写为：
```csharp
/// <summary>
/// 执行 FieldSql（参数 @domainId），返回字段值。无结果返回空串。
/// </summary>
private string ResolveBusinessField(string fieldSql, long domainId)
{
    if (string.IsNullOrWhiteSpace(fieldSql))
        return string.Empty;
    var result = context.Database.SqlQuery<string>(
        fieldSql,
        new System.Data.SqlClient.SqlParameter("@domainId", domainId)
    ).FirstOrDefault();
    return result ?? string.Empty;
}
```

- [ ] **Step 2: 适配 GenerateCode 预解析阶段**

GenerateCode 的 Step 2（预解析非流水号子项）中的 BusinessField 处理逻辑需适配。

当前代码（约 Line 490-496）：
```csharp
case "BusinessField":
    var bf = JsonConvert.DeserializeObject<BusinessFieldProperties>(item.Properties);
    preBusinessFields[item.Id] = bf;
    bfResolvedValues[item.Id] = ResolveBusinessField(bf.BizFieldDefinitionId, rule, input);
    break;
```

修改为：
```csharp
case "BusinessField":
    var bf = JsonConvert.DeserializeObject<BusinessFieldProperties>(item.Properties);
    // 校验 Domain 一致性
    var fieldDef = repoBizField.GetAll()
        .FirstOrDefault(f => f.IsDeleted != true && f.Id == bf.BizFieldDefinitionId);
    if (fieldDef == null)
        throw new Exception($"未找到业务字段定义: Id={bf.BizFieldDefinitionId}");
    if (fieldDef.DomainCode != "General" && fieldDef.DomainCode != rule.Domain)
        throw new Exception($"业务字段 Domain({fieldDef.DomainCode})与规则 Domain({rule.Domain})不一致");

    preBusinessFields[item.Id] = bf;
    bfResolvedValues[item.Id] = ResolveBusinessField(fieldDef.FieldSql, input.DomainId);
    break;
```

Step 3（拼接阶段）中 `var bf = preBusinessFields[item.Id];` 后的补全逻辑不变，继续使用 `bf.PaddingLength` 和 `bf.PaddingChar`。

- [ ] **Step 3: 更新 BusinessFieldProperties**

`BusinessFieldProperties` 类（在 `CodeRuleItemDto.cs` 中）保持不变，它存的是 `BizFieldDefinitionId`（不是 FieldSql），通过 Id 关联查询。

- [ ] **Step 4: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

预期：0 Error。

- [ ] **Step 5: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] 重写 ResolveBusinessField + GenerateCode 适配 DomainId/Domain 校验"
```

---

### Task 8: SaveRule 新增 Domain 校验

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `SaveRule` 方法（约 Line 85-154）

**关联需求:** 003-CodeGenerator优化.md 4.2.2 校验规则

- [ ] **Step 1: SaveRule 中加 Domain 校验**

在 `SaveRule` 方法的 `input.CheckData();` 之后，新增 Domain 一致性校验：

```csharp
public OutDto SaveRule(CodeRuleDto input)
{
    OutDto outDto = new OutDto() { States = true, Tips = "保存成功" };

    input.CheckData();

    // Domain 一致性校验：BusinessField 子项引用的 BizFieldDefinition.DomainCode 必须 == CodeRule.Domain
    var bfItems = input.Items?.Where(i => i.ItemType == "BusinessField").ToList();
    if (bfItems != null && bfItems.Any())
    {
        foreach (var bfItem in bfItems)
        {
            var bfp = bfItem.DeserializeProperties<BusinessFieldProperties>();
            var fieldDef = repoBizField.GetAll()
                .FirstOrDefault(f => f.IsDeleted != true && f.Id == bfp.BizFieldDefinitionId);
            if (fieldDef == null)
                throw new Exception($"业务字段定义不存在: Id={bfp.BizFieldDefinitionId}");
            if (fieldDef.DomainCode != "General" && fieldDef.DomainCode != input.Domain)
                throw new Exception($"业务字段「{fieldDef.FieldName}」所属领域({fieldDef.DomainCode})与规则领域({input.Domain})不一致");
        }
    }

    // ... 后续原有逻辑不变
```

插入位置：`input.CheckData();` 之后，`if (input.Id > 0)` 之前。

- [ ] **Step 2: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

- [ ] **Step 3: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] SaveRule 新增 Domain 一致性校验"
```

---

### Task 9: SaveBizField 适配新字段

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — `SaveBizField` 方法（约 Line 368-401）

**关联需求:** 003-CodeGenerator优化.md 4.4 服务层

- [ ] **Step 1: 更新 SaveBizField 字段赋值**

当前 `SaveBizField` 中的属性赋值：
```csharp
entity.FieldName = input.FieldName;
entity.SourceTable = input.SourceTable;
entity.SourceField = input.SourceField;
entity.Format = input.Format;
entity.DefaultValue = input.DefaultValue;
entity.Description = input.Description;
```

修改为：
```csharp
entity.FieldName = input.FieldName;
entity.DomainCode = input.DomainCode;
entity.DomainName = input.DomainName;
entity.FieldSql = input.FieldSql;
entity.Description = input.Description;
entity.Modifier = input.Modifier;
entity.LastModificationTime = input.LastModificationTime;
```

- [ ] **Step 2: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

- [ ] **Step 3: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] SaveBizField 适配新字段（DomainCode/DomainName/FieldSql）"
```

---

### Task 10: 新增 GetDomainList 接口

**Files:**
- Modify: `SAHG.Salt.Application/CodeGenerator/ICodeGeneratorService.cs` — 新增方法声明
- Modify: `SAHG.Salt.Application/CodeGenerator/CodeGeneratorService.cs` — 新增方法实现

**关联需求:** 003-CodeGenerator优化.md 4.4 服务层（GetDomainList）

- [ ] **Step 1: 接口新增声明**

在 `ICodeGeneratorService` 中（`#region 业务字段定义 CRUD` 之后、`#region 统一查询` 之前）新增：

```csharp
#region Domain 查询

/// <summary>
/// 获取所有已定义的业务领域列表（供 CodeRule 和 BizCodeIdentifier 页面的 Domain 下拉选项）
/// </summary>
IList<DomainOptionDto> GetDomainList();

#endregion
```

- [ ] **Step 2: 创建 DomainOptionDto**

新建文件 `SAHG.Salt.Application/CodeGenerator/Dto/DomainOptionDto.cs`：

```csharp
namespace SAHG.Salt.CodeGenerator.Dto
{
    /// <summary>
    /// Domain 下拉选项
    /// </summary>
    public class DomainOptionDto
    {
        /// <summary>业务领域标识</summary>
        public string DomainCode { get; set; }

        /// <summary>业务领域显示名称</summary>
        public string DomainName { get; set; }
    }
}
```

- [ ] **Step 3: Service 实现**

在 `CodeGeneratorService` 中（`#region 校验编码规则` 之后、`#region 统一查询` 之前）新增：

```csharp
#region Domain 查询

public IList<DomainOptionDto> GetDomainList()
{
    return repoBizField.GetAll()
        .Where(f => f.IsDeleted != true && !string.IsNullOrWhiteSpace(f.DomainCode))
        .GroupBy(f => new { f.DomainCode, f.DomainName })
        .Select(g => new DomainOptionDto
        {
            DomainCode = g.Key.DomainCode,
            DomainName = g.Key.DomainName
        })
        .OrderBy(d => d.DomainCode)
        .ToList();
}

#endregion
```

- [ ] **Step 4: 注册新文件**

`DomainOptionDto.cs` 需要注册到 `.csproj` 和 SVN：

```bash
# 在 SAHG.Salt.Application.csproj 的 <ItemGroup> 中按字母序插入：
# <Compile Include="CodeGenerator\Dto\DomainOptionDto.cs" />

cd D:/work/cc/caikuangzi.fenlu/trunk
svn add "SAHG.Salt.Application/CodeGenerator/Dto/DomainOptionDto.cs"
```

- [ ] **Step 5: 编译验证**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.Application\SAHG.Salt.Application.csproj" //t:Build //p:Configuration=Debug //v:q
```

- [ ] **Step 6: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] 新增 GetDomainList 接口 + DomainOptionDto"
```

---

### Task 11: 更新 Controller

**Files:**
- Modify: `SAHG.Salt.WebAppApi/Areas/CodeGenerator/Controllers/CodeGeneratorController.cs`

**关联需求:** 003-CodeGenerator优化.md 4.4 控制器层

- [ ] **Step 1: 新增 GetDomainList Action**

在 Controller 的 `#region 业务字段定义 CRUD` 之后、`#region 统一查询` 之前新增：

```csharp
#region Domain 查询

/// <summary>
/// 获取所有已定义的业务领域列表（供 Domain 下拉选项）
/// </summary>
[HttpGet]
[CommonLog("获取业务领域列表")]
public IList<DomainOptionDto> GetDomainList()
{
    return codeGenService.GetDomainList();
}

#endregion
```

同时新增 using：
```csharp
using SAHG.Salt.CodeGenerator.Dto;
```
（已存在则跳过）

- [ ] **Step 2: 编译验证（全解决方案）**

```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.sln" //t:Build //p:Configuration=Debug //v:q
```

预期：0 Error。

- [ ] **Step 3: Commit**

```bash
cd D:/work/cc/caikuangzi.fenlu/trunk
svn commit -m "[CodeGenerator] Controller 新增 GetDomainList Action"
```

---

## 阶段 C：前端适配（caikuangzi.fenluwebproject 仓库）

### Task 12: 更新 bizField 管理页

**Files:**
- Modify: `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\views\CodeGenerator\bizField\` 目录下的表单页面

**关联需求:** 003-CodeGenerator优化.md 4.4 前端 — bizField

- [ ] **Step 1: 表单字段替换**

去掉 4 个旧字段：SourceTable、SourceField、Format、DefaultValue
新增 3 个字段：
- `DomainCode` — 文本输入框（开发人员自由输入），必填
- `DomainName` — 文本输入框（开发人员自由输入），必填
- `FieldSql` — 多行文本框（textarea），必填，提示示例：`SELECT ProductName FROM Products WHERE Id = @domainId`

保留 `FieldName`、`Description` 字段不变。

- [ ] **Step 2: 列表列替换**

列表页中去掉 SourceTable、SourceField、Format 列，新增 DomainCode、DomainName 列。

- [ ] **Step 3: 提交**

```bash
cd D:/work/cc/caikuangzi.fenluwebproject/trunk
svn commit -m "[CodeGenerator] bizField 页面：SourceX 四字段 → DomainCode/DomainName/FieldSql"
```

---

### Task 13: 更新 codeRule 管理页

**Files:**
- Modify: `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\views\CodeGenerator\codeRule\` 目录下的表单页面

**关联需求:** 003-CodeGenerator优化.md 4.4 前端 — codeRule + 4.2.3 添加子项交互约束

- [ ] **Step 1: 表单新增 Domain 下拉**

新增 `Domain` 下拉选择框，数据源调 `GET /api/CodeGenerator/CodeGenerator/GetDomainList`，选项格式 `{DomainCode, DomainName}`，显示 `DomainName`，值为 `DomainCode`。用户不可手动输入。

- [ ] **Step 2: 列表新增 Domain 列**

列表页新增 `Domain` 展示列。

- [ ] **Step 3: 添加子项 — Domain 前置检查**

点击"添加子项"按钮时，先检查表单中 `Domain` 是否有值：
- 若 `Domain` 为空 → `layer.msg("请先选择业务领域")` 或等价的 alert 提示，**不打开**子项弹框
- 若 `Domain` 已选 → 继续执行打开子项弹框的逻辑

- [ ] **Step 4: 添加子项 — 业务字段下拉过滤**

子项弹框中加载业务字段下拉选项时，过滤规则：
- 仅显示 `DomainCode == rule.Domain` 或 `DomainCode == "General"` 的 BizFieldDefinition
- 过滤逻辑可在前端做（从已加载的 BizFieldDefinition 列表中 filter），也可调后端接口时传入 DomainCode 参数由后端过滤
- 若采用前端过滤，需确保加载的是全量 BizFieldDefinition 列表（非分页数据）

- [ ] **Step 5: 提交**

```bash
cd D:/work/cc/caikuangzi.fenluwebproject/trunk
svn commit -m "[CodeGenerator] codeRule 页面：Domain 下拉 + 添加子项 Domain 前置检查 + 业务字段过滤"
```

---

### Task 14: 更新 bizCode 管理页

**Files:**
- Modify: `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\views\CodeGenerator\bizCode\` 目录下的表单页面

**关联需求:** 003-CodeGenerator优化.md 4.4 前端 — bizCode

- [ ] **Step 1: 表单新增 Domain 下拉**

与 Task 13 步 1 相同：新增 `Domain` 下拉选择框，调 `GetDomainList`，用户不可手输。

- [ ] **Step 2: 列表新增 Domain 列**

列表页新增 `Domain` 展示列。

- [ ] **Step 3: 提交**

```bash
cd D:/work/cc/caikuangzi.fenluwebproject/trunk
svn commit -m "[CodeGenerator] bizCode 页面：新增 Domain 下拉选择"
```

---

### Task 15: 更新 generate 页面

**Files:**
- Modify: `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\views\CodeGenerator\generate\` 目录下的页面
- Modify: 所有调用 GenerateCode API 的前端页面（如 `commonProductionStages/generatorProductCodes/`）

**关联需求:** 003-CodeGenerator优化.md 4.4 前端 — generate + 4.2.3

- [ ] **Step 1: 参数替换**

去掉 `BizContext`（字典输入框），改为 `DomainId`（数字输入框）。调用 GenerateCode API 时参数从：
```javascript
{
    CodeSign: "ProductCode",
    Count: n,
    BizContext: { 123: productId },  // 旧方式
    Objects: [...]
}
```
改为：
```javascript
{
    CodeSign: "ProductCode",
    Count: n,
    DomainId: productId,             // 新方式
    Objects: [...]
}
```

- [ ] **Step 2: 搜索所有调用方**

Grep 搜索 `BizContext` 关键字，确保所有调用 GenerateCode 的前端代码都已替换为 `DomainId`。

```bash
grep -r "BizContext" D:/work/cc/caikuangzi.fenluwebproject/trunk/Web/Web/v2/views/
grep -r "BizContext" D:/work/cc/caikuangzi.fenluwebproject/trunk/Web/Web/v2/
```

- [ ] **Step 3: 提交**

```bash
cd D:/work/cc/caikuangzi.fenluwebproject/trunk
svn commit -m "[CodeGenerator] generate 页面：BizContext → DomainId 参数替换"
```

---

## 任务汇总

| Task | 内容 | 仓库 | 角色 | 依赖 |
|------|------|------|------|------|
| 1 | StartValue 修复 | trunk | developer | 无 |
| 2 | 软删除子项过滤 | trunk | developer | 无 |
| 3 | 数据库迁移 | trunk | developer | Task 4 |
| 4 | Core 实体更新 | trunk | developer | 无 |
| 5 | DTO 更新 | trunk | developer | Task 4 |
| 6 | AutoMapper | trunk | developer | Task 5 |
| 7 | ResolveBusinessField + GenerateCode | trunk | developer | Task 5 |
| 8 | SaveRule Domain 校验 | trunk | developer | Task 5 |
| 9 | SaveBizField 适配 | trunk | developer | Task 5 |
| 10 | GetDomainList 接口 | trunk | developer | Task 4,5 |
| 11 | Controller 更新 | trunk | developer | Task 10 |
| 12 | bizField 前端 | fenluwebproject | developer1 | Task 11 |
| 13 | codeRule 前端 | fenluwebproject | developer1 | Task 11 |
| 14 | bizCode 前端 | fenluwebproject | developer1 | Task 11 |
| 15 | generate 前端 | fenluwebproject | developer1 | Task 11 |

### 执行顺序

```
阶段 A（并行）:  Task 1 ─┬─ 编译验证 → 提交
                        Task 2 ─┘

阶段 B（串行）:  Task 4 → Task 5 → Task 6/7/8/9/10 → Task 3(迁移) → Task 11(Controller) → 编译验证 → 提交

阶段 C（前端）:   Task 12/13/14/15（可并行） → 各自提交
```

### 编译检查点

| 检查点 | 范围 | 时机 |
|--------|------|------|
| CP1 | SAHG.Salt.Application.csproj | Task 1, 2, 5, 7, 8, 9, 10 各步完成后 |
| CP2 | SAHG.Salt.Core.csproj | Task 4 完成后 |
| CP3 | SAHG.Salt.sln（全解决方案） | Task 11 完成后（最终验证） |
