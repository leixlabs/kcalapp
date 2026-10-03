"""Temporary repro: create a meal with a photo, then screenshot the weekly card."""
import os
import time

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy

import helpers
from conftest import APPIUM_SERVER, BUNDLE_ID, SIM_APP_PATH


def select_test_photo(driver) -> None:
    for label in (
        "允许访问所有照片",
        "允许",
        "选取照片",
        "Allow Full Access",
        "Allow",
        "Select Photos",
    ):
        if helpers.exists(driver, helpers.by_label(label)):
            driver.find_element(*helpers.by_label(label)).click()
            time.sleep(0.5)
            break

    deadline = time.time() + 30
    while time.time() < deadline:
        thumbs = driver.find_elements(
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeImage" AND label BEGINSWITH "Photo,"',
        )
        if thumbs:
            rect = thumbs[0].rect
            driver.execute_script(
                "mobile: tap",
                {"x": rect["x"] + rect["width"] / 2, "y": rect["y"] + rect["height"] / 2},
            )
            return
        cells = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
        if cells:
            cells[0].click()
            return
        time.sleep(0.4)
    raise RuntimeError("photo picker did not show the test image")


def main() -> None:
    options = XCUITestOptions()
    options.automation_name = "XCUITest"
    options.bundle_id = BUNDLE_ID
    options.no_reset = True
    options.new_command_timeout = 300
    options.set_capability("appium:wdaLaunchTimeout", 120000)
    options.device_name = os.environ.get("IOS_DEVICE_NAME", "iPhone 17")
    options.platform_version = os.environ.get("IOS_PLATFORM_VERSION", "26.5")
    options.app = SIM_APP_PATH

    d = webdriver.Remote(APPIUM_SERVER, options=options)
    d.implicitly_wait(2)
    d.terminate_app(BUNDLE_ID)
    d.activate_app(BUNDLE_ID)
    try:
        helpers.wait_for(d, helpers.by_label_contains("拍照识别热量"), timeout=40)
        d.save_screenshot("/tmp/repro_home_before.png")

        fab = helpers.wait_for(d, helpers.by_label_contains("拍照识别热量"))
        helpers.long_press(d, fab)
        select_test_photo(d)

        helpers.wait_for(d, helpers.by_label_contains("拍照识别热量"), timeout=30)
        time.sleep(4)
        d.save_screenshot("/tmp/repro_home_after.png")

        helpers.tap_text(d, "本周总结", timeout=20)
        helpers.wait_for(d, helpers.by_label_contains("本周回顾"), timeout=25)
        time.sleep(4)
        d.save_screenshot("/tmp/repro_weekly_card.png")
    finally:
        d.quit()


if __name__ == "__main__":
    main()
