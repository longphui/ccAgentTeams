# 测试用例：生产工单产品编码生成

- **制定者**: QA
- **制定时间**: 2026-05-13 19:00
- **参考需求**: `AgentTeams/shared/requirements/001-生产工单产品编码生成.md`
- **参考计划**: `AgentTeams/shared/requirements/001-plan-生产工单产品编码生成.md`

---

## 第一部分：接口测试

### TC-API-001: 正常登录获取 Token

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Common/Account/Login` |
| **入参** | `{ "Data": { "Username": "hongbin", "Password": "123456", "Source": null } }` |
| **期望结果** | 返回 200，`result.code === 0`，`result.data.token` 非空 |
| **线程组** | 单用户 |

### TC-API-002: GetPageListForCodeGen — 基础分页查询

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回 200，`result.code === 0`，`result.data.count` >= 0，`result.data.Items` 为数组，数组元素含 `generatedCodeCount` 字段 |
| **验证点** | 字段 `generatedCodeCount` 存在且为 int 类型 |

### TC-API-003: GetPageListForCodeGen — 过滤工单编号

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "SkipCount": 0, "MaxResultCount": 10, "WorkOrderNo": "PROD-001" }` |
| **期望结果** | 返回匹配工单编号的工单列表 |
| **验证点** | Items 中所有工单的 WorkOrderNo 包含 "PROD-001" |

### TC-API-004: GetPageListForCodeGen — 过滤产品名称

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "SkipCount": 0, "MaxResultCount": 10, "ProductName": "测试产品" }` |
| **期望结果** | 返回匹配产品名称的工单列表 |
| **验证点** | Items 中所有工单的 ProductName 包含 "测试产品" |

### TC-API-005: GetPageListForCodeGen — 无权限（缺 Token）

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "SkipCount": 0, "MaxResultCount": 10 }`（不传 Authorization Header） |
| **期望结果** | 返回 401 或 403 |

### TC-API-006: GetCodeRecordsByObject — 按 ObjectType 查询全部

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回 200，`result.code === 0`，`result.data.Items` 为编码记录数组 |
| **验证点** | 每条记录含 `codeValue`、`objects`、`creationTime` 字段 |

### TC-API-007: GetCodeRecordsByObject — 按 ObjectType + ObjectId 查询

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "ObjectId": 1, "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回指定工单的编码记录 |
| **验证点** | 每条记录的 Objects 中包含 `ObjectType="ProduceWorkOrder"` 且 `ObjectId=1` |

### TC-API-008: GetCodeRecordsByObject — 按工单编号筛选

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "WorkOrderNo": "PROD-001", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回对应工单编号的编码记录 |
| **验证点** | 返回非空列表（如果 PRE-001 有编码记录） |

### TC-API-009: GetCodeRecordsByObject — 按编码值模糊筛选

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "CodeValue": "CP", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回编码值包含 "CP" 的记录 |
| **验证点** | Items 中所有记录的 CodeValue 包含 "CP" |

### TC-API-010: GetCodeRecordsByObject — 按时间范围筛选

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "StartTime": "2026-05-01T00:00:00", "EndTime": "2026-05-13T23:59:59", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回时间范围内的编码记录 |
| **验证点** | Items 中所有记录的 CreationTime 在指定范围内 |

### TC-API-011: GetCodeRecordsByObject — 空 ObjectType

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回错误提示，不崩溃 |
| **严重度** | Normal |

### TC-API-012: GenerateCode — 正常生成（Count=1）

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "ProductCode", "Count": 1, "Objects": [{ "ObjectType": "ProduceWorkOrder", "ObjectId": 1 }, { "ObjectType": "Product", "ObjectId": 1 }] }` |
| **期望结果** | 返回 200，生成 1 条编码记录 |
| **验证点** | 返回编码数组长度 === 1，重启查询该工单编码数量增加 1 |

### TC-API-013: GenerateCode — 批量生成（Count=5）

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "ProductCode", "Count": 5, "Objects": [{ "ObjectType": "ProduceWorkOrder", "ObjectId": 1 }, { "ObjectType": "Product", "ObjectId": 1 }] }` |
| **期望结果** | 返回 200，生成 5 条编码记录 |
| **验证点** | 返回编码数组长度 === 5，5 条编码值唯一 |

### TC-API-014: GenerateCode — 缺 Objects（参数校验）

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "ProductCode", "Count": 1, "Objects": null }` |
| **期望结果** | 返回错误提示 |
| **严重度** | Normal |

### TC-API-015: GenerateCode — 缺 CodeSign（参数校验）

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "", "Count": 1, "Objects": [{ "ObjectType": "ProduceWorkOrder", "ObjectId": 1 }] }` |
| **期望结果** | 返回错误提示 |
| **严重度** | Normal |

---

## 第二部分：前端验证

### TC-UI-001: 页面正常加载

