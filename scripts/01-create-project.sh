#!/usr/bin/env bash
# =============================================================
# Step 1：建立 Scrum 專案、設定 Sprint 日期與 Area（對應 README 第 2 章）
# =============================================================
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

SPRINT1_START="${SPRINT1_START:-2026-10-19}"
SPRINT1_END="${SPRINT1_END:-2026-10-30}"
SPRINT2_START="${SPRINT2_START:-2026-11-02}"
SPRINT2_END="${SPRINT2_END:-2026-11-13}"

echo ">> 建立專案 $ADO_PROJECT（Scrum 流程、Git、Private）"
az devops project create \
  --name "$ADO_PROJECT" \
  --description "零售電商「購物車」產品的 Scrum 實戰教學專案" \
  --process Scrum \
  --source-control git \
  --visibility private \
  --output table

echo ">> 設定 Sprint 1 / Sprint 2 日期（Scrum 範本預設已建立 Sprint 1~6）"
az boards iteration project update --path "\\$ADO_PROJECT\\Iteration\\Sprint 1" \
  --start-date "$SPRINT1_START" --finish-date "$SPRINT1_END" --output table
az boards iteration project update --path "\\$ADO_PROJECT\\Iteration\\Sprint 2" \
  --start-date "$SPRINT2_START" --finish-date "$SPRINT2_END" --output table

echo ">> 建立 Area（依產品模組切分）"
for area in "Web 前台" "Cart API" "Payment"; do
  az boards area project create --name "$area" --path "\\$ADO_PROJECT\\Area" --output table
done

echo ">> 讓預設團隊包含所有子 Area（Include sub areas）"
az boards area team update --team "$ADO_TEAM" --path "\\$ADO_PROJECT" --include-sub-areas true --output table || \
  echo "   (若此步驟失敗，請到 Project settings > Team configuration > Areas 手動勾選 Include sub areas)"

echo "完成！請開啟 $ADO_ORG/$ADO_PROJECT"
