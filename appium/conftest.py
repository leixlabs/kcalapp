"""Appium driver fixture 与公共常量。

默认跑 iOS 模拟器（无需真机签名）：
  - 设备/系统版本可用环境变量覆盖：IOS_DEVICE_NAME / IOS_PLATFORM_VERSION
  - App 路径：项目 build/ios/iphonesimulator/Runner.app（run.sh 会先构建）

真机模式（需要已配置 WDA 签名）：
  APPIUM_REAL_DEVICE=1 IOS_UDID=<udid> XCODE_ORG_ID=<teamId> pytest ...
"""
import os

import pytest
from appium import webdriver
from appium.options.ios import XCUITestOptions

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIM_APP_PATH = os.path.join(PROJECT_ROOT, "build", "ios", "iphonesimulator", "Runner.app")

BUNDLE_ID = "com.calory.calory"
APPIUM_SERVER = os.environ.get("APPIUM_SERVER", "http://127.0.0.1:4723")
MOCK_BASE_URL = os.environ.get("MOCK_BASE_URL", "http://127.0.0.1:8611/v1")

REAL_DEVICE = os.environ.get("APPIUM_REAL_DEVICE") == "1"


def _build_options() -> XCUITestOptions:
    options = XCUITestOptions()
    options.automation_name = "XCUITest"
    options.bundle_id = BUNDLE_ID
    # 保留 app 数据（LLM 配置存在 sqlite + keychain），让测试用例可顺序依赖
    options.no_reset = True
    options.new_command_timeout = 300
    options.set_capability("appium:wdaLaunchTimeout", 120000)

    if REAL_DEVICE:
        options.udid = os.environ["IOS_UDID"]
        options.set_capability("appium:xcodeOrgId", os.environ["XCODE_ORG_ID"])
        options.set_capability("appium:xcodeSigningId", "iPhone Developer")
        options.set_capability("appium:updatedWDABundleId", f"{os.environ['XCODE_ORG_ID']}.wda")
        options.set_capability("appium:usePrebuiltWDA", True)
    else:
        options.device_name = os.environ.get("IOS_DEVICE_NAME", "iPhone 17")
        options.platform_version = os.environ.get("IOS_PLATFORM_VERSION", "26.5")
        options.app = SIM_APP_PATH
    return options


@pytest.fixture(scope="session")
def driver():
    if not REAL_DEVICE and not os.path.isdir(SIM_APP_PATH):
        pytest.fail(f"模拟器包不存在: {SIM_APP_PATH}\n先执行: flutter build ios --debug --simulator")

    d = webdriver.Remote(APPIUM_SERVER, options=_build_options())
    d.implicitly_wait(2)
    # noReset 会保留 app 上次退出时的页面栈，重启进程确保从首页开始
    d.terminate_app(BUNDLE_ID)
    d.activate_app(BUNDLE_ID)
    yield d
    d.quit()
