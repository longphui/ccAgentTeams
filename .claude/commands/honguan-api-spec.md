---
description: [鸿冠ERP] API 规范 — 请求/响应格式、分页、端点、错误处理、认证、契约示例
allowed-tools: []
---

# 鸿冠ERP API 规范

> 以下规范来自鸿冠ERP实际代码分析，是生成 API 契约的依据。
> **适用角色**：Architect（生成契约时必读）、Reviewer（审查契约一致性时必读）。

## 响应统一包装（Furion UnifyResult）

所有接口响应由 Furion `UnifyResult` 自动统一包装为：

| 字段 | 类型 | 说明 |
|------|------|------|
| `succeeded` | bool | 业务是否成功 |
| `data` | object/null | 业务数据（成功时） |
| `errors` | string/object | 错误信息（失败时） |
| `extras` | object | 扩展字段（`UnifyContext.Fill` 填充） |
| `statusCode` | int | HTTP 状态码 |
| `timestamp` | long | Unix 毫秒时间戳 |

**成功响应示例：**
```json
{
  "succeeded": true,
  "data": { "id": 1, "name": "xxx" },
  "errors": null,
  "extras": null,
  "statusCode": 200,
  "timestamp": 1689600000000
}
```

**失败响应示例：**
```json
{
  "succeeded": false,
  "data": null,
  "errors": "参数不能为空",
  "extras": null,
  "statusCode": 400,
  "timestamp": 1689600000000
}
```

## 分页规范

分页请求参数：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `pageNo` | int | 否 | 页码（默认 1） |
| `pageSize` | int | 否 | 每页条数（默认 20） |
| `keyword` | string | 否 | 关键词搜索（通用） |

分页响应 `PagedList<T>` — 包装在 `data` 中：

| 字段 | 类型 | 说明 |
|------|------|------|
| `pageIndex` | int | 当前页码 |
| `pageSize` | int | 每页条数 |
| `totalCount` | int | 总记录数 |
| `totalPages` | int | 总页数 |
| `items` | T[] | 数据列表 |
| `hasPreviousPage` | bool | 是否有上一页 |
| `hasNextPage` | bool | 是否有下一页 |

**分页响应示例：**
```json
{
  "succeeded": true,
  "data": {
    "pageIndex": 1,
    "pageSize": 20,
    "totalCount": 156,
    "totalPages": 8,
    "items": [ /* ... */ ],
    "hasPreviousPage": false,
    "hasNextPage": true
  }
}
```

## CRUD 端点规范（CurdBase\<T\>）

继承 `CurdBase<T>` 的 Service 自动获得以下端点：

| HTTP | 路由 | 说明 | 入参 |
|------|------|------|------|
| POST | `/api/{entity}/page` | 分页查询 | `{pageNo, pageSize, keyword, ...filter}` |
| POST | `/api/{entity}/list` | 全部列表 | `{keyword, ...filter}` |
| GET | `/api/{entity}/get-by-id` | 按 ID 查询 | `?id=1` |
| GET | `/api/{entity}/get-by-code` | 按编码查询 | `?code=xxx` |
| POST | `/api/{entity}/create-or-update` | 创建/更新 | `{id: 0 或 >0, ...fields}` |
| POST | `/api/{entity}/delete-by-id` | 软删除 | `{id: 1}` |
| GET | `/api/{entity}/columns` | 表格列定义 | 无 |
| GET | `/api/{entity}/filters` | 过滤字段 | 无 |
| GET | `/api/{entity}/fields` | 表单字段 | 无 |
| POST | `/api/{entity}/options` | 下拉选项 | `{keyword}` |

## 自定义端点规范

实现 `IDynamicApiController` + `[ApiDescriptionSettings(Groups = new string[] { "Infra" })]`：

- 路由由方法名自动生成：`/api/{class-name-minus-service}/{method-name}`（kebab-case）
- 手动指定：`[HttpPost("custom-route")]` 或 `[HttpGet("custom-route")]`
- 所有 POST 端点用 `[FromBody]` 接收 JSON body
- 所有 GET 端点用 `[FromQuery]` 接收查询参数
- 返回类型可以是强类型 DTO、匿名对象、`PagedList<T>`、`Task<T>` — Furion 自动包装

## 错误处理

- 业务错误抛出：`Oops.Oh("错误消息")` → Furion 自动包装为 `{succeeded: false, errors: "错误消息"}`
- 验证错误：DataAnnotations 验证失败自动返回 400 + errors 详情
- 权限错误：JWT 中间件返回 401
- 永远不要手动构造 `{succeeded: false}` 响应 — 统一用 `Oops.Oh()`

## 认证规范

| 项目 | 值 |
|------|-----|
| 方案 | JWT Bearer |
| 请求头 | `Authorization: Bearer <token>` |
| Token 获取 | `POST /api/auth/login-by-username` → `{userName, password, tenantId}` |
| Token 在响应头 | `access-token: <token>` + `x-access-token: <token>`（Login 接口） |
| Token 刷新 | 请求头带 `X-Authorization: <token>`，响应头返回新 `access-token` |

## DTO 命名约定

| 用途 | 命名模式 | 示例 |
|------|---------|------|
| 分页查询输入 | `{Entity}Filter` | `WorkOrderFilter` |
| 创建/更新输入 | `{Entity}InputDto` | `WorkOrderInputDto` |
| 输出/展示 | `{Entity}Dto` | `WorkOrderDto` |
| 下拉选项 | 匿名对象 | `new { label, value }` |

DTO 放 `Services/{Module}/Dtos/` 子目录，POCO 类无统一基类，验证用 `[Required]`/`[MaxLength]` 等 DataAnnotations。

## 契约示例

```markdown
### 2.x 查询采购订单分页

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/work-order/page |
| 说明 | 分页查询采购订单 |
| 认证 | Bearer Token |
| 执行者 | Developer |

#### 请求

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| pageNo | int | 否 | 页码（默认 1） |
| pageSize | int | 否 | 每页条数（默认 20） |
| keyword | string | 否 | 关键词搜索 |
| status | string | 否 | 状态过滤 |

\`\`\`json
{ "pageNo": 1, "pageSize": 20, "keyword": "", "status": "" }
\`\`\`

#### 响应 — 成功

| 字段 | 类型 | 说明 |
|------|------|------|
| data.pageIndex | int | 当前页码 |
| data.pageSize | int | 每页条数 |
| data.totalCount | int | 总记录数 |
| data.items | array | 订单列表 |

\`\`\`json
{
  "succeeded": true,
  "data": {
    "pageIndex": 1, "pageSize": 20, "totalCount": 156, "totalPages": 8,
    "items": [ { "id": 1, "orderNo": "PO-001", "status": "待审核" } ],
    "hasPreviousPage": false, "hasNextPage": true
  }
}
\`\`\`

#### 响应 — 错误

\`\`\`json
{ "succeeded": false, "data": null, "errors": "权限不足" }
\`\`\`

#### Mock 数据（Developer1 用）

\`\`\`javascript
var mockData = {
  succeeded: true,
  data: { pageIndex: 1, pageSize: 20, totalCount: 156, totalPages: 8,
    items: [ { id: 1, orderNo: "PO-001", status: "待审核" } ],
    hasPreviousPage: false, hasNextPage: true }
};
\`\`\`
```
