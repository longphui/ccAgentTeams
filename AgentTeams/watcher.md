# AgentTeams 自动协作机制

采用 **trigger 信号 + /loop 检测** 实现角色间自动接力，无需手动触发。

---

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│                      用户启动（一次性）                        │
│                                                              │
│  窗口 1: /loop 5s /agent-trigger developer1                  │
│  窗口 2: /loop 5s /agent-trigger reviewer                    │
│  窗口 3: /loop 5s /agent-trigger qa                          │
│  窗口 4: /loop 5s /agent-trigger developer                   │
│  窗口 5: /loop 5s /agent-trigger architect                   │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  /agent-trigger 检查 watcher/trigger-{role}.txt              │
│                                                              │
│  有文件 → 删除 → 启动 agent                                   │
│  无文件 → 静默跳过 (/loop 下一轮继续)                          │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  Agent 处理完消息后 → 写 watcher/trigger-{下游角色}.txt       │
│                                                              │
│  Developer1 完成 → 写 trigger-reviewer.txt                   │
│  Reviewer 完成   → 写 trigger-developer1.txt                 │
│  QA 完成        → 写 trigger-architect.txt                  │
│  Architect 分派  → 写 trigger-developer.txt                   │
└──────────────────────────────────────────────────────────────┘
```

## 使用方法

### 1. 启动监控窗口（每个角色一个窗口，只需启动一次）

```
窗口 1: /loop 5s /agent-trigger developer1
窗口 2: /loop 5s /agent-trigger reviewer
窗口 3: /loop 5s /agent-trigger qa
窗口 4: /loop 5s /agent-trigger developer
窗口 5: /loop 5s /agent-trigger architect
```

每个窗口独立运行，互不干扰。

### 2. 启动工作流

在 architect 窗口中输入任务描述，或手动在任意窗口中断 loop 并执行 `/agent-architect`。

Architect 分派任务 → 写 trigger 文件 → 对应 agent 窗口检测到 → 自动启动。

### 3. 自动接力示例

```
Architect 分派 TASK 给 Developer1
  → 写 trigger-developer1.txt
  → 窗口1 /agent-trigger 检测到 → 启动 Developer1
  
Developer1 编码完成 → 发 REVIEW 给 Reviewer
  → 写 trigger-reviewer.txt
  → 窗口2 /agent-trigger 检测到 → 启动 Reviewer
  
Reviewer 审查通过 → 发 RESULT 给 Developer1
  → 写 trigger-developer1.txt
  → 窗口1 /agent-trigger 检测到 → 启动 Developer1
  
Developer1 → 发 TEST 给 QA
  → 写 trigger-qa.txt
  → 窗口3 /agent-trigger 检测到 → 启动 QA
  
QA 测试通过 → 发 RESULT 给 Architect
  → 写 trigger-architect.txt
  → 窗口5 /agent-trigger 检测到 → 启动 Architect
```

全程无需手动触发，各窗口自动接力。

## Trigger 文件说明

| 文件 | 触发角色 | 由谁创建 |
|------|---------|---------|
| `watcher/trigger-developer.txt` | Developer (后端) | Architect、Reviewer、QA |
| `watcher/trigger-developer1.txt` | Developer1 (前端) | Architect、Reviewer、QA |
| `watcher/trigger-reviewer.txt` | Reviewer (审查) | Developer、Developer1 |
| `watcher/trigger-qa.txt` | QA (测试) | Developer、Developer1 |
| `watcher/trigger-architect.txt` | Architect (架构师) | Developer、Developer1、Reviewer、QA |

Trigger 文件为空文件，只用来做信号检测。`/agent-trigger` 检测到后立即删除（防止重复触发）。

## 对比旧方案

| | /loop + /agent-trigger | watcher.sh | 手动触发 |
|------|------|------|------|
| 自动接力 | ✅ | ❌ (只通知) | ❌ |
| 上下文隔离 | ✅ (各窗口) | ✅ | ✅ |
| 无空转消耗 | ✅ (只检查文件) | ✅ | - |
| 需要用户操作 | 仅启动时 | 每次都要手动 | 每次都要手动 |

## 备用：watcher.sh 终端脚本

```bash
bash watcher.sh
```

在 Git Bash 终端中运行，监控所有角色收件箱并打印通知。不自动触发 agent，仅用于调试。
