---
description: [分路] 前端开发辅助 — 编码规范、页面模板、API 调用、SVN 操作
argument-hint: [page|api|test|svn]
allowed-tools: [Bash, Read, Glob, Grep, Edit, Write]
---

# 前端开发辅助

## 技术栈

| 技术 | 说明 |
|------|------|
| Vue 3 | 全局构建 `vue.global.js`，**无 SFC / 无打包器** |
| UI | LayuiVue 2.22.2（`layui-vue/index@2.22.2.js`） |
| HTTP | 原生 `fetch()`，封装为 Http / HttpE / Http2 |
| 状态 | `Vue.reactive()` 单例 `appContext`，无 Vuex/Pinia |
| 路由 | iframe + 标签页，自定义实现，无 vue-router |
| SVN | `https://vip.svnspot.net/caikuangzi.fenluwebproject/trunk` |

## 项目结构

```
v2/
├── app.js / appContext.js / appConfig.js   # 主应用入口 + 全局状态 + 配置
├── baseService.js                          # HTTP 客户端 (Http/HttpE/Http2)
├── resloader.js                            # 资源动态加载器
├── libs/components.js                      # LayuiVue 全局组件注册
├── views/                                  # 业务页面（按模块划分）
└── component/                              # 自定义组件
```

## 页面模板

### 列表页 (index.html)
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <script id="importresloader" src="/v2/importresloader.js?v=1.0.1"
        then="loadLayuiVue"></script>
</head>
<body>
    <div id="app">
        <lay-page-view method="post" :page="page" :columns="columns"
            :filters="filters" data-url="/api/xxx/GetPageList"
            :page-maper="PageMaper" ref="page"
            :custom-toolbar="true" :default-toolbar="true">
            <!-- 工具栏 --><!-- 操作列 --><!-- 自定义列 -->
        </lay-page-view>
    </div>
    <script>
        const { createApp } = Vue;
        const { layer } = LayuiVue;
        const appContext = getAppContext();
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
- 资源加载同上，body 内含 `lay-card` + `lay-form`
- `state = getState()` 获取传入数据，`state.onConfirm = this.saveEntry` 注册回调
- 保存成功调 `state.return()` 关闭弹窗并通知列表刷新

## 代码规范

### 资源引入
- **必须**通过 `<script id="importresloader" then="loadLayuiVue">` 加载
- **禁止**直接写 `<link>` 或 `<script src="...">`

### HTTP 调用
- 旧版 API → `Http.post(url, { data })` / `Http.get(url, params)`，响应 `{ success, result }`
- 新版 API → `Http2.post(url, data)` / `Http2.get(url, params)`，响应 `{ succeeded, data, errors }`

### LayPageView 核心组件
- `columns`: 列定义，`customSlot` 对应模板 `<template v-slot:xxx>`
- `filters`: 搜索条件，`staticFilter` 隐藏过滤（如公司ID）
- `page-maper`: `{ totalCount: 'count', items: 'items' }` 适配后端分页格式

### 按钮规范（高频错误点）
| 场景 | 用 | 必须属性 |
|------|-----|----------|
| 打开编辑弹窗/新增页 | `lay-link-button` | `href` + `target="_popup"` + `:area` + `:ok` |
| 删除/启禁/纯动作 | `lay-button` | `@click` |
- **`lay-link-button` 无 `href` 会报错**: `Cannot read properties of undefined (reading 'match')`

### 数据交互模式
| 场景 | 方式 |
|------|------|
| 列表新增/编辑 | `LayLinkButton` `target="_popup"` → `:state="row"` → `state.return()` |
| 删除 | `layer.confirm()` → `Http.post(url/{id})` → `this.$refs.page?.retryCurrentPage()` |
| 启禁 | `Http.post(url/{id})` → `this.$refs.page?.retryCurrentPage()` |

### 权限控制
```javascript
data() { return {
    addType: appContext.route.checkTabPermissions(pathName, 'add'),
    updateType: appContext.route.checkTabPermissions(pathName, 'update'),
    deleteType: appContext.route.checkTabPermissions(pathName, 'delete'),
}; }
// 模板: v-if="addType"
```

### 注释（强制，禁止零注释）
- 文件头 `<!-- 模块名 — 列表/表单页 功能说明 路由 -->`
- 模板区块 `<!-- ===== 工具栏按钮 ===== -->`
- JS data 属性 `// 权限控制` `// 分页映射`
- methods 方法 `// 删除确认弹窗` `// 刷新当前页`
- 复杂逻辑 `// 本地新增子项用 _key 标识，提交时过滤 id`

### 消息提示
```javascript
layer.msg("操作成功", { icon: 1, time: 2000 });
layer.msg("操作失败", { icon: 2, time: 2000 });
layer.confirm("确定删除？", { title: "删除", yes: (i) => { /* ... */ layer.close(i); } });
```

## 测试

| 项目 | 值 |
|------|-----|
| 地址 | `http://localhost:8095/` |
| 页面路径 | `http://localhost:8095/v2/views/{模块}/{功能}/index.html` |

检查清单：页面加载 → 搜索分页 → 新增 → 编辑回显 → 删除 → 字段验证 → 异常提示 → 权限控制

## 新建文件（强制）

新建文件后必须 `svn add "相对路径/新文件"`（仅暂存，**不 svn commit**），否则不纳入版本控制。不限于 `.html`，所有未被 `.svnignore` 排除的文件均适用。交付时统一提交。

## 文件移动（强制）

移动/重命名文件或目录时，**必须使用 `svn mv`**（禁止直接拷贝或文件系统 `mv`）。

## 文件删除（强制）

删除文件时，**必须使用 `svn rm`**（禁止直接 `rm` 或 delete）。

## 目录操作（强制）

创建目录：`svn mkdir` 或先创建再 `svn add`
删除目录：`svn rm`（自动递归删除目录内所有文件）

## SVN 错误操作修复

若已错误操作（SVN `!` 缺失 + `?` 未跟踪），修复：
```bash
svn rm --force oldPath/file    # 标记旧文件已删除
svn add newPath                # 添加新目录/文件
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
**格式**：`[模块] 简短说明`  
**禁止提交**：`.vs/` `bin/` `obj/` `node_modules/` `packages/` `.env` `*.log`
