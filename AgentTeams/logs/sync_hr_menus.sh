#!/bin/bash
# 将分路 PlatformId=6 的人力管理(id=314)菜单树同步到 PlatformId=12
# 关键变更: isIframe=true, PlatformId=12, name 加 iframe_ 前缀标识

TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"
send() {
  local f="$1" n="$2"
  local r=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d "@$f" 2>/dev/null)
  echo "$n: $r"
  # extract new id from result
  echo "$r" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://'
}

# ========================================
# Level 0: 人力管理 (root, parentId=0)
# ========================================
cat > /tmp/hr_314.json << 'JSONEOF'
{"Data":{"title":"人力管理","name":"iframe_humanResourceManagement","path":"/humanResourceManagement","component":"/humanResourceManagement","redirect":"../User/Employee/Info.html","parentId":0,"menuSort":12,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-user-o","iconImageUrl":"","Describe":"分路-人力管理","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
echo "=== Level 0: 人力管理 ==="
R314=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_314.json 2>/dev/null)
echo "人力管理: $R314"
NEW_314=$(echo "$R314" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')
echo "New ID for 人力管理: $NEW_314"

# ========================================
# Level 1: 9 children of 人力管理
# ========================================
echo "=== Level 1 ==="

# 员工管理 (315)
cat > /tmp/hr_315.json << JSONEOF
{"Data":{"title":"员工管理","name":"iframe_employeeManagement","path":"/v2/views/manpowerManage/staffManagement/tab_index.html","component":"/v2/views/manpowerManage/staffManagement/tab_index.html","redirect":"","parentId":$NEW_314,"menuSort":1,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-address-book-o","iconImageUrl":"","Describe":"分路-员工管理","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R315=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_315.json 2>/dev/null)
echo "员工管理: $R315"
NEW_315=$(echo "$R315" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 人事审批 (327)
cat > /tmp/hr_327.json << JSONEOF
{"Data":{"title":"人事审批","name":"iframe_personnelApproval","path":"/personnelApproval","component":"/personnelApproval","redirect":"../User/Approval/Application.html","parentId":$NEW_314,"menuSort":2,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-user-times","iconImageUrl":"","Describe":"分路-人事审批","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R327=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_327.json 2>/dev/null)
echo "人事审批: $R327"
NEW_327=$(echo "$R327" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 考勤管理 (340)
cat > /tmp/hr_340.json << JSONEOF
{"Data":{"title":"考勤管理","name":"iframe_attendanceManagement","path":"/attendanceManagement","component":"/attendanceManagement","redirect":"../User/Attendance/AttendanceSetting.html","parentId":$NEW_314,"menuSort":3,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-street-view","iconImageUrl":"","Describe":"分路-考勤管理","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R340=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_340.json 2>/dev/null)
echo "考勤管理: $R340"
NEW_340=$(echo "$R340" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 薪资管理 (343)
cat > /tmp/hr_343.json << JSONEOF
{"Data":{"title":"薪资管理","name":"iframe_salaryManagement","path":"/salaryManagement","component":"/salaryManagement","redirect":"../User/Salary/EmployeeSalary.html","parentId":$NEW_314,"menuSort":4,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-money","iconImageUrl":"","Describe":"分路-薪资管理","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R343=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_343.json 2>/dev/null)
echo "薪资管理: $R343"
NEW_343=$(echo "$R343" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 账号管理 (323)
cat > /tmp/hr_323.json << JSONEOF
{"Data":{"title":"账号管理","name":"iframe_accountPermissions","path":"/accountPermissions","component":"/accountPermissions","redirect":"../User/Employee/Account.html","parentId":$NEW_314,"menuSort":5,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-user-md","iconImageUrl":"","Describe":"分路-账号管理","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R323=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_323.json 2>/dev/null)
echo "账号管理: $R323"
NEW_323=$(echo "$R323" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 组织机构 (319)
cat > /tmp/hr_319.json << JSONEOF
{"Data":{"title":"组织机构","name":"iframe_organization","path":"/v2/views/manpowerManage/organization/tab_index.html","component":"/v2/views/manpowerManage/organization/tab_index.html","redirect":"","parentId":$NEW_314,"menuSort":6,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-sitemap","iconImageUrl":"","Describe":"分路-组织机构","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R319=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_319.json 2>/dev/null)
echo "组织机构: $R319"
NEW_319=$(echo "$R319" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 劳动合同 (555)
cat > /tmp/hr_555.json << JSONEOF
{"Data":{"title":"劳动合同","name":"iframe_contracManagement","path":"/v2/views/manpowerManage/contracManagement/tab_index.html","component":"/v2/views/manpowerManage/contracManagement/tab_index.html","redirect":"","parentId":$NEW_314,"menuSort":7,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-file-text-o","iconImageUrl":"","Describe":"分路-劳动合同","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R555=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_555.json 2>/dev/null)
echo "劳动合同: $R555"
NEW_555=$(echo "$R555" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 办公用品 (589)
cat > /tmp/hr_589.json << JSONEOF
{"Data":{"title":"办公用品","name":"iframe_officeSupplies","path":"/v2/views/manpowerManage/officeSupplies/index.html","component":"/v2/views/manpowerManage/officeSupplies/index.html","redirect":"","parentId":$NEW_314,"menuSort":8,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-shopping-bag","iconImageUrl":"","Describe":"分路-办公用品","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R589=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_589.json 2>/dev/null)
echo "办公用品: $R589"
NEW_589=$(echo "$R589" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

# 办公资产 (556)
cat > /tmp/hr_556.json << JSONEOF
{"Data":{"title":"办公资产","name":"iframe_assetsManagement","path":"/v2/views/manpowerManage/assetsManagement/tab_index.html","component":"/v2/views/manpowerManage/assetsManagement/tab_index.html","redirect":"","parentId":$NEW_314,"menuSort":9,"menuType":1,"isLink":false,"isLinkText":"","isHide":false,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"fa fa-pie-chart","iconImageUrl":"","Describe":"分路-办公资产","PlatformId":12,"PlatformName":"","MenuButtons":["search"],"children":[]}}
JSONEOF
R556=$(curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/hr_556.json 2>/dev/null)
echo "办公资产: $R556"
NEW_556=$(echo "$R556" | grep -o '"id":[0-9]*' | grep -v '"id":0' | head -1 | sed 's/"id"://')

echo "=== Level 1 IDs: 315=$NEW_315 327=$NEW_327 340=$NEW_340 343=$NEW_343 323=$NEW_323 319=$NEW_319 555=$NEW_555 589=$NEW_589 556=$NEW_556 ==="
echo "=== LEVEL 1 DONE ==="
