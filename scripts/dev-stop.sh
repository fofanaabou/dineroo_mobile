#!/usr/bin/env sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PID_FILE="${ROOT_DIR}/.cloudflared-dev.pid"

if [ ! -f "${PID_FILE}" ]; then
  exit 0
fi

pid=$(cat "${PID_FILE}" 2>/dev/null || true)

if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
  kill "${pid}" 2>/dev/null || true
fi

rm -f "${PID_FILE}"
