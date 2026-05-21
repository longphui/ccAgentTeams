#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"

send() {
  local f="$1" name="$2"
  local resp=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null)
  echo "$name: $resp"
}

# ===== 产品价格调整 (fixed path) =====
cat > /tmp/mc_3_37.json << 'EOF'
{"Data":{"title":"产品价格调整","name":"menu_3_37","path":"views/product_management/productPriceAdjust/index.html","component":"views/product_management/productPriceAdjust/index.html","redirect":"","parentId":4714,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-产品价格调整","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/mc_3_37.json "产品价格调整(fixed)"

# ===== 工艺管理 children (parent DB ID: 4715) =====
cat > /tmp/mc_9_91.json << 'EOF'
{"Data":{"title":"工序管理","name":"menu_9_91","path":"views/product_management/process/index.html","component":"views/product_management/process/index.html","redirect":"","parentId":4715,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工序管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_9_92.json << 'EOF'
{"Data":{"title":"工艺路线管理","name":"menu_9_92","path":"views/product_management/routing/index.html","component":"views/product_management/routing/index.html","redirect":"","parentId":4715,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工艺路线管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_9_93.json << 'EOF'
{"Data":{"title":"BOM设计","name":"menu_9_93","path":"views/product_management/bom/index.html","component":"views/product_management/bom/index.html","redirect":"","parentId":4715,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-BOM设计","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_9_94.json << 'EOF'
{"Data":{"title":"产品设计","name":"menu_9_94","path":"views/marketing/sales_performance/index.html","component":"views/marketing/sales_performance/index.html","redirect":"","parentId":4715,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-产品设计","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_9_95.json << 'EOF'
{"Data":{"title":"工艺工序设计","name":"menu_9_95","path":"views/product_management/processDesign/index.html","component":"views/product_management/processDesign/index.html","redirect":"","parentId":4715,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-工艺工序设计","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 工艺管理 children ==="
send /tmp/mc_9_91.json "工序管理"
send /tmp/mc_9_92.json "工艺路线管理"
send /tmp/mc_9_93.json "BOM设计"
send /tmp/mc_9_94.json "产品设计"
send /tmp/mc_9_95.json "工艺工序设计"

# ===== 营销管理 children (parent DB ID: 4716) =====
cat > /tmp/mc_5_51.json << 'EOF'
{"Data":{"title":"销售计划","name":"menu_5_51","path":"views/marketing/marketing_plans/index.html","component":"views/marketing/marketing_plans/index.html","redirect":"","parentId":4716,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-销售计划","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_52.json << 'EOF'
{"Data":{"title":"订单管理","name":"menu_5_52","path":"views/marketing/sales_order/index.html","component":"views/marketing/sales_order/index.html","redirect":"","parentId":4716,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-订单管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_55.json << 'EOF'
{"Data":{"title":"发货管理","name":"menu_5_55","path":"views/marketing/order_delivery/index.html","component":"views/marketing/order_delivery/index.html","redirect":"","parentId":4716,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-发货管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_53.json << 'EOF'
{"Data":{"title":"销售业绩","name":"menu_5_53","path":"views/marketing/sales_performance/index.html","component":"views/marketing/sales_performance/index.html","redirect":"","parentId":4716,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-销售业绩","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_54.json << 'EOF'
{"Data":{"title":"客户管理","name":"menu_5_54","path":"views/marketing/customers/index.html","component":"views/marketing/customers/index.html","redirect":"","parentId":4716,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-客户管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_5_56.json << 'EOF'
{"Data":{"title":"销售订单","name":"menu_5_56","path":"views/marketing/orderManagement/index.html","component":"views/marketing/orderManagement/index.html","redirect":"","parentId":4716,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-销售订单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_5_57.json << 'EOF'
{"Data":{"title":"基础设置","name":"menu_5_57","path":"views/marketing/basicSettings/index.html","component":"views/marketing/basicSettings/index.html","redirect":"","parentId":4716,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-营销基础设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_59.json << 'EOF'
{"Data":{"title":"纸箱报价","name":"menu_5_59","path":"views/marketing/box_quotation/index.html","component":"views/marketing/box_quotation/index.html","redirect":"","parentId":4716,"menuSort":80,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-calculator","iconImageUrl":"","Describe":"鸿冠ERP-纸箱报价","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_5_58.json << 'EOF'
{"Data":{"title":"运费管理","name":"menu_5_58","path":"views/marketing/freight/index.html","component":"views/marketing/freight/index.html","redirect":"","parentId":4716,"menuSort":90,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-rmb","iconImageUrl":"","Describe":"鸿冠ERP-运费管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 营销管理 children ==="
send /tmp/mc_5_51.json "销售计划"
send /tmp/mc_5_52.json "订单管理"
send /tmp/mc_5_55.json "发货管理"
send /tmp/mc_5_53.json "销售业绩"
send /tmp/mc_5_54.json "客户管理"
send /tmp/mc_5_56.json "销售订单"
send /tmp/mc_5_57.json "基础设置"
send /tmp/mc_5_59.json "纸箱报价"
send /tmp/mc_5_58.json "运费管理"
