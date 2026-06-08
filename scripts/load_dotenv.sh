#!/usr/bin/env bash
# Usage: source scripts/load_dotenv.sh && load_dotenv .env

load_dotenv() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Env file not found: ${file}" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    if [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      export "${line?}"
    fi
  done < "${file}"
}
