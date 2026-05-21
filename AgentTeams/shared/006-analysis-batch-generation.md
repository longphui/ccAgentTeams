# `ProduceReportingWorkService.Approval()` 方法分析报告

## 一、方法概述

`Approval()` 是报工审核方法（`ProduceReportingWorkService.cs:548-693`）。审核通过后，根据工单所有工序的完成情况，自动生成生产批次（`ProduceProductionBatch`），供后续入库使用。

**核心数据流**：报工记录（多工序、多人员）→ 审核通过 → 汇总完成量 → 生成批次 → 入库。

---

## 二、SVN 版本演进（关键）

SVN 历史揭示 Bug 是如何引入的：

### r4539（原始版本）
```csharp
// 计算各工序-任务组最小完成量
var productionNum = 0;
foreach (var item in groupByProduceTasks) {
    var completedQuantity = item.Sum(a => a.CompletedQuantity);
    if (completedQuantity == 0) { productionNum = 0; break; }
    if (productionNum > 0 && completedQuantity < productionNum) productionNum = completedQuantity;
    if (productionNum == 0) productionNum = completedQuantity;
}
if (productionNum > completedTotalNum && entity.StagesCode == maxStepNumStages.StagesCode)
{
    ProductionNum = entity.QuantityGood;  // BUG: 应为 productionNum - completedTotalNum
}
```

**状态**：`productionNum` 计算正确（各阶段最小完成量 = 通过全工序的单位数），但门禁条件限制"仅最后一道工序触发"，且 `ProductionNum` 未减去已批次数量导致重复累计。

### r4573（lh502647115, 2026-05-20）
- 注释改为"所有工序都有数据时生成批次号，不限制是否为最后一道工序"
- 但代码条件**未改**，仍为 `entity.StagesCode == maxStepNumStages.StagesCode`（注释与代码矛盾）
- 加了 `//ProductionNum = productionNum - completedTotalNum` 注释行但实际仍用 `entity.QuantityGood`

### r4578（15289876461, 2026-05-21，当前最新）
- 移除了最后一道工序限制 ✓
- **删除了 `productionNum` 计算逻辑** ✗（核心错误）
- 改为 `ProductionNum = entity.QuantityGood - completedTotalNum`（不可比的两类量做减法）

---

## 三、已识别 Bug

### Bug 1（严重）：批次 ProductionNum 用单条报工量 vs 累计批次做比较

**位置**: 第 634 / 651 行。r4578 删除了 `productionNum`（各阶段最小完成量），改用单条 `entity.QuantityGood`。

**问题**：`entity.QuantityGood`（单条报工良品）与 `completedTotalNum`（累计批次总量）属于不同量纲，不可比较/相减。

**复现场景**（工单计划产量 100，两道工序各有 1 个报工）：

| 审核顺序 | 报工良品 | 累计批次 | 条件判断 | 批次产出 | 批次累计 |
|----------|---------|---------|---------|---------|---------|
| 第1笔审核 | 30 | 0 | 30>0 ✓ | ProdNum=30 | **30** |
| 第2笔审核 | 25 | 30 | **25>30 ✗** | **无批次** | 30 |
| 第3笔审核 | 55 | 30 | 55>30 ✓ | ProdNum=25 | **55** |

> 审核通过 30+25+55=110 单位，批次仅累计 55，差距 55。入库时严重短缺。

### Bug 2（中等）：批次号 `Substring` 越界风险

**位置**: 第 639 行 `BatchNo.Substring(BatchNo.Length - 3, 3)`

若数据库中存在长度 < 3 的 BatchNo（如 `"A1"`），抛出 `ArgumentOutOfRangeException`，整个审核回滚。

### Bug 3（轻微）：`maxStepNumStages` 死代码

**位置**: 第 622-623 行。r4573 中用于限制"仅最后工序触发"，r4578 移除限制后该变量不再使用。

---

## 四、优化方案

**核心思想**：恢复 r4539 中正确的 `productionNum` 计算（各工序-任务组最小完成量 = 通过全流程的单位数），结合 r4578 的"不限最后工序"改进，修正 ProductionNum 为增量差额。

