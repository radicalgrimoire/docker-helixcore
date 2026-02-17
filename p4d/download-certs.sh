#!/bin/bash

# Helix P4D SAML証明書ダウンロードスクリプト

set -e

# 使用方法を表示
show_usage() {
  cat << EOF
使用方法: $0 [OPTIONS]

OPTIONS:
  -r, --repo REPO        GitHubリポジトリ (形式: owner/repository)
  -t, --token TOKEN      GitHubトークン
  -d, --dir DIRECTORY    保存先ディレクトリ (デフォルト: ./certs)
  -y, --yes              確認をスキップ
  -h, --help             このヘルプを表示

環境変数:
  GITHUB_REPO           リポジトリ名
  GITHUB_TOKEN          GitHubトークン
  CERT_DIR              保存先ディレクトリ

例:
  # 対話形式
  $0

  # 引数で指定
  $0 -r owner/repo -t ghp_token -d ./certs

  # 環境変数で指定
  export GITHUB_REPO="owner/repo"
  export GITHUB_TOKEN="ghp_token"
  $0 -y

EOF
  exit 0
}

# 引数の解析
REPO=""
TOKEN=""
DOWNLOAD_DIR=""
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--repo)
      REPO="$2"
      shift 2
      ;;
    -t|--token)
      TOKEN="$2"
      shift 2
      ;;
    -d|--dir)
      DOWNLOAD_DIR="$2"
      shift 2
      ;;
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      echo "エラー: 不明なオプション: $1"
      echo "ヘルプを表示: $0 --help"
      exit 1
      ;;
  esac
done

echo "==================================="
echo "Helix P4D SAML証明書ダウンロード"
echo "==================================="
echo ""

# リポジトリの設定（優先順位: 引数 > 環境変数 > 対話入力）
if [ -z "${REPO}" ]; then
  if [ -n "${GITHUB_REPO}" ]; then
    REPO="${GITHUB_REPO}"
    echo "リポジトリ: ${REPO} (環境変数から)"
  else
    echo "GitHubリポジトリを入力してください"
    echo "形式: owner/repository"
    read -p "リポジトリ [radicalgrimoire/pfx-tools]: " input_repo
    REPO="${input_repo:-radicalgrimoire/pfx-tools}"
  fi
else
  echo "リポジトリ: ${REPO} (引数から)"
fi

# ダウンロードディレクトリの設定
if [ -z "${DOWNLOAD_DIR}" ]; then
  if [ -n "${CERT_DIR}" ]; then
    DOWNLOAD_DIR="${CERT_DIR}"
    echo "保存先: ${DOWNLOAD_DIR} (環境変数から)"
  else
    read -p "保存先ディレクトリ [./certs]: " input_dir
    DOWNLOAD_DIR="${input_dir:-./certs}"
  fi
else
  echo "保存先: ${DOWNLOAD_DIR} (引数から)"
fi

# トークンの設定
if [ -z "${TOKEN}" ]; then
  if [ -n "${GITHUB_TOKEN}" ]; then
    TOKEN="${GITHUB_TOKEN}"
    echo "認証: トークン設定済み ✓ (環境変数から)"
  else
    echo ""
    echo "GitHubトークンを入力してください（プライベートリポジトリの場合必須）"
    echo "トークンの作成: https://github.com/settings/tokens"
    echo "必要な権限: repo"
    echo ""
    read -sp "GitHubトークン (入力は非表示): " input_token
    echo ""
    TOKEN="${input_token}"
    
    if [ -z "${TOKEN}" ]; then
      echo ""
      echo "⚠️  警告: トークンが入力されませんでした"
      read -p "トークンなしで続行しますか？ (y/N): " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "中断しました"
        exit 1
      fi
    fi
  fi
else
  echo "認証: トークン設定済み ✓ (引数から)"
fi

# 設定確認
if [ "${SKIP_CONFIRM}" = false ]; then
  echo ""
  echo "--- 設定内容 ---"
  echo "リポジトリ: ${REPO}"
  echo "保存先: ${DOWNLOAD_DIR}"
  echo "認証: $([ -n "${TOKEN}" ] && echo "あり" || echo "なし")"
  echo ""
  read -p "この設定で続行しますか？ (Y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "中断しました"
    exit 1
  fi
fi
echo ""

# ダウンロードディレクトリの作成
mkdir -p "${DOWNLOAD_DIR}"

# curl共通オプション
CURL_OPTS="-L -f -s -S"

# 最新リリースの取得
echo "最新リリースを取得中..."
if [ -n "${TOKEN}" ]; then
  RELEASE_INFO=$(curl ${CURL_OPTS} \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/releases/latest" 2>&1)
else
  RELEASE_INFO=$(curl ${CURL_OPTS} \
    "https://api.github.com/repos/${REPO}/releases/latest" 2>&1)
fi

# エラーチェック
if [ $? -ne 0 ]; then
  echo ""
  echo "❌ エラー: リリース情報の取得に失敗しました"
  echo ""
  echo "${RELEASE_INFO}"
  echo ""
  echo "考えられる原因:"
  echo "  1. リポジトリにリリースが存在しない"
  echo "  2. GITHUB_TOKENが無効または権限不足"
  echo "  3. リポジトリ名が間違っている"
  echo ""
  echo "トークンの作成方法:"
  echo "  https://github.com/settings/tokens"
  echo "  必要な権限: repo (プライベートリポジトリの場合)"
  exit 1
fi

# リリース情報のパース（jqがあれば使用、なければgrep）
if command -v jq &> /dev/null; then
  DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r '.assets[0].url')
  TAG_NAME=$(echo "${RELEASE_INFO}" | jq -r '.tag_name')
  ASSET_NAME=$(echo "${RELEASE_INFO}" | jq -r '.assets[0].name')
