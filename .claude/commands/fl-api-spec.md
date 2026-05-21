---
description: [分路] API 规范 — 请求/响应格式、分页、路由、错误处理、认证、契约示例
allowed-tools: []
---

# 分路系统 API 规范

> 以下规范来自分路系统实际代码分析，是生成 API 契约的依据。
> **适用角色**：Architect（生成契约时必读）、Reviewer（审查契约一致性时必读）。

## 请求统一包装（SaltRequest\<T\>）

所有 POST 请求 Body 由 `SaltRequest<T>` 包装，业务数据放在 `Data` 字段中：

```json
{
  "Data": {
    /* 实际业务 DTO */
  }
}
```

Controller 中通过 `input.Data` 获取业务对象：
```csharp
public OutDto Create([FromBody] SaltRequest<HRM_StaffInput> input)
{
    var dto = input.Data;  // ← 业务对象在这里
}
```

## 响应统一包装（SaltResponse\<T\>）

所有接口响应包装为：

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | bool | 业务是否成功 |
| `result` | object | 业务数据（成功时，可以是 T、PagedListOutput\<T\>、List\<T\>） |
| `error` | object | 错误信息（失败时），含 `code`、`message`、`details` |
| `unAuthorizedRequest` | bool | 是否认证失败 |

**成功响应（单条查询）：**
```json
{
  "success": true,
  "result": { "id": 1, "name": "张三", "staffCode": "S001" },
  "error": null,
  "unAuthorizedRequest": false
}
```

**成功响应（增删改 OutDto）：**
```json
{
  "success": true,
  "result": { "states": true, "id": 42, "tips": "保存成功" },
  "error": null,
  "unAuthorizedRequest": false
}
```

**失败响应：**
```json
{
  "success": false,
  "result": null,
  "error": { "code": -1, "message": "员工不存在", "details": null },
  "unAuthorizedRequest": false
}
```

## 错误响应格式

| error.code | 含义 |
|------------|------|
| `401` | Token 验证失败 |
| `-1` | 通用业务错误 |
| `0` | 无错误（成功时 error 为 null） |

- HTTP 状态码始终为 **200**（即使业务失败）
- 通过 `success` 字段判断成功/失败
- `error.message` 为面向用户的错误描述
- `error.details` 为调试详情（可选）

## 分页规范

**分页请求参数**（使用 `SkipCount` + `MaxResultCount`）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `SkipCount` | int | 否 | 跳过条数（从 0 开始） |
| `MaxResultCount` | int | 否 | 每页条数 |
| `CurrentPage` | int | 否 | 当前页码（少数接口使用） |
| `PageSize` | int | 否 | 每页条数（少数接口使用） |

**分页响应 `PagedListOutput<T>`**（注意字段全小写）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `count` | int | 当前页记录数 |
| `totalcount` | int | 总记录数 |
| `items` | T[] | 数据列表 |

```json
{
  "success": true,
  "result": {
    "count": 20,
    "totalcount": 156,
    "items": [ /* ... */ ]
  }
}
```

> ⚠️ **关键差异**：分路使用 `SkipCount`+`MaxResultCount`（ABP 风格），**不是** `pageNo`+`pageSize`。字段名全小写。

## 路由规范

```
http://localhost:8088/api/{Area}/{Controller}/{Action}/{id?}
```

| 组件 | 说明 | 示例 |
|------|------|------|
| Area | 模块区域（文件夹名） | `HRM`, `Common`, `FM` |
| Controller | 控制器名（不含 `Controller` 后缀） | `Staff`, `Account` |
| Action | 方法名 | `GetPageList`, `Save`, `DeletePost` |
| id | 可选 ID 参数 | `42` |

## HTTP 方法约定

| 操作 | HTTP | 说明 |
|------|------|------|
| 查询单个（按 ID） | GET | `GET /api/HRM/Staff/GetDetails?id=42` |
| 查询分页列表 | POST | `POST /api/HRM/Staff/GetPageList` + body |
| 查询全部列表 | POST | `POST /api/HRM/Staff/GetList` + body |
| 新增 | POST | `POST /api/HRM/Staff/Save` + `SaltRequest<T>` |
| 修改 | POST | `POST /api/HRM/Staff/Save` + `SaltRequest<T>`（区别：DTO 中 id > 0） |
| 删除 | POST | `POST /api/HRM/Staff/DeletePost` + body |
| 业务操作 | POST | `POST /api/HRM/Staff/SomeAction` + body |

