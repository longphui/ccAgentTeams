# AgentTeams 通信协议

## 核心原则

1. **原子消息** — 每条消息只包含一个主题/任务
2. **显式状态** — 通过 replyTo 链追踪任务状态
3. **文件即消息** — 收件箱中的 `.msg.json` 文件 = 一条消息
4. **幂等处理** — 通过消息 ID 避免重复处理
5. **消息与代码分离** — outbox 只放 JSON 消息，代码文件写入项目实际目录

## 目录用途（硬规则）

| 目录 | 放什么 | 不放什么 |
|------|--------|----------|
| `inbox/<role>/` | `.msg.json` 消息（待处理） | 代码文件 |
| `outbox/<role>/` | 结果 `.json` 消息 + 审查报告等文档 | ❌ 代码文件 |
| `work/` | 临时草稿 | 最终代码 |
| `shared/` | context.json、决策记录、编码规范 | 业务代码 |
| **你的项目目录** | ✅ 所有源代码 | — |

`payload.files` 字段指向文件的**真实路径**，接收方按路径去读：

## 消息生命周期

```
[发送方]                    [文件系统]                    [接收方]
   |                           |                           |
   |-- 写入 .msg.json -------->|                           |
   |   (inbox/<to>/msg-xxx)    |                           |
   |                           |<-- 读取并重命名为 .processing
   |                           |                           |
   |                           |             处理完成后写入 .done
   |                           |                           |
   |<-- 读取 outbox/ ----------|<-- 写入结果
   |    (outbox/msg-xxx-result.json)
```

## 文件命名规范

| 阶段 | 文件名 | 位置 |
|------|--------|------|
| 待处理 | `msg-{timestamp}-{id}.msg.json` | `inbox/<role>/` |
| 处理中 | `msg-{timestamp}-{id}.processing` | `inbox/<role>/` |
| 已完成 | `msg-{timestamp}-{id}.done` | `inbox/<role>/` |
| 结果 | `msg-{replyTo}-result.json` | `outbox/` |

## 会话例行检查

每个 Claude Code 会话启动时应声明角色并以该角色身份工作：

```
我是 [角色名]，现在开始工作会话。
请先检查 inbox/<我的角色>/ 下是否有待处理消息。
```

### 检查命令模板
```bash
# 检查收件箱
ls "D:/work/claude code/AgentTeams/inbox/<role>/"*.msg.json 2>/dev/null

# 读取并开始处理第一条消息
# 将 .msg.json 重命名为 .processing 标记为处理中
```

## 上下文共享

`shared/context.json` 用于共享项目状态：
```json
{
  "project": "项目名称",
  "language": "Go",
  "framework": "Gin",
  "database": "PostgreSQL 16",
  "currentBranch": "feature/jwt-auth",
  "activeTask": "实现JWT认证",
  "decisions": ["shared/decisions/001-database-choice.md"],
  "conventions": ["shared/conventions/code-style.md"]
}
```

## 决策记录

重大技术决策写入 `shared/decisions/`，格式：
```markdown
# 决策 #001: 数据库选型

- **日期**: 2026-05-11
- **决策者**: Architect
- **选项**: PostgreSQL vs MySQL vs MongoDB
- **选择**: PostgreSQL 16
- **理由**: 需要 JSONB 支持、更好的全文搜索、与现有运维工具链兼容
```

## 通信礼仪

- 收到 TASK 后，先回复确认（ACK：`"收到任务，预计 X 小时完成"`）
- 遇到阻塞时发送 ALERT，不要沉默等待
- 完成工作后立即发送 RESULT，附上产出文件路径
- QUERY 类消息期望 1 小时内回复
- 每个会话结束时发送 SYNC 更新当前状态
