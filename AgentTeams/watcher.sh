#!/bin/bash
# AgentTeams 收件箱监控器
# 用途: 监控各角色收件箱，发现新消息时通知用户触发对应角色
# 用法: 在单独终端窗口运行  bash watcher.sh

TEAMS_DIR="$(cd "$(dirname "$0")" && pwd)"
SEEN_FILE="$TEAMS_DIR/watcher/seen.txt"
POLL_INTERVAL=3  # 轮询间隔（秒）

mkdir -p "$TEAMS_DIR/watcher"

# 角色 → 对应 agent 命令
declare -A ROLE_CMD=(
    ["developer"]="/agent-developer"
    ["developer1"]="/agent-developer1"
    ["reviewer"]="/agent-reviewer"
    ["qa"]="/agent-qa"
    ["architect"]="/agent-architect"
)

declare -A ROLE_NAME=(
    ["developer"]="Developer (后端)"
    ["developer1"]="Developer1 (前端)"
    ["reviewer"]="Reviewer (审查)"
    ["qa"]="QA (测试)"
    ["architect"]="Architect (架构师)"
)

echo "============================================"
echo "  AgentTeams 收件箱监控器"
echo "  每 ${POLL_INTERVAL}s 扫描一次"
echo "  按 Ctrl+C 停止"
echo "============================================"
echo ""

touch "$SEEN_FILE"

while true; do
    for role_dir in "$TEAMS_DIR/inbox/"*; do
        role=$(basename "$role_dir")
        [[ -z "${ROLE_CMD[$role]}" ]] && continue

        for msg in "$role_dir"/*.msg.json 2>/dev/null; do
            [[ ! -f "$msg" ]] && continue
            msg_name=$(basename "$msg")

            # 已通知过的跳过
            if grep -qxF "$msg_name" "$SEEN_FILE" 2>/dev/null; then
                continue
            fi

            # 读取消息类型和主题（简单解析，不依赖 jq）
            msg_type=$(grep -oP '"type"\s*:\s*"\K[^"]+' "$msg" 2>/dev/null | head -1)
            msg_subject=$(grep -oP '"subject"\s*:\s*"\K[^"]+' "$msg" 2>/dev/null | head -1)
            msg_from=$(grep -oP '"from"\s*:\s*"\K[^"]+' "$msg" 2>/dev/null | head -1)

            # 新消息！
            echo ""
            echo "┌──────────────────────────────────────────┐"
            echo "│  📬 ${ROLE_NAME[$role]} 收到新消息"
            echo "├──────────────────────────────────────────┤"
            echo "│  来自: $msg_from"
            echo "│  类型: $msg_type"
            echo "│  主题: $msg_subject"
            echo "│  文件: $msg_name"
            echo "├──────────────────────────────────────────┤"
            echo "│  👉 请在新窗口执行: ${ROLE_CMD[$role]}"
            echo "└──────────────────────────────────────────┘"
            echo ""

            # 标记为已通知
            echo "$msg_name" >> "$SEEN_FILE"
        done
    done

    sleep "$POLL_INTERVAL"
done
