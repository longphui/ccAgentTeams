# 测试报告 — bizCode Domain/规则顺序 + 过滤 + 联动
- **测试者**: QA
- **测试时间**: 2026-05-16 16:30
- **被测模块**: bizCode create_edit.html（业务编码标识新增/编辑页）
- **测试环境**: 代码审查

## 测试摘要
| 总数 | 通过 | 失败 | 跳过 | 覆盖率 |
|------|------|------|------|--------|
| 4 | 4 | 0 | 0 | 100% |

## 测试用例列表
| # | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|------|------|------|
| 1 | 字段顺序 — Domain 在 CodeRule 前 | 代码审查 | ✅ | domain line 34, codeRuleId line 45 |
| 2 | 规则按 Domain 过滤 | 代码审查 | ✅ | applyRuleFilter() line 118-127 |
| 3 | 联动清空 — 切换 Domain 清空不匹配规则 | 代码审查 | ✅ | watch line 158-167 |
| 4 | 编辑回显 — Domain + 规则过滤正确 | 代码审查 | ✅ | mounted() 顺序正确 line 91-101 |

## 发现的 Bug
| # | 严重度 | 描述 | 状态 |
|---|--------|------|------|
| 无 | - | - | - |

## 代码审查详情

### 1. 字段顺序 (line 34 vs 45)
表单中 `业务领域` DOM元素在 `编码规则` 之前，用户从上到下先选 Domain 再选规则。

### 2. 规则过滤 (lines 118-127)
```javascript
applyRuleFilter() {
    const domain = this.entry.data?.domain;
    if (!domain) {
        this.ruleList = this.ruleCache;
    } else {
        this.ruleList = this.ruleCache.filter(
            r => r.domain === domain || r.domain === 'General' || !r.domain
        );
    }
}
```
覆盖场景：无 Domain → 全量；有 Domain → 当前域 + General + 无域规则。

### 3. 联动清空 (lines 158-167)
```javascript
'entry.data.domain'(newDomain) {
    this.applyRuleFilter();
    if (newDomain && this.entry.data.codeRuleId) {
        const selected = this.ruleCache.find(
            r => r.id === this.entry.data.codeRuleId);
        if (selected?.domain && selected.domain !== newDomain
            && selected.domain !== 'General') {
            this.entry.data.codeRuleId = null;
        }
    }
}
```
- Product → Order：清空（Product 规则不匹配 Order）
- Product → Product：保留
- General 规则 → 切换 Domain：保留（General 跨域通用）

### 4. 编辑回显 (lines 91-101)
mounted() 顺序：loadDomainList() → 恢复 data（含 Domain）→ loadRuleList()。loadRuleList 内部调用 applyRuleFilter，此时 Domain 已恢复，过滤正确。
