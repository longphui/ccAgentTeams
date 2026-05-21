# 测试计划: #006 报工审核批次生成修复

- **测试者**: QA
- **日期**: 2026-05-21
- **被测方法**: `ProduceReportingWorkService.Approval()`
- **被测 API**: `POST /api/Produce/ProduceReportingWork/Approval`
- **测试脚本**: `AgentTeams/logs/test-006-approval-batch.sh`
- **状态**: ⏳ 测试用例已编写，等待 Developer 修复完成后执行

---

## 测试范围

| Bug | 严重度 | 测试方法 |
|-----|--------|---------|
| Bug 1: ProductionNum 计算错误 | critical | T01~T04, R01 |
| Bug 2: 批次号 Substring 越界 | medium | R02 |
| Bug 3: maxStepNum 死代码 | minor | 编译验证（Developer 负责） |

---

## 测试用例列表

### 功能验证

| # | 用例名称 | 场景 | 预期结果 |
|---|---------|------|---------|
| T01 | 单工序单报工审核 | 1 笔报工（QuantityGood=30），ApprovalStatus=1 | 生成 1 个批次，ProductionNum=报工良品数 |
| T02 | 多工序全部完成（需多工序数据） | 工单计划100，各工序均完成 | 批次累计 = 100 |
| T03 | 多工序先后审核（需多工序数据） | 工序A先审核，工序B后审核 | 工序不全时不生成批次，全到后=Min |
| T04 | 追加报工增量（需历史批次数据） | 已有批次30，新审核达成80 | 新批次 ProdNum=50 |
| T05 | 报工审核驳回 | ApprovalStatus=2 | 不生成批次，批次表无新增 |

### API 契约

| # | 用例名称 | 场景 | 预期结果 |
|---|---------|------|---------|
| C01 | 无 Token 请求 | 不带 Authorization header | 401 或 success:false |
| C02 | 缺少必填字段 | 不带 ReportingWorkId | 返回业务错误 |

### 回归

| # | 用例名称 | 场景 | 预期结果 |
|---|---------|------|---------|
| R01 | 已审批报工批次验证 | 查询已审批报工对应批次 | 批次数据存在且一致 |
| R02 | 批次号格式 | 检查 BatchNo 长度 | >= 4 字符，无越界风险 |
| T08 | 审核通过工单状态 | ApprovalStatus=1 | 工单 Status 正常变更 |
| T09 | 审核驳回工单状态 | ApprovalStatus=2 | 工单 Status 不变 |

---

## 执行步骤

1. `bash AgentTeams/logs/test-006-approval-batch.sh`
2. 若失败，检查 API 日志 `App_Data/Logs/` 确认根因
3. 通过后输出测试报告

## T02~T04 手动补充说明

T02/T03/T04 涉及多工序场景，脚本中未自动化（需特定测试工单数据），将在 Developer 修复后通过以下方式手动验证：

```
T02: 查询一个含2道工序的工单，确认两道工序各有一笔报工 → 审核两者 → 批次累计 == 计划产量
T03: 先审核工序A的报工（此时工序B无数据 Min=0）→ 不应生成批次 → 再审核工序B → 批次=Min(B.CompletedQuantity)
T04: 已有一批30的批次 → 继续审核直到 Min=80 → 新批次 ProdNum=50
```

## 验证要点（基于分析报告场景）

工单计划产量 100，切割+组装两道工序：

| 审核顺序 | 切割累计 | 组装累计 | Min | 预期批次 |
|----------|---------|---------|-----|---------|
| 1st(切割30) | 30 | 0 | 0 | 无 |
| 2nd(组装30) | 30 | 30 | 30 | Batch#1 ProdNum=30 |
| 3rd(切割50) | 80 | 30 | 30 | 无 (≤已批次) |
| 4th(组装50) | 80 | 80 | 80 | Batch#2 ProdNum=50 |
| 5th(切割20) | 100 | 80 | 80 | 无 |
| 6th(组装20) | 100 | 100 | 100 | Batch#3 ProdNum=20 |

批次累计 30+50+20=100 = 计划产量 ✓
