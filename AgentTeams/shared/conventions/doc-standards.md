# 需求文档与实施计划 — 编写规范

> 适用角色：Architect。以后所有新功能均按此模板输出。

---

## 一、需求文档（`{编号}-{标题}.md`）

定义 **WHAT** — 做什么、为什么做、不做哪些。

### 1.1 必填章节

```markdown
# 需求 #{编号}: {标题}

- **日期**: YYYY-MM-DD
- **状态**: 分析中 / 已确认 / 实施中 / 已交付
- **工期**: X 天/周

## 目标
2-3 句话：解决什么问题、给谁用、期望效果。

## 范围
### 包含
- 功能点 1
- 功能点 2

### 不包含
- 明确排除的内容（防止范围蔓延）

## 用户故事 / 场景
1. 作为【角色】，我希望【功能】，以便【价值】。
2. ...

## 验收标准
| # | 场景 | 操作 | 预期结果 |
|---|------|------|---------|
| 1 | 正常流程 | xxx | xxx |
| 2 | 边界情况 | xxx | xxx |
| 3 | 异常情况 | xxx | xxx |

## 技术决策
| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 集成方式 | A/B/C | X | ... |
```

### 1.2 编写原则

- **业务语言**：用户/产品经理能看懂，不写技术实现细节
- **明确排除**：说清楚 NOT in scope，避免"顺手加需求"
- **验收可测**：每条标准能直接转化为 QA 测试用例

---

## 二、实施计划（`{编号}-plan-{标题}.md`）

定义 **HOW** — 怎么做、谁来做、什么顺序、如何验证。

### 2.1 必填章节及顺序

```markdown
# 实施计划 #{编号}: {标题}

- **日期**: YYYY-MM-DD
- **工期**: X 天
- **分析文档**: {编号}-{标题}.md
- **需求文档**: 同上

---

## 1. 架构总览

ASCII 架构图，展示：
- 涉及哪些系统/模块
- 数据流向（箭头）
- 新增组件 vs 改造组件（标注 NEW / MOD）

```

### 2.2 API 契约（新增，强制）

**目的**：前后端并行开发的基础。Developer 按契约实现接口，Developer1 按契约 mock 数据。

每条 API 必须写明：

```markdown
---

## 2. API 契约

### 2.1 {接口名称}

| 属性 | 值 |
|------|-----|
| 端点 | POST /api/xxx |
| 说明 | 功能描述 |
| 认证 | Bearer Token / 匿名 |
| 执行者 | Developer |

#### 请求

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platformId | int | 是 | 平台ID |

```json
{
  "platformId": 1
}
```

#### 响应 — 成功

| 字段 | 类型 | 说明 |
|------|------|------|
| children | array | 子菜单列表 |
| children[].id | int | 菜单ID |
| children[].title | string | 菜单标题 |
| children[].parent | int | 父菜单ID |
| children[].path | string | 路由路径 |
| children[].icon | string | 图标名称 |
| children[].children | array | 子菜单（递归） |
| children[].menuButtons | string[] | 按钮权限码 |

```json
{
  "children": [
    {
      "id": 1001,
      "title": "员工管理",
      "parent": 0,
      "path": "/views/hrm-proxy/index.html?page=staffManagement/staffInfo/index.html",
      "icon": "icon-people",
      "children": [],
      "menuButtons": ["search", "add", "edit", "delete"]
    }
  ],
  "startup": { "id": 1, "parentId": 0, "title": "首页", "path": "views/dashbord/index.html" }
}
```

#### 响应 — 错误

```json
{
  "succeeded": false,
  "errors": [{ "message": "Token 验证失败" }]
}
```

#### Mock 数据（Developer1 用）

```javascript
// 前端可临时使用以下数据独立开发，无需等待后端就绪
var mockMenuData = {
  children: [ /* 同上 */ ],
  startup: { "id": 1, "parentId": 0, "title": "首页", "path": "views/dashbord/index.html" }
};
```
```

### 2.3 契约编写原则

- **每个端点一条契约**：不合并、不省略
- **字段表 + JSON 示例双写**：字段表精确类型，JSON 对照检查
- **必须含错误响应**：Developer1 需要知道错误时的数据格式
- **必须含 Mock 数据**：Developer1 拿到就能开工，不依赖后端编译完成
- **标注执行者**：明确哪个角色负责实现

### 2.4 后续章节

```markdown
---

## 3. 数据变更（如有）

| 表 | 操作 | SQL / 说明 |
|----|------|-----------|
| AbpMenuRoute | INSERT | 新增天津宏观世纪模块菜单记录 |

## 4. 任务拆解

每个 Task：
- **执行者** + **依赖** + **估时**
- **涉及文件**（精确路径）
- **实现要点**（关键逻辑，不写完整代码）
- **验证标准**（可独立验证）

## 5. 依赖关系图

ASCII 依赖图，标注哪些 Task 可并行。

```

## 6. 分派计划

| 批次 | Task | 执行者 | 触发条件 |
|------|------|--------|---------|
| Round 1 | 1,2 | Developer | 无依赖 |
| Round 1 | 3,4 | Developer1 | 无依赖（有 Mock） |
| Round 2 | 5 | Developer1 | Task 2 完成 |

## 7. 工作量汇总

| 执行者 | 任务数 | 估时 |
|--------|--------|------|
| Developer | N | X 天 |
| Developer1 | N | X 天 |
| QA | 1 | X 天 |
| 合计 | | X 天 |
```

---

## 三、关键改进：前后端并行

```
旧模式（串行，Developer1 空等）：
  Developer 写完后端 → 接口可用 → Developer1 联调 → QA

新模式（并行，契约驱动）：
  1. Architect 输出 API 契约（含 Mock 数据）
  2. Developer 按契约实现接口  ┐
  3. Developer1 用 Mock 开发页面 ┘ → 同时进行
  4. 两端完成后联调切换 → QA
```

**做到并行的条件：**
- API 契约中字段类型精确到 `string` / `int` / `array` / `object`
- JSON 示例覆盖成功和错误两种响应
- Mock 数据可直接复制粘贴到前端代码中使用

---

## 四、文件命名

```
shared/requirements/
├── {编号}-{标题}.md           # 需求文档
└── {编号}-plan-{标题}.md      # 实施计划

shared/decisions/
└── {编号}-{决策标题}.md       # 架构决策记录

项目目录/
└── {功能模块}-analysis.md     # 可选：技术分析报告（如系统对比、选型分析）
```
