#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"
send() { local f="$1" n="$2"; local r=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null); echo "$n: $r"; }
X=/tmp/x.json

# ===== 基础数据(4753) children =====
cat > $X << 'EOF'
{"Data":{"title":"工单类型","name":"menu_10_1003_100303","path":"views/production/workorder_type/index.html","component":"views/production/workorder_type/index.html","redirect":"","parentId":4753,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工单类型","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "工单类型"
cat > $X << 'EOF'
{"Data":{"title":"工作中心","name":"menu_10_1003_100301","path":"views/production/workcenter/index.html","component":"views/production/workcenter/index.html","redirect":"","parentId":4753,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工作中心","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "工作中心"
cat > $X << 'EOF'
{"Data":{"title":"产线","name":"menu_10_1003_100302","path":"views/production/production_line/index.html","component":"views/production/production_line/index.html","redirect":"","parentId":4753,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-产线","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "产线"
cat > $X << 'EOF'
{"Data":{"title":"班组","name":"menu_10_1003_100304","path":"views/production/workTeam/index.html","component":"views/production/workTeam/index.html","redirect":"","parentId":4753,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-班组","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "班组"

# ===== 订单排程(4754) children =====
cat > $X << 'EOF'
{"Data":{"title":"瓦楞机排程","name":"menu_10_1002_100201","path":"views/production/orderScheduling/corrugator/index.html","component":"views/production/orderScheduling/corrugator/index.html","redirect":"","parentId":4754,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-瓦楞机排程","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send $X "瓦楞机排程"
cat > $X << 'EOF'
{"Data":{"title":"后道设备排程","name":"menu_10_1002_100202","path":"views/production/orderScheduling/postProcess/index.html","component":"views/production/orderScheduling/postProcess/index.html","redirect":"","parentId":4754,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-后道设备排程","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send $X "后道设备排程"

# ===== 设备信息(4757) child =====
cat > $X << 'EOF'
{"Data":{"title":"IoT实时监控","name":"menu_10_1006_100601","path":"views/production/iotMonitor/index.html","component":"views/production/iotMonitor/index.html","redirect":"","parentId":4757,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-desktop","iconImageUrl":"","Describe":"鸿冠ERP-IoT实时监控","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "IoT实时监控"

# ===== 采购申请单(4762) children =====
cat > $X << 'EOF'
{"Data":{"title":"我的采购申请单","name":"menu_7_75_751","path":"views/purchasing/purchaseRequisition/myPurchaseRequisition/index.html","component":"views/purchasing/purchaseRequisition/myPurchaseRequisition/index.html","redirect":"","parentId":4762,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-我的采购申请单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send $X "我的采购申请单"
cat > $X << 'EOF'
{"Data":{"title":"申请单审核","name":"menu_7_75_752","path":"views/purchasing/purchaseRequisition/review/index.html","component":"views/purchasing/purchaseRequisition/review/index.html","redirect":"","parentId":4762,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-申请单审核","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send $X "申请单审核"

# ===== 仓储管理(4768) children =====
cat > $X << 'EOF'
{"Data":{"title":"仓储总览","name":"menu_6_61_609","path":"views/warehousing/inventory_query/index.html","component":"views/warehousing/inventory_query/index.html","redirect":"","parentId":4768,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-仓储总览","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "仓储总览"
cat > $X << 'EOF'
{"Data":{"title":"库区库位","name":"menu_6_61_610","path":"views/warehousing/reservoirAreaAndLocation/index.html","component":"views/warehousing/reservoirAreaAndLocation/index.html","redirect":"","parentId":4768,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-库区库位","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "库区库位"
cat > $X << 'EOF'
{"Data":{"title":"库存查询","name":"menu_6_61_611","path":"views/warehousing/inventory/index.html","component":"views/warehousing/inventory/index.html","redirect":"","parentId":4768,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-库存查询","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "库存查询"
cat > $X << 'EOF'
{"Data":{"title":"原纸库存","name":"menu_6_61_6111","path":"views/warehousing/Inventory/rawPaperInventory/index.html","component":"views/warehousing/Inventory/rawPaperInventory/index.html","redirect":"","parentId":4768,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-原纸库存","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "原纸库存"
cat > $X << 'EOF'
{"Data":{"title":"库存流水","name":"menu_6_61_600","path":"views/warehousing/inventory_record/index.html","component":"views/warehousing/inventory_record/index.html","redirect":"","parentId":4768,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-库存流水","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "库存流水"
cat > $X << 'EOF'
{"Data":{"title":"入库管理","name":"menu_6_61_612","path":"views/warehousing/inbound/index.html","component":"views/warehousing/inbound/index.html","redirect":"","parentId":4768,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-入库管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "入库管理"
cat > $X << 'EOF'
{"Data":{"title":"出库管理","name":"menu_6_61_613","path":"views/warehousing/stock_out_management/index.html","component":"views/warehousing/stock_out_management/index.html","redirect":"","parentId":4768,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-出库管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "出库管理"
cat > $X << 'EOF'
{"Data":{"title":"出库单列表","name":"menu_6_61_6131","path":"views/warehousing/outbound_order/index.html","component":"views/warehousing/outbound_order/index.html","redirect":"","parentId":4768,"menuSort":80,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-出库单列表","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "出库单列表"
cat > $X << 'EOF'
{"Data":{"title":"调拨管理","name":"menu_6_61_614","path":"views/warehousing/stock_transfer_management/index.html","component":"views/warehousing/stock_transfer_management/index.html","redirect":"","parentId":4768,"menuSort":90,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-调拨管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "调拨管理"
cat > $X << 'EOF'
{"Data":{"title":"盘点管理","name":"menu_6_61_615","path":"views/warehousing/stock_check_management/index.html","component":"views/warehousing/stock_check_management/index.html","redirect":"","parentId":4768,"menuSort":100,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-盘点管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "盘点管理"
cat > $X << 'EOF'
{"Data":{"title":"报损管理","name":"menu_6_61_616","path":"views/warehousing/stock_damage_management/index.html","component":"views/warehousing/stock_damage_management/index.html","redirect":"","parentId":4768,"menuSort":110,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-报损管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "报损管理"
cat > $X << 'EOF'
{"Data":{"title":"库存预警","name":"menu_6_61_617","path":"views/warehousing/stock_warning_management/index.html","component":"views/warehousing/stock_warning_management/index.html","redirect":"","parentId":4768,"menuSort":120,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-库存预警","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "库存预警"
cat > $X << 'EOF'
{"Data":{"title":"批次管理","name":"menu_6_61_619","path":"views/warehousing/batch/index.html","component":"views/warehousing/batch/index.html","redirect":"","parentId":4768,"menuSort":130,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-批次管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "批次管理"
cat > $X << 'EOF'
{"Data":{"title":"仓库设置","name":"menu_6_61_618","path":"views/warehousing/warehouse_settings/index.html","component":"views/warehousing/warehouse_settings/index.html","redirect":"","parentId":4768,"menuSort":140,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-仓库设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "仓库设置"

# ===== 物流管理(4769) children =====
cat > $X << 'EOF'
{"Data":{"title":"运输管理","name":"menu_6_62_621","path":"views/logistics/logistics_management/transportation_management.html","component":"views/logistics/logistics_management/transportation_management.html","redirect":"","parentId":4769,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-运输管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "运输管理"
cat > $X << 'EOF'
{"Data":{"title":"配送管理","name":"menu_6_62_622","path":"views/logistics/logistics_management/distribution_management.html","component":"views/logistics/logistics_management/distribution_management.html","redirect":"","parentId":4769,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-配送管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "配送管理"
cat > $X << 'EOF'
{"Data":{"title":"物流跟踪","name":"menu_6_62_623","path":"views/logistics/logistics_management/logistics_tracking.html","component":"views/logistics/logistics_management/logistics_tracking.html","redirect":"","parentId":4769,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-物流跟踪","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "物流跟踪"
cat > $X << 'EOF'
{"Data":{"title":"物流公司管理","name":"menu_6_62_624","path":"views/logistics/logistics_management/logistics_company.html","component":"views/logistics/logistics_management/logistics_company.html","redirect":"","parentId":4769,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-物流公司管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "物流公司管理"
cat > $X << 'EOF'
{"Data":{"title":"配送方式管理","name":"menu_6_62_625","path":"views/logistics/logistics_management/logistics_type.html","component":"views/logistics/logistics_management/logistics_type.html","redirect":"","parentId":4769,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-配送方式管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "配送方式管理"

# ===== 售后管理(4770) children =====
cat > $X << 'EOF'
{"Data":{"title":"退货管理","name":"menu_6_63_631","path":"views/logistics/aftersales_management/return_management.html","component":"views/logistics/aftersales_management/return_management.html","redirect":"","parentId":4770,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-退货管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "退货管理"
cat > $X << 'EOF'
{"Data":{"title":"换货管理","name":"menu_6_63_632","path":"views/logistics/aftersales_management/exchange_management.html","component":"views/logistics/aftersales_management/exchange_management.html","redirect":"","parentId":4770,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-换货管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "换货管理"
cat > $X << 'EOF'
{"Data":{"title":"维修管理","name":"menu_6_63_633","path":"views/logistics/aftersales_management/repair_management.html","component":"views/logistics/aftersales_management/repair_management.html","redirect":"","parentId":4770,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-维修管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "维修管理"

# ===== 组织架构(4771) children =====
cat > $X << 'EOF'
{"Data":{"title":"组织管理","name":"menu_8_81_811","path":"views/hr/org/orgManage/index.html","component":"views/hr/org/orgManage/index.html","redirect":"","parentId":4771,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sitemap","iconImageUrl":"","Describe":"鸿冠ERP-组织管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "组织管理"
cat > $X << 'EOF'
{"Data":{"title":"组织类型","name":"menu_8_81_812","path":"views/hr/org/orgType/index.html","component":"views/hr/org/orgType/index.html","redirect":"","parentId":4771,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sitemap","iconImageUrl":"","Describe":"鸿冠ERP-组织类型","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "组织类型"
cat > $X << 'EOF'
{"Data":{"title":"角色管理","name":"menu_8_81_813","path":"views/hr/org/positionManage/index.html","component":"views/hr/org/positionManage/index.html","redirect":"","parentId":4771,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sitemap","iconImageUrl":"","Describe":"鸿冠ERP-角色管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "角色管理"

# ===== 考勤管理(4773) children =====
cat > $X << 'EOF'
{"Data":{"title":"默认工作时间","name":"menu_8_82_821","path":"views/hr/attendance/defaultTime/index.html","component":"views/hr/attendance/defaultTime/index.html","redirect":"","parentId":4773,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-clock-o","iconImageUrl":"","Describe":"鸿冠ERP-默认工作时间","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "默认工作时间"
cat > $X << 'EOF'
{"Data":{"title":"企业日历设置","name":"menu_8_82_822","path":"views/hr/attendance/enterpriseCalendarSet/index.html","component":"views/hr/attendance/enterpriseCalendarSet/index.html","redirect":"","parentId":4773,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-clock-o","iconImageUrl":"","Describe":"鸿冠ERP-企业日历设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "企业日历设置"

# ===== 薪资管理(4774) children =====
cat > $X << 'EOF'
{"Data":{"title":"员工薪资","name":"menu_8_83_831","path":"views/hr/salary/employeeSalary/index.html","component":"views/hr/salary/employeeSalary/index.html","redirect":"","parentId":4774,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-员工薪资","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send $X "员工薪资"
cat > $X << 'EOF'
{"Data":{"title":"薪资计算公式","name":"menu_8_83_832","path":"views/hr/salary/salaryFormula/index.html","component":"views/hr/salary/salaryFormula/index.html","redirect":"","parentId":4774,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-薪资计算公式","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "薪资计算公式"
cat > $X << 'EOF'
{"Data":{"title":"计件规则设置","name":"menu_8_83_833","path":"views/hr/salary/ruleSettings/pieceRateWageRule/index.html","component":"views/hr/salary/ruleSettings/pieceRateWageRule/index.html","redirect":"","parentId":4774,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-计件规则设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "计件规则设置"
cat > $X << 'EOF'
{"Data":{"title":"员工系数设置","name":"menu_8_83_834","path":"views/hr/salary/ruleSettings/pieceRateWorkerCoefficient/index.html","component":"views/hr/salary/ruleSettings/pieceRateWorkerCoefficient/index.html","redirect":"","parentId":4774,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-员工系数设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "员工系数设置"

# ===== 员工管理(4781) children =====
cat > $X << 'EOF'
{"Data":{"title":"员工档案","name":"menu_8_90b_901","path":"views/hr/employee/employeeArchive/index.html","component":"views/hr/employee/employeeArchive/index.html","redirect":"","parentId":4781,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-员工档案","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "员工档案"
cat > $X << 'EOF'
{"Data":{"title":"离职员工","name":"menu_8_90b_902","path":"views/hr/employee/employeeFormer/index.html","component":"views/hr/employee/employeeFormer/index.html","redirect":"","parentId":4781,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-离职员工","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "离职员工"
cat > $X << 'EOF'
{"Data":{"title":"临时员工","name":"menu_8_90b_903","path":"views/hr/employee/employeeTemporary/index.html","component":"views/hr/employee/employeeTemporary/index.html","redirect":"","parentId":4781,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-临时员工","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "临时员工"

# ===== 权限管理-HR(4782) children =====
cat > $X << 'EOF'
{"Data":{"title":"系统权限","name":"menu_8_91_910","path":"views/hr/permission/systemPermissions/index.html","component":"views/hr/permission/systemPermissions/index.html","redirect":"","parentId":4782,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-系统权限","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "系统权限"
cat > $X << 'EOF'
{"Data":{"title":"角色权限","name":"menu_8_91_911","path":"views/hr/permission/rolePermissions/index.html","component":"views/hr/permission/rolePermissions/index.html","redirect":"","parentId":4782,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-角色权限","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "角色权限"
cat > $X << 'EOF'
{"Data":{"title":"账号权限","name":"menu_8_91_912","path":"views/hr/permission/accountPermissions/index.html","component":"views/hr/permission/accountPermissions/index.html","redirect":"","parentId":4782,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-账号权限","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "账号权限"
cat > $X << 'EOF'
{"Data":{"title":"批量设置","name":"menu_8_91_913","path":"views/hr/permission/batchSetting/index.html","component":"views/hr/permission/batchSetting/index.html","redirect":"","parentId":4782,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-批量设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send $X "批量设置"

echo "=== BATCH 3 DONE ==="
