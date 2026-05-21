# 需求 #004: HRM 集成到天津宏观世纪ERP — 阶段 1（iframe 嵌入 + 菜单统一）

- **日期**: 2026-05-17
- **状态**: 实施中
- **工期**: 4.5 天
- **方案文档**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\HRMFromFenluToHonguan.md`
- **实施计划**: `D:\work\cc\caikuangzi01.huoguan_erp\trunk\HRMFromFenluToHonguan-plan.md`

## 目标

用户登录天津宏观世纪ERP后，在菜单中点击 HRM 功能节点，标签页内打开 HRM 页面并可完整操作。菜单和按钮权限统一由 HRM 的 `api/HRM/MenuRoute/GetListByRole` 接口管理。

## 技术决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 集成方式 | iframe 嵌入 + 代理页面 | 改动最小，2 系统不改架构 |
| 菜单统一 | 天津宏观世纪前端改调 HRM API | 复用 HRM 角色-菜单-按钮权限体系 |
| Token 过期防控 | `?embedded=true` + postMessage | 跨域兼容，分路仅改 ~20 行 |
| Token 获取 | 天津宏观世纪后端代理 + 预设账号 | 安全可控，不暴露分路接口 |

## 关键文件

- 天津宏观世纪后端: `IChainStar.Infrastructure.Application/Services/HrmProxy/`
- 天津宏观世纪前端: `wwwroot/views/hrm-proxy/index.html`, `wwwroot/js/app.js`, `baseService.js`, `appContext.js`
- 分路前端: `caikuangzi.fenluwebproject/trunk/Web/Web/v2/baseService.js`
- 分路后端: IIS CORS 配置
- 数据库: `fenluDatabasetest` → `AbpMenuRoute` 表
