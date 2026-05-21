# Agent Teams — AI 开发团队协作系统

基于 Claude Code 的多角色协作开发系统，通过文件收件箱 + 自动 trigger/loop 实现无人值守接力。

## 环境要求

- **Claude Code** CLI（需登录 Anthropic 账号）
- **Windows Terminal**（用于 5 格布局一键启动，放在 `AgentTeams/tools/terminal-*/` 下）
- **Git Bash**（部分脚本使用 bash 命令）

> **迁移注意**：所有路径统一由 `AgentTeams/env.json` 管理。迁移到新机器时**只需修改这一个文件**，无需改动任何脚本或配置。

## 目录结构

```
AgentTeams/
├── env.json                    # ⭐ 环境配置 — 所有路径的唯一真相源
├── tools/
│   └── terminal-1.25.1171.0/   # Windows Terminal（便携版）
├── inbox/                      # 📥 收件箱
│   ├── architect/
│   ├── developer/
│   ├── developer1/
│   ├── reviewer/
│   └── qa/
├── outbox/                     # 📤 发件箱（同上 5 个角色）
├── archive/                    # 🗄️ 已完成消息归档（同上 5 个角色）
├── watcher/                    # 🔔 trigger 信号文件 + seen 记录
├── shared/                     # 📋 共享资源
│   ├── context.json            #   项目上下文
│   ├── requirements/           #   需求文档 + 实施计划
│   ├── decisions/              #   架构决策记录
│   └── conventions/            #   编码规范
├── logs/                       # 📝 编译/构建/测试日志
├── start-team.ps1              # 🚀 WT 5 格布局一键启动
├── start-team.bat              #    start-team.ps1 的 bat 包装
├── start-{role}.bat            #    单角色独立启动
└── _wt-{role}.bat              #    WT 子窗口启动脚本
```

## 角色一览

| 角色 | 命令 | 职责 |
|------|------|------|
| **Architect** | `/agent-architect` | 需求分析、架构决策、任务分派 |
| **Developer** | `/agent-developer` | 后端实现、Bug 修复 |
| **Developer1** | `/agent-developer1` | 前端实现、Bug 修复 |
| **Reviewer** | `/agent-reviewer` | 代码审查、安全审查 |
| **QA** | `/agent-qa` | 浏览器验证、API 测试 |

## 快速搭建（新机器从零开始）

### 1. 创建工作目录

```powershell
mkdir D:\work\cc
cd D:\work\cc
```

### 2. 克隆团队配置 + 项目仓库

```powershell
# 团队配置（如果托管在 Git）
git clone <team-config-repo> .

# 如果是从已有机器复制，直接拷贝以下内容到 D:\work\cc\：
#   .claude\        → Claude Code 配置
#   AgentTeams\     → 通信系统
```

项目仓库按各自方式 checkout 到本地任意目录。

### 3. ⭐ 适配本机环境（只需改一个文件）

编辑 `AgentTeams/env.json`，填写本机的实际路径：

```json
{
  "agentTeams": "D:/work/cc/AgentTeams",
  "tools": {
    "terminal": "D:/work/cc/AgentTeams/tools/terminal-1.25.1171.0/wt.exe"
  },
  "projects": {
    "fenlu":      "D:/work/cc/caikuangzi.fenlu/trunk",
    "fenluWeb":   "D:/work/cc/caikuangzi.fenluwebproject/trunk",
    "honguan":    "D:/work/cc/caikuangzi01.huoguan_erp/trunk"
  }
}
```

所有启动脚本和 TASK 分派都从此文件读取路径，无需逐处修改。

### 4. 填写项目上下文

编辑 `AgentTeams/shared/context.json`，更新项目和团队状态。

### 5. 启动团队

**方式 A：Windows Terminal 5 格布局（推荐）**

双击 `AgentTeams\start-team.bat`，或在终端中：
```powershell
powershell -ExecutionPolicy Bypass -File AgentTeams/start-team.ps1
```

窗口布局如下：

```
┌────────────────────┬──────────────┬──────────────┐
│                    │  Developer   │ Developer1   │
│    Architect       │  (后端)       │  (前端)       │
│    (左边一半)       ├──────────────┼──────────────┤
│                    │  Reviewer    │    QA        │
│                    │  (审查)       │  (测试)       │
└────────────────────┴──────────────┴──────────────┘
```

- Architect 独占左半边（50%）
- 右半边 4 等分：右上 Developer + Developer1，右下 Reviewer + QA

**方式 B：单独启动某个角色**

在 `AgentTeams` 目录下运行：
```powershell
.\start-architect.bat
.\start-developer.bat
.\start-developer1.bat
.\start-reviewer.bat
.\start-qa.bat
```

每个角色启动后自动进入 `/loop 1m /agent-trigger` 模式，持续监控收件箱。

## 协作流程

```
用户 → Architect（分析需求、分派 TASK）
           │
           ├─→ Developer  inbox  → trigger → /loop 检测 → 自动启动
           └─→ Developer1 inbox  → trigger → /loop 检测 → 自动启动
                    │
                    ▼ 编码完成
              Reviewer inbox → trigger → /loop 检测 → 自动启动
                    │
                    ▼ 审查通过
              QA inbox       → trigger → /loop 检测 → 自动启动
                    │
                    ▼ 测试通过
              Architect inbox → 确认交付
```

**关键机制**：
- `/loop 1m /agent-trigger <role>` — 每分钟检查 trigger 文件，有信号就启动对应 agent
- Agent 启动后自动读 context → 检查 inbox → 处理消息 → 写结果 → 写下游 trigger
- 全程无人值守，各角色自动接力

### 消息生命周期

```
.msg.json  →  .processing  →  .done  →  archive/
（待处理）     （处理中）      （已完成）   （归档清理）
```

各角色自行归档已完成的 `.done`，超过 20 个时强制清理。

## 添加新项目

1. 项目 checkout 到本地任意目录
2. 在 `env.json` 的 `projects` 中添加项目路径映射
3. 在 `.claude/commands/` 下创建对应的规范文件
4. 更新 `shared/context.json`
5. 如需新角色，在 `.claude/commands/` 下新建 `agent-<name>.md`，并在 watcher 和 trigger 中注册

## 常见问题

**Q: 角色卡在 `.processing` 不动？**
检查 `AgentTeams/watcher/trigger-{role}.txt` 是否存在。没有则手动 `echo >` 创建。

**Q: 如何停止自动循环？**
在对应终端按 `Ctrl+C` 退出 `/loop`。

**Q: 收件箱文件太多？**
各角色有自动清理机制（超过 20 个 `.done` 强制归档），也可以手动移入 `archive/`。

**Q: 迁移到新机器怎么做？**
1. 拷贝 `.claude/` + `AgentTeams/` 到新机器
2. Clone 项目仓库到新路径
3. 修改 `AgentTeams/env.json` 中的路径
4. 运行 `start-team.bat`