else
  # assetsセクションのURLを取得（リリース本体のURLではなく）
  DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | grep -o '"url"[[:space:]]*:[[:space:]]*"https://api.github.com/repos/[^"]*releases/assets/[0-9]*"' | head -1 | grep -o 'https://[^"]*')
  TAG_NAME=$(echo "${RELEASE_INFO}" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
  ASSET_NAME=$(echo "${RELEASE_INFO}" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)
fi

if [ -z "${DOWNLOAD_URL}" ] || [ "${DOWNLOAD_URL}" == "null" ]; then
  echo ""
  echo "❌ エラー: ダウンロードURLが見つかりません"
  echo ""
  echo "リリース情報:"
  echo "${RELEASE_INFO}" | head -20
  echo ""
  echo "手動でダウンロードする場合:"
  echo "  https://github.com/${REPO}/releases"
  exit 1
fi

echo "リリース: ${TAG_NAME}"
echo "ファイル: ${ASSET_NAME}"
echo ""

# アーカイブのダウンロード（GitHub API経由で認証付き）
echo "証明書をダウンロード中..."
ARCHIVE_FILE="${DOWNLOAD_DIR}/certs.tar.gz"

if [ -n "${TOKEN}" ]; then
  # プライベートリポジトリ: API経由で2段階ダウンロード
  # 1. リダイレクトURLを取得
  REDIRECT_URL=$(curl -sI \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/octet-stream" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${DOWNLOAD_URL}" | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
  
  if [ -z "${REDIRECT_URL}" ]; then
    echo ""
    echo "❌ エラー: ダウンロードURLの取得に失敗しました"
    echo "デバッグ: DOWNLOAD_URL=${DOWNLOAD_URL}"
    exit 1
  fi
  
  echo "リダイレクトURL取得完了"
  
  # 2. リダイレクト先から直接ダウンロード
  HTTP_CODE=$(curl -L -w "%{http_code}" -o "${ARCHIVE_FILE}" "${REDIRECT_URL}")
  
  if [ "${HTTP_CODE}" -ne 200 ]; then
    echo ""
    echo "❌ エラー: ダウンロードに失敗しました (HTTP ${HTTP_CODE})"
    rm -f "${ARCHIVE_FILE}"
    exit 1
  fi
else
  # パブリックリポジトリ: browser_download_urlから直接ダウンロード
  BROWSER_URL=$(echo "${RELEASE_INFO}" | grep -o '"browser_download_url": "[^"]*' | head -1 | cut -d'"' -f4)
  
  HTTP_CODE=$(curl -L -w "%{http_code}" -o "${ARCHIVE_FILE}" "${BROWSER_URL}")
  
  if [ "${HTTP_CODE}" -ne 200 ]; then
    echo ""
    echo "❌ エラー: ダウンロードに失敗しました (HTTP ${HTTP_CODE})"
    rm -f "${ARCHIVE_FILE}"
    exit 1
  fi
fi

# ダウンロードファイルのサイズ確認
if [ ! -s "${ARCHIVE_FILE}" ]; then
  echo ""
  echo "❌ エラー: ダウンロードしたファイルが空です"
  exit 1
fi

echo "ダウンロード完了: $(ls -lh "${ARCHIVE_FILE}" | awk '{print $5}')"


# アーカイブの展開
echo "証明書を展開中..."
tar -xzf "${ARCHIVE_FILE}" -C "${DOWNLOAD_DIR}"

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ エラー: アーカイブの展開に失敗しました"
  echo "アーカイブファイル: ${ARCHIVE_FILE}"
  echo ""
  echo "手動で確認:"
  echo "  tar -tzf ${ARCHIVE_FILE}"
  exit 1
fi

# 展開されたファイルを確認
CERT_FILES=$(find "${DOWNLOAD_DIR}" -type f \( -name "*.crt" -o -name "*.key" \) | wc -l)
if [ "${CERT_FILES}" -eq 0 ]; then
  echo ""
  echo "❌ エラー: 証明書ファイルが見つかりません"
  echo "アーカイブの内容を確認してください: ${ARCHIVE_FILE}"
  echo ""
  echo "展開されたファイル:"
  ls -la "${DOWNLOAD_DIR}"
  exit 1
fi

# アーカイブファイルの削除
rm -f "${ARCHIVE_FILE}"

echo ""
echo "==================================="
echo "ダウンロード完了！"
echo "==================================="
echo "証明書の場所: $(cd "${DOWNLOAD_DIR}" && pwd)"
echo ""
echo "ファイル一覧:"
ls -lh "${DOWNLOAD_DIR}" | grep -E "\.(crt|key)$" || ls -lh "${DOWNLOAD_DIR}"
echo ""
echo "次のステップ:"
echo "1. ca.crt, client.crt, server.crt を適切な場所にコピー"
echo "2. ca.key, client.key, server.key を安全に保管"
echo ""
echo "証明書の確認:"
echo "  openssl x509 -in ${DOWNLOAD_DIR}/ca.crt -noout -subject -dates"
