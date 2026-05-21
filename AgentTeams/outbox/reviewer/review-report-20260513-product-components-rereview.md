# 复审报告 — #002 商品组装编码关联（修复验证）

- **审查者**: Reviewer
- **复审时间**: 2026-05-13
- **复审范围**: 3 files (IProductComponentsService.cs, ProductComponentsService.cs, ProductComponentsController.cs)
- **参考基线**: `review-report-20260513-product-components.md`（初审查出 8 项，4 项必须修复）
- **复审结论**: ✅ 复审通过

---

## 逐项验证

| # | 严重度 | 原问题 | 修复 | 状态 |
|---|--------|--------|------|------|
| 1 | critical | GetDetails 无 CompanyId 过滤 | Service line 66: `x.CompanyId == companyId`；Controller line 43: 传入 `CurrentCompanyId` | ✅ |
| 2 | critical | Delete 无 CompanyId 过滤 | Service line 160: `x.CompanyId == companyId`；Controller line 75: 传入 `CurrentCompanyId` | ✅ |
| 3 | high | GetPageList 未分页 | Service line 35: 添加 `.Skip(input.SkipCount).Take(input.MaxResultCount)` | ✅ |
| 4 | high | GetAvailableCodes 全表扫描 | Service lines 180-183: JOIN `ProductComponents` 父表并过滤 `p.CompanyId == companyId` | ✅ |

### 额外修复验证

| 原问题 | 修复 | 状态 |
|--------|------|------|
| Delete `LastModificationUserId = 0` 硬编码 | Service line 165: `entity.LastModificationUserId = modifierUserId` | ✅ |
| GetDetails 全量加载产品 | Service lines 70-71: 仅查 `productIds = new[] { entity.ProductId, entity.ComponentProductId }` | ✅ |

---

## 未修复项（维持原判）

| # | 严重度 | 问题 | 说明 |
|---|--------|------|------|
| 5 | normal | Save 逐条 SaveChangesAsync | 未修复。循环内仍有 N 次 DB 往返，但属性能优化建议，不阻塞合入 |
| 6 | normal | `new Random()` 无种子 | 未修复。低风险，非阻塞项 |

---

## 新增问题检查

- `GetAvailableCodes` 中 `!usedCodes.Contains(r.CodeValue)` 仍使用内存 `Contains`，但现在已通过 JOIN 过滤为单租户数据，合理。✅
- 分页 `Skip().Take()` 位置正确（OrderByDescending 之后，ToListAsync 之前）。✅
- Controller 三个修改的方法均正确传入 `CurrentCompanyId` / `CurrentUserId` / `CurrentUserName`。✅
- 无新增 SQL 注入、XSS、越权风险。✅

---

## 总结

4 项必须修复项 + 2 项额外优化全部正确实现。保留 normal 级别的 SaveChanges 批量和 Random 种子 2 项作为后续优化建议，不阻塞上线。允许合入。