> ⚠️ **关键差异**：分路除了按 ID 查询单项用 GET，其余**全部用 POST**（包括列表查询、删除、业务操作）。

## Action 命名约定

| 模式 | 说明 | 示例 |
|------|------|------|
| `Get{Entity}List` / `GetPageList` | 分页/列表查询 | `GetStaffList` |
| `Get{Entity}Details` / `GetDetails` | 按 ID 查详情 | `GetStaffDetails` |
| `Save` / `Create{Entity}` | 新增/修改 | `Save` |
| `DeletePost` | 删除 | `DeletePost` |
| `Import{Entity}` / `Export{Entity}` | 导入导出 | `ImportStaff` |
| `{动词}{名词}` | 业务操作 | `CheckIn`, `Approve` |

## OutDto（增删改返回）

| 字段 | 类型 | 说明 |
|------|------|------|
| `States` | bool | 操作是否成功 |
| `Id` | int | 新增/修改的记录 ID |
| `Tips` | string | 提示信息 |

泛型版本 `OutDto<T>` 额外含 `Data` 字段。

## DTO 命名约定

| 用途 | 命名模式 | 示例 |
|------|---------|------|
| 查询输出 | `{Module}_{Entity}Dto` | `HRM_StaffDto` |
| 输入/保存 | `{Module}_{Entity}Input` | `HRM_StaffInput` |
| 基础类 | `{Module}_CompanyEntityDto` | `HRM_CompanyEntityDto` |
| 基础输入 | `{Module}_BaseInput` | `HRM_BaseInput` |

- DTO 继承 `HRM_CompanyEntityDto`，重写 `CheckData()` 做验证
- `CompanyId` 在基类中自动处理
- 新增/修改时调用 `dto.CreateNew(userName, companyId)` / `dto.Update(userName)`

## 认证规范

| 项目 | 值 |
|------|-----|
| 方案 | JWT Bearer（自定义 `SaltAuthorize`） |
| 请求头 | `Authorization: Bearer <token>` |
| Token 获取 | `POST /api/Common/Account/Login` → `{Data: {Username, Password, Source}}` |
| Token 响应字段 | `result.token`（在 `SaltResponse.result` 中） |
| Token 刷新 | 请求头 `X-Authorization: <refreshToken>` |
| 业务 Headers | `companyId`、`taskId`、`activityId`、`workflowId`、`processId`、`timestamp` |

**登录请求示例：**
```json
{
  "Data": {
    "Username": "hongbin",
    "Password": "123456",
    "Source": null
  }
}
```

## 契约示例

```markdown
### 2.x 查询员工分页列表

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/HRM/Staff/GetPageList |
| 说明 | 分页查询员工列表 |
| 认证 | Bearer Token |
| 执行者 | Developer |

#### 请求

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Data.SkipCount | int | 否 | 跳过条数（默认 0） |
| Data.MaxResultCount | int | 否 | 每页条数（默认 20） |
| Data.Keyword | string | 否 | 关键词搜索 |

\`\`\`json
{ "Data": { "SkipCount": 0, "MaxResultCount": 20, "Keyword": "" } }
\`\`\`

#### 响应 — 成功

| 字段 | 类型 | 说明 |
|------|------|------|
| result.count | int | 当前页记录数 |
| result.totalcount | int | 总记录数 |
| result.items | array | 员工列表 |

\`\`\`json
{
  "success": true,
  "result": {
    "count": 20, "totalcount": 156,
    "items": [ { "Id": 1, "StaffCode": "S001", "StaffName": "张三" } ]
  }
}
\`\`\`

#### 响应 — 错误

\`\`\`json
{ "success": false, "result": null, "error": { "code": 401, "message": "Token 验证失败" } }
\`\`\`

#### Mock 数据（Developer1 用）

\`\`\`javascript
var mockData = {
  success: true,
  result: { count: 20, totalcount: 156,
    items: [ { Id: 1, StaffCode: "S001", StaffName: "张三" } ] }
};
\`\`\`
```
