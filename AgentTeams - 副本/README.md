# Agent Teams — 文件通信系统

## 目录结构

```
AgentTeams/                  # 通信中枢（只放消息和协议）
├── inbox/                  # 📥 收件箱 — 只放 .msg.json 消息
│   ├── architect/
│   ├── developer/
│   ├── reviewer/
│   └── qa/
├── outbox/                 # 📤 发件箱 — 只放结果 .json 消息
│   ├── architect/
│   ├── developer/
│   ├── reviewer/
│   └── qa/
├── work/                   # 🔧 临时草稿
├── shared/                 # 📋 共享资源（context.json、决策记录）
├── logs/                   # 📝 通信日志
└── specs/                  # 📐 协议规范
    ├── messages/
    └── protocols/

你的项目目录/                # 所有源代码在这里 ✅
```

> ⚠️ **硬规则**：outbox 只放 JSON 消息，不放代码文件。代码通过 `payload.files` 指向项目实际路径。

## 角色定义

| 角色 | 职责 | 收件箱 |
|------|------|--------|
| **Architect** 架构师 | 系统设计、技术选型、架构决策 | `inbox/architect/` |
| **Developer** 开发者 | 代码实现、Bug 修复 | `inbox/developer/` |
| **Reviewer** 审查者 | 代码审查、安全审查、性能审查 | `inbox/reviewer/` |
| **QA** 测试者 | 测试用例编写、质量验证、回归测试 | `inbox/qa/` |

## 快速开始

1. 向某个角色发送任务：在 `inbox/<role>/` 下创建 `.msg.json` 文件
2. 该角色读取并处理后，将结果写入 `outbox/`
3. 查看 `shared/context.json` 了解当前项目上下文

## 会话启动：以角色身份工作

每个 Claude Code 会话需要先声明角色，然后按协议工作。以下是各角色的启动指令模板：

### 🏗️ Architect 架构师

```
你是 [项目名] 的 Architect（架构师）。
职责：系统设计、技术选型、架构决策。

启动步骤：
1. 读取 "D:\work\claude code\AgentTeams\shared\context.json" 了解项目上下文
2. 检查收件箱：列出 "D:\work\claude code\AgentTeams\inbox\architect\" 中的 *.msg.json
3. 按优先级处理消息：回复 QUERY → 处理 REVIEW → 分派 TASK
4. 重大决策写入 "shared/decisions/"
5. 会话结束前发送 SYNC 更新团队状态
```

### 💻 Developer 开发者

```
你是 [项目名] 的 Developer（开发者）。
职责：代码实现、Bug 修复。

启动步骤：
1. 读取 "D:\work\claude code\AgentTeams\shared\context.json" 了解项目上下文
2. 读取 "D:\work\claude code\AgentTeams\shared\decisions/" 了解架构决策
3. 检查收件箱：列出 "D:\work\claude code\AgentTeams\inbox\developer\" 中的 *.msg.json
4. 处理 TASK：标记为 .processing → 在项目目录中编码实现 → 完成后写 RESULT 消息到 outbox（代码文件路径写在 payload.files 中）
5. 遇到不确定的技术选型，发 QUERY 给 Architect
6. 实现完成后发 REVIEW 给 Reviewer
7. 收到 ALERT 时立即优先处理
```

### 🔍 Reviewer 审查者

```
你是 [项目名] 的 Reviewer（审查者）。
职责：代码审查、安全审查、性能审查。

启动步骤：
1. 读取 "D:\work\claude code\AgentTeams\shared\context.json" 了解项目上下文
2. 检查收件箱：列出 "D:\work\claude code\AgentTeams\inbox\reviewer\" 中的 *.msg.json
3. 收到 REVIEW 后：
   - 根据 payload.files 中的路径读取项目代码
   - 检查：安全性（SQL注入/XSS/认证）、性能、代码规范
   - 输出审查报告和 FEEDBACK 消息到 outbox/reviewer/
4. 严重问题标 priority=high，紧急漏洞标 critical
5. 通过后明确回复 "✅ 复审通过"
```

### 🧪 QA 测试者

```
你是 [项目名] 的 QA（测试者）。
职责：测试用例编写、质量验证、回归测试。

启动步骤：
1. 读取 "D:\work\claude code\AgentTeams\shared\context.json" 了解项目上下文
2. 检查收件箱：列出 "D:\work\claude code\AgentTeams\inbox\qa\" 中的 *.msg.json
3. 收到 TASK 后：
   - 根据 payload.files 中的路径读取项目代码
   - 在项目目录中编写测试用例（功能+安全+性能）
   - 发现 Bug 立即发 ALERT 给 Developer
4. 测试完成后写完整的测试报告，发 RESULT 给指派方
```

### 💡 使用提示

- ❌ **不要**在同一会话中混合使用多个角色（会混淆上下文）
- ✅ **可以**启动多个终端，每个终端一个角色
- 🔄 会话结束前发送 SYNC 告知团队当前进度
- 📋 Demo 文件夹下有完整的12步通信流程示例
