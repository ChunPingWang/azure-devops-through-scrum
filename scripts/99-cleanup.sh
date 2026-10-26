#!/usr/bin/env bash
# =============================================================
# 清理：刪除教學用專案（對應 README 第 10 章）
# 注意：刪除後 28 天內可於 Organization settings > Projects 還原，之後永久刪除。
# =============================================================
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

PROJECT_ID=$(az devops project show --project "$ADO_PROJECT" --query id -o tsv)
read -r -p "確定要刪除專案 '$ADO_PROJECT' ($PROJECT_ID) 嗎？輸入專案名稱確認：" ans
if [ "$ans" != "$ADO_PROJECT" ]; then
  echo "名稱不符，已取消。"; exit 1
fi
az devops project delete --id "$PROJECT_ID" --yes
echo "已刪除 $ADO_PROJECT"