| 项目 | 内容 |
|------|------|
| **访问** | `http://localhost:8095/v2/views/productionManage/commonProductionStages/index.html` |
| **操作** | 打开页面 |
| **期望结果** | 页面正常渲染，三个 Tab 标签可见：「未生成编码」「已生成编码」「编码记录」 |
| **严重度** | Critical |

### TC-UI-002: Tab 切换

| 项目 | 内容 |
|------|------|
| **操作** | 依次点击「未生成编码」「已生成编码」「编码记录」三个 Tab |
| **期望结果** | 每次切换后对应 Tab 内容正确渲染，列表自动加载 |
| **严重度** | High |

### TC-UI-003: Tab1 — 未生成编码列表展示

| 项目 | 内容 |
|------|------|
| **操作** | 切换到 Tab1「未生成编码」|
| **期望结果** | 列表展示编码数量为 0 的工单，列包含：工单编号、产品名称、生产数量、工单状态、编码数量、操作。操作列为「生成编码」按钮 |
| **验证点** | `generatedCodeCount` 字段值为 0 |

### TC-UI-004: Tab1 — 生成编码确认弹窗

| 项目 | 内容 |
|------|------|
| **操作** | 点击某工单的「生成编码」按钮 |
| **期望结果** | 弹出确认弹窗，标题「确认生成编码」，显示工单编号、产品名称、生成数量。有「取消」和「确认」按钮 |
| **验证点** | 工单编号与行数据一致，生成数量 === PlannedProductionNum |

### TC-UI-005: Tab1 — 确认后生成编码

| 项目 | 内容 |
|------|------|
| **操作** | 在确认弹窗中点击「确认」按钮 |
| **期望结果** | 提示「编码生成成功」，弹窗关闭，Tab1 列表刷新，该工单消失（因已生成编码） |
| **严重度** | Critical |

### TC-UI-006: Tab2 — 已生成编码列表展示

| 项目 | 内容 |
|------|------|
| **操作** | 切换到 Tab2「已生成编码」|
| **期望结果** | 列表展示编码数量 > 0 的工单，操作列为「查询编码」按钮 |
| **验证点** | `generatedCodeCount` > 0，编码数量准确 |

### TC-UI-007: Tab2 — 点击查询编码打开弹窗

| 项目 | 内容 |
|------|------|
| **操作** | 点击某工单的「查询编码」按钮 |
| **期望结果** | 打开编码查询弹窗（codeList.html），URL 中带 workOrderId 和 workOrderNo 参数 |
| **验证点** | 弹窗中筛选条件默认填入工单编号，列表加载该工单的编码记录 |

### TC-UI-008: Tab3 — 编码记录列表

| 项目 | 内容 |
|------|------|
| **操作** | 切换到 Tab3「编码记录」|
| **期望结果** | 列表展示编码记录，列包含：编码值、规则名称、业务编码、生成时间 |
| **验证点** | 数据正确，分页正常 |

### TC-UI-009: 编码查询弹窗 — 各筛选条件功能

| 项目 | 内容 |
|------|------|
| **操作** | 在 codeList.html 中分别使用工单编号、商品名称、编码值、时间范围进行筛选 |
| **期望结果** | 各筛选条件独立生效，筛选结果正确 |
| **验证点** | 组合筛选也正确 |

---

## 第三部分：安全测试

### TC-SEC-001: SQL 注入 — 工单编号搜索

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "WorkOrderNo": "' OR '1'='1", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 不泄露额外数据，不报数据库异常 |
| **严重度** | Critical |

### TC-SEC-002: SQL 注入 — 产品名称搜索

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "ProductName": "'; DROP TABLE CodeRecords; --", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 不执行恶意 SQL，不破坏表结构 |
| **严重度** | Critical |

### TC-SEC-003: SQL 注入 — 编码值搜索

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "ProduceWorkOrder", "CodeValue": "' OR 1=1; --", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 不泄露额外数据，不报数据库异常 |
| **严重度** | Critical |

### TC-SEC-004: 越权 — 修改 ObjectId 访其他公司工单

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **操作** | 使用 Token 登录公司 2026，但传入其他公司的工单 ObjectId |
| **期望结果** | 不返回其他公司数据，返回空列表或拒绝访问 |
| **严重度** | Critical |

### TC-SEC-005: XSS — 编码查询弹窗输入

| 项目 | 内容 |
|------|------|
| **操作** | 在 codeList.html 的筛选框中输入 `<script>alert(1)</script>` |
| **期望结果** | 不执行脚本，页面安全 |
| **严重度** | High |

---

## 第四部分：边界测试

### TC-EDGE-001: GenerateCode Count=0

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "ProductCode", "Count": 0, "Objects": [...] }` |
| **期望结果** | 返回错误提示，不生成编码 |
| **严重度** | Normal |

### TC-EDGE-002: GenerateCode Count > 1000

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "ProductCode", "Count": 1001, "Objects": [...] }` |
| **期望结果** | 返回错误提示或限制在合理范围，不崩溃 |
| **严重度** | High |

