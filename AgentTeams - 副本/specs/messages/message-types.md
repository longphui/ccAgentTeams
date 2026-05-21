# 消息类型说明

## TASK — 任务指派
指派具体工作。接收方应执行并回复 RESULT。
```json
{
  "id": "msg-20260511-120000-a1b2",
  "type": "TASK",
  "from": "architect",
  "to": "developer",
  "priority": "high",
  "timestamp": "2026-05-11T12:00:00+08:00",
  "payload": {
    "subject": "实现 JWT 认证中间件",
    "context": "需要为 API Gateway 添加 JWT 验证",
    "content": "## 要求\n1. 解析 Authorization header\n2. 验证 token 签名\n3. 将解析后的 user_id 注入 request context\n\n## 技术栈\n- Go 1.22\n- 使用 golang-jwt 库",
    "files": ["src/middleware/auth.go", "src/config/jwt.go"],
    "actions": ["实现中间件", "编写单元测试", "更新 API 文档"],
    "deadline": "2026-05-12T18:00:00+08:00"
  }
}
```

## RESULT — 结果汇报
任务完成后的结果回复（必须设置 replyTo）。
```json
{
  "id": "msg-20260511-150000-c3d4",
  "type": "RESULT",
  "from": "developer",
  "to": "architect",
  "timestamp": "2026-05-11T15:00:00+08:00",
  "replyTo": "msg-20260511-120000-a1b2",
  "payload": {
    "subject": "✅ JWT 认证中间件已完成",
    "content": "## 完成情况\n...",
    "files": ["D:/project/src/auth/middleware.go", "D:/project/src/auth/service.go"]
  }
}
```

## QUERY — 咨询提问
向某角色提问或请求澄清。
```json
{
  "id": "msg-20260511-160000-e5f6",
  "type": "QUERY",
  "from": "developer",
  "to": "architect",
  "priority": "normal",
  "timestamp": "2026-05-11T16:00:00+08:00",
  "payload": {
    "subject": "token 刷新策略选型",
    "content": "access token 过期时间建议设多长？是否需要 refresh token 机制？"
  }
}
```

## REVIEW — 审查请求
请求代码/设计/安全审查。
```json
{
  "id": "msg-20260511-170000-g7h8",
  "type": "REVIEW",
  "from": "developer",
  "to": "reviewer",
  "priority": "high",
  "timestamp": "2026-05-11T17:00:00+08:00",
  "payload": {
    "subject": "审查 auth 模块 SQL 注入风险",
    "content": "请重点检查第42行和第78行的数据库查询",
    "files": ["src/auth/login.go", "src/auth/register.go"]
  }
}
```

## ALERT — 紧急通知
需要立即关注的问题（通常 priority=critical）。
```json
{
  "id": "msg-20260511-180000-i9j0",
  "type": "ALERT",
  "from": "qa",
  "to": "all",
  "priority": "critical",
  "timestamp": "2026-05-11T18:00:00+08:00",
  "payload": {
    "subject": "🚨 发现高危安全漏洞",
    "content": "登录接口存在 SQL 注入，可绕过认证",
    "files": ["logs/vulnerability-report.md"]
  }
}
```

## SYNC — 状态同步
同步当前进度、上下文或决策。
```json
{
  "id": "msg-20260511-190000-k1l2",
  "type": "SYNC",
  "from": "architect",
  "to": "all",
  "priority": "low",
  "timestamp": "2026-05-11T19:00:00+08:00",
  "payload": {
    "subject": "决策同步：数据库选型确定为 PostgreSQL",
    "content": "经讨论确定使用 PostgreSQL 16，不使用 MySQL",
    "files": ["shared/decisions/001-database-choice.md"]
  }
}
```

## FEEDBACK — 反馈建议
对已完成工作的评价或改进建议。
```json
{
  "id": "msg-20260511-200000-m3n4",
  "type": "FEEDBACK",
  "from": "reviewer",
  "to": "developer",
  "priority": "normal",
  "timestamp": "2026-05-11T20:00:00+08:00",
  "payload": {
    "subject": "审查反馈：JWT 中间件需改进错误处理",
    "content": "## 改进建议\n1. 当 token 过期时返回 401 而非 500\n2. 建议添加 token 黑名单检查",
    "files": []
  }
}
```
