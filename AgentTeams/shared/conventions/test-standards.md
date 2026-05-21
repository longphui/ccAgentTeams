# 测试规范

- **版本**: 1.0
- **日期**: 2026-05-20
- **适用项目**: 分路系统 + 天津宏观世纪ERP
- **适用角色**: Developer / Developer1 / QA / Reviewer

---

## 一、测试层级定义

| 层级 | 范围 | 工具 | 执行者 | 执行频率 |
|------|------|------|--------|---------|
| 后端单元测试 | .cs 方法级逻辑 | NUnit（建议） | Developer | 每次编译前 |
| 前端单元测试 | JS 纯函数（工具函数/数据处理） | Vitest（建议） | Developer1 | 提交前 |
| API 接口测试 | HTTP 端点（请求/响应/状态码/错误） | curl 脚本、Playwright API | QA / Developer | 每次 API 变更 |
| JS 函数测试 | 浏览器全局函数（checkTabPermissions 等） | Playwright page.evaluate | QA | 每次 JS 变更 |
| UI 交互测试 | 按钮点击/弹窗/表单/弹窗内按钮 | Playwright page.click / page.fill | QA | 每个功能完成后 |
| E2E 流程测试 | 完整业务链路 | Playwright | QA | 每个迭代 |
| 回归测试 | Bug 修复后验证 | Playwright | QA | Bug 修复后 |

### 层级关系

```
后端单元测试 ─┐
前端单元测试 ─┤ → API 接口测试 ─→ JS 函数测试 ─→ UI 交互测试 ─→ E2E 流程测试
              └──────────────────────────────────────────────────────→ 回归测试（贯穿）
```

下层测试失败时不应继续上层测试。优先修复下层问题。

---

## 二、UI 交互测试规范

这是项目当前最大缺口。每个功能页面必须覆盖以下测试维度。

### 2.1 按钮覆盖

列表页每个按钮必须有对应的点击+结果验证用例：

| 按钮 | 测试内容 |
|------|---------|
| 搜索 | 输入关键词 → 点击搜索 → 列表刷新 |
| 重置 | 输入搜索条件 → 点击重置 → 条件清空 |
| 新增 | 点击新增 → 弹窗打开 → 标题正确 |
| 编辑 | 选中行 → 点击编辑 → 弹窗打开 → 数据回填 |
| 删除 | 选中行 → 点击删除 → 确认弹窗 → 确认/取消 |
| 导出 | 点击导出 → 下载触发 |
| 审批 | 点击审批 → 弹窗打开 → 操作生效 |

### 2.2 弹窗覆盖

每个弹窗必须有打开→填表→提交→验证结果的完整链路：

```javascript
test('新增弹窗 — 打开 → 填表 → 点确定 → 列表刷新', async ({ page }) => {
  // 1. 打开新增弹窗
  await page.click('button:has-text("新增")');
  await page.waitForSelector('.layui-layer');
  
  // 2. 填写表单
  await page.fill('input[placeholder="供应商名称"]', '测试供应商');
  await page.fill('input[placeholder="联系人"]', '张三');
  
  // 3. 提交
  await page.click('.layui-layer button:has-text("确定")');
  
  // 4. 验证
  await page.waitForResponse(resp => resp.url().includes('/api/supplier/create'));
  await expect(page.locator('.layui-layer')).toBeHidden();
});
```

弹窗内按钮必须单独测试：点取消不保存、点确定保存成功、点 X 关闭不保存。

### 2.3 表单交互

| 测试类型 | 用例 |
|---------|------|
| 输入框 | fill 正常值 → 数据绑定正确；fill 空值 → 必填校验触发 |
| 下拉选择 | 选择选项 → 值绑定正确；清空选择 → 显示 placeholder |
| 日期选择 | 选择日期 → 格式正确；清空 → 不报错 |
| 必填校验 | 留空必填项 → 提交 → 显示错误提示 |
| 格式校验 | 输入非法格式 → 提交 → 显示格式提示 |

### 2.4 列表交互

| 测试类型 | 用例 |
|---------|------|
| 搜索 | 输入条件 → 搜索 → API 请求参数正确 |
| 分页 | 切换页码 → API 请求含正确的 pageIndex/pageSize |
| 排序 | 点击列头 → API 请求含正确排序参数 |
| 行内操作 | 行内按钮点击 → 响应正确 |

### 2.5 权限联动

