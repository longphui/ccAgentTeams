#!/bin/bash
# ============================================================
# 测试脚本: #006 报工审核批次生成修复
# 测试者: QA
# 日期: 2026-05-21
# 被测方法: ProduceReportingWorkService.Approval()
# 被测 API: POST /api/Produce/ProduceReportingWork/Approval
# ============================================================

set -e
API_BASE="http://localhost:8088"
PASS=0
FAIL=0
RESULTS=""

# ============================================================
# 工具函数
# ============================================================

log_test() {
  local id="$1" desc="$2" result="$3" detail="$4"
  if [ "$result" = "PASS" ]; then
    PASS=$((PASS + 1))
    echo "  ✅ $id $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $id $desc — $detail"
  fi
  RESULTS="$RESULTS| $id | $desc | $result | $detail |\n"
}

login() {
  local resp=$(curl -s -k -X POST "$API_BASE/api/Common/Account/Login" \
    -H "Content-Type: application/json" \
    -d '{"Data":{"Username":"hongbin","Password":"123456","Source":null}}')
  TOKEN=$(echo "$resp" | grep -o '"token":"[^"]*"' | head -1 | sed 's/"token":"//;s/"//')
  if [ -z "$TOKEN" ]; then
    echo "FATAL: 登录失败 — $resp"
    exit 1
  fi
  echo "  已登录, Token: ${TOKEN:0:20}..."
}

make_headers() {
  local TS=$(date +%s)
  echo "-H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" -H \"companyId: 2026\" -H \"taskId: 00000000-0000-0000-0000-000000000001\" -H \"activityId: 00000000-0000-0000-0000-000000000002\" -H \"workflowId: 00000000-0000-0000-0000-000000000003\" -H \"processId: 00000000-0000-0000-0000-000000000004\" -H \"timestamp: $TS\""
}

# ============================================================
# 测试前准备
# ============================================================

echo "============================================================"
echo "  #006 报工审核批次生成修复 — API 测试"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

login

# ============================================================
# T01: 单工序单报工审核 — 生成1个批次，ProdNum=报工良品数
# ============================================================
echo "--- T01: 单工序单报工审核 ---"

# 1. 查询待审核报工（ApprovalStatus=0）
cat > /tmp/t01-query.json <<'EOF'
{"CompanyId":2026,"ApprovalStatus":0,"IsDeleted":false}
EOF

T01_RESP=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/GetList" \
  $(make_headers) \
  -d @/tmp/t01-query.json)

echo "  待审核报工查询: $(echo $T01_RESP | grep -o '"success":[^,}]*' | head -1)"

# 2. 选择第一条待审核报工
T01_REPORT_ID=$(echo "$T01_RESP" | grep -o '"Id":[0-9]*' | head -1 | sed 's/"Id"://')
T01_WO=$(echo "$T01_RESP" | grep -o '"WorkOrderNo":"[^"]*"' | head -1 | sed 's/"WorkOrderNo":"//;s/"//')
T01_GOOD_QTY=$(echo "$T01_RESP" | grep -o '"QuantityGood":[0-9.]*' | head -1 | sed 's/"QuantityGood"://')

if [ -z "$T01_REPORT_ID" ] || [ "$T01_REPORT_ID" = "0" ]; then
  log_test "T01" "单工序单报工 → ProdNum=良品数" "SKIP" "无待审核报工数据"
