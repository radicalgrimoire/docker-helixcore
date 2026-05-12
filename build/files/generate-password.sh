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
  # Read a fixed number of bytes with dd and then filter with tr
  # to avoid SIGPIPE caused by applying head to an infinite stream.
  CANDIDATE="$(dd if=/dev/urandom bs=$(( LENGTH * 8 )) count=1 2>/dev/null | LC_ALL=C tr -dc "$ALLOWED_CHARS")"

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
