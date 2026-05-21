# 测试报告 — GetRuleDetails 子项列表按 SortOrder 排序
- **测试者**: QA
- **测试时间**: 2026-05-16 15:35
- **被测模块**: CodeGenerator GetRuleDetails API + 前端列表展示
- **测试环境**: IIS localhost:8088, hongbin/123456, CompanyId=2026

## 测试摘要
| 总数 | 通过 | 失败 | 跳过 | 覆盖率 |
|------|------|------|------|--------|
| 4 | 4 | 0 | 0 | 100% |

## 测试用例列表
| # | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|------|------|------|
| 1 | 后端排序逻辑 | 代码审查 | ✅ | CodeGeneratorService.cs:83 `.OrderBy(i => i.SortOrder)` |
| 2 | GenerateCode 同样排序 | 代码审查 | ✅ | CodeGeneratorService.cs:476 同逻辑 |
| 3 | API GetRuleDetails 返回排序 | API测试 | ✅ | id=7 返回 sortOrder=1,2 升序 |
| 4 | 前端列表按后端顺序展示 | 代码审查 | ✅ | create_edit.html 直接使用 res.items |

## 发现的 Bug
| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 无 | - | - | - |

## 代码审查详情

### GetRuleDetails (CodeGeneratorService.cs:83)
```csharp
rule.Items = rule.Items.Where(i => !i.IsDeleted).OrderBy(i => i.SortOrder).ToList();
```

### GenerateCode (CodeGeneratorService.cs:476)
```csharp
var items = rule.Items.Where(i => !i.IsDeleted).OrderBy(i => i.SortOrder).ToList();
```

### API 响应验证 (id=7)
```json
"items": [
  {"sortOrder":1, "itemType":"SerialNumber", "id":21},
  {"sortOrder":2, "itemType":"Constant", "id":20}
]
```

### 前端 (create_edit.html)
- 加载: `this.entry.items = res.items || []` — 按 API 返回顺序展示
- 新增: push 到末尾，sortOrder = length+1 — 天然在正确位置
- 移动: `moveItem()` 重新按 sortOrder 排序后 reindex
