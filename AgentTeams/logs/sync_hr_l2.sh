#!/bin/bash
TOKEN=$(cat /tmp/fenlu_token.txt)
BASE="http://localhost:8088/api/HRM/MenuRoute/Save"
S() {
  local t="$1" n="$2" p="$3" h="$4" b="$5" s="$6" i="$7" pid="$8"
  cat > /tmp/_j.json << JSONEOF
{"Data":{"title":"$t","name":"$n","path":"$p","component":"$p","redirect":"","parentId":$pid,"menuSort":$s,"menuType":1,"isLink":false,"isLinkText":"","isHide":$h,"isKeepAlive":true,"isAffix":false,"isIframe":true,"icon":"$i","iconImageUrl":"","Describe":"分路-$t","PlatformId":12,"PlatformName":"","MenuButtons":[$b],"children":[]}}
JSONEOF
  echo -n "$t: "; curl -s -X POST "$BASE" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "companyId: 17047" -d @/tmp/_j.json
  echo ""
}

echo "=== 员工管理(4866) children ==="
S "员工信息" "iframe_staffInfo" "/v2/views/manpowerManage/staffManagement/staffInfo/index.html" "true" '"add","update","delete","search","import"' 1 "fa fa-truck" 4866
S "员工档案" "iframe_staffRecord" "/v2/views/manpowerManage/staffManagement/staffRecord/index.html" "true" '"update","search","add","delete"' 2 "fa fa-truck" 4866
S "离职员工" "iframe_staffDimission" "/v2/views/manpowerManage/staffManagement/staffDimission/index.html" "true" '"add","update","delete","search"' 3 "fa fa-truck" 4866

echo "=== 人事审批(4867) children ==="
S "审批管理" "iframe_approvalManagement" "../User/Approval/Application.html" "false" '"add","update","delete","search"' 1 "fa fa-window-minimize" 4867
S "转正申请" "iframe_regular" "../User/Approval/Regular.html" "false" '"add","update","delete","search"' 2 "fa fa-window-minimize" 4867
S "离职申请" "iframe_resign" "../User/Approval/Resign.html" "false" '"add","update","delete","search"' 3 "fa fa-window-minimize" 4867
S "审批人设置" "iframe_approverSettings" "../User/Approval/Approver.html" "false" '"add","update","delete","search"' 4 "fa fa-window-minimize" 4867

echo "=== 考勤管理(4868) children ==="
S "考勤设置v2" "iframe_attendanceSet" "/v2/views/manpowerManage/attendanceManagement/attendanceSet/index.html" "false" '"add","update","delete","search"' 1 "fa fa-superpowers" 4868
S "考勤信息v2" "iframe_attendanceInfo" "/v2/views/manpowerManage/attendanceManagement/attendanceInfo/index.html" "false" '"add","update","delete","search"' 2 "fa fa-superpowers" 4868
S "考勤设置" "iframe_attendanceSetting" "../User/Attendance/AttendanceSetting.html" "true" '"search"' 3 "fa fa-window-minimize" 4868
S "班次管理" "iframe_shiftManagement" "/v2/views/manpowerManage/attendanceManagement/shiftManagement/index.html" "false" '"search"' 4 "fa fa-superpowers" 4868
S "考勤信息" "iframe_attendanceInput" "../User/CheckWorkAttendance/Index.html" "true" '"search"' 5 "fa fa-window-minimize" 4868
S "考勤统计" "iframe_attendanceStatistics" "/v2/views/manpowerManage/attendanceManagement/attendanceStatistics/index.html" "false" '"search"' 6 "fa fa-truck" 4868

echo "=== 薪资管理(4869) children ==="
S "薪资支付" "iframe_salary-pay" "/v2/views/manpowerManage/salaryManagement/salaryPay.html" "false" '"search"' 1 "fa fa-superpowers" 4869
S "薪资设置" "iframe_salary-settings" "/v2/views/manpowerManage/salaryManagement/salarySettings.html" "false" '"search"' 2 "fa fa-superpowers" 4869

echo "=== 账号管理(4870) children ==="
S "登录账号" "iframe_login_Account" "/v2/views/manpowerManage/accountPermissions/loginAccount/index.html" "false" '"add","update","delete","search"' 1 "fa fa-superpowers" 4870
S "扫码注册" "iframe_scanRegister" "/v2/views/manpowerManage/accountPermissions/scanRegister/index.html" "false" '"search"' 2 "fa fa-superpowers" 4870
S "权限设置" "iframe_permissionSetting" "/v2/views/manpowerManage/accountPermissions/permissionSetting/tab_index.html" "false" '"search"' 3 "fa fa-superpowers" 4870

echo "=== 组织机构(4871) children ==="
S "组织管理" "iframe_organizationManage" "/v2/views/manpowerManage/organization/organizationManage/index.html" "true" '"add","update","delete","search"' 1 "fa fa-shopping-bag" 4871
S "组织类型" "iframe_organizationType" "/v2/views/manpowerManage/organization/organizationType/index.html" "true" '"search","add","update","delete"' 2 "fa fa-shopping-bag" 4871
S "岗位管理" "iframe_postManage" "/v2/views/manpowerManage/organization/postManage/index.html" "true" '"add","update","delete","search"' 3 "fa fa-shopping-bag" 4871

echo "=== DONE ==="
