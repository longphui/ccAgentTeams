#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"

send() {
  local f="$1" name="$2"
  local resp=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null)
  echo "$name: $resp"
}

# ===== 生产管理 children (parent DB ID: 4717) =====
cat > /tmp/mc_10_1001.json << 'EOF'
{"Data":{"title":"工单管理","name":"menu_10_1001","path":"views/production/workorder/index.html","component":"views/production/workorder/index.html","redirect":"","parentId":4717,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工单管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_10_1003.json << 'EOF'
{"Data":{"title":"基础数据","name":"menu_10_1003","path":"views/production/basicData/index.html","component":"views/production/basicData/index.html","redirect":"","parentId":4717,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-基础数据","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_10_1002.json << 'EOF'
{"Data":{"title":"订单排程","name":"menu_10_1002","path":"views/production/orderScheduling/index.html","component":"views/production/orderScheduling/index.html","redirect":"","parentId":4717,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-订单排程","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_10_1004.json << 'EOF'
{"Data":{"title":"派工管理","name":"menu_10_1004","path":"views/production/dispatch/index.html","component":"views/production/dispatch/index.html","redirect":"","parentId":4717,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-派工管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_10_1005.json << 'EOF'
{"Data":{"title":"报工管理","name":"menu_10_1005","path":"views/production/report/index.html","component":"views/production/report/index.html","redirect":"","parentId":4717,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-报工管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_10_1006.json << 'EOF'
{"Data":{"title":"设备信息","name":"menu_10_1006","path":"views/production/iotMonitor/index.html","component":"views/production/iotMonitor/index.html","redirect":"","parentId":4717,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-设备信息","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 生产管理 children ==="
send /tmp/mc_10_1001.json "工单管理"
send /tmp/mc_10_1003.json "基础数据"
send /tmp/mc_10_1002.json "订单排程"
send /tmp/mc_10_1004.json "派工管理"
send /tmp/mc_10_1005.json "报工管理"
send /tmp/mc_10_1006.json "设备信息"

# ===== 采购管理 children (parent DB ID: 4718) =====
cat > /tmp/mc_7_71.json << 'EOF'
{"Data":{"title":"采购计划","name":"menu_7_71","path":"views/purchasing/purchase_plans/index.html","component":"views/purchasing/purchase_plans/index.html","redirect":"","parentId":4718,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-采购计划","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_7_72.json << 'EOF'
{"Data":{"title":"采购订单","name":"menu_7_72","path":"views/purchasing/purchase_orders/index.html","component":"views/purchasing/purchase_orders/index.html","redirect":"","parentId":4718,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-采购订单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_7_73.json << 'EOF'
{"Data":{"title":"供应商管理","name":"menu_7_73","path":"views/purchasing/suppliers/index.html","component":"views/purchasing/suppliers/index.html","redirect":"","parentId":4718,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-供应商管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_7_74.json << 'EOF'
{"Data":{"title":"供货清单","name":"menu_7_74","path":"views/purchasing/material-supplier-map/index.html","component":"views/purchasing/material-supplier-map/index.html","redirect":"","parentId":4718,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-供货清单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_7_75.json << 'EOF'
{"Data":{"title":"采购申请单","name":"menu_7_75","path":"views/purchasing/purchaseRequisition/index.html","component":"views/purchasing/purchaseRequisition/index.html","redirect":"","parentId":4718,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-采购申请单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_7_76.json << 'EOF'
{"Data":{"title":"生产需求清单","name":"menu_7_76","path":"views/purchasing/productionDemandList/index.html","component":"views/purchasing/productionDemandList/index.html","redirect":"","parentId":4718,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-生产需求清单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 采购管理 children ==="
send /tmp/mc_7_71.json "采购计划"
send /tmp/mc_7_72.json "采购订单"
send /tmp/mc_7_73.json "供应商管理"
send /tmp/mc_7_74.json "供货清单"
send /tmp/mc_7_75.json "采购申请单"
send /tmp/mc_7_76.json "生产需求清单"