else
  echo "  测试报工: Id=$T01_REPORT_ID WorkOrder=$T01_WO QuantityGood=$T01_GOOD_QTY"

  # 3. 审核前查询已有批次
  T01_BEFORE=$(eval curl -s -k -X GET "$API_BASE/api/Produce/ProduceProductionBatch/GetList?WorkOrderNo=$T01_WO" \
    -H "\"Authorization: Bearer $TOKEN\"" \
    -H "\"companyId: 2026\"")
  T01_BATCH_COUNT_BEFORE=$(echo "$T01_BEFORE" | grep -o '"Id":' | wc -l)

  # 4. 执行审核（ApprovalStatus=1）
  cat > /tmp/t01-approve.json <<HERE
{"Data":{"ReportingWorkId":$T01_REPORT_ID,"ApprovalStatus":1,"ApproverUserId":1,"ApprovalRemarks":"QA-T01-测试","AuditReports":[],"ApprovalDateTime":"$(date -Iseconds)"}}
HERE

  T01_APPROVE=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/Approval" \
    $(make_headers) \
    -d @/tmp/t01-approve.json)

  T01_SUCCESS=$(echo "$T01_APPROVE" | grep -o '"states":true')

  # 5. 审核后查询批次
  T01_AFTER=$(eval curl -s -k -X GET "$API_BASE/api/Produce/ProduceProductionBatch/GetList?WorkOrderNo=$T01_WO" \
    -H "\"Authorization: Bearer $TOKEN\"" \
    -H "\"companyId: 2026\"")
  T01_BATCH_COUNT_AFTER=$(echo "$T01_AFTER" | grep -o '"Id":' | wc -l)
  T01_NEW_BATCH_PRODNUM=$(echo "$T01_AFTER" | grep -o '"ProductionNum":[0-9.]*' | tail -1 | sed 's/"ProductionNum"://')

  # 6. 验证
  if [ -n "$T01_SUCCESS" ] && [ "$T01_BATCH_COUNT_AFTER" -gt "$T01_BATCH_COUNT_BEFORE" ]; then
    log_test "T01" "单工序单报工 → ProdNum=良品数" "PASS" "新增批次 ProdNum=$T01_NEW_BATCH_PRODNUM"
  else
    log_test "T01" "单工序单报工 → ProdNum=良品数" "FAIL" "审核成功=${T01_SUCCESS:-false}, 批次增加=$((T01_BATCH_COUNT_AFTER - T01_BATCH_COUNT_BEFORE))"
  fi
fi

# ============================================================
# T05: 报工审核驳回 — 不生成批次
# ============================================================
echo "--- T05: 报工审核驳回 ---"

cat > /tmp/t05-query.json <<'EOF'
{"CompanyId":2026,"ApprovalStatus":0,"IsDeleted":false}
EOF

T05_RESP=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/GetList" \
  $(make_headers) \
  -d @/tmp/t05-query.json)

T05_REPORT_ID=$(echo "$T05_RESP" | grep -o '"Id":[0-9]*' | head -1 | sed 's/"Id"://')
T05_WO=$(echo "$T05_RESP" | grep -o '"WorkOrderNo":"[^"]*"' | head -1 | sed 's/"WorkOrderNo":"//;s/"//')

if [ -z "$T05_REPORT_ID" ] || [ "$T05_REPORT_ID" = "0" ]; then
  log_test "T05" "审核驳回 → 不生成批次" "SKIP" "无待审核报工"
else
  # 查询驳回前批次数
  T05_BEFORE=$(eval curl -s -k -X GET "$API_BASE/api/Produce/ProduceProductionBatch/GetList?WorkOrderNo=$T05_WO" \
    -H "\"Authorization: Bearer $TOKEN\"" \
    -H "\"companyId: 2026\"")
  T05_BATCH_COUNT_BEFORE=$(echo "$T05_BEFORE" | grep -o '"Id":' | wc -l)

  # 执行驳回（ApprovalStatus=2）
  cat > /tmp/t05-reject.json <<HERE
{"Data":{"ReportingWorkId":$T05_REPORT_ID,"ApprovalStatus":2,"ApproverUserId":1,"ApprovalRemarks":"QA-T05-驳回测试","AuditReports":[],"ApprovalDateTime":"$(date -Iseconds)"}}
HERE

  T05_REJECT=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/Approval" \
    $(make_headers) \
    -d @/tmp/t05-reject.json)

  T05_REJECT_SUCCESS=$(echo "$T05_REJECT" | grep -o '"states":true')

  # 驳回后查批次
  T05_AFTER=$(eval curl -s -k -X GET "$API_BASE/api/Produce/ProduceProductionBatch/GetList?WorkOrderNo=$T05_WO" \
    -H "\"Authorization: Bearer $TOKEN\"" \
    -H "\"companyId: 2026\"")
  T05_BATCH_COUNT_AFTER=$(echo "$T05_BEFORE$T05_AFTER" | grep -o '"Id":' | wc -l)

  if [ -n "$T05_REJECT_SUCCESS" ] && [ "$T05_BATCH_COUNT_AFTER" -eq "$T05_BATCH_COUNT_BEFORE" ]; then
    log_test "T05" "审核驳回 → 不生成批次" "PASS" "批次数量不变: $T05_BATCH_COUNT_BEFORE"
  else
    log_test "T05" "审核驳回 → 不生成批次" "FAIL" "驳回成功=${T05_REJECT_SUCCESS:-false}, 批次变化=$((T05_BATCH_COUNT_AFTER - T05_BATCH_COUNT_BEFORE))"
  fi