```csharp
var groupByProduceTasks = produceTasks.GroupBy(a => new { a.CompanyId, a.ProductId, a.StagesCode, a.StagesTaskCode });
if (groupByProduceTasks.Count() >= workOrderStagesCount)
{
    // 计算各阶段最小完成量（通过所有工序的单位数）
    var productionNum = groupByProduceTasks.Min(g => g.Sum(a => a.CompletedQuantity));

    var isCompleted = productionNum >= produceWorkOrder.PlannedProductionNum;

    // 查询已生成批次合计
    decimal alreadyBatched = 0;
    var batches = _context.ProduceProductionBatchs
        .Where(a => a.CompanyId == entity.CompanyId
            && a.WorkOrderNo == entity.WorkOrderNo
            && (a.Status == 2 || a.Status == 3))
        .ToList();
    if (batches.Count > 0) alreadyBatched = batches.Sum(a => a.ProductionNum);

    // 差额 > 0 才生成新批次
    if (productionNum > alreadyBatched)
    {
        var seq = (batches.Count + 1).ToString().PadLeft(3, '0');
        var newBatchNo = entity.WorkOrderNo + seq;

        var produceProductionBatch = new ProduceProductionBatch
        {
            CompanyId = entity.CompanyId,
            CompanyName = _context.Companies.FirstOrDefault(a => a.Id == entity.CompanyId)?.CompanyName,
            WorkOrderNo = entity.WorkOrderNo,
            BatchNo = newBatchNo,
            ProductionNum = productionNum - alreadyBatched,
            Status = 2,
            TaskId = entity.TaskId,
            ProcessId = entity.ProcessId,
            CreationTime = input.ApprovalDateTime ?? DateTime.Now,
            LastModificationTime = input.ApprovalDateTime ?? DateTime.Now,
        };
        _context.ProduceProductionBatchs.Add(produceProductionBatch);
    }

    if (isCompleted)
    {
        produceWorkOrder.Status = 2;
        produceWorkOrder.ActualEntTime = input.ApprovalDateTime ?? DateTime.Now;
        produceWorkOrder.LastModificationTime = input.ApprovalDateTime ?? DateTime.Now;
        produceWorkOrder.LastModificationUserId = input.ApproverUserId;
        produceWorkOrder.LastModificationUserName = companyAccount?.UserName;
        _context.ProduceWorkOrders.AddOrUpdate(produceWorkOrder);
    }
}
```

### 关键变更点

| 变更 | 当前 r4578 | 优化后 | 理由 |
|------|-----------|--------|------|
| 完成量计算 | 无（已删除） | `groupByProduceTasks.Min(g => g.Sum(CompletedQuantity))` | 恢复 r4539 逻辑，取各阶段最小完成量 |
| 比较条件 | `entity.QuantityGood > completedTotalNum` | `productionNum > alreadyBatched` | 同类量比较（累计 vs. 累计） |
| 批次数量 | `entity.QuantityGood - completedTotalNum` | `productionNum - alreadyBatched` | 增量 = 累计完成 - 累计已批次 |
| 批次号 | 解析末尾 3 位数字 +1 | `batches.Count + 1` 顺序编号 | 消除越界风险 |
| 死代码 | `maxStepNum`/`maxStepNumStages` | 删除 | 无引用 |

### 为什么用 Min 而不是 Sum

多工序生产是流水线模型：同一批物料依次经过各工序，只有**所有工序都完成的单位**才算可入库的成品。取各工序-任务组 `CompletedQuantity` 的最小值，即为通过全流程的单位数。Sum 会导致各工序重复计数。

---

## 五、验证场景

**工单计划产量 100，含切割、组装两道工序，各 1 个报工任务：**

| 审核顺序 | 阶段 | 报工 | 切割累计 | 组装累计 | Min | 已批次 | 批次产出 | 累计批次 |
|----------|------|------|---------|---------|-----|-------|---------|---------|
| 1 | 切割 | 30 | 30 | 0 | 0 | 0 | — | 0 |
| 2 | 组装 | 30 | 30 | 30 | **30** | 0 | Batch#1=30 | 30 |
| 3 | 切割 | 50 | 80 | 30 | **30** | 30 | — | 30 |
| 4 | 组装 | 50 | 80 | 80 | **80** | 30 | Batch#2=50 | 80 |
| 5 | 切割 | 20 | 100 | 80 | **80** | 80 | — | 80 |
| 6 | 组装 | 20 | 100 | 100 | **100** | 80 | Batch#3=20 | 100 |

> 切割工序先报满 100，但组装未完成时 Min=0 或不足 100，不生成多余批次。两端都完成后 Min=100，批次累计 100，**完全匹配工单计划产量**。

---

## 六、建议执行顺序

1. **修复 Bug 1** — 恢复 `productionNum = Min` 计算 + 修正 ProductionNum = `productionNum - alreadyBatched`
2. **修复 Bug 2** — 批次号改为 `batches.Count + 1`
3. **清理 Bug 3** — 删除 `maxStepNum`/`maxStepNumStages`
4. **编译验证** — MSBuild 解决方案 0 Error
5. **测试验证** — 多工序多报工端到端验证，确认批次总和 = 工单计划产量