```javascript
test('权限联动 — 无权限按钮应隐藏或禁用', async ({ page }) => {
  // mock 权限中不含 'delete'
  await page.evaluate(() => {
    const item = window.appContext.menu.items.find(m => m.path === 'views/xxx/index.html');
    if (item) item.menuButtons = ['search', 'add', 'edit']; // 无 delete
  });
  
  const deleteBtn = page.locator('button:has-text("删除")');
  await expect(deleteBtn).toBeHidden();
});
```

### 2.6 错误处理

| 场景 | 预期行为 |
|------|---------|
| API 返回 500 | 页面不崩溃，显示 toast 提示 |
| API 返回 401 | 跳转登录页或提示重新登录 |
| 网络断开 | 显示网络错误提示，可重试 |
| 超长数据 | 文本截断不撑破布局 |
| 空列表 | 显示"暂无数据"提示 |

---

## 三、API 测试规范

### 3.1 测试模板

每个 API 端点至少覆盖以下用例：

```bash
# ===== 正常请求 =====
cat > /tmp/api-test-normal.json <<'EOF'
{"param1": "valid_value", "param2": 1}
EOF

curl -s -X POST "http://localhost:8088/api/xxx/endpoint" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/api-test-normal.json | python -m json.tool

# ===== 缺少必填参数 =====
cat > /tmp/api-test-missing.json <<'EOF'
{"param2": 1}
EOF

curl -s -X POST "http://localhost:8088/api/xxx/endpoint" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/api-test-missing.json

# ===== 边界值 =====
cat > /tmp/api-test-boundary.json <<'EOF'
{"param1": "", "param2": 0}
EOF

curl -s -X POST "http://localhost:8088/api/xxx/endpoint" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/api-test-boundary.json

# ===== 无 Token =====
curl -s -X POST "http://localhost:8088/api/xxx/endpoint" \
  -H "Content-Type: application/json" \
  -d @/tmp/api-test-normal.json
```

### 3.2 响应验证项

| 验证项 | 说明 |
|--------|------|
| HTTP 状态码 | 成功 200、认证失败 401、参数错误 400、服务错误 500 |
| `succeeded` / `success` / `code` | 按项目 API 格式验证 |
| 响应字段类型 | 遍历 `data` 内每个字段，验证类型正确（string/int/array/object） |
| 分页字段 | `totalCount`、`pageIndex`、`pageSize` 存在且正确 |
| 错误信息 | `errors[0].message` 有具体描述，不是空字符串 |
| 时间字段 | ISO 8601 格式或 Unix 时间戳 |

### 3.3 分路 API 响应格式速查

| 客户端 | 成功判断 | 数据字段 | 使用场景 |
|--------|---------|---------|---------|
| `Http` (baseUrl1) | `res.success === true` | `res.result` | 旧分路 API |
| `HttpE` (baseUrl2) | `res.code === 200` | `res.data` | 能源 API |
| `Http2` (newFenluApiBase) | `res.succeeded === true` | `res.data` | Furion API |

### 3.4 curl 文件方式规范（强制）

所有 curl POST 必须使用 `-d @file` 传 JSON，禁止 bash 内联：

```bash
# 1. 先写 JSON 到临时文件
cat > /tmp/test-input.json <<'EOF'
{"data":{"fieldName":"test","domainCode":"Product","domainName":"商品","fieldSql":"SELECT 1"}}
EOF

# 2. 用 -d @file 发送
curl -X POST "http://localhost:8088/api/..." \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/test-input.json
```

---

## 四、JS 函数测试规范

### 4.1 纯函数单元测试（Vitest）

纯工具函数（不依赖浏览器 API）用 Vitest 测试：

```javascript
// 示例：日期格式化函数
import { describe, it, expect } from 'vitest';

describe('formatDate', () => {
  it('正常日期 → 返回 yyyy-MM-dd 格式', () => {
    expect(formatDate('2026-05-20T10:00:00')).toBe('2026-05-20');
  });
  
  it('空值 → 返回空字符串', () => {
    expect(formatDate(null)).toBe('');
    expect(formatDate(undefined)).toBe('');
  });
  
  it('无效日期 → 返回 Invalid Date', () => {
    expect(formatDate('not-a-date')).toBe('Invalid Date');
  });
});
```

### 4.2 浏览器全局函数测试（Playwright page.evaluate）

必须在浏览器环境中运行的函数用 Playwright：

```javascript
test('checkTabPermissions — 有权限返回 true', async ({ page }) => {
  const result = await page.evaluate(() => {
    return window.checkTabPermissions('views/purchasingManagement/index.html', 'add');
  });
  expect(result).toBe(true);
});

test('checkTabPermissions — 无权限返回 false', async ({ page }) => {
  const result = await page.evaluate(() => {
    return window.checkTabPermissions('views/purchasingManagement/index.html', 'delete');
  });
  expect(result).toBe(false);
});
```

