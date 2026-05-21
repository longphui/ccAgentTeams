# 实施计划 #004: HRM 集成到天津宏观世纪ERP — 阶段 1

- **日期**: 2026-05-17
- **工期**: 4.5 天
- **分析文档**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\HRMFromFenluToHonguan.md`
- **需求文档**: `004-HRM集成到天津宏观世纪ERP-阶段1.md`

---

## 架构总览

```
天津宏观世纪浏览器 (localhost:5021)
  │
  ├─ 登录 → 天津宏观世纪 JWT (access-token / x-access-token 在响应头)
  │
  ├─ checkUser() → GET /api/context-user/current-user → userInfo
  │
  ├─ initMenu() → POST /api/menu-proxy/get-list-by-role (天津宏观世纪后端)
  │     └─ 天津宏观世纪后端 → POST 分路 /api/HRM/MenuRoute/GetListByRole
  │          └─ 字段映射: parentId→parent, HRM path→hrm-proxy path
  │          └─ 返回: { children: [...], startup: {...} }
  │
  ├─ 天津宏观世纪原生页面（采购/生产/产品等）
  │     └─ 直接加载 views/xxx/index.html
  │     └─ 按钮权限: appContext.route.checkTabPermissions(path, btn)
  │
  └─ HRM iframe 页面
        └─ /views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html
             ├─ postMessage({type: "HRM_GET_CONTEXT"}) → 父窗口
             ├─ 父窗口 app.js 监听 → POST /api/hrm-auth/get-fenlu-token
             ├─ 返回 HRM_CONTEXT → 写入 iframe localStorage
             └─ iframe 加载 分路页面?embedded=true
                  └─ Token 过期 → postMessage({type: "HRM_TOKEN_EXPIRED"})
