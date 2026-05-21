# 代码审查报告 — #002 商品组装编码关联

- **审查者**: Reviewer
- **审查时间**: 2026-05-13
- **审查范围**: 13 files (7 new backend + 3 new frontend + 3 modified)
- **总体评价**: **需修改** — 2个critical租户隔离漏洞 + 2个high + 4个中低风险项

---

## 审查文件清单

### NEW — Core 实体 (2)
| # | 文件 | 说明 |
|---|------|------|
| 1 | `SAHG.Salt.Core/Produce/ProductComponents.cs` | 继承 `BasicEntity`，显式定义 `CompanyId` |
| 2 | `SAHG.Salt.Core/Produce/ProductComponentCodes.cs` | 继承 `SaltEntity`，无 `CompanyId` 属性 |

### NEW — Application (4)
| # | 文件 | 说明 |
|---|------|------|
| 3 | `.../Dto/ProductComponentsDto.cs` | 继承 `HRM_CompanyEntityDto` |
| 4 | `.../Dto/ProductComponentsInput.cs` | 无基类继承，含 `CompanyId` + `Components` 列表 |
| 5 | `.../IProductComponentsService.cs` | 6 methods 接口定义 |
| 6 | `.../ProductComponentsService.cs` | 核心业务逻辑（6 methods） |

### NEW — Controller (1)
| # | 文件 | 说明 |
|---|------|------|
| 7 | `.../ProductComponentsController.cs` | 6 Actions，全部 `[PPMLog]` |

### NEW — 前端 (3)
| # | 文件 | 说明 |
|---|------|------|
| 8 | `ProductComponents/index.html` | 列表页（展开编码） |
| 9 | `ProductComponents/create_edit.html` | 手动组装表单 + 编码选择器 |
| 10 | `ProductComponents/autoAssembly.html` | 一键自动组合 + 结果预览 |

### MODIFIED (3)
| # | 文件 | 变更 |
|---|------|------|
| 11 | `SaltDbContext.cs:576-577` | 新增 `ProductComponents` + `ProductComponentCodes` 两个 `DbSet` |
| 12 | `HRM_DtoMapping.cs:222-223` | 新增双向 AutoMapper 映射 |
| 13 | `.csproj` | 未检查，假定标准编译项 |

---

## 发现问题

| # | 类别 | 严重度 | 文件:行号 | 描述 | 建议 |
|---|------|--------|-----------|------|------|
| 1 | 租户隔离 | **critical** | `ProductComponentsService.cs:66` | `GetDetails` 查询 `_context.ProductComponents.FirstOrDefault(x => x.Id == id && !x.IsDeleted)` **未按 `CompanyId` 过滤**。`ProductComponents` 继承 `BasicEntity → SaltEntity`，`SaltEntity` 未实现 `IMustHaveCompany`，无全局租户过滤器。攻击者遍历 ID 可读取任意公司组装记录。Controller 也未传入 `CurrentCompanyId`。 | 改为 `_context.ProductComponents.FirstOrDefault(x => x.Id == id && x.CompanyId == companyId && !x.IsDeleted)`，Controller 从 `CurrentCompanyId` 获取并传入 |
| 2 | 租户隔离 | **critical** | `ProductComponentsService.cs:159` | `Delete` 查询 `_context.ProductComponents.FirstOrDefault(x => x.Id == id && !x.IsDeleted)` **未按 `CompanyId` 过滤**。任意租户用户可软删除其他公司的组装记录。 | 增加 `CompanyId` 过滤条件；`ProductComponents` 未自动过滤租户（`BasicEntity` 无 `IMustHaveCompany`） |
| 3 | 功能缺陷 | **high** | `ProductComponentsService.cs:35` | `GetPageList` 中 `query.OrderByDescending(...).ToListAsync()` **加载全量数据**，未使用 `input.SkipCount` / `input.MaxResultCount`。`PagedListOutput` 的 `Items` 包含全部记录而非当前页数据。数据量大时每次请求返回全量，分页形同虚设。 | 添加 `.Skip(input.SkipCount).Take(input.MaxResultCount)` 在 `ToListAsync()` 之前 |
| 4 | 性能 | **high** | `ProductComponentsService.cs:179-182` | `GetAvailableCodes` 中 `_context.ProductComponentCodes.Where(c => !c.IsDeleted).Select(c => c.CodeValue).ToListAsync()` **查询所有租户的全部已用编码**（`ProductComponentCodes` 无 `CompanyId` 属性，无法加租户过滤）。一次性加载全量表到内存做 `Contains`。数据量随系统使用持续增长。 | 方案A: 给 `ProductComponentCodes` 加 `CompanyId` 字段并过滤。方案B: 改用 JOIN 查询替代 `Contains`，让 DB 端处理 `NOT IN`。 |
| 5 | 代码规范 | **normal** | `ProductComponentsService.cs:115,129` | `Save` 方法在 `foreach` 循环内多次 `await _context.SaveChangesAsync()`（每个 component 一次 + 每个 component 的 codes 一次）。2N 次 DB 往返。 | 改为全部 `Add` 后单次 `SaveChangesAsync()`；EF 会自动回填 `entity.Id` 用于子表关联 |
| 6 | 随机安全 | **normal** | `ProductComponentsService.cs:141` | `new Random()` 无种子，在 ASP.NET 请求处理中若同一 tick 内多次调用 `AutoAssemble` 可能生成相同随机序列。 | 使用 `RandomNumberGenerator` 或 `Guid.NewGuid()` 作为排序键 |
| 7 | 性能 | **low** | `ProductComponentsService.cs:70` | `GetDetails` 中 `_productRep.GetAll().Where(p => !p.IsDeleted).ToListAsync()` 加载全量产品到内存，只为了查 2 个产品名。 | 改为 `_productRep.GetAll().Where(p => (p.Id == entity.ProductId \|\| p.Id == entity.ComponentProductId) && !p.IsDeleted).ToListAsync()` |
| 8 | 代码规范 | **low** | `ProductComponentsService.cs:164` | `Delete` 中 `entity.LastModificationUserId = 0` 硬编码为 0，与 `GetPageList` 等方法传入实际用户 ID 不一致。 | 与其他方法一致传入实际修改者 ID |

