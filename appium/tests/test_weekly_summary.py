"""Appium smoke coverage for the compact weekly-summary entry point."""

import time

from appium.webdriver.common.appiumby import AppiumBy

import helpers


def _wait_for_visible(driver, locator, timeout: float = 15, max_scrolls: int = 8):
    """Return the first displayed+enabled match, scrolling it into view.

    The ``本周总结`` text button sits at the bottom of the home progress
    section. Off-screen Flutter nodes still exist in the XCUITest tree but
    report a zero rect (``is_displayed() == False``), so plain presence checks
    (and ``element_to_be_clickable``) time out until the node is scrolled in.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        for element in driver.find_elements(*locator):
            if element.is_displayed() and element.is_enabled():
                return element
        helpers.scroll_down(driver, ratio=0.4)
        time.sleep(0.3)
    return None


def test_compact_home_entry_opens_weekly_summary(driver):
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)

    entry_locator = (
        AppiumBy.IOS_PREDICATE,
        'type == "XCUIElementTypeButton" AND label == "本周总结"',
    )
    entry = _wait_for_visible(driver, entry_locator)
    assert entry is not None, (
        "Home does not show a clickable compact weekly-summary entry"
    )

    entry.click()
    helpers.wait_for(driver, helpers.by_label_contains("本周回顾"), timeout=15)
    assert helpers.exists(driver, helpers.by_label_contains("生成图片保存")), (
        "Weekly summary page does not expose the share-card action"
    )