```

---

## API 契约

> 以下契约按天津宏观世纪 `honguan-api-spec.md` 和分路 `fl-api-spec.md` 规范编写。
> **Developer 按契约实现接口，Developer1 用 Mock 数据独立开发前端。**

### 契约 A: Token 桥接 API（天津宏观世纪 → 分路）

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/hrm-auth/get-fenlu-token |
| 说明 | 天津宏观世纪后端用预设账号获取分路系统 JWT Token（带内存缓存） |
| 认证 | Bearer Token（天津宏观世纪 JWT） |
| 系统 | honguan |
| 执行者 | Developer |

#### 请求

无 body（服务端从 `appsettings.json` 的 `HrmConfig` 节读取账号密码）。

#### 响应 — 成功

| 字段 | 类型 | 说明 |
|------|------|------|
| succeeded | bool | true |
| data | object | Token 数据 |
| data.token | string | 分路 JWT Token |

```json
{
  "succeeded": true,
  "data": { "token": "eyJhbGciOiJIUzI1NiIs..." },
  "errors": null,
  "extras": null,
  "statusCode": 200,
  "timestamp": 1715900000000
}
```

> **注意**：Furion UnifyResult 自动包装。Service 返回 `HrmTokenDto` → 实际 HTTP 响应如上。

#### 响应 — 错误

```json
{
  "succeeded": false,
  "data": null,
  "errors": "分路登录失败: 用户名或密码错误",
  "extras": null,
  "statusCode": 500,
  "timestamp": 1715900000000
}
```

---

### 契约 B: 菜单代理 API（天津宏观世纪 → 分路）

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/menu-proxy/get-list-by-role |
| 说明 | 调用分路菜单 API 获取用户菜单树，转换 HRM 路径为 hrm-proxy 代理页路径 |
| 认证 | Bearer Token（天津宏观世纪 JWT） |
| 系统 | honguan |
| 执行者 | Developer |

#### 请求

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platformId | int | 是 | 平台 ID（天津宏观世纪 Web 端固定为 1） |

```json
{ "platformId": 1 }
```

#### 响应 — 成功

| 字段 | 类型 | 说明 |
|------|------|------|
| data.children | array | 菜单树（顶层节点列表） |
| data.children[].id | int | 菜单 ID |
| data.children[].title | string | 菜单标题（分配给角色时已指定名称） |
| data.children[].parent | int | 父菜单 ID（0 = 根节点） |
| data.children[].path | string | 页面路径（HRM→hrm-proxy 代理，其他→原样） |
| data.children[].icon | string | 图标名称（Font Awesome 4 或 icon- 前缀） |
| data.children[].children | array | 子菜单节点（递归） |
| data.children[].menuButtons | string[] | 按钮权限码 |
| data.startup | object | 默认首页 |
| data.startup.id | int | 菜单 ID |
| data.startup.parentId | int | 父菜单 ID |
| data.startup.title | string | 标题 |
| data.startup.path | string | 路由路径 |
| data.startup.name | string | 名称 |

```json
{
  "succeeded": true,
  "data": {
    "children": [
      {
        "id": 1001,
        "title": "人力资源",
        "parent": 0,
        "path": "",
        "icon": "fa fa-users",
        "children": [
          {
            "id": 1002,
            "title": "员工管理",
            "parent": 1001,
            "path": "/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html",
            "icon": "icon-people",
            "children": [],
            "menuButtons": ["search", "add", "edit", "delete"]
          }
        ],
        "menuButtons": []
      },
      {
        "id": 2001,
        "title": "采购管理",
        "parent": 0,
        "path": "views/purchase_management/index.html",
        "icon": "fa fa-shopping-cart",
        "children": [],
        "menuButtons": ["search", "add", "edit", "delete", "approve"]
      }
    ],
    "startup": { "id": 2001, "parentId": 0, "title": "采购管理", "path": "views/purchase_management/index.html", "name": "采购管理" }
  },
  "errors": null,
  "extras": null,
  "statusCode": 200,
  "timestamp": 1715900000000
}
```

> **注意**：天津宏观世纪前端 `Http.invoke` 自动解包 → `res.data` → 得到 `{children, startup}`。Task 5a 的代码 `let { children, startup } = data` 正确。

#### 响应 — 错误

```json
{
  "succeeded": false,
  "data": null,
  "errors": "分路菜单接口调用失败: Token 验证失败",
  "extras": null,
  "statusCode": 500,
  "timestamp": 1715900000000
}
```

#### Mock 数据（Developer1 用）

```javascript
// 复制到 app.js initMenu() 中使用，独立开发前端菜单功能，无需等待后端就绪
var mockMenuData = {
  succeeded: true,
  data: {
    children: [
      {
        id: 1001, title: "人力资源", parent: 0, path: "", icon: "fa fa-users",
        children: [
          { id: 1002, title: "员工管理", parent: 1001,
            path: "/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html",
            icon: "icon-people", children: [],
            menuButtons: ["search","add","edit","delete"] },
          { id: 1003, title: "考勤管理", parent: 1001,
            path: "/views/hrm-proxy/index.html?page=attendanceManagement/attendance/index.html",
            icon: "icon-calendar", children: [],
            menuButtons: ["search","add","edit","delete"] }
        ],
        menuButtons: []
      },
      {
        id: 2001, title: "采购管理", parent: 0,
        path: "views/purchase_management/index.html", icon: "fa fa-shopping-cart",
        children: [], menuButtons: ["search","add","edit","delete","approve"]
      }
    ],
    startup: { id: 2001, parentId: 0, title: "采购管理", path: "views/purchase_management/index.html", name: "采购管理" }
  }
};
```

---

### 契约 C: 分路登录 API（天津宏观世纪后端调用）

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/Common/Account/Login |
| 说明 | 天津宏观世纪 `HrmAuthService` 使用预设账号登录分路系统获取 Token |
| 认证 | 匿名 |
| 系统 | fl |
| 执行者 | Developer（天津宏观世纪后端调用，不需修改分路代码） |

#### 请求（SaltRequest 包装）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Data.Username | string | 是 | 用户名 |
| Data.Password | string | 是 | 密码 |
| Data.Source | null | 否 | 来源 |

```json
{
  "Data": {
    "Username": "hongbin",
    "Password": "123456",
    "Source": null
  }
}
```

#### 响应 — 成功（SaltResponse）

| 字段 | 类型 | 说明 |
|------|------|------|
| success | bool | true |
| result | object | 登录结果 |
| result.token | string | JWT Token |
| result.xToken | string | 刷新 Token |

```json
{
  "success": true,
  "result": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "xToken": "eyJhbGciOiJIUzI1NiIs...",
    "userId": 1,
    "userName": "hongbin"
  },
  "error": null,
  "unAuthorizedRequest": false
}
```

#### 响应 — 错误（SaltResponse）

```json
{
  "success": false,
  "result": null,
  "error": { "code": -1, "message": "用户名或密码错误", "details": null },
  "unAuthorizedRequest": false
}
```

---

### 契约 D: 分路菜单 API（天津宏观世纪后端调用）

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/HRM/MenuRoute/GetListByRole |
| 说明 | 根据平台 ID 获取用户角色对应的菜单树（分路 `AbpMenuRoute` 表） |
| 认证 | Bearer Token（分路 JWT，由契约 C 获取） |
| 系统 | fl |
| 执行者 | Developer（天津宏观世纪后端调用，不需修改分路代码） |

#### 请求

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platformId | int | 是 | 平台 ID |

```json
{ "platformId": 1 }
```

> ⚠️ **待 Developer 确认**：该端点是否需要 `{Data: {platformId: 1}}` SaltRequest 包装？计划代码直接传 `{platformId: 1}`。若端点使用 `[FromBody] SaltRequest<XxxInput>` 则需要 Data 包装，否则不需要。

#### 响应 — 成功（SaltResponse）

| 字段 | 类型 | 说明 |
|------|------|------|
| result.menuList | array | 用户有权限的菜单树 |
| result.menuList[].id | int | 菜单 ID |
| result.menuList[].title | string | 菜单标题 |
| result.menuList[].parentId | int | 父菜单 ID |
| result.menuList[].path | string | 原始路径（如 `/v2/views/manpowerManage/staffManagement/staffInfo/index.html`） |
| result.menuList[].icon | string | 图标 |
| result.menuList[].children | array | 子菜单 |
| result.menuList[].menuButtons | string[] | 按钮权限码 |
| result.startup | object | 默认首页 |

```json
{
  "success": true,
  "result": {
    "menuList": [
      {
        "id": 1001, "title": "人力资源", "parentId": 0, "path": "", "icon": "fa fa-users",
        "children": [
          { "id": 1002, "title": "员工管理", "parentId": 1001,
            "path": "/v2/views/manpowerManage/staffManagement/staffInfo/index.html",
            "icon": "icon-people", "children": [],
            "menuButtons": ["search","add","edit","delete"] }
        ],
        "menuButtons": []
      }
    ],
    "startup": { "id": 1002, "parentId": 1001, "title": "员工管理",
      "path": "/v2/views/manpowerManage/staffManagement/staffInfo/index.html", "name": "员工管理" }
  },
  "error": null,
  "unAuthorizedRequest": false
}
```

#### 响应 — 错误（SaltResponse）

```json
{
  "success": false,
  "result": null,
  "error": { "code": 401, "message": "Token 验证失败", "details": null },
  "unAuthorizedRequest": true
}
```

---

### 契约 E: postMessage 上下文协议（天津宏观世纪前端 ↔ hrm-proxy iframe）

| 属性 | 值 |
|------|-----|
| 通信方式 | `window.postMessage` |
| 作用 | 天津宏观世纪父窗口向 hrm-proxy 代理页注入分路认证上下文 |
| 系统 | honguan (前端) |
| 执行者 | Developer1 |

#### HRM_GET_CONTEXT（iframe → 父窗口）

```javascript
// hrm-proxy/index.html 加载后发送
window.parent.postMessage({ type: "HRM_GET_CONTEXT" }, "*");
```

#### HRM_CONTEXT（父窗口 → iframe）

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | "HRM_CONTEXT" |
| token | string | 分路 JWT Token（带 "Bearer " 前缀） |
| xToken | string | 同 token |
| userInfo | object | 当前用户信息 |
| companyId | int | 公司 ID |
| baseUrl1 | string | 分路 API 基地址 |

```javascript
// app.js message 监听器返回
e.source.postMessage({
  type: "HRM_CONTEXT",
  token: "Bearer eyJhbGci...",
  xToken: "Bearer eyJhbGci...",
  userInfo: { id: 1, name: "hongbin", companyId: 2026 },
  companyId: 2026,
  baseUrl1: "http://localhost:8088",
  baseUrl2: "http://localhost:8088",
  newFenluApiBase: "http://localhost:8088"
}, "*");
```

#### HRM_TOKEN_EXPIRED（iframe → 父窗口）

```javascript
// 分路 baseService.js: onTokenExpired() → postMessage
window.parent.postMessage({ type: "HRM_TOKEN_EXPIRED" }, "*");
// 父窗口收到后重新获取 token → 回传 HRM_CONTEXT → iframe 刷新页面
```

#### Mock（Developer1 独立开发用）

```javascript
// 在 hrm-proxy/index.html 中注释掉真实 postMessage，用以下 Mock：
(function mockContext() {
  var mockCtx = {
    type: "HRM_CONTEXT",
    token: "Bearer mock-token-for-dev",
    xToken: "Bearer mock-token-for-dev",
    userInfo: { id: 1, name: "hongbin", companyId: 2026 },
    companyId: 2026,
    baseUrl1: "http://localhost:8088"
  };
  setTimeout(function() {
    window.dispatchEvent(new MessageEvent("message", { data: mockCtx, origin: "*" }));
  }, 100);
})();
// 复制到 hrm-proxy/index.html 中替代 window.parent.postMessage 调用，
// 即可在浏览器直接打开代理页进行独立开发调试。
```

---

## 依赖关系

```
Task 1 (Token API)  ──┬── Task 7 (postMessage 监听)
                      └── Task 2 (菜单代理)
                                │
