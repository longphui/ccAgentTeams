---
description: [鸿冠ERP] 前端开发辅助 — 编码规范、页面模板、API 调用、SVN 操作
argument-hint: [page|api|test|svn]
allowed-tools: [Bash, Read, Glob, Grep, Edit, Write]
---

# 鸿冠ERP 前端开发辅助

## 技术栈

| 技术 | 说明 |
|------|------|
| Vue 3 | 全局构建 `vue.global.js`，**无 SFC / 无打包器** |
| UI | LayuiVue 2.23.3（`layui-vue/index@2.23.3.js`） |
| HTTP | 原生 `fetch()`，封装为单一 `Http` 对象（`http.js`） |
| 状态 | `Vue.reactive()` 单例 `appContext`，无 Vuex/Pinia |
| 路由 | 标签页 + 自定义内存路由，无 vue-router |
| 构建 | BundlerMinifier（合并压缩），无 Webpack/Vite |
| 部署 | Kestrel 独立静态文件服务（:5021） |
| SVN | `https://vip.svnspot.net/caikuangzi01.huoguan_erp/trunk` |

## 项目结构

```
IChainStar.Infrastructure.Frontend/wwwroot/
├── index.html              # 主 SPA 壳（侧边栏 + 标签页路由区）
├── login.html              # 登录页
├── register.html           # 公司注册向导
├── appConfig.js            # 前端配置（baseUrl、version）
├── menu.json               # 侧边栏菜单定义（静态）
├── locales.json            # 国际化文本（133KB）
├── js/
│   ├── http.js             # HTTP 请求封装（Fetch API + Token 管理）
│   ├── baseService.js      # 基础服务（菜单加载、用户信息）
│   ├── app.js              # Vue 3 主入口（createApp）
│   ├── appContext.js       # 全局状态（userInfo、layout、theme、menu、route）
│   ├── themes.js           # 主题系统（3 套主题）
│   └── util.js             # 工具函数（314 行）
├── libs/
│   ├── vue@3/              # Vue 3 全局构建
│   ├── layui-vue/          # LayuiVue 2.23.3
│   └── mainmenu/           # 主菜单组件
├── components/
│   ├── components/         # 22 个通用组件
│   ├── businessComponents/ # 13 个业务组件
│   ├── bundle.js           # 合并后的组件脚本
│   └── bundle.css          # 合并后的组件样式
└── views/                  # 157 个视图目录
    ├── production/         # 生产管理
    ├── marketing/          # 营销管理
    ├── warehousing/        # 仓储管理
    ├── purchasing/         # 采购管理
    ├── product_management/ # 产品管理
    ├── hr/                 # 人力资源
    └── ...
```

## 资源引入

- **直接使用 `<script src="...">` 或 `<link>` 标签**引入 JS 和 CSS
- **禁止**使用 `<script id="importresloader">` 方式（那是分路系统的规范，鸿冠不使用）
- 典型案例：
```html
<script src="/libs/vue@3/vue.global.js"></script>
<link rel="stylesheet" href="/libs/layui-vue/index@2.23.3.css" />
<script src="/libs/layui-vue/index@2.23.3.js"></script>
```

## 页面模板

### 列表页 (index.html)

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>模块名 — 列表</title>
    <link rel="stylesheet" href="/libs/layui-vue/index@2.23.3.css" />
    <link rel="stylesheet" href="/components/bundle.css" />
</head>
<body>
    <div id="app">
        <lay-page-view method="post" :page="page" :columns="columns"
            :filters="filters" data-url="/api/{entity}/page"
            :page-maper="PageMaper" ref="page"
            :custom-toolbar="true" :default-toolbar="true">
            <!-- 工具栏按钮 -->
            <!-- 操作列 -->
            <!-- 自定义列 -->
        </lay-page-view>
    </div>
    <script src="/js/http.js"></script>
    <script src="/js/appContext.js"></script>
    <script src="/libs/vue@3/vue.global.js"></script>
    <script src="/libs/layui-vue/index@2.23.3.js"></script>
    <script src="/components/bundle.js"></script>
    <script>
        const { createApp } = Vue;
        const { layer } = LayuiVue;
        const appContext = window.appContext;
        const pathName = window.location.pathname;
        const app = createApp({
            data() { return { /* filters, columns, page */ }; },
            methods: { /* openConfirm, retryCurrentPage */ },
        });
        app.use(LayuiVueAll);
        app.mount("#app");
    </script>
