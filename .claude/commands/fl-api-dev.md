---
description: [分路] 后端接口开发辅助 — 编译、测试、代码规范、SVN 操作
argument-hint: [compile|test|svn]
allowed-tools: [Bash, Read, Glob, Grep, Edit, Write]
---

# 分路接口系统开发辅助

## 技术栈

| 技术 | 说明 |
|------|------|
| .NET Framework 4.8 | **禁止使用 `dotnet build`** |
| ABP Framework | ASP.NET Boilerplate + Zero 模块 |
| Entity Framework 6 | Code First，`System.Data.Entity` |
| IoC | Castle Windsor（ABP IocManager） |
| 序列化 | Newtonsoft.Json |
| SVN | `https://vip.svnspot.net/caikuangzi.fenlu/trunk` |

## 项目分层

```
SAHG.Salt.Core/          # 领域实体层（Entity），继承 SaltEntity 或 HRM_CompanyEntity
SAHG.Salt.Application/   # 应用服务层（Service + DTO），继承 SaltAppServiceBase
SAHG.Salt.WebAppApi/     # Web API 控制器层（Areas/），继承 SaltControllerBase
SAHG.Salt.EntityFramework/ # EF DbContext + 仓储
```

## 编译

**编译整个解决方案（禁止 `dotnet build`）：**
```bash
cmd //c "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\work\cc\caikuangzi.fenlu\trunk\SAHG.Salt.sln" //t:Build //p:Configuration=Debug //v:q
```

## 代码规范

### 返回类型
- 增删改 → `OutDto`（`States` bool + `Tips` string）
- 查询列表 → `IList<TDto>` 或 `PagedListOutput<TDto>`
- 查询单个 → `TDto`

### Service 层
- 实现接口 `I{Name}Service`，继承 `SaltAppServiceBase`
- 构造函数注入 `IRepository<TEntity>`，原生 SQL 注入 `SaltDbContext`
- 所有查询带 `IsDeleted != true && CompanyId == input.CompanyId`
- 软删除：`entity.Delete(modifier)` + `repo.Update(entity)`
- 条件过滤使用 `WhereIf(condition, predicate)`

### Controller 层
- 继承 `SaltControllerBase`，路由自动映射 `api/{area}/{controller}/{action}`
- 查询 `[HttpGet]`，增删改 `[HttpPost]`
- 入参 `[FromBody] SaltRequest<TDto> input`，业务对象从 `input.Data` 取
- 新增：`input.Data.CreateNew(userName, companyId)`
- 修改：`input.Data.Update(userName)`

### DTO
- 继承 `HRM_CompanyEntityDto`，重写 `CheckData()` 做验证
- 不通过抛 `throw new ArgumentException("描述")`

### AutoMapper
- 在 `HRM_DtoMapping.CreateMapping()` 中注册双向映射

### 注释（强制，禁止零注释）
- 类和接口 `/// <summary>说明用途</summary>`
- public 属性 `/// <summary>字段含义</summary>`
- public 方法 `/// <summary>方法用途</summary>`，复杂参数加 `<param>` 和 `<returns>`
- 方法内：算法/性能优化/边界处理加 `//` 行注释
- Service/Controller 用 `#region` 分组
- 特殊标记：`// TODO:` `// FIXME:` `// HACK:` `// NOTE:`

### Controller 日志
- 每个 Action 加审计日志，按模块选对应 Attribute：

| 属性 | 模块 | 属性 | 模块 |
|------|------|------|------|
| `[HRMLog]` | 人力资源 | `[FMLog]` | 财务管理 |
| `[WHLog]` | 仓库管理 | `[COLog]` | 协同办公 |
| `[WBLog]` | 工作台 | `[BSLog]` | 基础设置 |
| `[SMLog]` | 销售管理 | `[CRMLog]` | 客户拜访 |
| `[PMLog]` | 采购管理 | `[PDMLog]` | 设计管理 |
| `[CMLog]` | 商品管理 | `[PPMLog]` | 生产管理 |

- 新模块暂无专用 Attribute 时用 `[CommonLog("操作描述")]`（模块名=公共模块）
- 需新建模块日志时，在 `SAHG.Salt.Core/Audit/LogAttribute.cs` 添加子类