Task 3 (CORS 配置)               │
Task 4 (embedded=true)           │
                                │
                      Task 5a (getWebAppMenu 改造)
                      Task 5b (mainmenu 字段适配)
                      Task 5c (checkPermissions 移植)
                                │
                      Task 6 (hrm-proxy 代理页)
                      Task 7 (postMessage 监听)
                      Task 8 (initMenu startup 适配)
                                │
                      Task 9 (DB 菜单数据)
                                │
                      Task 10 (E2E 验证)
```

**Task 1-4 可并行执行。Task 5-8 依赖 Task 1-2。Task 9 依赖 Task 2。Task 10 依赖全部。**

---

## Task 1: 天津宏观世纪后端 — Token 桥接 API

**执行者**: Developer  
**估时**: 0.5 天  
**依赖**: 无

### 1.1 注册命名 HttpClient

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Web.Core\Startup.cs`

参照已有的 `IotApi` 注册方式（约第 65 行），在 `ConfigureServices` 中添加：

```csharp
// 注册分路 API HTTP 客户端
services.AddHttpClient("FenluApi", client =>
{
    var baseUrl = App.Configuration["FenluApi:BaseUrl"] ?? "http://localhost:8088";
    var timeoutSecondsStr = App.Configuration["FenluApi:TimeoutSeconds"];
    if (!int.TryParse(timeoutSecondsStr, out var timeoutSeconds) || timeoutSeconds <= 0)
        timeoutSeconds = 30;
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(timeoutSeconds);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
});
```

### 1.2 添加配置节

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Web.Entry\appsettings.json`

参照已有的 `IotApi` 节，添加：

```json
"FenluApi": {
    "BaseUrl": "http://localhost:8088",
    "TimeoutSeconds": 30
},
"HrmConfig": {
    "Username": "hongbin",
    "Password": "123456"
}
```

### 1.3 创建 HrmAuthService

**新建文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Application\Services\HrmProxy\HrmAuthService.cs`

```csharp
using System.Net.Http;
using System.Text;
using Furion.DynamicApiController;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace IChainStar.Infrastructure.Application.Services.HrmProxy
{
    /// <summary>
    /// HRM 认证桥接服务 — 用预设账号获取分路系统 Token
    /// </summary>
    [ApiDescriptionSettings(Groups = new string[] { "Infra" })]
    public class HrmAuthService : IDynamicApiController
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private string _cachedToken;
        private DateTime _tokenExpiresAt = DateTime.MinValue;

        public HrmAuthService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        /// <summary>
        /// 获取分路系统 JWT Token（带缓存，过期前 5 分钟自动刷新）
        /// </summary>
        [HttpPost("get-fenlu-token")]
        public async Task<HrmTokenDto> GetFenluTokenAsync()
        {
            // 缓存有效则直接返回
            if (!string.IsNullOrEmpty(_cachedToken) && DateTime.Now < _tokenExpiresAt.AddMinutes(-5))
            {
                return new HrmTokenDto { Token = _cachedToken };
            }

            var username = _configuration["HrmConfig:Username"] ?? "hongbin";
            var password = _configuration["HrmConfig:Password"] ?? "123456";

            var client = _httpClientFactory.CreateClient("FenluApi");
            var requestBody = JsonConvert.SerializeObject(new
            {
                Data = new
                {
                    Username = username,
                    Password = password,
                    Source = (string)null
                }
            });

            var response = await client.PostAsync(
                "/api/Common/Account/Login",
                new StringContent(requestBody, Encoding.UTF8, "application/json"));

            response.EnsureSuccessStatusCode();
            var responseBody = await response.Content.ReadAsStringAsync();
            var jObject = JObject.Parse(responseBody);

            // 分路响应: { success: true, result: { token: "xxx", xToken: "xxx" } }
            if (jObject["success"]?.Value<bool>() == true)
            {
                _cachedToken = jObject["result"]["token"].ToString();
                _tokenExpiresAt = DateTime.Now.AddHours(2); // 假设分路 Token 有效期 2 小时
                return new HrmTokenDto { Token = _cachedToken };
            }

            throw new InvalidOperationException($"分路登录失败: {jObject["error"]?["message"]?.ToString() ?? "未知错误"}");
        }
    }

    /// <summary>
    /// HRM Token 返回 DTO
    /// </summary>
    public class HrmTokenDto
    {
        /// <summary>
        /// 分路 JWT Token
        /// </summary>
        public string Token { get; set; }
    }
}
```

**注意**: 需要确认 `IChainStar.Infrastructure.Application` 的 GlobalUsings 是否已包含 `Newtonsoft.Json` 和 `Newtonsoft.Json.Linq`。如没有，在文件头部手动 `using`。

### 1.4 验证

```bash
curl -X POST http://localhost:5000/api/hrm-auth/get-fenlu-token
# 预期（Furion UnifyResult 包装）: {"succeeded":true,"data":{"token":"eyJ..."},"errors":null,"statusCode":200}
```

---

## Task 2: 天津宏观世纪后端 — 菜单代理 API

**执行者**: Developer  
**估时**: 0.5 天  
**依赖**: Task 1（共用 HrmAuthService 获取分路 Token）

### 2.1 创建 MenuProxyService

