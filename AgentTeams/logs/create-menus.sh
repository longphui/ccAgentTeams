#!/bin/bash
# Create all 鸿冠 ERP menus in 分路 HRM_MenuRoute table
# Naming: menu_{originalId} incorporating original 鸿冠 menu IDs

TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"
COMMON='H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047"'

# Helper function to create a menu and return the DB ID
create_menu() {
    local json_file="$1"
    local resp=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "$(cat $json_file)" 2>/dev/null)
    echo "$resp"
}

# === LEVEL 0: Top-level menus ===

# 1. 首页 (id:1)
cat > /tmp/menu_create_1.json << 'JSONEOF'
{"Data":{"title":"首页","name":"menu_1","path":"views/dashbord/index/html","component":"views/dashbord/index/html","redirect":"","parentId":0,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-home","iconImageUrl":"","Describe":"鸿冠ERP-首页","PlatformId":12,"PlatformName":"","MenuButtons":[],"children":[]}}
JSONEOF

# 2. 产品管理 (id:3)
cat > /tmp/menu_create_3.json << 'JSONEOF'
{"Data":{"title":"产品管理","name":"menu_3","path":"views/product_management/index.html","component":"views/product_management/index.html","redirect":"","parentId":0,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-cubes","iconImageUrl":"","Describe":"鸿冠ERP-产品管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 3. 工艺管理 (id:9)
cat > /tmp/menu_create_9.json << 'JSONEOF'
{"Data":{"title":"工艺管理","name":"menu_9","path":"views/product_management/process/index.html","component":"views/product_management/process/index.html","redirect":"","parentId":0,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-wrench","iconImageUrl":"","Describe":"鸿冠ERP-工艺管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 4. 营销管理 (id:5)
cat > /tmp/menu_create_5.json << 'JSONEOF'
{"Data":{"title":"营销管理","name":"menu_5","path":"views/marketing/marketing_plans/index.html","component":"views/marketing/marketing_plans/index.html","redirect":"","parentId":0,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-line-chart","iconImageUrl":"","Describe":"鸿冠ERP-营销管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 5. 生产管理 (id:10)
cat > /tmp/menu_create_10.json << 'JSONEOF'
{"Data":{"title":"生产管理","name":"menu_10","path":"views/production/workorder/index.html","component":"views/production/workorder/index.html","redirect":"","parentId":0,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-industry","iconImageUrl":"","Describe":"鸿冠ERP-生产管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 6. 采购管理 (id:7)
cat > /tmp/menu_create_7.json << 'JSONEOF'
{"Data":{"title":"采购管理","name":"menu_7","path":"views/purchase_management/index.html","component":"views/purchase_management/index.html","redirect":"","parentId":0,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-shopping-cart","iconImageUrl":"","Describe":"鸿冠ERP-采购管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 7. 设备管理 (id:11)
cat > /tmp/menu_create_11.json << 'JSONEOF'
{"Data":{"title":"设备管理","name":"menu_11","path":"views/equipment_management/equipment/index.html","component":"views/equipment_management/equipment/index.html","redirect":"","parentId":0,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-server","iconImageUrl":"","Describe":"鸿冠ERP-设备管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 8. 仓储物流管理 (id:6)
cat > /tmp/menu_create_6.json << 'JSONEOF'
{"Data":{"title":"仓储物流管理","name":"menu_6","path":"views/warehousing/inventory_query/index.html","component":"views/warehousing/inventory_query/index.html","redirect":"","parentId":0,"menuSort":80,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-archive","iconImageUrl":"","Describe":"鸿冠ERP-仓储物流管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 9. 项目管理 (id:7 - duplicate, use suffix)
cat > /tmp/menu_create_7b.json << 'JSONEOF'
{"Data":{"title":"项目管理","name":"menu_7_project","path":"views/project/index.html","component":"views/project/index.html","redirect":"","parentId":0,"menuSort":90,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-product-hunt","iconImageUrl":"","Describe":"鸿冠ERP-项目管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 10. 计划管理 (id:11 - duplicate)
cat > /tmp/menu_create_11b.json << 'JSONEOF'
{"Data":{"title":"计划管理","name":"menu_11_plan","path":"views/plan/index.html","component":"views/plan/index.html","redirect":"","parentId":0,"menuSort":100,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-calendar","iconImageUrl":"","Describe":"鸿冠ERP-计划管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 11. 权限管理 (id:3 - duplicate)
cat > /tmp/menu_create_3b.json << 'JSONEOF'
{"Data":{"title":"权限管理","name":"menu_3_auth","path":"views/authority/index.html","component":"views/authority/index.html","redirect":"","parentId":0,"menuSort":110,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-key","iconImageUrl":"","Describe":"鸿冠ERP-权限管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

# 12. 人力资源 (id:8)
cat > /tmp/menu_create_8.json << 'JSONEOF'
{"Data":{"title":"人力资源","name":"menu_8","path":"views/hr/index.html","component":"views/hr/index.html","redirect":"","parentId":0,"menuSort":120,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-users","iconImageUrl":"","Describe":"鸿冠ERP-人力资源管理模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 13. 协同办公 (id:12)
cat > /tmp/menu_create_12.json << 'JSONEOF'
{"Data":{"title":"协同办公","name":"menu_12","path":"views/approvalflow/index.html","component":"views/approvalflow/index.html","redirect":"","parentId":0,"menuSort":130,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-handshake-o","iconImageUrl":"","Describe":"鸿冠ERP-协同办公模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
JSONEOF

# 14. 基础设置 (id:4)
cat > /tmp/menu_create_4.json << 'JSONEOF'
{"Data":{"title":"基础设置","name":"menu_4","path":"views/base_settings/custom_property/frame.html","component":"views/base_settings/custom_property/frame.html","redirect":"","parentId":0,"menuSort":140,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-cog","iconImageUrl":"","Describe":"鸿冠ERP-基础设置模块","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
JSONEOF

echo "=== Creating top-level menus ==="

for f in 1 3 9 5 10 7 11 6 7b 11b 3b 8 12 4; do
    echo "Creating menu_$f..."
    RESP=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/menu_create_${f}.json 2>/dev/null)
    echo "menu_$f: $RESP" >> /tmp/menu_create_results.txt
    echo "$RESP"
done

echo "=== Done creating top-level menus ==="
echo "Results saved to /tmp/menu_create_results.txt"
