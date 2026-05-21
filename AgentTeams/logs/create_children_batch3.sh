#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"

send() {
  local f="$1" name="$2"
  local resp=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null)
  echo "$name: $resp"
}

# ===== 设备管理 children (parent DB ID: 4719) =====
cat > /tmp/mc_11_1111.json << 'EOF'
{"Data":{"title":"设备台账","name":"menu_11_1111","path":"views/equipment_management/equipment/index.html","component":"views/equipment_management/equipment/index.html","redirect":"","parentId":4719,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-设备台账","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_11_1112.json << 'EOF'
{"Data":{"title":"设备类型","name":"menu_11_1112","path":"views/equipment_management/equipment_type/index.html","component":"views/equipment_management/equipment_type/index.html","redirect":"","parentId":4719,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-设备类型","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_11_1113.json << 'EOF'
{"Data":{"title":"设备巡检","name":"menu_11_1113","path":"views/equipment/inspection/index.html","component":"views/equipment/inspection/index.html","redirect":"","parentId":4719,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-设备巡检","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_11_1114.json << 'EOF'
{"Data":{"title":"设备维保","name":"menu_11_1114","path":"views/equipment/maintenance/index.html","component":"views/equipment/maintenance/index.html","redirect":"","parentId":4719,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-设备维保","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 设备管理 children ==="
send /tmp/mc_11_1111.json "设备台账"
send /tmp/mc_11_1112.json "设备类型"
send /tmp/mc_11_1113.json "设备巡检"
send /tmp/mc_11_1114.json "设备维保"

# ===== 仓储物流管理 children (parent DB ID: 4720) =====
cat > /tmp/mc_6_61.json << 'EOF'
{"Data":{"title":"仓储管理","name":"menu_6_61","path":"views/warehousing/inventory_query/index.html","component":"views/warehousing/inventory_query/index.html","redirect":"","parentId":4720,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-ticket","iconImageUrl":"","Describe":"鸿冠ERP-仓储管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_6_62.json << 'EOF'
{"Data":{"title":"物流管理","name":"menu_6_62","path":"views/logistics/logistics_management/index.html","component":"views/logistics/logistics_management/index.html","redirect":"","parentId":4720,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-物流管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_6_63.json << 'EOF'
{"Data":{"title":"售后管理","name":"menu_6_63","path":"views/logistics/aftersales_management/index.html","component":"views/logistics/aftersales_management/index.html","redirect":"","parentId":4720,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-dot-circle-o","iconImageUrl":"","Describe":"鸿冠ERP-售后管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 仓储物流管理 children ==="
send /tmp/mc_6_61.json "仓储管理"
send /tmp/mc_6_62.json "物流管理"
send /tmp/mc_6_63.json "售后管理"

# ===== 人力资源 children (parent DB ID: 4724) =====
cat > /tmp/mc_8_81.json << 'EOF'
{"Data":{"title":"组织架构","name":"menu_8_81","path":"views/hr/org/index.html","component":"views/hr/org/index.html","redirect":"","parentId":4724,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sitemap","iconImageUrl":"","Describe":"鸿冠ERP-组织架构","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_90a.json << 'EOF'
{"Data":{"title":"人员账号管理","name":"menu_8_90a","path":"views/hr/user/index.html","component":"views/hr/user/index.html","redirect":"","parentId":4724,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-id-card","iconImageUrl":"","Describe":"鸿冠ERP-人员账号管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_82.json << 'EOF'
{"Data":{"title":"考勤管理","name":"menu_8_82","path":"views/hr/attendance/index.html","component":"views/hr/attendance/index.html","redirect":"","parentId":4724,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-clock-o","iconImageUrl":"","Describe":"鸿冠ERP-考勤管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_83.json << 'EOF'
{"Data":{"title":"薪资管理","name":"menu_8_83","path":"views/hr/salary/index.html","component":"views/hr/salary/index.html","redirect":"","parentId":4724,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-money","iconImageUrl":"","Describe":"鸿冠ERP-薪资管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_8_84.json << 'EOF'
{"Data":{"title":"招聘管理","name":"menu_8_84","path":"views/hr/recruitment/index.html","component":"views/hr/recruitment/index.html","redirect":"","parentId":4724,"menuSort":50,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-user-plus","iconImageUrl":"","Describe":"鸿冠ERP-招聘管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_85.json << 'EOF'
{"Data":{"title":"培训管理","name":"menu_8_85","path":"views/hr/training/index.html","component":"views/hr/training/index.html","redirect":"","parentId":4724,"menuSort":60,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-graduation-cap","iconImageUrl":"","Describe":"鸿冠ERP-培训管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_86.json << 'EOF'
{"Data":{"title":"绩效管理","name":"menu_8_86","path":"views/hr/performance/index.html","component":"views/hr/performance/index.html","redirect":"","parentId":4724,"menuSort":70,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-line-chart","iconImageUrl":"","Describe":"鸿冠ERP-绩效管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_87.json << 'EOF'
{"Data":{"title":"员工自助","name":"menu_8_87","path":"views/hr/self_service/index.html","component":"views/hr/self_service/index.html","redirect":"","parentId":4724,"menuSort":80,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-laptop","iconImageUrl":"","Describe":"鸿冠ERP-员工自助","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_88.json << 'EOF'
{"Data":{"title":"离职管理","name":"menu_8_88","path":"views/hr/resignation/index.html","component":"views/hr/resignation/index.html","redirect":"","parentId":4724,"menuSort":90,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sign-out","iconImageUrl":"","Describe":"鸿冠ERP-离职管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_89.json << 'EOF'
{"Data":{"title":"报表中心","name":"menu_8_89","path":"views/hr/report_center/index.html","component":"views/hr/report_center/index.html","redirect":"","parentId":4724,"menuSort":100,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-bar-chart","iconImageUrl":"","Describe":"鸿冠ERP-报表中心","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

cat > /tmp/mc_8_90b.json << 'EOF'
{"Data":{"title":"员工管理","name":"menu_8_90b","path":"views/hr/employee/index.html","component":"views/hr/employee/index.html","redirect":"","parentId":4724,"menuSort":110,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-address-book","iconImageUrl":"","Describe":"鸿冠ERP-员工管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_8_91.json << 'EOF'
{"Data":{"title":"权限管理","name":"menu_8_91","path":"views/hr/authority/index.html","component":"views/hr/authority/index.html","redirect":"","parentId":4724,"menuSort":120,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-key","iconImageUrl":"","Describe":"鸿冠ERP-权限管理","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 人力资源 children ==="
send /tmp/mc_8_81.json "组织架构"
send /tmp/mc_8_90a.json "人员账号管理"
send /tmp/mc_8_82.json "考勤管理"
send /tmp/mc_8_83.json "薪资管理"
send /tmp/mc_8_84.json "招聘管理"
send /tmp/mc_8_85.json "培训管理"
send /tmp/mc_8_86.json "绩效管理"
send /tmp/mc_8_87.json "员工自助"
send /tmp/mc_8_88.json "离职管理"
send /tmp/mc_8_89.json "报表中心"
send /tmp/mc_8_90b.json "员工管理"
send /tmp/mc_8_91.json "权限管理"

# ===== 协同办公 children (parent DB ID: 4725) =====
cat > /tmp/mc_12_121.json << 'EOF'
{"Data":{"title":"审批流设置","name":"menu_12_121","path":"views/approvalflow/index.html","component":"views/approvalflow/index.html","redirect":"","parentId":4725,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-审批流设置","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_12_122.json << 'EOF'
{"Data":{"title":"我发起的审批","name":"menu_12_122","path":"views/collaborative_office/approval/my_approvals.html","component":"views/collaborative_office/approval/my_approvals.html","redirect":"","parentId":4725,"menuSort":20,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-我发起的审批","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_12_123.json << 'EOF'
{"Data":{"title":"待我审批","name":"menu_12_123","path":"views/collaborative_office/approval/waiting-me-approve.html","component":"views/collaborative_office/approval/waiting-me-approve.html","redirect":"","parentId":4725,"menuSort":30,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-desktop","iconImageUrl":"","Describe":"鸿冠ERP-待我审批","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

cat > /tmp/mc_12_124.json << 'EOF'
{"Data":{"title":"我参与的审批","name":"menu_12_124","path":"views/collaborative_office/approval/related-approvals.html","component":"views/collaborative_office/approval/related-approvals.html","redirect":"","parentId":4725,"menuSort":40,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-th-large","iconImageUrl":"","Describe":"鸿冠ERP-我参与的审批","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete","approve"],"children":[]}}
EOF

echo "=== 协同办公 children ==="
send /tmp/mc_12_121.json "审批流设置"
send /tmp/mc_12_122.json "我发起的审批"
send /tmp/mc_12_123.json "待我审批"
send /tmp/mc_12_124.json "我参与的审批"

# ===== 基础设置 children (parent DB ID: 4726) =====
cat > /tmp/mc_4_41.json << 'EOF'
{"Data":{"title":"自定义属性","name":"menu_4_41","path":"views/base_settings/custom_property/frame.html","component":"views/base_settings/custom_property/frame.html","redirect":"","parentId":4726,"menuSort":10,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-list","iconImageUrl":"","Describe":"鸿冠ERP-自定义属性","PlatformId":12,"PlatformName":"","MenuButtons":["search","add","edit","delete"],"children":[]}}
EOF

echo "=== 基础设置 children ==="
send /tmp/mc_4_41.json "自定义属性"

echo "=== DONE ==="