**新建文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Application\Services\HrmProxy\MenuProxyService.cs`

```csharp
using System.Net.Http;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace IChainStar.Infrastructure.Application.Services.HrmProxy
{
    /// <summary>
    /// 菜单代理服务 — 转发分路菜单 API 并做字段映射
    /// </summary>
    [ApiDescriptionSettings(Groups = new string[] { "Infra" })]
    public class MenuProxyService : IDynamicApiController
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly HrmAuthService _hrmAuthService;

        public MenuProxyService(IHttpClientFactory httpClientFactory, HrmAuthService hrmAuthService)
        {
            _httpClientFactory = httpClientFactory;
            _hrmAuthService = hrmAuthService;
        }

        /// <summary>
        /// 获取合并后的菜单树（含天津宏观世纪模块和 HRM 模块）
        /// </summary>
        [HttpPost("get-list-by-role")]
        public async Task<object> GetListByRoleAsync([FromBody] MenuRequestDto request)
        {
            // 获取分路 Token
            var tokenDto = await _hrmAuthService.GetFenluTokenAsync();
            var fenluToken = "Bearer " + tokenDto.Token;

            // 调用分路菜单 API
            var client = _httpClientFactory.CreateClient("FenluApi");
            var requestBody = JsonConvert.SerializeObject(new
            {
                platformId = request.PlatformId
            });

            var httpRequest = new HttpRequestMessage(HttpMethod.Post,
                "/api/HRM/MenuRoute/GetListByRole")
            {
                Content = new StringContent(requestBody, Encoding.UTF8, "application/json")
            };
            httpRequest.Headers.Add("Authorization", fenluToken);

            var response = await client.SendAsync(httpRequest);
            response.EnsureSuccessStatusCode();
            var responseBody = await response.Content.ReadAsStringAsync();
            var jObject = JObject.Parse(responseBody);

            // 分路菜单响应: { success: true, result: { menuList: [...], startup: {...} } }
            var menuList = jObject["result"]["menuList"] as JArray;
            var startup = jObject["result"]["startup"];

            // 字段映射：遍历菜单树
            var transformedMenuList = TransformMenuNodes(menuList);

            return new
            {
                children = transformedMenuList,
                startup = TransformStartup(startup)
            };
        }

        /// <summary>
        /// 递归转换菜单节点：parentId → parent，HRM path → hrm-proxy path
        /// </summary>
        private JArray TransformMenuNodes(JArray nodes)
        {
            if (nodes == null) return new JArray();

            var result = new JArray();
            foreach (var node in nodes)
            {
                var item = new JObject();

                // id / title / icon 不变
                item["id"] = node["id"];
                item["title"] = node["title"];
                item["icon"] = node["icon"];

                // parentId → parent（天津宏观世纪前端组件使用 parent 字段）
                item["parent"] = node["parentId"] ?? 0;

                // path 映射：HRM 模块指向 hrm-proxy，非 HRM 模块保持原样
                var originalPath = node["path"]?.ToString() ?? "";
                if (originalPath.Contains("/v2/views/manpowerManage/"))
                {
                    // HRM 页面 → hrm-proxy 代理页
                    // 去掉 /v2/views/manpowerManage/ 前缀，得到相对路径
                    var relativePath = originalPath.Replace("/v2/views/manpowerManage/", "");
                    item["path"] = "/views/hrm-proxy/index.html?page=" + relativePath;
                }
                else
                {
                    // 天津宏观世纪原生页面，路径不变
                    item["path"] = originalPath;
                }

                // 保留按钮权限
                item["menuButtons"] = node["menuButtons"] is JArray buttons
                    ? buttons
                    : new JArray();

                // 递归处理子节点
                if (node["children"] is JArray children && children.Count > 0)
                {
                    item["children"] = TransformMenuNodes(children);
                }

                result.Add(item);
            }
            return result;
        }

        /// <summary>
        /// 转换 startup 对象
        /// </summary>
        private JObject TransformStartup(JToken startup)
        {
            if (startup == null) return null;

            var result = new JObject();
            result["id"] = startup["id"];
            result["parentId"] = startup["parentId"];

            // HRM 的 startup path 也需要映射
            var originalPath = startup["path"]?.ToString() ?? "";
            if (originalPath.Contains("/v2/views/manpowerManage/"))
            {
                var relativePath = originalPath.Replace("/v2/views/manpowerManage/", "");
                result["path"] = "/views/hrm-proxy/index.html?page=" + relativePath;
            }
            else
            {
                result["path"] = originalPath;
            }

            // startup 的 name 字段 → title（适配天津宏观世纪 app.js initMenu）
            result["title"] = startup["title"] ?? startup["name"];
            result["name"] = startup["name"] ?? startup["title"];

            return result;
        }
    }

    /// <summary>
    /// 菜单请求 DTO
    /// </summary>
    public class MenuRequestDto
    {
        /// <summary>
        /// 平台 ID
        /// </summary>
        public int PlatformId { get; set; }
    }
}
```

### 2.2 注册 MenuProxyService 为 DI 服务

在 `HrmAuthService` 中加 `ITransient` 接口使其可被注入（或 Furion 自动扫描注册）。如果 `IDynamicApiController` 不自动注册 DI，需要让 `HrmAuthService` 实现一个标记接口或在 `MenuProxyService` 中通过属性注入。

**确认**: Furion 的 `IDynamicApiController` 实现类自动注册为 Transient，无需额外配置。

### 2.3 验证

```bash
curl -X POST http://localhost:5000/api/menu-proxy/get-list-by-role \
  -H "Content-Type: application/json" \
  -d '{"platformId":1}'
# 预期（Furion UnifyResult 包装）: {"succeeded":true,"data":{"children":[...],"startup":{...}},"errors":null}
# 检查: data.children 中 HRM 模块的 path 应包含 /views/hrm-proxy/index.html?page=
# 检查: 每个节点有 parent 字段（不是 parentId）
# 检查: 每个节点有 menuButtons 数组
```

---

## Task 3: 分路后端 — CORS 配置

**执行者**: Developer  
**估时**: 0.25 天  
**依赖**: 无

### 3.1 方案

在分路 IIS 中配置 CORS 响应头，允许天津宏观世纪前端 (localhost:5021) 跨域访问分路 API (localhost:8088)。

**文件**: 分路项目 `Web.config`（`D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\Web.config`）

在 `<system.webServer>` 节中添加：

```xml
<httpProtocol>
  <customHeaders>
    <add name="Access-Control-Allow-Origin" value="http://localhost:5021" />
    <add name="Access-Control-Allow-Headers" value="Content-Type,Authorization,X-Authorization" />
    <add name="Access-Control-Allow-Methods" value="GET,POST,PUT,DELETE,OPTIONS" />
    <add name="Access-Control-Allow-Credentials" value="true" />
  </customHeaders>
