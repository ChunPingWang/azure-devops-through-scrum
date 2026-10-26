#!/usr/bin/env bash
# =============================================================
# Step 3：推送範例程式、建立 CI Pipeline、設定 main 分支原則
# 對應 README 第 6、7 章。
# 前置：本機 git 已可存取 Azure Repos（Repos > Files > Generate Git Credentials，
#       或使用 Git Credential Manager）。
# =============================================================
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"

REPO_URL=$(az repos show --repository "$ADO_REPO" --query remoteUrl -o tsv)
REPO_ID=$(az repos show --repository "$ADO_REPO" --query id -o tsv)

echo ">> 推送 sample-app 到 $REPO_URL"
cp -r "$ROOT/sample-app/." "$WORK/"
cd "$WORK"
git init -q -b main
git add .
git commit -q -m "Initial commit: 購物車服務骨架與 CI pipeline"
git remote add origin "$REPO_URL"
git push -u origin main

echo ">> 建立 YAML Pipeline（使用 repo 內的 azure-pipelines.yml）"
az pipelines create \
  --name "ShopCart-CI" \
  --repository "$ADO_REPO" --repository-type tfsgit \
  --branch main --yaml-path azure-pipelines.yml \
  --skip-first-run true --output table

echo ">> main 分支原則：至少 1 位 Reviewer"
az repos policy approver-count create \
  --repository-id "$REPO_ID" --branch main \
  --minimum-approver-count 1 --creator-vote-counts true \
  --allow-downvotes false --reset-on-source-push false \
  --blocking true --enabled true --output table

echo ">> main 分支原則：PR 必須連結 Work Item"
az repos policy work-item-linking create \
  --repository-id "$REPO_ID" --branch main \
  --blocking true --enabled true --output table

# 若已有 Microsoft-hosted 平行作業額度或 Self-hosted Agent，可再加上 Build Validation：
# PIPELINE_ID=$(az pipelines show --name ShopCart-CI --query id -o tsv)
# az repos policy build create --repository-id "$REPO_ID" --branch main \
#   --build-definition-id "$PIPELINE_ID" --display-name "CI must pass" \
#   --queue-on-source-update-only true --manual-queue-only false \
#   --valid-duration 720 --blocking true --enabled true

echo "完成！"
