#!/usr/bin/env bash
# =============================================================
# Step 4（選用）：在 Linux / macOS 主機上安裝 Self-hosted Agent
# 新建立的 Organization 預設「Microsoft-hosted 平行作業 = 0」，
# Pipeline 會出現 "No hosted parallelism has been purchased or granted"。
# 解法 A：到 https://aka.ms/azpipelines-parallelism-request 申請免費額度（需數個工作天）
# 解法 B：使用本腳本建立 Self-hosted Agent（私有專案免費 1 個平行作業）
#
# 必要環境變數：
#   AZP_URL    例：https://dev.azure.com/<your-org>
#   AZP_TOKEN  具備 Agent Pools (Read & manage) 權限的 PAT —— 請勿寫進 Git
# 選用：AZP_POOL（預設 Default）、AZP_AGENT_NAME（預設主機名稱）
#
# 安裝完成後，請把 azure-pipelines.yml 的 pool 改為：
#   pool:
#     name: Default
# =============================================================
set -euo pipefail
: "${AZP_URL:?請設定 AZP_URL}"
: "${AZP_TOKEN:?請設定 AZP_TOKEN（PAT）}"
AZP_POOL="${AZP_POOL:-Default}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-$(hostname)}"
AGENT_VERSION="${AGENT_VERSION:-5.281.1}"   # 備援版本；最新版本見 https://github.com/microsoft/azure-pipelines-agent/releases

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  PKG="linux-x64" ;;
  Linux-aarch64) PKG="linux-arm64" ;;
  Darwin-arm64)  PKG="osx-arm64" ;;
  Darwin-x86_64) PKG="osx-x64" ;;
  *) echo "不支援的平台"; exit 1 ;;
esac

mkdir -p ~/azagent && cd ~/azagent
if [ ! -f ./config.sh ]; then
  # 向 Organization 查詢此平台最新的 Agent 下載網址；查不到時使用 AGENT_VERSION
  URL=$(curl -fsSL -u ":${AZP_TOKEN}" \
        "${AZP_URL}/_apis/distributedtask/packages/agent?platform=${PKG}&\$top=1&api-version=7.1" \
        | grep -o '"downloadUrl":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  URL="${URL:-https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-${PKG}-${AGENT_VERSION}.tar.gz}"
  echo "下載 Agent：$URL"
  curl -fsSL -o agent.tar.gz "$URL"
  tar -xzf agent.tar.gz && rm agent.tar.gz
fi

./config.sh --unattended \
  --url "$AZP_URL" --auth pat --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" --agent "$AZP_AGENT_NAME" \
  --acceptTeeEula --replace

echo "設定完成。前景執行：./run.sh ；或安裝為服務（Linux）：sudo ./svc.sh install && sudo ./svc.sh start"