</httpProtocol>
```

如果分路已有 `Web.config`，注意不要重复 `<httpProtocol>` 节。

### 3.2 处理 OPTIONS 预检

IIS 默认不处理 OPTIONS 请求。在 `Global.asax` 的 `Application_BeginRequest` 中添加：

```csharp
protected void Application_BeginRequest()
{
    if (HttpContext.Current.Request.HttpMethod == "OPTIONS")
    {
        HttpContext.Current.Response.StatusCode = 200;
        HttpContext.Current.Response.End();
        return;
    }
}
```

### 3.3 验证

浏览器 DevTools Network 面板 → 访问天津宏观世纪前端 → 操作 HRM 页面 → 确认分路 API 请求无 CORS 报错。

---

## Task 4: 分路前端 — `?embedded=true` Token 过期防控

**执行者**: Developer1  
**估时**: 0.25 天  
**依赖**: 无  
**文件**: `D:\work\cc\caikuangzi.fenluwebproject\trunk\Web\Web\v2\baseService.js`

### 4.1 需求

当 HRM 页面在 iframe 中运行时（URL 带 `?embedded=true`），Token 失效发 `postMessage` 而非跳转登录页。

### 4.2 实施步骤

**Step 1** — 在文件顶部（`const Http = {` 之前）添加：

```javascript
// ===== 嵌入模式检测（iframe 内运行时使用） =====
var isEmbedded = (function() {
    var m = location.search.match(/[?&]embedded=true/);
    return !!m;
})();

function onTokenExpired() {
    if (isEmbedded) {
        // 嵌入模式：通知父窗口重新认证，不跳转
        window.parent.postMessage({ type: "HRM_TOKEN_EXPIRED" }, "*");
        return;
    }
    // 非嵌入模式：原有跳转逻辑
    getRootWindow().location.href = "/login.html";
}
```

**Step 2** — 找到启动时 Token 检查（约第 435 行）：

```javascript
// 原来:
if (localStorage.getItem("token") == null || localStorage.getItem("token") == undefined) {
    getRootWindow().location.href = "/login.html";
}

// 改为:
if (localStorage.getItem("token") == null || localStorage.getItem("token") == undefined) {
    onTokenExpired();
}
```

**Step 3** — 替换 `Http.errorHandler` 中的 401 跳转。找到：

```javascript
if (res.error && res.error.code == "401") {
    this.layer.msg("对不起，您没有该系统的访问权限，或token过期，请重登录",
        { icon: 2, time: 2000 }, (id) => {
            getRootWindow().location.href = "/login.html";
        });
}
```

改为：

```javascript
if (res.error && res.error.code == "401") {
    this.layer.msg("对不起，您没有该系统的访问权限，或token过期，请重登录",
        { icon: 2, time: 2000 }, (id) => {
            onTokenExpired();
        });
}
```

**Step 4** — 替换 `Http.errorHandler` 中 `case 401` 的跳转：

```javascript
// 原来:
case 401:
    getRootWindow().location.href = "/login.html";
    break;

// 改为:
case 401:
    onTokenExpired();
    break;
```

**Step 5** — 同理替换 `HttpE` 和 `Http2` 的 errorHandler 中的 401 跳转（共 2-3 处）。

### 4.3 验证

1. 非嵌入模式（URL 不带 `?embedded=true`）：Token 失效 → 正常跳转登录页 ✅
2. 嵌入模式（URL 带 `?embedded=true`）：
   - 手动执行 `localStorage.removeItem("token")` 后刷新 → 不发跳转 ✅
   - 在 DevTools Console 看到 `postMessage({type: "HRM_TOKEN_EXPIRED"})` ✅

---

## Task 5a: 天津宏观世纪前端 — getWebAppMenu 改调菜单代理

**执行者**: Developer1  
**估时**: 0.25 天  
**依赖**: Task 2（菜单代理 API 就绪）

### 5a.1 改动内容

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\js\baseService.js`

找到 `getWebAppMenu` 函数，当前实现：

```javascript
async getWebAppMenu() {
    return Http.get("menu.json", {
        platformId: window.PlatformId,
    }).then((data) => {
        console.log(data);
        let { children, startup } = data;
        let menu = {
            id: "0",
            title: "Web端",
            parentId: "0",
            children,
            startup,
        };
        return menu;
    });
},
```

改为：

```javascript
async getWebAppMenu() {
    return Http.invoke("/api/menu-proxy/get-list-by-role", "POST", {
        platformId: window.PlatformId,
    }).then((data) => {
        console.log(data);
        let { children, startup } = data;
        let menu = {
            id: "0",
            title: "Web端",
            parentId: "0",
            children,
            startup,
        };
        return menu;
    }).catch(function(err) {
        // 降级：菜单代理失败时回退到静态 menu.json
        console.warn("动态菜单加载失败，回退到静态 menu.json", err);
        return Http.get("menu.json", {
            platformId: window.PlatformId,
        }).then((data) => {
            let { children, startup } = data;
            return {
                id: "0", title: "Web端", parentId: "0",
                children, startup,
            };
        });
    });
},
```

**关键**: `Http.invoke` 用 POST 方法调用。天津宏观世纪的 `Http.invoke` 处理 `response.ok` → `res.succeeded` → 返回 `res.data`。菜单代理 API 直接返回 `{children, startup}`，符合预期。

**注意**: 天津宏观世纪 `Http.invoke` 返回的是 `res.data` 而非 `res`。如果菜单代理返回的顶层对象就是 `{children, startup}`，那 `data` 即为该对象。保持原有 `let { children, startup } = data` 解构方式。

### 5a.2 验证

刷新天津宏观世纪首页，控制台应输出菜单数据（来自 API），菜单树正常渲染。

---

## Task 5b: 天津宏观世纪前端 — mainmenu 字段适配

**执行者**: Developer1  
**估时**: 0.25 天  
**依赖**: Task 5a

### 5b.1 检查 parent 字段

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\libs\mainmenu\index.js`

天津宏观世纪 mainmenu 组件使用 `children` 数组嵌套渲染，不依赖 `parent` / `parentId` 字段来构建树——树结构已经在数据中了。组件只需要 `item.id`、`item.title`、`item.icon`、`item.path`、`item.children`。

**结论**: mainmenu 字段适配可能不需要改动。Task 2 的字段映射已经保证了 `children` 嵌套结构正确。

**但需验证**: 菜单组件 `openMenu` 方法使用 `menu.id`、`menu.path`、`menu.title` 来创建路由。确认 `menuButtons` 不影响菜单渲染（预期：不影响，LayuiVue `<lay-menu>` 不识别此字段）。

### 5b.2 图标适配

菜单代理返回的图标名可能是分路风格（如 `icon-people`）。验证天津宏观世纪 mainmenu 的图标处理：

```javascript
<icon :name="Lv1.icon?.replace('fa fa-','')" family="fa4"></icon>
```

如果图标不显示，在 MenuProxyService 中添加图标名映射表（如 `icon-people` → `fa fa-users`），或在前端做转换。

### 5b.3 验证

菜单展开/选中正常，图标正常显示，无 JS 报错。

---

## Task 5c: 天津宏观世纪前端 — appContext 移植 checkPermissions

**执行者**: Developer1  
**估时**: 0.5 天  
**依赖**: Task 5a（菜单数据就绪后权限检查才有意义）

### 5c.1 改动内容

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\js\appContext.js`

在 `route` 对象（约第 289 行附近）的现有方法后面，添加两个方法。

当前天津宏观世纪 `route` 对象：
```javascript
route: {
    appContext,
    maxRoutes: 20,
    currentRoute: null,
    items: [],
    openRoute(route) { ... },
    addRoute(route) { ... },
    setCurrentRoute(id) { ... },
    removeRoute(id) { ... },
    removeCurrentRoute() { ... },
},
```

在 `removeCurrentRoute` 之后（`},` 之前）添加：

```javascript
// ===== 按钮权限检查（从分路 appContext.js 移植） =====

// 基于当前路由 ID 检查按钮权限
checkPermissions(btn) {
    var index = this.items.findIndex(function(item) {
        return item.id === this.currentRoute;
    }.bind(this));
    if (index >= 0) {
        if (this.items[index].menuButtons && this.items[index].menuButtons.length > 0) {
            return this.items[index].menuButtons.indexOf(btn) >= 0;
        }
    }
    return false;
},

// 基于 path 递归遍历菜单树检查按钮权限
checkTabPermissions(path, btn) {
    if (path) {
        var checkTabPermissionsFromSubMenu = function(menus, path, btn) {
            for (var i = 0; i < menus.length; i++) {
                if (menus[i].path === path) {
                    if (menus[i].menuButtons && menus[i].menuButtons.length > 0) {
                        if (menus[i].menuButtons.indexOf(btn) >= 0) {
                            return true;
                        }
                    }
                }
                if (menus[i].children && menus[i].children.length > 0) {
                    var result = checkTabPermissionsFromSubMenu(menus[i].children, path, btn);
                    if (result) {
                        return true;
                    }
                }
            }
            return false;
        };
        return checkTabPermissionsFromSubMenu(this.appContext.menu.items, path, btn);
    } else {
        // path 为空时检查当前路由
        var index = this.items.findIndex(function(item) {
            return item.id === this.currentRoute;
        }.bind(this));
        if (index >= 0) {
            if (this.items[index].menuButtons && this.items[index].menuButtons.length > 0) {
                return this.items[index].menuButtons.indexOf(btn) >= 0;
            }
        }
        return false;
    }
},
```

**同时需要更新路由添加时保留 menuButtons**。找到 `addRoute` 方法中路由对象的构造部分，确保：

```javascript
addRoute(route) {
    // ...
    var newRoute = {
        id: route.id ?? Date.now() + Math.random(),
        name: route.name || route.title,
        path: route.path,
        menuButtons: route.menuButtons || [], // 保留按钮权限
        loading: true,
        // ...
    };
    // ...
}
```

即需要在 `addRoute` 中把传入 `route` 的 `menuButtons` 存到路由项上。

再看 mainmenu 的 `openMenu` 方法：

```javascript
openMenu(menu) {
    if (menu.id && this.appContext.route.items.findIndex(function(x) { return x.id == menu.id; }) > -1) {
        this.appContext.route.setCurrentRoute(menu.id);
    } else {
        var route = this.appContext.route.addRoute({
            id: menu.id,
            path: menu.path,
            name: menu.title,
        });
        route && this.appContext.route.setCurrentRoute(route.id);
    }
},
```

需要在 `addRoute` 调用时传入 `menuButtons`：

```javascript
var route = this.appContext.route.addRoute({
    id: menu.id,
    path: menu.path,
    name: menu.title,
    menuButtons: menu.menuButtons || [],
});
```

### 5c.2 暴露到全局

由于分路页面使用 `window.checkTabPermissions`（部分页面通过 `appContext.route.checkTabPermissions`），确认天津宏观世纪已有的全局暴露。在 `appContext.js` 末尾或 `app.js` 中添加：

```javascript
window.checkTabPermissions = function(path, btn) {
    return appContext.route.checkTabPermissions(path, btn);
};
```

### 5c.3 验证

```javascript
// 在浏览器 Console 执行：
appContext.route.checkTabPermissions("views/product_management/index.html", "add");
// 预期: true 或 false（取决于菜单数据中该 path 的 menuButtons）
```

---

## Task 6: 天津宏观世纪前端 — hrm-proxy 代理页面

**执行者**: Developer1  
**估时**: 0.5 天  
**依赖**: 无（可独立开发，用 mock postMessage 测试）

### 6.1 新建文件

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\views\hrm-proxy\index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>HRM 页面加载中...</title>
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        iframe { width: 100%; height: 100vh; border: none; }
        .loading { display: flex; align-items: center; justify-content: center;
                   height: 100vh; color: #666; font-size: 14px; }
        .error { display: flex; align-items: center; justify-content: center;
                 height: 100vh; color: #ff5722; font-size: 14px; flex-direction: column; }
    </style>
</head>
<body>
<div id="loadingMsg" class="loading">HRM 页面加载中...</div>
<iframe id="hrmFrame" style="display:none;"></iframe>

<script>
(function() {
    // 解析 URL 参数
    var params = new URLSearchParams(window.location.search);
    var targetPage = params.get("page");     // 如 staffManagement/staffInfo/index.html
    var stateKey = params.get("stateKey");   // 表单编辑时的数据主键

    if (!targetPage) {
        document.getElementById("loadingMsg").className = "error";
        document.getElementById("loadingMsg").innerHTML =
            "<p>缺少 page 参数</p><p style='font-size:12px;color:#999;'>示例: ?page=staffManagement/staffInfo/index.html</p>";
        return;
    }

    var hrmToken = null;
    var hrmBaseUrl = "http://localhost:8088";

    // 请求父窗口注入上下文
    window.parent.postMessage({ type: "HRM_GET_CONTEXT" }, "*");

    // 接收上下文
    window.addEventListener("message", function handler(e) {
        if (e.data?.type !== "HRM_CONTEXT") return;
        window.removeEventListener("message", handler);

        hrmToken = e.data.token;
        hrmBaseUrl = e.data.baseUrl1 || hrmBaseUrl;

        loadHrmPage();
    });

    function loadHrmPage() {
        var frame = document.getElementById("hrmFrame");

        // 构建 HRM 页面 URL
        var targetUrl = hrmBaseUrl + "/v2/views/manpowerManage/"
                      + targetPage;
        var sep = targetUrl.indexOf("?") >= 0 ? "&" : "?";
        targetUrl += sep + "embedded=true";
        if (stateKey) {
            targetUrl += "&stateKey=" + encodeURIComponent(stateKey);
        }

        // 先尝试写入 localStorage（同源情况下可用）
        // 跨域时此操作会失败，依赖分路自己从 URL/header 获取 token
        try {
            frame.contentWindow.localStorage.setItem("token", hrmToken);
            frame.contentWindow.localStorage.setItem("xToken", hrmToken);
        } catch (e) {
            // 跨域时不可写，忽略（分路页面自己从 URL 参数读取）
            targetUrl += "&hrmToken=" + encodeURIComponent(hrmToken);
        }

        frame.src = targetUrl;
        frame.style.display = "";
        document.getElementById("loadingMsg").style.display = "none";
    }

    // 监听 Token 过期
    window.addEventListener("message", function(e) {
        if (e.data?.type === "HRM_TOKEN_EXPIRED") {
            hrmToken = null;
            // 重新获取 Token
            window.parent.postMessage({ type: "HRM_GET_CONTEXT" }, "*");
            window.addEventListener("message", function refreshHandler(ev) {
                if (ev.data?.type !== "HRM_CONTEXT") return;
                window.removeEventListener("message", refreshHandler);
                hrmToken = ev.data.token;
                loadHrmPage();
            });
        }
    });

    // 超时处理（5 秒没响应）
    setTimeout(function() {
        if (!hrmToken) {
            document.getElementById("loadingMsg").className = "error";
            document.getElementById("loadingMsg").innerHTML =
                "<p>HRM 认证超时，请刷新重试</p>" +
                "<p style='font-size:12px;color:#999;'>如果问题持续，请联系管理员</p>";
        }
    }, 5000);
})();
</script>
</body>
</html>
```

### 6.2 验证

直接访问 `http://localhost:5021/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html`
→ 预期：先显示"加载中"，父窗口返回上下文后 iframe 加载 HRM 页面

### 6.3 Mock 独立开发

独立开发时，用 Mock 注入替代父窗口 postMessage（详见 [契约 E Mock](#契约-e-postmessage-上下文协议天津宏观世纪前端--hrm-proxy-iframe)）。
在 `hrm-proxy/index.html` 中，将 `window.parent.postMessage(...)` 替换为 `mockContext()` 即可在浏览器直接打开代理页调试。

---

## Task 7: 天津宏观世纪前端 — app.js postMessage 监听

**执行者**: Developer1  
**估时**: 0.25 天  
**依赖**: Task 1（Token 桥接 API） + Task 6

### 7.1 改动内容

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\js\app.js`

在 `mounted()` 或 `created()` 末尾添加全局 message 监听。位置建议在 `mounted() {}` 的 `},` 之前，或紧接在 `app.mount('#app')` 之前。

```javascript
// ===== HRM iframe 上下文桥接 =====
window.addEventListener("message", async function(e) {
    if (e.data?.type === "HRM_GET_CONTEXT") {
        try {
            // 从后端获取分路 Token
            var hrmResp = await Http.invoke("/api/hrm-auth/get-fenlu-token", "POST");
            var hrmToken = hrmResp.token;

            // 返回上下文到 iframe
            e.source.postMessage({
                type: "HRM_CONTEXT",
                token: "Bearer " + hrmToken,
                xToken: "Bearer " + hrmToken,
                userInfo: appContext.userInfo,
                companyId: appContext.userInfo?.companyId,
                baseUrl1: "http://localhost:8088",
                baseUrl2: "http://localhost:8088",
                newFenluApiBase: "http://localhost:8088"
            }, "*");
        } catch (err) {
            console.error("HRM Token 获取失败:", err);
            e.source.postMessage({
                type: "HRM_CONTEXT_ERROR",
                message: "获取分路认证失败"
            }, "*");
        }
    }
});
```

### 7.2 验证

1. 天津宏观世纪首页加载后，打开 DevTools Console
2. 手动执行 `window.postMessage({type: "HRM_GET_CONTEXT"}, "*")`
3. 监听 `message` 事件，确认收到 `HRM_CONTEXT` 响应，token 非空

---

## Task 8: 天津宏观世纪前端 — initMenu startup 适配

**执行者**: Developer1  
**估时**: 0.25 天  
**依赖**: Task 5a（菜单数据就绪）

### 8.1 改动内容

**文件**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\IChainStar.Infrastructure.Frontend\wwwroot\js\app.js`

当前 `initMenu` 中 startup 处理：

```javascript
this.initMenu().then(menu => {
    const { parentId, id, title: name, path } = menu.startup || {};
    if (id) {
        this.appContext.menu.openKeys = [parentId, id];
    }
    let startupRoute = menu.startup ?
        { id, name, path } :
        { id: 1, name: '首页', path: 'views/dashbord/index.html' };
    let route = this.appContext.route.addRoute(startupRoute);
    this.appContext.route.setCurrentRoute(route.id);
});
```

改为（兼容 `name` 和 `title` 字段）：

```javascript
this.initMenu().then(menu => {
    var startup = menu.startup || {};
    var parentId = startup.parentId || 0;
    var id = startup.id;
    var name = startup.title || startup.name || '首页';
    var path = startup.path || 'views/dashbord/index.html';

    if (id) {
        this.appContext.menu.openKeys = [parentId, id];
    }
    var startupRoute = { id: id || 1, name: name, path: path };
    var route = this.appContext.route.addRoute(startupRoute);
    this.appContext.route.setCurrentRoute(route.id);
});
```

### 8.2 验证

登录后默认首页正确打开。如果 HRM 模块是某用户的 startup，应正确加载 hrm-proxy 页面。

---

## Task 9: HRM 数据库 — 天津宏观世纪模块菜单数据

**执行者**: Developer  
**估时**: 0.5 天  
**依赖**: Task 2（需要了解菜单代理的逻辑以正确配置 path）

### 9.1 说明

天津宏观世纪自有的模块（采购管理、生产管理、产品管理等）需要在分路的 `AbpMenuRoute` 表中注册菜单记录，才能在 `GetListByRole` 中返回。

### 9.2 SQL 示例

```sql
-- 一级菜单节点（图标使用 Font Awesome 4 命名）
INSERT INTO AbpMenuRoute (Title, Icon, Path, ParentId, PlatformId, IsDeleted, CreationTime)
VALUES (N'产品管理', N'fa fa-cubes', 'views/product_management/index.html', 0, 1, 0, GETDATE());

-- 子菜单节点（ParentId 指向上级节点 ID）
DECLARE @productId INT = SCOPE_IDENTITY();
INSERT INTO AbpMenuRoute (Title, Icon, Path, ParentId, PlatformId, IsDeleted, CreationTime)
VALUES (N'产品列表', N'', 'views/product_management/product_list/index.html', @productId, 1, 0, GETDATE());

-- 采购管理
INSERT INTO AbpMenuRoute (Title, Icon, Path, ParentId, PlatformId, IsDeleted, CreationTime)
VALUES (N'采购管理', N'fa fa-shopping-cart', 'views/purchase_management/index.html', 0, 1, 0, GETDATE());

-- ... 按实际模块逐个 INSERT
```

**重要**:
- `Path` 字段填写天津宏观世纪本地 views 路径（**不带** `/v2/` 前缀），MenuProxyService 中非 HRM 路径会原样保留
- `menuButtons` 字段：如果 `AbpMenuRoute` 表没有此字段，需要确认分路 HRM 中按钮权限存储在哪个表（可能是 `AbpMenuButton` 或直接在 `AbpMenuRoute` 中有 `MenuButtons` JSON 字段）。需 Developer 排查分路后端 `MenuRoute` Entity 的完整定义。

### 9.3 角色关联

新插入的菜单需要关联到现有角色，才能通过 `GetListByRole` 返回。Developer 需排查分路的角色-菜单关联表和 `GetListByRole` 的过滤逻辑。

### 9.4 验证

菜单代理 API 返回的 children 中应包含天津宏观世纪模块节点（path 以 `views/` 开头），且无 `/v2/` 前缀。

---

## Task 10: E2E 验证

**执行者**: QA  
**估时**: 0.5 天  
**依赖**: 全部 Task 1-9 完成

### 验证清单

| # | 验证项 | 操作 | 通过标准 |
|---|--------|------|---------|
| 1 | 菜单加载 | 登录天津宏观世纪，观察左侧菜单 | 菜单树包含天津宏观世纪模块（产品/采购等）+ HRM 模块（员工/考勤等） |
| 2 | HRM 页面加载 | 点击 HRM 菜单节点（如"员工管理"） | 标签页打开，iframe 内显示 HRM 页面 |
| 3 | HRM 列表查询 | 在 HRM 页面内操作查询 | 数据正常加载，分页正常 |
| 4 | HRM 新增 | 点击新增按钮 | 弹窗正常打开，字段完整 |
| 5 | HRM 保存 | 填写表单后保存 | 保存成功，列表刷新 |
| 6 | HRM 编辑 | 点击编辑按钮 | 弹窗加载已有数据 |
| 7 | HRM 删除 | 点击删除按钮并确认 | 删除成功，列表刷新 |
| 8 | 按钮权限 | 用不同角色登录 | 有权限角色看到按钮，无权限角色看不到 |
| 9 | Token 过期恢复 | 手动 `localStorage.removeItem("token")` 后操作 HRM 页面 | 页面自动恢复，不跳到分路登录页 |
| 10 | 天津宏观世纪原生模块 | 点击天津宏观世纪模块菜单（产品管理/采购管理等） | 正常打开，功能不受影响 |
| 11 | 天津宏观世纪原生按钮权限 | 检查 `checkTabPermissions` 对天津宏观世纪模块页面的控制 | 按钮按权限显示/隐藏 |
| 12 | 菜单降级 | 停掉分路后端，刷新天津宏观世纪首页 | 菜单回退到静态 menu.json（降级策略） |

---

## 工作量汇总

| Task | 执行者 | 系统 | 内容 | 估时 |
|------|--------|------|------|------|
| 1 | Developer | honguan | Token 桥接 API | 0.5 天 |
| 2 | Developer | honguan | 菜单代理 API | 0.5 天 |
| 3 | Developer | fl | CORS 配置（分路 IIS） | 0.25 天 |
| 4 | Developer1 | fl | 分路 ?embedded=true | 0.25 天 |
| 5a | Developer1 | honguan | getWebAppMenu 改造 | 0.25 天 |
| 5b | Developer1 | honguan | mainmenu 字段适配 | 0.25 天 |
| 5c | Developer1 | honguan | checkPermissions 移植 | 0.5 天 |
| 6 | Developer1 | honguan | hrm-proxy 代理页 | 0.5 天 |
| 7 | Developer1 | honguan | postMessage 监听 | 0.25 天 |
| 8 | Developer1 | honguan | initMenu startup 适配 | 0.25 天 |
| 9 | Developer | fl | DB 菜单数据（分路 DB） | 0.5 天 |
| 10 | QA | both | E2E 验证 | 0.5 天 |
| **合计** | | | | **4.5 天** |

## 分派批次

| 批次 | Task | 分派给 | 系统 | 触发条件 |
|------|------|--------|------|---------|
| Round 1 | 1, 2 | Developer | honguan | 立即可分派 |
| Round 1 | 3 | Developer | fl | 立即可分派 |
| Round 1 | 4 | Developer1 | fl | 立即可分派（Mock 开发） |
| Round 1 | 6, 7 | Developer1 | honguan | 立即可分派（Mock + 契约 E） |
| Round 2 | 5a, 5b, 5c, 8 | Developer1 | honguan | Task 1, 2 完成后 |
| Round 2 | 9 | Developer | fl | Task 2 完成后 |
| Round 3 | 10 | QA | both | 全部完成后 |
