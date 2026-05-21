# 实施计划 #006: 报工审核批次生成修复

- **日期**: 2026-05-21
- **工期**: 0.5 天
- **需求文档**: 006-报工审核批次生成修复.md
- **技术分析**: D:\work\cc\produceReportingWork.md

---

## 1. 架构总览

```
ProduceReportingWorkService.Approval()
  │
  ├── 审核状态更新（无变更）
  │
  └── ApprovalStatus==1 → 批次生成逻辑（修改）
        │
        ├── 计算 productionNum = Min(各工序-任务组 CompletedQuantity)  ← 恢复 r4539 逻辑
        ├── 查询 alreadyBatched = Sum(已有批次 ProductionNum)
        ├── if productionNum > alreadyBatched → 新批次 ProdNum = 差额  ← 修正
        └── if 全工序 >= 计划产量 → 工单 Status=2
```

**涉及系统**：
- `SAHG.Salt.Application/Produce/ProduceReportingWorkService.cs` — [MOD] `Approval()` 方法

**数据流向**：
```
ProduceReportingWork (报工) → ProduceTask (任务累计) → ProduceProductionBatch (批次) → 入库
```

---

## 2. 任务拆解

### Task 1: 修复 Approval() 批次生成三处 Bug

- **执行者**: Developer
- **依赖**: 无
- **估时**: 2 小时
- **涉及文件**: `SAHG.Salt.Application/Produce/ProduceReportingWorkService.cs`

**实现要点**：

1. **恢复 productionNum 计算**（替换删除的代码）：
   ```csharp
   var productionNum = groupByProduceTasks.Min(g => g.Sum(a => a.CompletedQuantity));
   ```

2. **修正条件 & ProductionNum**：
   ```csharp
   if (productionNum > alreadyBatched) {
       ProductionNum = productionNum - alreadyBatched;
   }
   ```

3. **批次号改为顺序编号**：
   ```csharp
   var seq = (batches.Count + 1).ToString().PadLeft(3, '0');
   ```

4. **删除死代码** `maxStepNum` / `maxStepNumStages`

- **验证标准**:
  - 编译通过 0 Error
  - 代码逻辑与 `produceReportingWork.md` 优化方案一致

---

## 3. 依赖关系图

```
Task 1 (Developer: 修复代码)
  │
  ├──→ Reviewer 审查
  │
  └──→ Task 2 (QA: 编写测试用例 + 验证)
```

---

## 4. 分派计划

| Round | Task | 执行者 | 说明 |
|-------|------|--------|------|
| Round 1 | Task 1 | Developer | 修复代码 → 发 REVIEW |
| Round 1 | Task 2 | QA | 基于分析报告编写测试用例 → 等待 Developer 完成后验证 |

---

## 5. 工作量汇总

| 执行者 | 任务数 | 估时 |
|--------|--------|------|
| Developer | 1 | 2h |
| QA | 1 | 1.5h |
| Reviewer | 1 | 0.5h |
| **合计** | | **4h** |
