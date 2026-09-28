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
APP_PATH="$PROJECT_ROOT/build/ios/iphonesimulator/Runner.app"
TEST_IMAGE="$PROJECT_ROOT/appium/assets/test_meal.png"
MOCK_PORT="${MOCK_PORT:-8611}"

SKIP_BUILD=0
PYTEST_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--skip-build" ]]; then
    SKIP_BUILD=1
  else
    PYTEST_ARGS+=("$arg")
  fi
done

echo "=== [1/6] 构建 iOS 模拟器包 ==="
if [[ $SKIP_BUILD -eq 0 ]]; then
  flutter build ios --debug --simulator
fi
[[ -d "$APP_PATH" ]] || { echo "未找到 $APP_PATH"; exit 1; }

echo "=== [2/6] 启动模拟器 $SIM_DEVICE ==="
xcrun simctl boot "$SIM_DEVICE" 2>/dev/null || true
open -a Simulator || true
# 等待启动完成
xcrun simctl bootstatus "$SIM_DEVICE" -b 2>/dev/null || true

echo "=== [3/6] 安装 App 并推入测试图片 ==="
xcrun simctl install booted "$APP_PATH" || true
python3 "$PROJECT_ROOT/appium/assets/make_test_image.py"
xcrun simctl addmedia booted "$TEST_IMAGE" || echo "warn: addmedia 失败（可能图片已在相册）"

echo "=== [4/6] 启动 Mock LLM 服务器 (127.0.0.1:$MOCK_PORT) ==="
python3 "$PROJECT_ROOT/appium/mock_llm_server.py" "$MOCK_PORT" &
MOCK_PID=$!
trap 'kill $MOCK_PID 2>/dev/null || true' EXIT
sleep 0.5
curl -sf "http://127.0.0.1:$MOCK_PORT/health" >/dev/null && echo "mock 已就绪"

echo "=== [5/6] 检查 Appium server ==="
if ! curl -sf "http://127.0.0.1:4723/status" >/dev/null; then
  echo "Appium server 未启动。请另开终端执行: appium"
  exit 1
fi

echo "=== [6/6] 运行 pytest ==="
cd "$PROJECT_ROOT/appium"
PYTHON="$PROJECT_ROOT/appium/.venv/bin/python"
[[ -x "$PYTHON" ]] || PYTHON="python3"
"$PYTHON" -m pytest tests/ -v --tb=short ${PYTEST_ARGS[@]+"${PYTEST_ARGS[@]}"}
