#!/usr/bin/env sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOG_FILE="${ROOT_DIR}/.cloudflared-dev.log"
PID_FILE="${ROOT_DIR}/.cloudflared-dev.pid"
ENV_FILE="${ROOT_DIR}/.env"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "[dev] cloudflared not found"
  if command -v brew >/dev/null 2>&1; then
    echo "[dev] installing cloudflared via brew..."
    if brew install cloudflared; then
      echo "[dev] cloudflared installed"
    else
      echo "[dev] failed to install cloudflared automatically"
      echo "[dev] run manually: brew install cloudflared"
      exit 1
    fi
  else
    echo "[dev] Homebrew not found"
    echo "[dev] install Homebrew first, then run: brew install cloudflared"
    exit 1
  fi
fi

if [ -f "${PID_FILE}" ]; then
  old_pid=$(cat "${PID_FILE}" 2>/dev/null || true)
  if [ -n "${old_pid}" ] && kill -0 "${old_pid}" 2>/dev/null; then
    kill "${old_pid}" 2>/dev/null || true
  fi
fi

rm -f "${LOG_FILE}" "${PID_FILE}"

nohup cloudflared tunnel --url "http://localhost:8080" >"${LOG_FILE}" 2>&1 &
tunnel_pid=$!
echo "${tunnel_pid}" >"${PID_FILE}"

echo "[dev] starting Cloudflare quick tunnel..."

tunnel_url=""
attempt=0
max_attempts=60

while [ "${attempt}" -lt "${max_attempts}" ]; do
  attempt=$((attempt + 1))

  if ! kill -0 "${tunnel_pid}" 2>/dev/null; then
    echo "[dev] tunnel process stopped unexpectedly"
    echo "[dev] check ${LOG_FILE}"
    exit 1
  fi

  if [ -f "${LOG_FILE}" ]; then
    tunnel_url=$(awk 'match($0,/https:\/\/[a-zA-Z0-9.-]+\.trycloudflare\.com/){print substr($0, RSTART, RLENGTH); exit}' "${LOG_FILE}" || true)
  fi

  if [ -n "${tunnel_url}" ]; then
    break
  fi

  sleep 1
done

if [ -z "${tunnel_url}" ]; then
  echo "[dev] could not detect tunnel URL"
  echo "[dev] check ${LOG_FILE}"
  exit 1
fi

perl -pi -e "s|^API_BASE_URL=.*$|API_BASE_URL=${tunnel_url}|" "${ENV_FILE}"

echo "[dev] API_BASE_URL set to ${tunnel_url}"
echo "[dev] tunnel pid: ${tunnel_pid}"
