#!/usr/bin/env bash
# =============================================================
# Step 2：建立 Product Backlog（Epic → Feature → PBI / Bug → Task）
# 對應 README 第 3、4 章。執行後即可在 Boards > Backlogs 看到完整階層。
# =============================================================
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

P="$ADO_PROJECT"
S1="$P\\Sprint 1"
S2="$P\\Sprint 2"
ME="${ADO_ASSIGNEE:-$(az account show --query user.name -o tsv 2>/dev/null || echo '')}"

# 建立 work item 並回傳 ID
# 用法：new_wi <type> <title> <iteration> <area> [額外 --fields ...]
new_wi() {
  local type="$1" title="$2" iteration="$3" area="$4"; shift 4
  az boards work-item create --type "$type" --title "$title" \
    --iteration "$iteration" --area "$area" "$@" --query id -o tsv
}

# 建立父子關係（child 的 parent 是 parent）
link_parent() {
  az boards work-item relation add --id "$1" --relation-type parent --target-id "$2" --output none
}

echo ">> Epic"
E1=$(new_wi Epic "購物車結帳體驗升級" "$P" "$P" \
  --description "讓消費者能順暢完成「選購 → 購物車 → 結帳付款」，目標：結帳轉換率提升 15%。" \
  --fields "System.Tags=Q4-OKR")

echo ">> Features"
F1=$(new_wi Feature "購物車管理"     "$P" "$P\\Cart API"); link_parent "$F1" "$E1"
F2=$(new_wi Feature "優惠與金額計算" "$P" "$P\\Cart API"); link_parent "$F2" "$E1"
F3=$(new_wi Feature "結帳付款"       "$P" "$P\\Payment");  link_parent "$F3" "$E1"

echo ">> Product Backlog Items（User Story 格式 + 驗收條件 + Effort）"
pbi() { # pbi <title> <story> <acceptance> <effort> <iteration> <area> <parent>
  local id
  id=$(new_wi "Product Backlog Item" "$1" "$5" "$P\\$6" \
      --description "$2" \
      --fields "Microsoft.VSTS.Common.AcceptanceCriteria=$3" "Microsoft.VSTS.Scheduling.Effort=$4")
  link_parent "$id" "$7"; echo "$id"
}
P1=$(pbi "加入商品到購物車" "身為消費者，我想要把商品加入購物車，以便稍後一起結帳。" \
  "Given 商品有庫存 When 點擊加入購物車 Then 購物車數量 +1；同商品再次加入時數量累加" 5 "$S1" "Web 前台" "$F1")
P2=$(pbi "調整購物車商品數量" "身為消費者，我想要修改購物車內商品數量，以便買到正確的份量。" \
  "數量範圍 1~99，超出時顯示錯誤；修改後小計即時更新" 3 "$S1" "Cart API" "$F1")
P3=$(pbi "移除購物車商品" "身為消費者，我想要移除不想買的商品，以便只結帳需要的東西。" \
  "點擊垃圾桶圖示後二次確認；移除後總金額即時更新" 2 "$S1" "Web 前台" "$F1")
P4=$(pbi "套用折扣碼" "身為消費者，我想要輸入折扣碼，以便享有活動優惠。" \
  "有效折扣碼顯示折抵金額；過期/無效折扣碼顯示原因" 5 "$S2" "Cart API" "$F2")
P5=$(pbi "計算運費與應付總額" "身為消費者，我想要在結帳前看到運費與總額，以便決定是否下單。" \
  "滿 NT\$1,000 免運，否則運費 NT\$80" 3 "$S2" "Cart API" "$F2")
P6=$(pbi "信用卡付款" "身為消費者，我想要用信用卡付款，以便快速完成訂單。" \
  "串接金流沙箱，授權成功導向訂單完成頁；失敗顯示可重試訊息" 8 "$S2" "Payment" "$F3")
P7=$(pbi "訂單確認 Email" "身為消費者，我想要收到訂單確認信，以便留存購買紀錄。" \
  "付款成功 1 分鐘內寄出" 3 "$P" "Payment" "$F3")

echo ">> Bug"
B1=$(new_wi Bug "購物車數量可輸入負數" "$S1" "$P\\Cart API" \
  --fields "Microsoft.VSTS.TCM.ReproSteps=1.加入任一商品 2.數量欄輸入 -1 3.小計變成負值" \
           "Microsoft.VSTS.Common.Severity=2 - High" "Microsoft.VSTS.Scheduling.Effort=1")
link_parent "$B1" "$F1"

echo ">> Sprint Planning：將 Sprint 1 的 PBI / Bug 改為 Committed"
for id in "$P1" "$P2" "$P3" "$B1"; do
  az boards work-item update --id "$id" --state Committed --output none
done

echo ">> Tasks（拆解 Sprint 1 的 PBI，單位：小時）"
task() { # task <title> <activity> <hours> <parent>
  local id
  id=$(new_wi Task "$1" "$S1" "$P" \
      --fields "Microsoft.VSTS.Common.Activity=$2" "Microsoft.VSTS.Scheduling.RemainingWork=$3" \
      ${ME:+--assigned-to "$ME"})
  link_parent "$id" "$4"
}
task "設計加入購物車 API（POST /cart/items）" Design 3 "$P1"
task "實作 Cart Service 與單元測試"           Development 8 "$P1"
task "前端「加入購物車」按鈕與提示"           Development 5 "$P1"
task "撰寫驗收測試案例"                       Testing 3 "$P1"
task "實作 PATCH /cart/items/{id} 數量更新"   Development 5 "$P2"
task "數量範圍驗證（1~99）"                   Development 2 "$P2"
task "測試數量邊界值"                         Testing 2 "$P2"
task "實作 DELETE /cart/items/{id}"           Development 3 "$P3"
task "前端刪除二次確認對話框"                 Development 3 "$P3"

cat <<EOF

完成！建立的主要 Work Items：
  Epic   #$E1
  Feature #$F1 #$F2 #$F3
  PBI    #$P1 #$P2 #$P3 #$P4 #$P5 #$P6 #$P7
  Bug    #$B1
請開啟 $ADO_ORG/$P/_backlogs 查看。
EOF