</body>
</html>
```

### 表单页 (create_edit.html)

- 资源引入同上
- body 内含 `lay-card` + `lay-form` 或 `lay-dynamic-form`
- 获取传入数据：通过 URL 参数或全局 `appContext.states` Map
- 保存成功通知父页面刷新列表

## 代码规范

### HTTP 调用

只有一个 HTTP 客户端（`http.js` 中的 `Http` 对象），基于 Fetch API：

```javascript
// GET
Http.get(url, params, headers, isSilent)

// POST
Http.post(url, data, headers, isSilent)

// 通用
Http.invoke(url, method, data, headers, isSilent, extraHandler)
```

**响应格式：** 鸿冠后端使用 Furion UnifyResult，响应结构为：
```json
{ "succeeded": true, "data": { ... }, "errors": null, "extras": null }
```

`Http.invoke` 在 `succeeded === true` 时直接返回 `res.data`（已解包）。

**关键：** `.then(res)` 中的 `res` 已经是展开后的 `res.data`，**不能**检查 `res.success` 或 `res.succeeded`。

**Token 管理：**
- 存储在 `localStorage.token` 和 `localStorage.xToken`
- 每次 API 调用自动从响应头刷新 Token（`access-token` / `x-access-token`）
- 401 时清除 Token 并跳转登录页

### LayPageView 核心组件

- `columns`: 列定义，`customSlot` 对应模板 `<template v-slot:xxx>`
- `filters`: 搜索条件
- `page-maper`: `{ totalCount: 'count', items: 'items' }` 适配后端分页格式
- `data-url`: 后端 API 地址

### 按钮规范

| 场景 | 用 | 说明 |
|------|-----|------|
| 打开弹窗/新增页 | `lay-link-button` | 需 `href` + `target="_popup"` |
| 删除/启禁/纯动作 | `lay-button` | 需 `@click` |
| 确认删除弹窗 | `layer.confirm()` | `yes` 回调中执行删除 |

### 权限控制（#004 新增）

```javascript
data() { return {
    addType: appContext.route.checkTabPermissions(pathName, 'add'),
    updateType: appContext.route.checkTabPermissions(pathName, 'update'),
    deleteType: appContext.route.checkTabPermissions(pathName, 'delete'),
}; }
// 模板: v-if="addType"
```

### 注释（强制，禁止零注释）

- 文件头 `<!-- 模块名 — 列表/表单页 功能说明 -->`
- 模板区块 `<!-- ===== 工具栏按钮 ===== -->`
- JS data 属性 `// 权限控制` `// 分页映射`
- methods 方法 `// 删除确认弹窗` `// 刷新当前页`
- 复杂逻辑 `// 说明 WHY`

### 消息提示

```javascript
layer.msg("操作成功", { icon: 1, time: 2000 });
layer.msg("操作失败", { icon: 2, time: 2000 });
layer.confirm("确定删除？", { title: "删除", yes: function(i) { /* ... */ layer.close(i); } });
```

### 变量声明

- **新代码统一使用 `const`/`let`**（禁止 `var`）
- camelCase 命名
- 双引号、使用分号
- 缩进：4 空格（非 Tab）

### 组件注册

```javascript
app.use(LayuiVueAll);  // 注册所有 LayuiVue + 自定义组件
app.use(PlusLayout);   // 布局组件
app.use(MainMenu);     // 菜单组件
```

## 测试

| 项目 | 值 |
|------|-----|
| 前端地址 | `http://localhost:5021` |
| 后端 API | `http://localhost:5000` |
| 页面路径 | `http://localhost:5021/views/{模块}/{功能}/index.html` |
| 账号 | `hongbin` / `123456` |

检查清单：页面加载 → 搜索分页 → 新增 → 编辑回显 → 删除 → 字段验证 → 异常提示 → 权限控制

## 新建文件（强制）

新建文件后必须 `svn add "相对路径/新文件"`（仅暂存，**不 svn commit**），否则不纳入版本控制。不限于 `.html`，所有未被忽略的文件均适用。交付时统一提交。

## 文件移动（强制）

移动/重命名文件或目录时，**必须使用 `svn mv`**（禁止直接拷贝或文件系统 mv）。

## 文件删除（强制）

删除文件时，**必须使用 `svn rm`**（禁止直接 rm 或 delete）。

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
**开发期间**：浏览器验证 → `svn up` → `svn st` → `svn add`（仅暂存）
**交付时**：`svn up` → `svn commit -m "说明"` 一次性入库（commit 前必须 update，避免代码覆盖）
**格式**：`<type>: <描述>`（如 `feat: 添加 HRM 代理页面`、`fix: 修复菜单图标显示`）
**类型**：`feat` / `fix` / `refactor` / `docs` / `style` / `perf`
**禁止提交**：`.vs/` `bin/` `obj/` `node_modules/` `packages/` `.env` `*.log`
