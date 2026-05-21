---
description: [鸿冠ERP] 后端接口开发辅助 — 编译、测试、代码规范、SVN 操作
argument-hint: [compile|test|svn]
allowed-tools: [Bash, Read, Glob, Grep, Edit, Write]
---

# 鸿冠ERP 后端开发辅助

## 技术栈

| 技术 | 说明 |
|------|------|
| .NET 10.0 | **使用 `dotnet build`**，非 .NET Framework |
| Furion 4.9.7 | 应用框架（动态 API、JWT、DI、启动约定） |
| SqlSugarCore 5.1.4 | ORM，静态 `DbContext.Instance` 单例 |
| Mapster | 对象映射（Furion 扩展） |
| Newtonsoft.Json | JSON 序列化 |
| StackExchange.Redis | Redis 缓存客户端 |
| BCrypt.Net-Next | 密码哈希 |
| SVN | `https://vip.svnspot.net/caikuangzi01.huoguan_erp/trunk` |

## 项目分层

```
IChainStar.Infrastructure.Core/          # 领域层（Entity、Enum、领域接口、状态机）
IChainStar.Infrastructure.Application/   # 应用层（AppService、DTO、审批引擎）
IChainStar.Infrastructure.Web.Core/      # Web 基础设施（Startup、JwtHandler、中间件）
IChainStar.Infrastructure.Web.Entry/     # Web 入口（Program.cs、appsettings.json）
IChainStar.Infrastructure.Frontend/      # 前端静态资源（独立 .csproj，Kestrel 静态文件服务）
```

依赖方向：`Core ← Application ← Web.Core ← Web.Entry`（Frontend 独立）

## 编译

**使用 `dotnet build`：**
```bash
dotnet restore D:\work\cc\caikuangzi01.huoguan_erp\trunk\honguan_erp.sln
dotnet build D:\work\cc\caikuangzi01.huoguan_erp\trunk\honguan_erp.sln -c Debug
```

**发布：**
```bash
dotnet publish D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Web.Entry -c Release -o ./publish/entry
```

**开发运行：**
```bash
cd D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Web.Entry && dotnet watch run
```

**特殊 CLI 参数：**
```bash
dotnet run -- --update-database           # 从实体生成表结构
dotnet run -- --update-database EntityName  # 更新指定实体表
dotnet run -- --update-locales            # 生成本地化文件
```

## 代码规范

### 核心模式

| 模式 | 说明 |
|------|------|
| **动态 API** | 实现 `IDynamicApiController`，方法自动暴露为 REST 端点 |
| **泛型 CRUD** | 继承 `CurdBase<T>`，获得完整的 CRUD 能力 |
| **全局过滤** | SqlSugar 自动应用软删除（`IsDeleted == false`）+ 租户（`TenantId`） |
| **审批流** | 实体实现 `IApprovalableEntity`，`CurdBase<T>` 中自动集成审批 |
| **状态机** | `Core/StateMachine/GenericStateMachine`，复杂状态转换使用 |

### 实体层（Core）

- 继承 `EntityBase`（标准实体：含租户、版本、软删、修改追踪）
- 轻量实体继承 `SimpleEntityBase`（无租户用 `NoTenantEntityBase`）
- 树形结构实现 `ITreeEntity`
- 数据权限实现 `IBelongToEntity` / `IBelongToManyEntity`
- 审批实体实现 `IApprovalableEntity`
- 自动编码实体实现 `ICodeEntity`
- 类名加 `Entity` 前缀：`EntityWorkOrder`、`EntityMaterial`

### 应用层（Application）

- Service 类实现 `IDynamicApiController` + `[ApiDescriptionSettings(Groups = new string[] { "Infra" })]`
- CRUD 继承 `CurdBase<T>` + 覆写虚方法
- 自定义非 CRUD Service 注入 `IHttpClientFactory`、`IConfiguration`、其他 Service
- 用 `App.Configuration["Section:Key"]` 读取配置
- 私有字段用 `_` 前缀 + camelCase：`_contextUserService`
- 返回匿名对象或强类型 DTO（Furion UnifyResult 自动包装）

### 动态 API 路由

| HTTP | 路由模式 | 说明 |
|------|---------|------|
| POST | `/api/{entity}/page` | 分页查询 |
| POST | `/api/{entity}/list` | 全部列表 |
| GET | `/api/{entity}/get-by-id?id=` | 按 ID 查询 |
| POST | `/api/{entity}/create-or-update` | 创建/更新 |
| POST | `/api/{entity}/delete-by-id` | 软删除 |
| GET | `/api/{entity}/columns` | 表格列定义 |
| GET | `/api/{entity}/filters` | 过滤字段定义 |
| POST | `/api/{entity}/options` | 下拉选项 |

### 自定义 Service 路由

实现 `IDynamicApiController` 后，用 `[HttpPost("route-name")]` / `[HttpGet("route-name")]` 定义路由。

### DTO

- POCO 类，无统一基类
- 验证用 `[Required]`、`[MaxLength]` 等 DataAnnotations
- DTO 放在 `Services/{Module}/Dtos/` 子目录