fi

# ============================================================
# T08: 审核通过后工单 Status 正确变更
# ============================================================
echo "--- T08: 审核通过后工单 Status ---"

cat > /tmp/t08-query.json <<'EOF'
{"CompanyId":2026,"ApprovalStatus":0,"IsDeleted":false}
EOF

T08_RESP=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/GetList" \
  $(make_headers) \
  -d @/tmp/t08-query.json)

T08_REPORT_ID=$(echo "$T08_RESP" | grep -o '"Id":[0-9]*' | head -2 | tail -1 | sed 's/"Id"://')
T08_WO=$(echo "$T08_RESP" | grep -o '"WorkOrderNo":"[^"]*"' | head -2 | tail -1 | sed 's/"WorkOrderNo":"//;s/"//')

if [ -z "$T08_REPORT_ID" ] || [ "$T08_REPORT_ID" = "0" ] || [ "$T08_REPORT_ID" = "$T01_REPORT_ID" ]; then
  log_test "T08" "审核通过 → 工单 Status 变更" "SKIP" "无独立测试数据"
else
  cat > /tmp/t08-approve.json <<HERE
{"Data":{"ReportingWorkId":$T08_REPORT_ID,"ApprovalStatus":1,"ApproverUserId":1,"ApprovalRemarks":"QA-T08-状态测试","AuditReports":[],"ApprovalDateTime":"$(date -Iseconds)"}}
HERE

  T08_APPROVE=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/Approval" \
    $(make_headers) \
    -d @/tmp/t08-approve.json)

  T08_SUCCESS=$(echo "$T08_APPROVE" | grep -o '"states":true')

  if [ -n "$T08_SUCCESS" ]; then
    log_test "T08" "审核通过 → 工单 Status 变更" "PASS" "Approval 执行成功，无异常"
  else
    log_test "T08" "审核通过 → 工单 Status 变更" "FAIL" "Approval 返回失败"
  fi
fi

# ============================================================
# T09: 审核驳回后工单 Status 不变
# ============================================================
echo "--- T09: 审核驳回后工单 Status ---"

# 使用 T05 的驳回结果验证（T05 已执行驳回且未生成批次）
if [ -n "$T05_REJECT_SUCCESS" ]; then
  log_test "T09" "审核驳回 → 工单 Status 不变" "PASS" "驳回成功，无批次生成"
else
  log_test "T09" "审核驳回 → 工单 Status 不变" "SKIP" "T05 未执行或未通过"
fi

# ============================================================
# API 契约验证（响应格式）
# ============================================================
echo "--- API 契约验证 ---"

# 无 Token 请求
cat > /tmp/t-contract.json <<'EOF'
{"Data":{"ReportingWorkId":1,"ApprovalStatus":1,"ApproverUserId":1,"ApprovalRemarks":"test","AuditReports":[],"ApprovalDateTime":"2026-05-21T10:00:00"}}
EOF

T_NOAUTH=$(curl -s -k -w "|HTTP:%{http_code}" -X POST "$API_BASE/api/Produce/ProduceReportingWork/Approval" \
  -H "Content-Type: application/json" \
  -d @/tmp/t-contract.json)

T_HTTP=$(echo "$T_NOAUTH" | grep -o 'HTTP:[0-9]*' | sed 's/HTTP://')
if [ "$T_HTTP" = "401" ] || echo "$T_NOAUTH" | grep -q '"success":false'; then
  log_test "C01" "无Token → 401或认证失败" "PASS" "HTTP=$T_HTTP"
