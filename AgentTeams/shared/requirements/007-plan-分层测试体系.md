# 实施计划 #007: 分层测试体系

- **日期**: 2026-05-21
- **工期**: 1 天
- **需求文档**: 007-分层测试体系.md

---

## 1. 架构总览

```
                      ┌─────────────────────┐
                      │   QA (Playwright)    │
                      └──────────┬──────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
     ┌────────────┐    ┌─────────────┐    ┌──────────────┐
     │ API curl   │    │ Playwright  │    │ Playwright   │
     │ 文件方式   │    │ Mock 模式   │    │ 真实后端     │
     │ (契约验证) │    │ (前端独立)  │    │ (联调验证)   │
     └────────────┘    └─────────────┘    └──────────────┘
                              │                  │
                      USE_MOCK=true      USE_MOCK=false
                      page.route()       无 Mock 注册
                              │                  │
                              └────────┬─────────┘
                                       │
                              同一套 spec 文件
                              if (useMock) { ... }
                                       │
                          ┌────────────┼────────────┐
                          │            │            │
                          ▼            ▼            ▼
                    headless:true  headless:false  截图/录屏
                    (CI/快速)     (调试/证据)    (失败自动)
```

### 改动点

| 文件 | 操作 | 说明 |
|------|------|------|
| `AgentTeams/qa/playwright.config.js` | MOD | 加 `useMock` 全局变量传递 |
| `AgentTeams/qa/playwright/*.spec.js` | MOD | Mock 注册加 `if (useMock)` 守卫 |
| `.claude/commands/agent-qa.md` | MOD | 流程从手工改为自动化分层 |
| `AgentTeams/shared/conventions/test-standards.md` | MOD | 对齐分层测试流程 |

---

## 2. 任务拆解

### Task 1: Playwright 配置改造 — 双模式支持

- **执行者**: Developer1
- **依赖**: 无
- **估时**: 0.5h
- **涉及文件**: `AgentTeams/qa/playwright.config.js`
- **实现要点**:
  1. 在 `use` 中通过 `process.env.USE_MOCK` 读取环境变量，默认 `true`
  2. 通过 `globalSetup` 或直接在 spec 中读取环境变量传递 `useMock` 标志
  3. 推荐方案：`use: { baseURL: ..., headless: true, useMock: process.env.USE_MOCK !== 'false' }`，spec 中通过 `test.info().project.use.useMock` 获取
  4. 不加 headed project（需要时用 `--headed` CLI 参数）
- **验证标准**: `USE_MOCK=false npx playwright test --list` 列出测试，配置读取正确

### Task 2: Spec 文件 Mock 守卫改造

- **执行者**: Developer1
- **依赖**: Task 1
- **估时**: 1h
- **涉及文件**: `AgentTeams/qa/playwright/*.spec.js`（22 个文件）
- **实现要点**:
  1. 每个 spec 文件顶部从 `test.info()` 或全局变量获取 `useMock` 标志
  2. `setupMockedPage()` 函数内所有 `page.route()` 调用加 `if (useMock)` 守卫
  3. 独立 `page.route()` 调用（不在 setupMockedPage 内的）也加守卫
  4. 对需要真实后端数据的断言（如 `iframe-embedded-e2e.spec.js`），`useMock=false` 时跳过 Mock 专用断言
- **验证标准**: `USE_MOCK=true` 和 `USE_MOCK=false` 两种模式下脚本不报语法错误

### Task 3: QA 角色定义更新

- **执行者**: Architect
- **依赖**: 无
- **估时**: 0.5h
- **涉及文件**: `.claude/commands/agent-qa.md`
- **实现要点**:
  1. 角色描述从"浏览器中手动验证功能"改为"Playwright 自动化分层测试"
  2. 处理流程改为三阶段：curl API 验证 → Playwright Mock → Playwright 真实后端
  3. 保留 curl 文件方式测试规范
  4. 增加 Playwright 执行命令速查
- **验证标准**: QA 启动后能按新流程执行测试

### Task 4: 测试规范对齐

- **执行者**: Architect
- **依赖**: Task 1, Task 2
- **估时**: 0.5h
- **涉及文件**: `AgentTeams/shared/conventions/test-standards.md`
- **实现要点**:
  1. 附录 A 更新：UI 交互测试/E2E 测试写明双模式
  2. 附录 B 更新：补充 Mock/真实后端模式说明
  3. 8.2 节补充 `USE_MOCK` 环境变量用法
- **验证标准**: 规范文件与 `playwright.config.js` 实际配置一致

---

## 3. 依赖关系图

```
Task 1 (Playwright 配置) ──→ Task 2 (Spec 改造)
                                    │
Task 3 (QA 定义更新) ────────────────┤
                                    │
                                    ▼
                              Task 4 (规范对齐)
```

- Task 1 和 Task 3 可并行
- Task 2 依赖 Task 1（需要知道配置读取方式）
- Task 4 依赖 Task 1 + Task 2（需要确认实际实现后对齐规范）

---

## 4. 分派计划

| 批次 | Task | 执行者 | 触发条件 |
|------|------|--------|---------|
| Round 1 | 1 | Developer1 | 无依赖 |
| Round 1 | 3 | Architect | 无依赖 |
| Round 2 | 2 | Developer1 | Task 1 完成 |
| Round 2 | 4 | Architect | Task 1 + 2 完成 |

---

## 5. 工作量汇总

| 执行者 | 任务数 | 估时 |
|--------|--------|------|
| Developer1 | 2 | 1.5h |
| Architect | 2 | 1h |
| **合计** | **4** | **2.5h** |
