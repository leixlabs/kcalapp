#!/usr/bin/env python3
"""调试工具：连接模拟器上的 App，dump 页面语义树，便于定位元素 label。

用法：
  python3 debug_dump.py              # dump 当前页所有可交互元素
  python3 debug_dump.py settings     # 点"设置"图标后 dump
"""
import sys

from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy

from conftest import _build_options, APPIUM_SERVER


def dump(driver, tag):
    print(f"\n===== {tag} =====")
    # 打印所有按钮和静态文本的 label/name，帮助确定可点击元素
    for cls in ("XCUIElementTypeButton", "XCUIElementTypeStaticText", "XCUIElementTypeOther"):
        els = driver.find_elements(AppiumBy.CLASS_NAME, cls)
        for e in els[:40]:
            label = e.get_attribute("label") or e.get_attribute("name") or ""
            if label.strip():
                print(f"[{cls.replace('XCUIElementType', '')}] {label!r}")


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else None
    driver = webdriver.Remote(APPIUM_SERVER, options=_build_options())
    driver.implicitly_wait(2)
    try:
        dump(driver, "首页")

        if action == "settings":
            # 尝试找到并点击设置按钮
            btns = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeButton")
            print(f"\n按钮总数: {len(btns)}")
            for b in btns:
                label = b.get_attribute("label") or ""
                if "设置" in label or "settings" in label.lower():
                    print(f"点击按钮: {label!r}")
                    b.click()
                    break
            else:
                # 兜底：点击右上角最后一个按钮
                print("未找到设置按钮，点击右上角区域")
                size = driver.get_window_size()
                driver.execute_script("mobile: tap", {
                    "x": size["width"] - 40, "y": 60,
                })
            import time
            time.sleep(1)
            dump(driver, "设置页")
    finally:
        driver.quit()


if __name__ == "__main__":
    main()
