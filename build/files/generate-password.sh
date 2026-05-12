#!/usr/bin/env bash
set -euo pipefail

LENGTH="${1:-16}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"

if ! [[ "$LENGTH" =~ ^[0-9]+$ ]] || [ "$LENGTH" -le 0 ]; then
  echo "Error: length must be a positive integer" >&2
  exit 1
fi

if ! [[ "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]] || [ "$MAX_ATTEMPTS" -le 0 ]; then
  echo "Error: MAX_ATTEMPTS must be a positive integer" >&2
  exit 1
fi

ALLOWED_CHARS='a-zA-Z0-9!@#%^&*()_+=-'
PASSWORD=""
ATTEMPT=1

while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
  # head を使わずに一度変数へ受けてから切り出し、pipefail と SIGPIPE の偶発失敗を避ける。
  CANDIDATE="$(openssl rand -base64 "$(( LENGTH * 4 ))" | tr -dc "$ALLOWED_CHARS")"

  if [ "${#CANDIDATE}" -ge "$LENGTH" ]; then
    PASSWORD="${CANDIDATE:0:LENGTH}"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
done

if [ "${#PASSWORD}" -ne "$LENGTH" ]; then
  echo "Error: failed to generate password with requested length after ${MAX_ATTEMPTS} attempts" >&2
  exit 1
fi

printf '%s\n' "$PASSWORD"
