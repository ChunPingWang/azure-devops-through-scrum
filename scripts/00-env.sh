#!/usr/bin/env bash
# =============================================================
# 共用環境變數：請先修改成你自己的 Organization 與專案名稱
# 使用方式：source scripts/00-env.sh
# =============================================================
export ADO_ORG="${ADO_ORG:-https://dev.azure.com/<your-org>}"
export ADO_PROJECT="${ADO_PROJECT:-ShopCart-Scrum-Demo}"
export ADO_TEAM="${ADO_TEAM:-${ADO_PROJECT} Team}"
export ADO_REPO="${ADO_REPO:-${ADO_PROJECT}}"

# 登入方式（擇一）：
#   1) az login                          （互動式登入，推薦）
#   2) export AZURE_DEVOPS_EXT_PAT=xxxx  （使用 Personal Access Token，請勿把 PAT 寫進 Git）

if ! command -v az >/dev/null 2>&1; then
  echo "請先安裝 Azure CLI：https://learn.microsoft.com/cli/azure/install-azure-cli" >&2
  return 1 2>/dev/null || exit 1
fi

# 安裝 azure-devops 擴充套件（已安裝則略過）
az extension show --name azure-devops >/dev/null 2>&1 || az extension add --name azure-devops

# 設定預設值，之後的 az devops / boards / repos / pipelines 指令就不用每次帶 --org --project
az devops configure --defaults organization="$ADO_ORG" project="$ADO_PROJECT"

echo "ADO_ORG=$ADO_ORG"
echo "ADO_PROJECT=$ADO_PROJECT"