### 注释（强制，禁止零注释）

- 类和接口 `/// <summary>说明用途</summary>`
- public 属性 `/// <summary>字段含义</summary>`
- public 方法 `/// <summary>方法用途</summary>`，参数加 `<param name="xxx">说明</param>`，返回值加 `<returns>说明</returns>`
- 方法内：算法/边界处理加 `//` 行注释
- **不使用 `#region`**（鸿冠极少使用）
- 注释使用中文

### 命名规范

| 类型 | 规则 | 示例 |
|------|------|------|
| 类/接口/方法 | PascalCase | `GetOrderList()` |
| 私有字段 | `_camelCase` | `_userService` |
| 局部变量/参数 | camelCase | `orderId` |
| 接口 | `I` 前缀 | `ICurdBase` |
| 实体类 | `Entity` 前缀 | `EntityWorkOrder` |
| 缩进 | Tab（4 列宽） | |
| 大括号 | Allman 风格（新行） | |

### HttpClient 注册与使用

在 `Startup.cs` 中注册命名客户端：
```csharp
services.AddHttpClient("FenluApi", client =>
{
    var baseUrl = App.Configuration["FenluApi:BaseUrl"] ?? "http://localhost:8088";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
});
```

在 Service 中使用：
```csharp
var client = _httpClientFactory.CreateClient("FenluApi");
var response = await client.PostAsync("/api/xxx", content);
```

### GlobalUsings

- Core 项目 `GlobalUsings.cs` 已包含 `Furion`、`Furion.DynamicApiController`、`Furion.DependencyInjection`、`SqlSugar`、`Mapster` 等
- Application 项目 `GlobalUsings.cs` 补充实体和 DTO 命名空间
- 新建文件时检查 GlobalUsings，避免重复 `using`

## API 规范

> 完整的 API 规范（请求/响应格式、分页、端点、错误处理、认证）已拆分到独立文件。
> **生成 API 契约时** → 读取 `D:\work\cc\.claude\commands\honguan-api-spec.md`

## 测试

### 环境

| 项目 | 值 |
|------|-----|
| API | `http://localhost:5000` |
| 账号 | `hongbin` / `123456` |

### 登录获取 Token

```bash
LOGIN=$(curl -s -k -X POST "http://localhost:5000/api/auth/login-by-username" \
  -H "Content-Type: application/json" \
  -d '{"userName":"hongbin","password":"123456","tenantId":"00000000-0000-0000-0000-000000000001"}')
TOKEN=$(echo "$LOGIN" | grep -o '"access-token":"[^"]*"' | sed 's/"access-token":"//;s/"//')
# 或从响应头获取
```

### 调用接口

```bash
curl -s -k -X POST "http://localhost:5000/api/{entity}/page" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pageNo":1,"pageSize":20}'
```

### 常见问题

| 现象 | 解决 |
|------|------|
| HTTP 401 | 重新 Login 获取 Token |
| HTTP 404 | 检查路由名（动态 API 路由为 `/api/xxx`） |
| 编译 Error | `dotnet build` 查看具体错误 |
| DLL 未生效 | 重启 `dotnet run` 或 `dotnet watch run` 自动检测 |

## 新建文件（强制）

每新建一个 `.cs` 文件，必须：
1. 在 `.csproj` 的 `<ItemGroup>` 中注册 `<Compile Include="相对路径\文件.cs" />`（按字母序）—— **仅当 .csproj 未启用隐式 Include 时需手动注册。检查 .csproj 的 `EnableDefaultCompileItems` 设置**
2. 添加到 SVN：`svn add "相对路径/文件"`（仅暂存，**不 svn commit**，交付时统一提交）

**遗漏后果**：不参与编译（运行时 TypeLoadException）或未纳入版本控制。

## 文件移动（强制）

移动/重命名文件时：
1. **使用 `svn mv oldPath newPath`**（禁止直接拷贝或文件系统 mv）
2. 若为 `.cs` 文件 → 同步更新 `.csproj` 中对应路径

## 文件删除（强制）

删除文件时：
1. **使用 `svn rm`**（禁止直接 rm 或 delete）
2. 若为 `.cs` 文件 → 从 `.csproj` 中移除对应 `<Compile Include>` 行

## 目录操作（强制）

创建目录：`svn mkdir` 或先创建再 `svn add`
删除目录：`svn rm`（自动递归删除目录内所有文件）

## SVN 错误操作修复

若已错误操作（SVN `!` 缺失 + `?` 未跟踪）：
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

**开发期间**：`svn up` → `svn st` → `svn add`（仅暂存）→ `dotnet build` 编译通过
**交付时**：`svn up` → `svn commit -m "说明"` 一次性入库（commit 前必须 update，避免代码覆盖）
**格式**：`<type>: <描述>`（如 `feat: 添加 HRM Token 桥接 API`、`fix: 修复菜单字段映射`）
**类型**：`feat` / `fix` / `refactor` / `docs` / `style` / `perf`
**禁止提交**：`bin/` `obj/` `.vs/` `node_modules/` `packages/` `.env` `*.log`
