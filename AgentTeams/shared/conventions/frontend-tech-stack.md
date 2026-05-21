# 前端技术栈与编码规范

- **日期**: 2026-05-19
- **适用项目**: 天津宏观世纪ERP (honguan) + 分路 (fenlu)

---

## 一、两个项目概览

| | 天津宏观世纪ERP | 分路 |
|---|---|---|
| **项目路径** | `caikuangzi01.huoguan_erp/.../wwwroot/` | `caikuangzi.fenluwebproject/.../Web/v2/` |
| **入口** | login.html → index.html | `/v2/index.html`（SPA shell） |
| **名称** | 分路ERP | 分路综合运营系统 |
| **框架** | Vue 3（全局脚本，无构建工具） | 同 |
| **组件库** | LayuiVue 2.23.3 | LayuiVue 2.22.2 + 经典 Layui v2 |
| **HTTP** | 原生 fetch（1 个 Http 客户端） | 原生 fetch（Http / HttpE / Http2） |
| **jQuery** | 无 | 有（经典 Layui 依赖） |
| **图表** | 无 | ECharts 5/6 + DataV |
| **多租户** | 无 | 有（公司切换） |

### 共同特征

- **零构建工具**：无 webpack/vite，资源通过 `document.write()` 动态注入 `<script>` 标签加载
- **Vue 3 全局构建**：`Vue.createApp()` 创建应用，每个页面是独立的 Vue 应用
- **API 响应格式不同**：见下文「API 响应格式」
- **页面即应用**：每个 `.html` 文件是自包含的 Vue 应用，有自己的 `createApp` + `mount`
- **跨窗口通信**：iframe + postMessage + stateKey（URL 参数传递共享状态键）

---

## 二、JS 文件分工

### 天津宏观世纪 (wwwroot/js/)

| 文件 | 职责 | 分派注意 |
|---|---|---|
| `app.js` | 主外壳：Vue 应用创建、菜单初始化、HRM 上下文桥接、布局/主题同步 | Developer1 |
| `appConfig.js` | 全局配置：baseUrl、version | Developer1 |
| `appContext.js` | 响应式全局状态：路由/菜单/布局/主题/通知/表单状态 | Developer1 |
| `baseService.js` | API 服务层：登录、菜单获取、流程映射 | Developer1 |
| `http.js` | HTTP 客户端：fetch 封装、Furion 解包、401 处理 | Developer1 |
| `util.js` | 工具函数：日期格式化、URL 处理、命名转换 | Developer1 |
| `resloader.js` | 资源加载器：按预设注入 CSS/JS 标签 | Developer1 |
| `importresloader.js` | 引导脚本：动态写 appConfig + resloader | Developer1 |
| `themes.js` | 主题预设（红/暗/蓝 3 套） | Developer1 |
| `applytheme.js` | 主题/布局 CSS 变量应用 | Developer1 |

### 分路 (v2/)

| 文件 | 职责 | 与天津宏观世纪差异 |
|---|---|---|
| `app.js` | 主外壳 + 公司切换 + 版本切换 + 菜单搜索 | 多公司切换、版本选择器 |
| `appConfig.js` | 多环境多 API 地址 | `baseUrl1/2/3` + `newFenluApiBase`，更多端点 |
| `baseService.js` | 3 个 HTTP 客户端 + 嵌入模式检测 | `Http`/`HttpE`/`Http2` 三种解包方式 |
| `baseServiceH5.js` | H5 变体，无视嵌入模式 | 401 始终跳登录页 |

---

## 三、API 响应格式（关键！分派时必须区分）

### 天津宏观世纪 — Furion 统一格式

```json
{
  "succeeded": true,
  "data": { ... },
  "errors": null
}
```

前端 `http.js` 检查 `res.succeeded` → 返回 `res.data`。

### 分路 — 三种格式混用

| 客户端 | 目标 | 解包判断 | 成功返回 |
|---|---|---|---|
| `Http` | 旧分路 API (`baseUrl1`) | `res.success` | `res.result` |
| `HttpE` | 能源 API (`baseUrl2`) | `res.code === 200` | `res.data` |
| `Http2` | Furion API (`newFenluApiBase`) | `res.succeeded` | `res.data` |