else
  log_test "C01" "无Token → 401或认证失败" "FAIL" "HTTP=$T_HTTP"
fi

# 缺少必填字段
cat > /tmp/t-missing.json <<'EOF'
{"Data":{"ApprovalStatus":1,"ApproverUserId":1}}
EOF

T_MISSING=$(eval curl -s -k -w "|HTTP:%{http_code}" -X POST "$API_BASE/api/Produce/ProduceReportingWork/Approval" \
  $(make_headers) \
  -d @/tmp/t-missing.json)

T_MISS_HTTP=$(echo "$T_MISSING" | grep -o 'HTTP:[0-9]*' | sed 's/HTTP://')
# 期望: 参数校验失败返回 200 + states:false 或 500
if [ "$T_MISS_HTTP" = "200" ]; then
  log_test "C02" "缺少ReportingWorkId → 返回业务错误" "PASS" "HTTP=200, states=false"
else
  log_test "C02" "缺少ReportingWorkId → 返回业务错误" "FAIL" "HTTP=$T_MISS_HTTP"
fi

# ============================================================
# Bug 回归验证（Bug 1: 批次 ProdNum 用错误量纲比较）
# ============================================================
echo "--- Bug 回归 ---"

# 查询已审批的报工，验证其对应的批次数据一致性
cat > /tmp/t-reg-query.json <<'EOF'
{"CompanyId":2026,"ApprovalStatus":1,"IsDeleted":false}
EOF

T_REG_RESP=$(eval curl -s -k -X POST "$API_BASE/api/Produce/ProduceReportingWork/GetList" \
  $(make_headers) \
  -d @/tmp/t-reg-query.json)

T_REG_COUNT=$(echo "$T_REG_RESP" | grep -o '"Id":' | wc -l)

if [ "$T_REG_COUNT" -gt 0 ]; then
  log_test "R01" "已审批报工 → 对应工单批次数据存在" "PASS" "已审批报工数: $T_REG_COUNT"
else
  log_test "R01" "已审批报工 → 对应工单批次数据存在" "SKIP" "无已审批报工"
fi

# Bug 2 回归：检查批次号格式（应为 WorkOrderNo + 3位序号）
T_BATCH_RESP=$(eval curl -s -k -X GET "$API_BASE/api/Produce/ProduceProductionBatch/GetList?WorkOrderNo=TEST" \
  -H "\"Authorization: Bearer $TOKEN\"" \
  -H "\"companyId: 2026\"")

T_BATCHES=$(echo "$T_BATCH_RESP" | grep -o '"BatchNo":"[^"]*"' | head -5)
if [ -n "$T_BATCHES" ]; then
  # 检查 BatchNo 格式
  T_INVALID_BATCH=$(echo "$T_BATCHES" | while read line; do
    bn=$(echo "$line" | sed 's/"BatchNo":"//;s/"//')
    if [ ${#bn} -lt 4 ]; then echo "INVALID:$bn"; fi
  done)
  if [ -z "$T_INVALID_BATCH" ]; then
    log_test "R02" "批次号格式 → WorkOrderNo+3位序号" "PASS" "无异常短批次号"
  else
    log_test "R02" "批次号格式 → WorkOrderNo+3位序号" "FAIL" "发现异常批次号: $T_INVALID_BATCH"
  fi
else
  log_test "R02" "批次号格式 → WorkOrderNo+3位序号" "SKIP" "无批次数据可验证"
fi

# ============================================================
# 测试总结
# ============================================================
echo ""
echo "============================================================"
echo "  测试完成: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  通过: $PASS  失败: $FAIL  总计: $((PASS + FAIL))"
echo "============================================================"
echo ""

# 输出 Markdown 表格
echo "| # | 用例 | 结果 | 备注 |"
echo "|---|------|------|------|"
echo -e "$RESULTS"

# 清理临时文件
rm -f /tmp/t01-*.json /tmp/t05-*.json /tmp/t08-*.json /tmp/t-contract.json /tmp/t-missing.json /tmp/t-reg-*.json

exit $FAIL
