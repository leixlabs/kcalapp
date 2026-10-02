"""Appium smoke coverage for the compact weekly-summary entry point."""

from appium.webdriver.common.appiumby import AppiumBy

import helpers


def test_compact_home_entry_opens_weekly_summary(driver):
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)
    assert helpers.scroll_to_text(driver, "本周总结", max_swipes=8), (
        "Home does not show the compact weekly-summary text entry"
    )

    entry = helpers.wait_for_clickable(
        driver,
        (
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeButton" AND label == "本周总结"',
        ),
        timeout=10,
    )
    entry.click()
    helpers.wait_for(driver, helpers.by_label_contains("本周回顾"), timeout=15)
    assert helpers.exists(driver, helpers.by_label_contains("生成分享卡片")), (
        "Weekly summary page does not expose the share-card action"
    )