---

## 审查维度详情

### 🔒 安全检查 — 不通过

- **租户隔离 (CRITICAL)**: `ProductComponents` 继承 `BasicEntity → SaltEntity → Entity`，未实现 `IMustHaveCompany`，ABP 不会自动应用租户过滤器。`GetDetails` 和 `Delete` 均未显式过滤 `CompanyId`，导致跨租户数据访问/破坏。
- **租户隔离 (HIGH)**: `ProductComponentCodes` 继承 `SaltEntity` 且无 `CompanyId` 属性，只能通过父表 `ProductComponents` 间接关联租户。`GetAvailableCodes` 直接查询子表，无法过滤租户。
- **SQL 注入**: 全 Linq-to-Entities 查询，无拼接 SQL。✅
- **认证/授权**: 继承 `SaltControllerBase`，复用框架级权限。✅
- **编码唯一性**: `Save` 方法（lines 94-100）通过 `Contains` 批量查询检查编码是否已被使用。✅

### ⚡ 性能检查 — 不通过

- **分页失效**: `GetPageList` 全量加载，见问题 #3。
- **全表扫描**: `GetAvailableCodes` 加载全部已用编码，见问题 #4。
- **N+1 SaveChanges**: `Save` 循环调用 `SaveChangesAsync`，见问题 #5。
- **全量产品加载**: `GetDetails` 加载所有产品，见问题 #7。

### 📐 代码规范检查 — 基本通过

- **日志属性**: Controller 6 个 Action 全部使用 `[PPMLog]`，与 Produce 模块一致。✅
- **AutoMapper 配置**: `HRM_DtoMapping.cs` 双向映射 `ProductComponents ↔ ProductComponentsDto`。✅（注意：`ProductComponentCodes` 和 `ProductComponentsInput` 未配置 AutoMapper，但服务中使用 Mapster `Adapt<>` 和手动映射，可接受）
- **实体继承**: `ProductComponents : BasicEntity`（有显式 `CompanyId`）vs `ProductComponentCodes : SaltEntity`（无 `CompanyId`）不一致。建议统一，且子表应有关联租户字段。
- **DTO 设计**: `ProductComponentsDto : HRM_CompanyEntityDto` 含 `ProductName`/`ComponentProductName` 展示字段；`ProductComponentsInput` 不含基类且无 `ShouldNormalize` 等接口。合理。
- **注释**: 所有 public 方法/DTO/实体有中文 XML doc。✅
- **Controller 返回类型**: `GetPageList` 返回 `dynamic`，与 Produce 模块其他 Controller 一致。✅

---

## 前端审查要点

| # | 文件 | 发现 |
|---|------|------|
| 1 | `index.html` | ✅ 列表展示正常，权限检查到位（`checkTabPermissions`），删除有 `layer.confirm` 二次确认 |
| 2 | `create_edit.html` | ✅ 表单校验完整（成品必选、数量>0、编码数=数量）；⚠️ `onProductChange` 调用 `GetAvailableCodes`（受后端性能问题 #4 影响） |
| 3 | `autoAssembly.html` | ✅ 自动组合流程正常；⚠️ `confirmSave` 方法仅显示"保存成功"并跳转（数据已在 `AutoAssemble` API 中保存），按钮文案可能让用户困惑——建议改为"确认返回" |

---

## 架构决策对照

- **实体继承**: `ProductComponents : BasicEntity` 显式含 `CompanyId`。`ProductComponentCodes : SaltEntity` 不含 `CompanyId`，依赖导航属性关联。但 `GetAvailableCodes` 直接查子表打破了这个依赖链。**与租户隔离设计偏离**。
- **`[PPMLog]`**: 日志属性与 Produce 模块其他 Controller 一致。✅

---

## 总结

后端整体结构清晰，编码唯一性校验、表单验证、软删除逻辑正确。但存在 **4 个必须修复的问题**：

1. **Critical**: `GetDetails` + `Delete` 缺少 `CompanyId` 过滤 → 租户数据泄露/破坏
2. **High**: `GetPageList` 未分页 → 全量返回
3. **High**: `GetAvailableCodes` 全量加载所有租户编码 → 性能退化

建议修复后复审。