## API 规范

> 完整的 API 规范（请求/响应格式、分页、路由、错误处理、认证）已拆分到独立文件。
> **生成 API 契约时** → 读取 `.claude/commands/fl-api-spec.md`

## 测试

### 环境

| 项目 | 值 |
|------|-----|
| IIS | `http://localhost:8088` |
| 站点/应用池 | `8088_fenluapi` |
| 账号 | `hongbin` / `123456` |
| 公司 | 2026 |

### 路由：`http://localhost:8088/api/{Area}/{Controller}/{Action}`

### 流程

**1. 登录获取 Token：**
```bash
LOGIN=$(curl -s -k -X POST "http://localhost:8088/api/Common/Account/Login" \
  -H "Content-Type: application/json" \
  -d '{"Data":{"Username":"hongbin","Password":"123456","Source":null}}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
```

**2. 调用接口：**
```bash
curl -s -k -X POST "http://localhost:8088/api/{Area}/{Controller}/{Action}" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{}"
```

**3. 带业务 Headers（AutoTask 等）：**
```bash
-H "companyId: 2026"
-H "taskId: 00000000-0000-0000-0000-000000000001"
-H "activityId: 00000000-0000-0000-0000-000000000002"
-H "workflowId: 00000000-0000-0000-0000-000000000003"
-H "processId: 00000000-0000-0000-0000-000000000004"
-H "timestamp: 1767024000"
```

**4. 检查 HTTP 状态码：**
```bash
curl -s -k -w "|HTTP:%{http_code}" ...
```

### 重启应用池
```bash
C:/Windows/System32/inetsrv/appcmd.exe stop apppool /apppool.name:"8088_fenluapi"
C:/Windows/System32/inetsrv/appcmd.exe start apppool /apppool.name:"8088_fenluapi"
```

### 常见问题

| 现象 | 解决 |
|------|------|
| HTTP 401 `token验证失败` | 重新 Login |
| HTTP 404 | URL 补 `/api/` 前缀 |
| HTTP 411 | POST 加 `-d "{}"` |
| DLL 未生效 | 重启应用池 |

## 新建文件（强制）

每新建一个文件，必须：
1. 若为 `.cs` 文件 → 在 `.csproj` 的 `<ItemGroup>` 中注册 `<Compile Include="相对路径\文件.cs" />`（按字母序）
2. 添加到 SVN：`svn add "相对路径/文件"`（仅暂存，**不 svn commit**，交付时统一提交）

**遗漏后果**：不参与编译（运行时 TypeLoadException）或未纳入版本控制。

## 文件移动（强制）

移动/重命名文件时，必须：
1. **使用 `svn mv oldPath newPath`**（禁止直接拷贝或 `mv` 命令）
2. 若为 `.cs` 文件 → 同步更新 `.csproj` 中对应路径

## 文件删除（强制）

删除文件时，必须：
1. **使用 `svn rm`**（禁止直接 `rm` 或 delete）
2. 若为 `.cs` 文件 → 从 `.csproj` 中移除对应 `<Compile Include>` 行

## 目录操作（强制）

创建目录：`svn mkdir` 或先创建再 `svn add`
删除目录：`svn rm`（自动递归删除目录内所有文件）

## SVN 错误操作修复

若已错误操作（SVN `!` 缺失 + `?` 未跟踪），修复：
```bash
svn rm --force oldPath/file
svn add newPath
```

## SVN

```bash
svn up                     # 拉取最新
svn st -q                  # 看改动
svn add <新文件>            # 添加新文件到版本控制（暂存，不提交）
# svn commit -m "说明"      # ⚠️ 开发期间不执行！交付时统一提交
```

**开发期间**：`svn up` → `svn st` → `svn add`（仅暂存）→ 编译通过  
**交付时**：`svn up` → `svn commit -m "说明"` 一次性入库（commit 前必须 update，避免代码覆盖）
**格式**：`[模块] 简短说明`  
**禁止提交**：`bin/` `obj/` `App_Data/` `packages/` `.vs/` `.env` `*.log` `node_modules/`
