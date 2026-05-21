---
description: 轻量触发器 — 检查触发信号文件，有信号才启动对应 agent（配合 /loop 使用）
argument-hint: <role>
allowed-tools: [Bash, Skill]
---

# Agent Trigger — 轻量触发器

检查 `watcher/trigger-{role}.txt` 是否存在：
- **存在** → 删除信号文件，启动对应 agent
- **不存在** → 静默退出（/loop 下一轮继续）

## 角色映射

| 参数 | 信号文件 | 启动 Skill |
|------|---------|-----------|
| `developer` 或 `/agent-developer` | `watcher/trigger-developer.txt` | `agent-developer` |
| `developer1` 或 `/agent-developer1` | `watcher/trigger-developer1.txt` | `agent-developer1` |
| `reviewer` 或 `/agent-reviewer` | `watcher/trigger-reviewer.txt` | `agent-reviewer` |
| `qa` 或 `/agent-qa` | `watcher/trigger-qa.txt` | `agent-qa` |
| `architect` 或 `/agent-architect` | `watcher/trigger-architect.txt` | `agent-architect` |

## 执行步骤

### Step 1：解析参数，确定角色

从用户参数中提取角色名（如 `/agent-trigger developer1` → `developer1`）。

### Step 2：检查信号文件

```bash
ls "D:/work/cc/AgentTeams/watcher/trigger-{role}.txt" 2>/dev/null
```

### Step 3：有信号 → 启动 Agent

如果文件存在：

```bash
rm "D:/work/cc/AgentTeams/watcher/trigger-{role}.txt"
```

然后调用 Skill 工具启动对应 agent，**不传参数**。

### Step 4：无信号 → 静默退出

不做任何事，不输出任何内容。

## 硬规则

- 🔴 不读文件内容，只检查文件是否存在
- 🔴 有信号必须先删文件再启动 agent（防止重复触发）
- 🔴 无信号时绝对安静，不输出任何文字
- 🔴 不检查 inbox，不看消息，只看 trigger 文件