### 4.3 测试覆盖维度

| 维度 | 说明 |
|------|------|
| 正常输入 | 典型参数，验证预期输出 |
| 边界值 | 空字符串、0、负数、极大值、`null`、`undefined` |
| 异常输入 | 错误类型、格式错误、注入字符 |
| 副作用 | 是否修改了全局状态、是否触发了 API 调用 |

---

## 五、测试命名与目录规范

### 5.1 文件命名

```
playwright/
├── {模块名}-e2e.spec.js           # E2E 流程测试
├── {模块名}-ui-interaction.spec.js # UI 交互测试
├── test-{功能描述}.spec.js         # Bug 回归验证
└── helpers/
    └── mock-data.js                # 共享 Mock 数据（可选）
```

### 5.2 测试用例命名

格式：`{场景} → {预期结果}` 或 `{场景} — {操作} → {预期}`

```javascript
// 推荐
test('新增按钮 — 点击 → 弹窗打开', ...);
test('搜索 — 输入关键词 → 列表过滤', ...);
test('编辑弹窗 — 修改后点取消 → 数据不变', ...);
test('checkTabPermissions — 不存在的 path → 返回 false', ...);

// 不推荐
test('test add button', ...);
test('test case 1', ...);
```

### 5.3 截图输出

```
playwright/screenshots/
├── 01-menu-tree.png
├── 02-icon-display.png
└── ...
```

截图路径使用 `path.join(SCREENSHOTS, '描述.png')`。

### 5.4 测试报告

Playwright HTML 报告输出到 `playwright/html-report/`。

---

## 六、测试数据管理

### 6.1 Mock 数据

- Mock 数据嵌入在 spec 文件顶部（`const MOCK_XXX = {...}`）
- 与 `shared/requirements/` 中 API 契约的 Mock 数据保持一致
- 如需复用，可提取到 `playwright/helpers/mock-data.js`

### 6.2 测试数据原则

| 原则 | 说明 |
|------|------|
| 独立 | 每个测试用例使用自己构造的数据，不依赖执行顺序 |
| 标识 | 测试数据用明显的前缀，如 `test-`、`qa-`、`mock-` |
| 清理 | 测试后清理创建的数据（通过 API 删除或标记为测试数据） |
| 脱敏 | 不使用真实用户数据、手机号、身份证号 |

### 6.3 Mock 与 API 契约同步

当 API 契约变更时，Mock 数据必须同步更新。测试中发现 Mock 数据与实际 API 响应不一致时，按照 API 实际响应修正 Mock。

---

## 七、回归测试

### 7.1 回归用例管理

每次 Bug 修复后，在对应模块的 spec 文件中追加一条回归用例：

```javascript
// REGRESSION: Bug 2026-05-20 — 供应商删除按钮在无权限时仍显示
test('回归 — 供应商删除按钮无权限时应隐藏', async ({ page }) => {
  await page.evaluate(() => {
    const item = window.appContext.menu.items.find(m => m.path.includes('supplierManage'));
    if (item) item.menuButtons = ['search', 'add']; // 不含 delete
  });
  
  await page.reload();
  const deleteBtn = page.locator('button:has-text("删除")');
  await expect(deleteBtn).toBeHidden();
});
```

### 7.2 回归用例命名

```
test('回归 — {Bug描述} → {修复后预期}', ...);
```

### 7.3 回归测试时机

| 触发条件 | 操作 |
|---------|------|
| Bug 修复后 | 立即追加回归用例 |
| 每次功能完成 | 运行该模块全部回归用例 |
| 发版前 | 运行全部回归用例 |

---

## 八、测试执行

### 8.1 本地执行命令

```bash
cd AgentTeams/qa

# === Mock 模式（默认，不依赖后端） ===
npx playwright test                        # 全部 spec
USE_MOCK=true npx playwright test          # 显式指定（同上）

# === 真实后端模式（联调验证） ===
USE_MOCK=false npx playwright test         # 全部 spec

# === 其他选项 ===
npx playwright test playwright/<spec>      # 单个 spec
npx playwright test --headed               # 可视模式（调试/截图证据）
USE_MOCK=false npx playwright test --headed  # 真实后端 + 可视
npx playwright test --ui                   # UI 交互式调试
npx playwright test --list                 # 列出测试（不执行，检查语法）
```

> `USE_MOCK` 由 `playwright.config.js` 的 `use.useMock` 字段传递给 spec，默认 `true`（向后兼容）。spec 中通过 `test.info().project.use.useMock` 获取。

