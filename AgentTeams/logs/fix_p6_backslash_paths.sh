#!/bin/bash
TOKEN="i6WvYGN5zDUnDFKixjMb6FCYs2131SaJfRFyPQAXeRRjRvrS57eJK9HI7z6aTk3yk3aqyVkT2Cb0cVPzjzjKjvh29x2r2r2h3L8CN-1z8zrisUp5mcszv_S2rxwv4s4dezxF6oz4Wr04851r9lhSxE0NwkxYg6sYDSow2ukK9K7Axj0rCBcqWzM5bJWdafkjMmB5op_rXQpXl13RZKs8iXAbZHYde467tDfGlW0KgHtozMIkRg4JEAx6veW8zp3e6f3sm-IAXNowM6Jel5jLlh8vdAr5Paub--3AH9v1iOeoFF1EMXboHA0ZzQmv4mLqaOOH8tW8sw9QNMifTUkm9qyu_Fc2cYcdIYrg9T_jzQhjNllIXQCyeeFj5RiWnscybyi3eXTe9RduOCxQfGGdzJ8lmRFahBSH6P6hHpaDft15MfWqU9PZNLo8wVieth-e1l6_i8lgWF-EJhApFRGispROXQsHvDRF8wA4puvb4lk18E3vgmPY0HNmLeRPyeOAUwrYzVJ1Evt_3Yh07yK3gTLpWZYP1HKo9rXxVHmFJn4cmL8BkYTNyNS1MY-Cto3IWO6fQd6eqm8a9ZhoiZmIOq9OEOSzHP9iIROAYGyMesAZJm4cUQztGGgOv-I-0xGde_kHUTf7wfd89beSaltX5T5YNrWeIxwelYa8nTZdjJo"
TMP="C:/Users/Administrator/AppData/Local/Temp"

echo "=== Fix #1: id=2058 客户商品编码 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_2058.json
echo ""
echo "=== Fix #2: id=582 内置功能启停 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_582.json
echo ""
echo "=== Fix #3: id=644 任务完成情况 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_644.json
echo ""
echo "=== Fix #4: id=645 向供货商下单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_645.json
echo ""
echo "=== Fix #5: id=646 历史预定任务 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_646.json
echo ""
echo "=== Fix #6: id=647 历史下单任务 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_647.json
echo ""
echo "=== Fix #7: id=676 领料管理v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_676.json
echo ""
echo "=== Fix #8: id=611 生产计划 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_611.json
echo ""
echo "=== Fix #9: id=612 装配工单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_612.json
echo ""
echo "=== Fix #10: id=614 工单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_614.json
echo ""
echo "=== Fix #11: id=613 任务 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_613.json
echo ""
echo "=== Fix #12: id=615 报工 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_615.json
echo ""
echo "=== Fix #13: id=616 待审核报工 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_616.json
echo ""
echo "=== Fix #14: id=617 报工工作台 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_617.json
echo ""
echo "=== Fix #15: id=648 未支付未发货 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_648.json
echo ""
echo "=== Fix #16: id=649 未支付已发货 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_649.json
echo ""
echo "=== Fix #17: id=650 待确认的支付 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_650.json
echo ""
echo "=== Fix #18: id=651 已支付订单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_651.json
echo ""
echo "=== Fix #19: id=652 已支付未发货 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_652.json
echo ""
echo "=== Fix #20: id=654 待支付订单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_654.json
echo ""
echo "=== Fix #21: id=653 已支付待确认 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_653.json
echo ""
echo "=== Fix #22: id=657 已支付采购单 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_657.json
echo ""
echo "=== Fix #23: id=578 待开发票v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_578.json
echo ""
echo "=== Fix #24: id=661 申请开发票v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_661.json
echo ""
echo "=== Fix #25: id=662 已开发票v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_662.json
echo ""
echo "=== Fix #26: id=663 税务登记v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_663.json
echo ""
echo "=== Fix #27: id=664 开票前登录v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_664.json
echo ""
echo "=== Fix #28: id=675 主动开具v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_675.json
echo ""
echo "=== Fix #29: id=673 索票信息v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_673.json
echo ""
echo "=== Fix #30: id=679 登记应用v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_679.json
echo ""
echo "=== Fix #31: id=680 已开具v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_680.json
echo ""
echo "=== Fix #32: id=561 销售费用申请 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_561.json
echo ""
echo "=== Fix #33: id=576 对账新增 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_576.json
echo ""
echo "=== Fix #34: id=579 退货查看 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_579.json
echo ""
echo "=== Fix #35: id=600 已审核费用 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_600.json
echo ""
echo "=== Fix #36: id=601 回款查看 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_601.json
echo ""
echo "=== Fix #37: id=564 下达核销任务v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_564.json
echo ""
echo "=== Fix #38: id=565 核销任务完成情况v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_565.json
echo ""
echo "=== Fix #39: id=573 查看历史核销v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_573.json
echo ""
echo "=== Fix #40: id=592 考勤设置v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_592.json
echo ""
echo "=== Fix #41: id=597 考勤信息v2 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_597.json
echo ""
echo "=== Fix #42: id=2088 班次管理 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_2088.json
echo ""
echo "=== Fix #43: id=891 考勤统计 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_891.json
echo ""
echo "=== Fix #44: id=568 企业问卷 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_568.json
echo ""
echo "=== Fix #45: id=569 问卷统计 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_569.json
echo ""
echo "=== Fix #46: id=570 问卷设置 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_570.json
echo ""
echo "=== Fix #47: id=566 日志管理 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_566.json
echo ""
echo "=== Fix #48: id=571 操作日志 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_571.json
echo ""
echo "=== Fix #49: id=900 能耗部门 ==="
curl -s -X POST "http://localhost:8088/api/HRM/MenuRoute/Save" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @$TMP/fix_path_900.json
echo ""
