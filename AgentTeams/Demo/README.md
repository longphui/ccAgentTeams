# Demo: 完整通信流程演示

## 场景背景
某 Web 项目需要为用户系统添加 JWT 登录认证。团队四人协作完成：
**Architect**（架构设计）→ **Developer**（编码实现）→ **Reviewer**（安全审查）→ **QA**（测试验收）

---

## 通信流程图（共12步）

| 步骤 | 文件夹 | 类型 | 发送方 | 接收方 | 主题 |
|------|--------|------|--------|--------|------|
| 01 | 任务派发 | TASK | Architect | Developer | 实现JWT登录认证模块 |
| 02 | 咨询答疑 | QUERY | Developer | Architect | Token过期策略确认 |
| 03 | 咨询答疑 | RESULT | Architect | Developer | ✅ 答复token策略 |
| 04 | 代码审查 | REVIEW | Developer | Reviewer | 审查auth模块安全性 |
| 05 | 代码审查 | FEEDBACK | Reviewer | Developer | ⚠️ 发现3个安全问题 |
| 06 | 代码审查 | RESULT | Developer | Reviewer | ✅ 安全问题已修复 |
| 07 | 代码审查 | RESULT | Reviewer | Developer | ✅ 复审通过 |
| 08 | Bug修复 | ALERT | QA | Developer | 🚨 token刷新接口500错误 |
| 09 | Bug修复 | RESULT | Developer | QA | ✅ Bug已修复 |
| 10 | 测试验收 | TASK | Architect | QA | 测试JWT认证完整流程 |
| 11 | 项目完成 | RESULT | QA | Architect | ✅ 全部测试通过 |
| 12 | 项目完成 | SYNC | Architect | all | 📢 项目完成总结 |