### TC-EDGE-003: GenerateCode — ProductCode 配置不存在

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/Generate` |
| **入参** | `{ "CodeSign": "NonExistentCode", "Count": 1, "Objects": [...] }` |
| **期望结果** | 返回明确错误提示（如"编码标识不存在"），不崩溃 |
| **严重度** | High |

### TC-EDGE-004: GetPageListForCodeGen — PageSize 极大值

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/Produce/ProduceWorkOrder/GetPageListForCodeGen` |
| **入参** | `{ "SkipCount": 0, "MaxResultCount": 10000 }` |
| **期望结果** | 不在应用层爆掉，返回合理数据量 |
| **严重度** | Low |

### TC-EDGE-005: GetCodeRecordsByObject — 不存在 ObjectType

| 项目 | 内容 |
|------|------|
| **接口** | `POST /api/CodeGenerator/CodeGenerator/GetCodeRecordsByObject` |
| **入参** | `{ "ObjectType": "NonExistentType", "SkipCount": 0, "MaxResultCount": 10 }` |
| **期望结果** | 返回 count=0，不报错 |
| **严重度** | Low |

---

## 测试结果汇总（待填写）

| # | 用例编号 | 用例名称 | 类型 | 结果 | 备注 |
|---|----------|----------|------|------|------|
| 1 | TC-API-001 | 正常登录获取 Token | 接口 | 待测试 | |
| 2 | TC-API-002 | GetPageListForCodeGen 基础分页 | 接口 | 待测试 | |
| 3 | TC-API-003 | GetPageListForCodeGen 过滤工单编号 | 接口 | 待测试 | |
| 4 | TC-API-004 | GetPageListForCodeGen 过滤产品名称 | 接口 | 待测试 | |
| 5 | TC-API-005 | GetPageListForCodeGen 缺Token | 接口 | 待测试 | |
| 6 | TC-API-006 | GetCodeRecordsByObject 按ObjectType查询 | 接口 | 待测试 | |
| 7 | TC-API-007 | GetCodeRecordsByObject 按ObjectType+ObjectId查询 | 接口 | 待测试 | |
| 8 | TC-API-008 | GetCodeRecordsByObject 按工单编号筛选 | 接口 | 待测试 | |
| 9 | TC-API-009 | GetCodeRecordsByObject 按编码值模糊筛选 | 接口 | 待测试 | |
| 10 | TC-API-010 | GetCodeRecordsByObject 按时间范围筛选 | 接口 | 待测试 | |
| 11 | TC-API-011 | GetCodeRecordsByObject 空ObjectType | 接口 | 待测试 | |
| 12 | TC-API-012 | GenerateCode 正常生成（Count=1） | 接口 | 待测试 | |
| 13 | TC-API-013 | GenerateCode 批量生成（Count=5） | 接口 | 待测试 | |
| 14 | TC-API-014 | GenerateCode 缺Objects | 接口 | 待测试 | |
| 15 | TC-API-015 | GenerateCode 缺CodeSign | 接口 | 待测试 | |
| 16 | TC-UI-001 | 页面正常加载 | 前端 | 待测试 | |
| 17 | TC-UI-002 | Tab切换 | 前端 | 待测试 | |
| 18 | TC-UI-003 | Tab1 未生成编码列表 | 前端 | 待测试 | |
| 19 | TC-UI-004 | 生成编码确认弹窗 | 前端 | 待测试 | |
| 20 | TC-UI-005 | 确认后生成编码 | 前端 | 待测试 | |
| 21 | TC-UI-006 | Tab2 已生成编码列表 | 前端 | 待测试 | |
| 22 | TC-UI-007 | 查询编码弹窗 | 前端 | 待测试 | |
| 23 | TC-UI-008 | Tab3 编码记录列表 | 前端 | 待测试 | |
| 24 | TC-UI-009 | 编码查询弹窗各筛选条件 | 前端 | 待测试 | |
| 25 | TC-SEC-001 | SQL注入 工单编号搜索 | 安全 | 待测试 | |
| 26 | TC-SEC-002 | SQL注入 产品名称搜索 | 安全 | 待测试 | |
| 27 | TC-SEC-003 | SQL注入 编码值搜索 | 安全 | 待测试 | |
| 28 | TC-SEC-004 | 越权 ObjectId访其他公司 | 安全 | 待测试 | |
| 29 | TC-SEC-005 | XSS 编码查询弹窗输入 | 安全 | 待测试 | |
| 30 | TC-EDGE-001 | GenerateCode Count=0 | 边界 | 待测试 | |
| 31 | TC-EDGE-002 | GenerateCode Count>1000 | 边界 | 待测试 | |
| 32 | TC-EDGE-003 | ProductCode配置不存在 | 边界 | 待测试 | |
| 33 | TC-EDGE-004 | PageSize极大值 | 边界 | 待测试 | |
| 34 | TC-EDGE-005 | 不存在ObjectType | 边界 | 待测试 | |
