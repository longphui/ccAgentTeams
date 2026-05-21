# 功能 #005：测试规范文档

- **功能编号**: #005
- **功能名称**: 测试规范文档
- **状态**: ✅ 可交付
- **完成日期**: 2026-05-20
- **涉及角色**: QA（编写）、Reviewer（审查）、Architect（确认）

## 需求

制定项目测试规范，覆盖测试层级定义、UI 交互测试、API 测试、JS 函数测试、回归测试等，作为全团队测试工作的统一标准。同时编写一个 UI 交互测试示范用例。

## 交付物

| 文件 | 说明 |
|------|------|
| `AgentTeams/shared/conventions/test-standards.md` | 通用测试规范（8 章 + 3 附录，约 250 行） |
| `AgentTeams/qa/playwright/supplierManage-ui-interaction.spec.js` | UI 交互测试示例（8 个用例） |

## 执行流程

1. QA 收到 TASK → 编写 test-standards.md + 示范 spec
2. QA 发 REVIEW → Reviewer 审查（msg-20260520-2220）
3. Reviewer 发现 6 个问题 → QA 修复（msg-20260520-2300-d5e6）
4. Reviewer 二次审查通过 ✅（msg-20260520-2330-e7f8）
5. QA 发 RESULT 给 Architect（msg-20260520-2345-f9g0）
6. Architect 确认可交付 → 发 SYNC 通知全团队
7. Architect 将 test-standards.md 接入 QA/Reviewer/Developer 角色定义文件

## 接入的角色定义

| 角色 | 接入方式 |
|------|---------|
| QA | Step 1 强制读取全文；测试维度速查表交叉引用各章节 |
| Reviewer | Step 1 读取；审查清单新增「测试覆盖」5 项（参照附录 C） |
| Developer | Step 1.6 API 自测时参考第 3 章 curl 模板 |
| Developer1 | 未接入（Vitest 无法在当前零构建工具项目中运行） |