### 8.2 Playwright 测试认证与 Mock

本项目支持 **Mock 模式**和**真实后端模式**双模式，通过环境变量 `USE_MOCK` 切换（默认 `true`，向后兼容）。

**Mock 模式**（`USE_MOCK=true`，默认，与开发 Mock 数据一致）：

```javascript
async function setupMockedPage(page, useMock) {
  if (!useMock) return;  // 真实后端模式，跳过所有 Mock

  await page.route('**/api/context-user/current-user', route => {
    route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_USER) });
  });
  await page.route('**/api/menu-proxy/get-list-by-role', route => {
    route.fulfill({ contentType: 'application/json', body: JSON.stringify(MOCK_MENU) });
  });
}

test('用例名', async ({ page }) => {
  const useMock = test.info().project.use.useMock;
  await setupMockedPage(page, useMock);
  // ...
});
```

**Standalone 脚本**（非 `@playwright/test`）直接用环境变量：

```javascript
const useMock = process.env.USE_MOCK !== 'false';
if (useMock) {
  // page.route() 注册
}
```

**关键点**：
- Mock 路由使用通配符 `**/api/**` 匹配所有端口，避免端口硬编码导致路由死代码
- Mock 数据与 `shared/requirements/` 中 API 契约的 Mock 数据保持一致
- 认证相关 API 必须在 `page.goto()` 之前完成 mock，否则页面可能因 401 跳转
- `USE_MOCK=false` 时所有 `page.route()` 跳过，请求直发后端，用于联调验证
- 同一套 spec，Mock 和真实后端各跑一次，不写两套脚本

### 8.3 执行前检查

- 前端 dev server 已启动（端口见 `playwright.config.js` 的 `baseURL`）
- `USE_MOCK=false` 模式时：后端 API 已启动且可访问
- `AgentTeams/qa/node_modules` 已安装
- 测试数据干净（无上次测试残留）

### 8.4 测试报告查看

```bash
npx playwright show-report playwright/html-report/
```

### 8.5 CI 规划（中期）

当前手动执行。未来可对接到 CI 流水线，配合以下方式触发：
- `npx playwright test` + `--reporter=html` 生成报告
- 失败时截图自动保存（`screenshot: 'only-on-failure'`）

---

## 附录 A：测试文件分工

| 测试内容 | 文件位置 | 编写者 |
|---------|---------|--------|
| .cs 单元测试 | 项目 `.Tests/` 目录 | Developer |
| JS 纯函数测试 | `qa/vitest/` 目录 | Developer1 |
| API 接口测试 | `qa/playwright/api-*.spec.js` | QA |
| UI 交互测试 | `qa/playwright/{模块}-ui-interaction.spec.js` | QA |
| E2E 流程测试 | `qa/playwright/{模块}-e2e.spec.js` | QA |
| 回归测试 | 追加到已有 spec 文件 | QA |

## 附录 B：现有测试资产盘点

| 类别 | 数量 | 覆盖范围 | 缺口 |
|------|------|---------|------|
| E2E 流程 | 约 3 个 spec（menu-e2e, iframe-embedded-e2e, e2e-real-data） | 菜单、路由、权限、iframe 桥接、真实数据 | 无业务模块覆盖 |
| Bug 回归 | 约 18 个 spec（test-*.spec.js + fixes/netfix verification） | 主题注入、Token 循环、端口、postMessage 等 | 只在代码级别验证 |
| UI 交互 | 1 个 spec（supplierManage-ui-interaction） | 供应商管理页面交互 | 大量业务模块缺失 |
| API 接口 | 0 | — | 完全缺失 |
| 单元测试 | 0 | — | 缺失前后端单元测试 |

> 所有 spec 已支持 `USE_MOCK` 双模式切换（#007）。Mock 模式下不依赖后端，`USE_MOCK=false` 切换真实后端联调。

## 附录 C：测试验收清单

每个功能模块在上线前必须通过以下检查：

- [ ] 后端单元测试通过（如有 .cs 变更）
- [ ] 前端单元测试通过（如有纯 JS 函数变更）
- [ ] API 测试：正常返回 + 异常返回 + 边界值
- [ ] UI 交互测试：按钮/弹窗/表单/列表交互覆盖
- [ ] 权限联动测试（如有权限控制）
- [ ] 无 console error（Uncaught/TypeError/ReferenceError）
- [ ] 回归用例已追加（如有 Bug 修复）
- [ ] 测试报告已输出到 `AgentTeams/logs/`
