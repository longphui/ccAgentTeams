# 已交付功能历史归档 (#001–#004)

归档日期: 2026-05-20 | 归档原因: 用户确认可交付

---

## #001 — 生产工单产品编码生成

- **项目**: 分路 (fl)
- **状态**: ✅ 可交付
- **已修复 Bug**:
  - NRE (AutoMapper)
  - codeList staticFilter
  - Tab1/Tab2 无区分
  - ProductName 中文搜索
- **已知非阻塞问题**: AddDays 时间筛选 (medium, 已有)

---

## #002 — 商品组装编码关联

- **项目**: 分路 (fl)
- **状态**: ✅ 可交付 (复审通过)
- **已修复 Bug**:
  - 租户隔离
  - 分页失效
  - GetAvailableCodes 全表扫描
  - Delete 硬编码
- **已知非阻塞问题**: SaveChanges 逐条执行 (normal), Random 无种子 (normal)

---

## #003 — CodeGenerator优化 + Domain重构

- **项目**: 分路 (fl)
- **状态**: ✅ 可交付
- **前后端**: ✅ QA 测试通过
- **决策**: #008 — BizFieldDefinition 加 DomainCode/DomainName/FieldSql, BizContext→DomainId
- **已修复 Bug**:
  - Save API 空异常 (false alarm)
  - codeRule 添加子项 Domain 前置检查 + 业务字段过滤
- **待手动执行**: Task 3 数据库迁移

---

## #004 — HRM集成到天津宏观世纪ERP-阶段1

- **项目**: 天津宏观世纪 (honguan)
- **状态**: ✅ 可交付
- **标题**: iframe嵌入 + 菜单权限统一
- **决策**: #009 (方案D 渐进混合), #011 (iframe_前缀判断替代路径硬编码)
- **Round 1** (2026-05-18): Task 1+2+3 (Developer) + Task 4+6+7 (Developer1) 全部通过审查和QA测试
- **Round 2** (2026-05-18~19): 收尾完成，全部 Task 已交付

### Task 明细

| 角色 | 任务 | 状态 |
|------|------|------|
| Developer | DB菜单数据 (Task 9) | ✅ 审查通过 ✅ QA通过 |
| Developer1 | getWebAppMenu + mainmenu + checkPermissions + initMenu (Task 5a/b/c/8) | ✅ 审查通过 ✅ API通过 |
| Developer1 | 修复 startup 路由缺少 menuButtons (分路端) | ✅ 8/8 Playwright |
| Developer1 | 天津宏观世纪端 startup 路由缺少 menuButtons (同步修复) | ✅ 8/8 Playwright |
| Developer1 | menuButtons 权限传递链路 (Bug #7, 3文件) | ✅ |
| Developer1 | menuButtons DataCloneError 展开运算符修复 (Bug #8) | ✅ |
| Developer1 | appConfig.js https→http (Bug #9) | ✅ |
| Developer1 | ColumnSelector.restore() try-catch 降级 (Bug #10) | ✅ |
| Developer1 | stub 补全 getDefaultTheme + applyThemeToTarget (Bug #11) | ✅ |
| Developer1 | getDefaultTheme 默认 CSS 变量 (Bug #12) | ✅ |
| Developer1 | stub 补全 openPage 弹窗方法 (Bug #13) | ✅ |
| Developer1 | applyThemeToTarget CSS 变量注入修复 (Bug #14) | ✅ |
| Developer1 | states Map 共享修复 (Bug #15) | ✅ |
| Developer1 | newFenluApiBase 5001→8088 (Bug #16) | ✅ |
| Developer1 | 创建 menu.json (Task 11) | ✅ |
| Developer1 | 修复 startup 首页 (Task 13) | ✅ |
| Developer1 | 源码注释改名 (Task 14) | ✅ |
| QA | Developer1 前端改造测试 | ✅ |
| QA | Playwright 浏览器自动化验证 | ✅ 8/8 |
| QA | E2E 验证报告 | ✅ |
| — | 修复49个反斜杠路径 (Task 12) | ❌ 取消 (用户确认: 已删除数据) |

### 环境修复
- Frontend.csproj TargetFramework net9.0→net10.0
- appConfig.js https→http (后端仅监听HTTP)

### 命名说明
2026-05-18 用户纠正: 项目名称 '鸿冠ERP' → '天津宏观世纪ERP'。honguan 是代码标识不变。
