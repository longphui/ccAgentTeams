#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"

send() { local f="$1" n="$2"; local r=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null); echo "$n: $r"; }

# ===== 产品档案(4736) children =====
cat > /tmp/l2_1.json << 'EOF'
{"Data":{"title":"纸箱档案","name":"menu_3_36_361","path":"views/product_management/productFile/cartonFile/index.html","component":"views/product_management/productFile/cartonFile/index.html","redirect":"","parentId":4736,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-纸箱档案","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
cat > /tmp/l2_2.json << 'EOF'
{"Data":{"title":"套件管理","name":"menu_3_36_362","path":"views/product_management/productFile/suite/index.html","component":"views/product_management/productFile/suite/index.html","redirect":"","parentId":4736,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-套件管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
cat > /tmp/l2_3.json << 'EOF'
{"Data":{"title":"组件明细","name":"menu_3_36_363","path":"views/product_management/productFile/suiteDetail/index.html","component":"views/product_management/productFile/suiteDetail/index.html","redirect":"","parentId":4736,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-组件明细","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
echo "=== 产品档案 children ==="
send /tmp/l2_1.json "纸箱档案"
send /tmp/l2_2.json "套件管理"
send /tmp/l2_3.json "组件明细"

# ===== 产品价格调整(4737) children =====
cat > /tmp/l2_4.json << 'EOF'
{"Data":{"title":"调价原因","name":"menu_3_37_370","path":"views/product_management/productPriceAdjust/priceAdjust/index.html","component":"views/product_management/productPriceAdjust/priceAdjust/index.html","redirect":"","parentId":4737,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-调价原因","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
cat > /tmp/l2_5.json << 'EOF'
{"Data":{"title":"价格调整申请单","name":"menu_3_37_371","path":"views/product_management/productPriceAdjust/customerReason/index.html","component":"views/product_management/productPriceAdjust/customerReason/index.html","redirect":"","parentId":4737,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-价格调整申请单","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF
cat > /tmp/l2_6.json << 'EOF'
{"Data":{"title":"成本原因","name":"menu_3_37_372","path":"views/product_management/productPriceAdjust/costReasons/index.html","component":"views/product_management/productPriceAdjust/costReasons/index.html","redirect":"","parentId":4737,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-成本原因","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF
echo "=== 产品价格调整 children ==="
send /tmp/l2_4.json "调价原因"
send /tmp/l2_5.json "价格调整申请单"
send /tmp/l2_6.json "成本原因"
