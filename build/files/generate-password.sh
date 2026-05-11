#!/usr/bin/env bash
set -euo pipefail

LENGTH="${1:-16}"

if ! [[ "$LENGTH" =~ ^[0-9]+$ ]] || [ "$LENGTH" -le 0 ]; then
  echo "Error: length must be a positive integer" >&2
  exit 1
fi

# 長さ不足に備えて大きめに生成し、許可文字のみを抽出する。
PASSWORD="$(openssl rand -base64 "$(( LENGTH * 2 ))" | tr -dc 'a-zA-Z0-9!@#%^&*()_+=-' | head -c "$LENGTH")"

if [ "${#PASSWORD}" -ne "$LENGTH" ]; then
  echo "Error: failed to generate password with requested length" >&2
  exit 1
fi

printf '%s\n' "$PASSWORD"
