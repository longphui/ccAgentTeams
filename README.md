# Agent Teams — AI 开发团队协作系统

基于 Claude Code 的多角色协作开发系统，通过文件收件箱 + 自动 trigger/loop 实现无人值守接力。

## 环境要求

- **Claude Code** CLI（需登录 Anthropic 账号）
- **Windows Terminal**（用于 5 格布局一键启动）
- **Git Bash**（部分脚本使用 bash 命令）

> **迁移注意**：所有配置文件中硬编码了绝对路径 `D:\work\cc`。克隆到其他机器时**必须**放在 `D:\work\cc` 目录下，否则启动脚本和 skill 文件中的全部路径失效。

## 目录结构

```
D:\work\cc\
├── .claude\
│   ├── commands/              # 角色 Skill 定义（agent-*.md）
│   └── settings.local.json    # 权限白名单
├── AgentTeams/                # 通信中枢
│   ├── inbox/                 # 📥 收件箱
│   │   ├── architect/
│   │   ├── developer/
│   │   ├── developer1/
│   │   ├── reviewer/
│   │   └── qa/
│   ├── outbox/                # 📤 发件箱（同上 5 个角色）
│   ├── archive/               # 🗄️ 已完成消息归档（同上 5 个角色）
│   ├── watcher/               # 🔔 trigger 信号文件 + seen 记录
│   ├── shared/                # 📋 共享资源
│   │   ├── context.json       #   项目上下文
│   │   ├── requirements/      #   需求文档 + 实施计划
│   │   ├── decisions/         #   架构决策记录
│   │   └── conventions/       #   编码规范
│   ├── logs/                  # 📝 编译/构建/测试日志
│   ├── start-team.ps1         # 🚀 WT 5 格布局一键启动
│   ├── start-team.bat         #    start-team.ps1 的 bat 包装
│   ├── start-{role}.bat       #    单角色独立启动
│   └── _wt-{role}.bat         #    WT 子窗口启动脚本
└── <项目仓库>/                 # 各项目代码（SVN checkout）
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

# 如果是从已有机器复制，直接拷贝以下目录到 D:\work\cc\：
#   .claude\        → Claude Code 配置
#   AgentTeams\     → 通信系统
```

项目仓库按各自方式 checkout 到 `D:\work\cc\` 下。

### 3. 适配本机环境

| 文件 | 可能需要修改 |
|------|-------------|
| `AgentTeams/start-team.ps1` | `$wt` — Windows Terminal 安装路径 |
| `.claude/settings.local.json` | 权限白名单（编译工具路径、token 等） |

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

在 `D:\work\cc` 下运行：
```powershell
AgentTeams\start-architect.bat
AgentTeams\start-developer.bat
AgentTeams\start-developer1.bat
AgentTeams\start-reviewer.bat
AgentTeams\start-qa.bat
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

## 常见问题

**Q: 角色卡在 `.processing` 不动？**
检查 `AgentTeams/watcher/trigger-{role}.txt` 是否存在。没有则手动 `echo >` 创建。

**Q: 如何停止自动循环？**
在对应终端按 `Ctrl+C` 退出 `/loop`。

**Q: 收件箱文件太多？**
各角色有自动清理机制（超过 20 个 `.done` 强制归档），也可以手动移入 `archive/`。

**Q: 如何添加新项目/新角色？**
1. 项目 checkout 到 `D:\work\cc\` 下
2. 在 `.claude/commands/` 下创建对应的规范文件
3. 更新 `shared/context.json`
4. 如需新角色，在 `.claude/commands/` 下新建 `agent-<name>.md`，并在 watcher 和 trigger 中注册
