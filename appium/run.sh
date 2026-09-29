#!/usr/bin/env bash
# 一键跑通核心流程自循环测试（模拟器模式）。
#
# 用法：
#   ./appium/run.sh                 # 构建 → 装模拟器 → 推测试图 → 起 mock → 跑 pytest
#   ./appium/run.sh --skip-build    # 跳过 flutter build（包已存在时加速）
#
# 前置（只需一次）：
#   bun add -g appium && appium driver install xcuitest
#   appium &                        # 或用 appium --allow-insecure
#   cd appium && python3 -m venv .venv && source .venv/bin/activate
#   pip install -r requirements.txt
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"
SIM_DEVICE="${IOS_DEVICE_NAME:-iPhone 17}"
export SIM_DEVICE
APP_PATH="$PROJECT_ROOT/build/ios/iphonesimulator/Runner.app"
TEST_IMAGE="$PROJECT_ROOT/appium/assets/test_meal.png"
MOCK_PORT="${MOCK_PORT:-8611}"
APPIUM_SERVER="${APPIUM_SERVER:-http://127.0.0.1:4723}"
MOCK_BASE_URL="${MOCK_BASE_URL:-http://127.0.0.1:$MOCK_PORT/v1}"
export MOCK_BASE_URL

SKIP_BUILD=0
PYTEST_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--skip-build" ]]; then
    SKIP_BUILD=1
  else
    PYTEST_ARGS+=("$arg")
  fi
done

if [[ "${APPIUM_REAL_DEVICE:-0}" == "1" ]]; then
  echo "此脚本运行 iOS 模拟器流程；真机请直接在 appium/ 下运行 pytest。"
  exit 2
fi

if ! curl -sf --max-time 2 "$APPIUM_SERVER/status" >/dev/null; then
  echo "Appium server 未启动或不可用：$APPIUM_SERVER"
  echo "请先启动 Appium server，再运行此脚本。"
  exit 1
fi

echo "=== [1/5] 构建 iOS 模拟器包 ==="
if [[ $SKIP_BUILD -eq 0 ]]; then
  flutter build ios --debug --simulator
fi
[[ -d "$APP_PATH" ]] || { echo "未找到 $APP_PATH"; exit 1; }

echo "=== [2/5] 启动模拟器 $SIM_DEVICE ==="
SIM_UDID="${IOS_SIMULATOR_UDID:-$(xcrun simctl list devices available -j | python3 -c '
import json, os, sys
name = os.environ["SIM_DEVICE"]
devices = json.load(sys.stdin)["devices"]
matches = [device["udid"] for runtime in devices.values() for device in runtime if device["name"] == name]
if not matches:
    raise SystemExit(f"No available iOS simulator named {name!r}")
print(matches[0])
')}"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator || true
xcrun simctl bootstatus "$SIM_UDID" -b

echo "=== [3/5] 安装 App 并推入测试图片 ==="
xcrun simctl install "$SIM_UDID" "$APP_PATH"
python3 "$PROJECT_ROOT/appium/assets/make_test_image.py"
xcrun simctl addmedia "$SIM_UDID" "$TEST_IMAGE" || echo "warn: addmedia 失败；若相册中没有测试图，识别流程会明确失败"

echo "=== [4/5] 检查 Mock LLM 服务器 (127.0.0.1:$MOCK_PORT) ==="
MOCK_URL="http://127.0.0.1:$MOCK_PORT"
MOCK_PID=""
cleanup() {
  if [[ -n "$MOCK_PID" ]]; then
    kill "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if curl -sf --max-time 2 "$MOCK_URL/health" >/dev/null; then
  echo "复用已运行的 Mock LLM：$MOCK_URL"
elif command -v lsof >/dev/null && lsof -nP -iTCP:"$MOCK_PORT" -sTCP:LISTEN >/dev/null; then
  echo "端口 $MOCK_PORT 已被占用，但不是可用的 Mock LLM 服务。"
  exit 1
else
  python3 "$PROJECT_ROOT/appium/mock_llm_server.py" "$MOCK_PORT" &
  MOCK_PID=$!
  READY=0
  for _ in $(seq 1 40); do
    if ! kill -0 "$MOCK_PID" 2>/dev/null; then
      echo "Mock LLM 服务启动失败。"
      exit 1
    fi
    if curl -sf --max-time 1 "$MOCK_URL/health" >/dev/null; then
      READY=1
      break
    fi
    sleep 0.25
  done
  if [[ "$READY" -ne 1 ]]; then
    echo "Mock LLM 服务在端口 $MOCK_PORT 未能就绪。"
    exit 1
  fi
fi

echo "=== [5/5] 运行核心用户旅程测试 ==="
cd "$PROJECT_ROOT/appium"
PYTHON="$PROJECT_ROOT/appium/.venv/bin/python"
[[ -x "$PYTHON" ]] || PYTHON="python3"
"$PYTHON" -m pytest tests/test_user_journey.py -v --tb=short --junitxml=/tmp/kcalapp-appium-results.xml ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"}
