#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"
send() { local f="$1" n="$2"; local r=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null); echo "$n: $r"; }

# ===== 产品设计(4741) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"新产品申请单","name":"menu_9_94_9410","path":"views/product_management/productDesign/ProductApplicationForm/index.html","component":"views/product_management/productDesign/ProductApplicationForm/index.html","redirect":"","parentId":4741,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-新产品申请单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "新产品申请单"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"工艺单","name":"menu_9_94_9411","path":"views/product_management/productDesign/processForm/index.html","component":"views/product_management/productDesign/processForm/index.html","redirect":"","parentId":4741,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-工艺单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "工艺单"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"产品变更申请单","name":"menu_9_94_9413","path":"views/product_management/productDesign/productChangeForm/index.html","component":"views/product_management/productDesign/productChangeForm/index.html","redirect":"","parentId":4741,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-产品变更申请单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "产品变更申请单"

# ===== 工艺工序设计(4742) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"工艺类型管理","name":"menu_9_95_9410","path":"views/product_management/processDesign/processTypeManagement/index.html","component":"views/product_management/processDesign/processTypeManagement/index.html","redirect":"","parentId":4742,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-工艺类型管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "工艺类型管理"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"工艺管理","name":"menu_9_95_9411","path":"views/product_management/processDesign/processManagement/index.html","component":"views/product_management/processDesign/processManagement/index.html","redirect":"","parentId":4742,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-工艺管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "工艺工序-工艺管理"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"关联设备与工艺","name":"menu_9_95_9412","path":"views/product_management/processDesign/equipmentProcessAssociation/index.html","component":"views/product_management/processDesign/equipmentProcessAssociation/index.html","redirect":"","parentId":4742,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-关联设备与工艺","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "关联设备与工艺"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"楞型管理","name":"menu_9_95_9417","path":"views/product_management/processDesign/LengType/index.html","component":"views/product_management/processDesign/LengType/index.html","redirect":"","parentId":4742,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-楞型管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "楞型管理"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"箱型管理","name":"menu_9_95_94131","path":"views/product_management/processDesign/boxTypeManagement/index.html","component":"views/product_management/processDesign/boxTypeManagement/index.html","redirect":"","parentId":4742,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-箱型管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "箱型管理"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"纸板BOM","name":"menu_9_95_9418","path":"views/product_management/processDesign/cardboardBOM/index.html","component":"views/product_management/processDesign/cardboardBOM/index.html","redirect":"","parentId":4742,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-纸板BOM","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "纸板BOM"

# ===== 发货管理(4745) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"车辆管理","name":"menu_5_55_551","path":"views/marketing/order_delivery/vehicleFile/index.html","component":"views/marketing/order_delivery/vehicleFile/index.html","redirect":"","parentId":4745,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-车辆管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "车辆管理"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"发货配送","name":"menu_5_55_552","path":"views/marketing/order_delivery/deliveryDistribution/index.html","component":"views/marketing/order_delivery/deliveryDistribution/index.html","redirect":"","parentId":4745,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-发货配送","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "发货配送"

# ===== 销售业绩(4746) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"销售统计","name":"menu_5_53_5310","path":"views/marketing/sales_performance/summary.html","component":"views/marketing/sales_performance/summary.html","redirect":"","parentId":4746,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-销售统计","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "销售统计"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"业绩报告","name":"menu_5_53_5311","path":"views/marketing/sales_performance/reports.html","component":"views/marketing/sales_performance/reports.html","redirect":"","parentId":4746,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-业绩报告","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "业绩报告"

# ===== 客户管理(4747) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"客户档案","name":"menu_5_54_541","path":"views/marketing/customers/customerProfile/index.html","component":"views/marketing/customers/customerProfile/index.html","redirect":"","parentId":4747,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-客户档案","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "客户档案"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"我的客户","name":"menu_5_54_542","path":"views/marketing/customers/myCustomer/index.html","component":"views/marketing/customers/myCustomer/index.html","redirect":"","parentId":4747,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-我的客户","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "我的客户"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"信用额度审批","name":"menu_5_54_543","path":"views/marketing/customers/creditLimit/index.html","component":"views/marketing/customers/creditLimit/index.html","redirect":"","parentId":4747,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-信用额度审批","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "信用额度审批"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"业务员审批","name":"menu_5_54_544","path":"views/marketing/customers/adjustSalespersonApproval/index.html","component":"views/marketing/customers/adjustSalespersonApproval/index.html","redirect":"","parentId":4747,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-业务员审批","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "业务员审批"

# ===== 销售订单(4748) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"纸箱订单","name":"menu_5_56_561","path":"views/marketing/orderManagement/cartonOrder/index.html","component":"views/marketing/orderManagement/cartonOrder/index.html","redirect":"","parentId":4748,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-纸箱订单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
send /tmp/x.json "纸箱订单"

# ===== 营销基础设置(4749) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"税率","name":"menu_5_57_571","path":"views/marketing/basicSettings/taxRate/index.html","component":"views/marketing/basicSettings/taxRate/index.html","redirect":"","parentId":4749,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-税率","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "税率"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"支付方式","name":"menu_5_57_572","path":"views/marketing/basicSettings/paymentMethod/index.html","component":"views/marketing/basicSettings/paymentMethod/index.html","redirect":"","parentId":4749,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-支付方式","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "支付方式"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"送货单格式","name":"menu_5_57_573","path":"views/marketing/basicSettings/deliveryNoteFormat/index.html","component":"views/marketing/basicSettings/deliveryNoteFormat/index.html","redirect":"","parentId":4749,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-送货单格式","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "送货单格式"

# ===== 运费管理(4751) children =====
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"运费配置","name":"menu_5_58_581","path":"views/marketing/freight/config/index.html","component":"views/marketing/freight/config/index.html","redirect":"","parentId":4751,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-运费配置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "运费配置"
cat > /tmp/x.json << 'EOF'
{"Data":{"title":"运费汇总","name":"menu_5_58_582","path":"views/marketing/freight/record/index.html","component":"views/marketing/freight/record/index.html","redirect":"","parentId":4751,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-运费汇总","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
send /tmp/x.json "运费汇总"

echo "=== BATCH 2 DONE ==="
