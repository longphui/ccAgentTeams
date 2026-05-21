#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"

send() {
  local f="$1" name="$2"
  local resp=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null)
  echo "$name: $resp"
}

# === 产品管理 children (parent DB ID: 4714) ===
cat > /tmp/menu_child_3_36.json << 'JSONEOF'
{"Data":{"title":"物料管理","name":"menu_3_36","path":"views/product_management/material/index.html","component":"views/product_management/material/index.html","redirect":"","parentId":4714,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-物料管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_31.json << 'JSONEOF'
{"Data":{"title":"商品列表","name":"menu_3_31","path":"views/product_management/product/index.html","component":"views/product_management/product/index.html","redirect":"","parentId":4714,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-商品列表","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_32.json << 'JSONEOF'
{"Data":{"title":"商品分类","name":"menu_3_32","path":"views/product_management/category/index.html","component":"views/product_management/category/index.html","redirect":"","parentId":4714,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-商品分类","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_33.json << 'JSONEOF'
{"Data":{"title":"品牌管理","name":"menu_3_33","path":"views/product_management/brand/index.html","component":"views/product_management/brand/index.html","redirect":"","parentId":4714,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-品牌管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_35.json << 'JSONEOF'
{"Data":{"title":"计量单位管理","name":"menu_3_35","path":"views/product_management/unit/index.html","component":"views/product_management/unit/index.html","redirect":"","parentId":4714,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-计量单位管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_36b.json << 'JSONEOF'
{"Data":{"title":"产品档案","name":"menu_3_36b","path":"views/product_management/cartonFile/index.html","component":"views/product_management/cartonFile/index.html","redirect":"","parentId":4714,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-产品档案","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

cat > /tmp/menu_child_3_37.json << 'JSONEOF'
{"Data":{"title":"产品价格调整","name":"menu_3_37","path":"views/product_management/cartonFile/index.html","component":"views/product_management/cartonFile/index.html","redirect":"","parentId":4714,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-产品价格调整","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

echo "=== 产品管理 children ==="
send /tmp/menu_child_3_36.json "物料管理"
send /tmp/menu_child_3_31.json "商品列表"
send /tmp/menu_child_3_32.json "商品分类"
send /tmp/menu_child_3_33.json "品牌管理"
send /tmp/menu_child_3_35.json "计量单位管理"
send /tmp/menu_child_3_36b.json "产品档案"
send /tmp/menu_child_3_37.json "产品价格调整"