> ⚠️ 分派分路前端任务时，必须确认接口走哪个 HttpClient，错误处理逻辑不同。

---

## 四、页面结构模式

### 列表页模板

```html
<script id="importresloader" then="loadLayuiVue"></script>
<div id="app">
  <lay-page-view :columns="columns" :filters="filters"
    :data-url="'/api/xxx/list'" service-base-url="/api/xxx">
    <template #toolbar>
      <lay-link-button url="views/module/create_edit.html">新增</lay-link-button>
    </template>
  </lay-page-view>
</div>
<script>
const app = Vue.createApp({
  data() { return { columns: [...], filters: [...] }; }
});
app.use(LayuiVueAll);
app.mount("#app");
</script>
```

### 表单页（弹窗内打开）

```html
<script id="importresloader" then="loadLayuiVue"></script>
<div id="app">
  <lay-form :model="form" :rules="rules">
    <lay-input v-model="form.name" />
    <!-- ... -->
  </lay-form>
</div>
<script>
const { createApp } = Vue;
const app = createApp({
  data() {
    const state = getState();
    return { form: state?.value || {} };
  }
});
app.use(LayuiVueAll);
app.mount("#app");
</script>
```

### 关键约定

- `importresloader` 必须放在页面最顶部
- `LayuiVueAll` 是全局注册的组件集
- 跨页面传参用 `getState()`（从 URL `stateKey` 获取共享状态）
- `appContext.route` 管理 Tab（最多 20 个），不是 Vue Router

---

## 五、iframe 嵌入架构（#004 HRM 集成专用）

```
主窗口 (app.js, HRM_GET_CONTEXT 监听器)
  └── Tab iframe (PlusLayout 渲染)
      └── hrm-proxy/index.html (代理页)
          └── HRM 页面 iframe (分路系统)
```

### postMessage 消息契约

| 消息类型 | 方向 | 携带数据 |
|---|---|---|
| `HRM_GET_CONTEXT` | hrm-proxy → 主窗口 | 无 |
| `HRM_CONTEXT` | 主窗口 → hrm-proxy | token, xToken, userInfo, baseUrl1, companyId |
| `HRM_CONTEXT_ERROR` | 主窗口 → hrm-proxy | message |
| `HRM_TOKEN_EXPIRED` | 分路页面 → hrm-proxy | 无 |

### 关键坑点

1. **`window.parent` vs `window.top`**：hrm-proxy 嵌套在两层 iframe 中，必须用 `window.top` 发消息到主窗口
2. **Vue reactive Proxy 不能 postMessage**：`appContext.userInfo` 是 reactive 对象，必须 `JSON.parse(JSON.stringify(...))` 后才能传
3. **分路 `baseService.js` 未读 hrmToken**：token 通过 URL 传递，但分路代码未写入 localStorage，需在嵌入模式下补充

---

## 六、分派速查表

| 文件类型 / 操作 | → 分派给 |
|---|---|
| `.html` 页面（视图/模板） | Developer1 |
| `.js` 文件（任何项目） | Developer1 |
| CSS / 样式 / 布局 | Developer1 |
| Vue 组件 / LayuiVue | Developer1 |
| localStorage / postMessage / DOM | Developer1 |
| `.cs` 后端代码 | Developer |
| `.csproj` 项目配置 | Developer |
| 数据库 / SQL | Developer |
| API 数据问题 | 优先 Developer |

> 2026-05-19 纠正：`.js` 和浏览器 API 操作归 Developer1，不以所在项目区分。

---

## 七、资源加载顺序

```
importresloader.js
  └→ appConfig.js（全局配置）
  └→ resloader.js（按预设加载）
      ├─ Vue 3 全局
      ├─ LayuiVue CSS + JS
      ├─ FontAwesome
      ├─ 自定义 bundle.css/js
      ├─ themes.js → applytheme.js
      ├─ util.js → http.js → baseService.js
      └─ appContext.js
```

加载完成后 `app.js` 或页面内联脚本创建 Vue 应用。
