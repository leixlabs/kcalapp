# Appium + WebDriverAgent 自循环测试

对核心链路做真机/模拟器端到端验证：

```
首页 → 配置 LLM → 长按拍照按钮 → 相册选图 → AI 识别 → 保存记录 → 首页/日历展示
```

AI 请求由本地 `mock_llm_server.py` 接管，返回固定识别结果，保证测试确定性；
同时 mock 会记录所有请求，测试末尾断言"图片识别请求确实发出"。

## 一次性环境准备

```bash
# 1. Appium 2 + XCUITest 驱动（内含 WebDriverAgent）
npm install -g appium
appium driver install xcuitest

# 2. 启动 Appium server（保持运行，另开终端）
appium

# 3. Python 依赖
python3 -m venv .venv && source .venv/bin/activate
pip install -r appium/requirements.txt
```

## 跑测试（模拟器，推荐）

```bash
./appium/run.sh               # 全流程：build → 起模拟器 → 装 app → 推测试图 → 起 mock → pytest
./appium/run.sh --skip-build  # 已构建过时加速
```

## 跑测试（真机）

真机需要 WebDriverAgent 签名，准备：

1. 用 Xcode 打开 `ios/Runner.xcworkspace`，配置你的开发 Team
2. 查设备 UDID：`xcrun xctrace list devices`
3. 执行：

```bash
export APPIUM_REAL_DEVICE=1
export IOS_UDID=<你的设备UDID>
export XCODE_ORG_ID=<你的Apple Team ID>
export MOCK_BASE_URL=http://<Mac局域网IP>:8611/v1   # 真机无法访问 127.0.0.1
./appium/run.sh --skip-build   # 真机包需提前 flutter build ios --debug 并安装
```

## 目录

```
appium/
├── conftest.py            # Appium driver fixture（模拟器/真机两套 caps）
├── helpers.py             # 元素查找、长按、mock 查询工具
├── mock_llm_server.py     # 本地 OpenAI 兼容 mock，记录请求供断言
├── assets/
│   └── make_test_image.py # 生成测试用 PNG（纯标准库）
├── tests/
│   └── test_app.py        # 核心流程用例（按 class 顺序执行）
└── run.sh                 # 一键脚本
```

## 排错

- **找不到"拍照识别热量"**：Flutter 语义树可能把按钮文本挂在子节点，用 `appium inspector` 查看实际 label。
- **相册为空**：`xcrun simctl addmedia booted appium/assets/test_meal.png`
- **真机连不上 mock**：确认手机和 Mac 同网段，`MOCK_BASE_URL` 用 Mac 的局域网 IP，防火墙放行 8611 端口。
- **WDA 签名失败**：参考 https://appium.github.io/appium-xcuitest-driver/latest/preparation/real-device-config/
