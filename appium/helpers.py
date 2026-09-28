"""Appium 测试公共工具：元素查找、长按、等待。"""
from __future__ import annotations

import time
import urllib.request

from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

DEFAULT_TIMEOUT = 10


def by_label(text: str):
    """按 Flutter 语义标签（accessibility id）查找。Flutter 默认把 Text 内容导出为 label。"""
    return (AppiumBy.ACCESSIBILITY_ID, text)


def by_label_contains(text: str):
    return (AppiumBy.IOS_PREDICATE, f'label CONTAINS[c] "{text}" OR name CONTAINS[c] "{text}"')


def wait_for(driver, locator, timeout=DEFAULT_TIMEOUT):
    return WebDriverWait(driver, timeout).until(EC.presence_of_element_located(locator))


def wait_for_clickable(driver, locator, timeout=DEFAULT_TIMEOUT):
    return WebDriverWait(driver, timeout).until(EC.element_to_be_clickable(locator))


def tap_text(driver, text: str, timeout=DEFAULT_TIMEOUT):
    el = wait_for_clickable(driver, by_label_contains(text), timeout)
    el.click()
    return el


def exists(driver, locator) -> bool:
    try:
        driver.find_element(*locator)
        return True
    except NoSuchElementException:
        return False


def wait_gone(driver, locator, timeout=DEFAULT_TIMEOUT) -> bool:
    """等待元素消失，返回是否成功消失。"""
    deadline = time.time() + timeout
    while time.time() < deadline:
        if not exists(driver, locator):
            return True
        time.sleep(0.3)
    return False


def long_press(driver, element, duration_ms: int = 900):
    """XCUITest 原生长按（mobile: touchAndHold），用于 FAB 唤起相册入口。"""
    rect = element.rect
    driver.execute_script("mobile: touchAndHold", {
        "x": rect["x"] + rect["width"] / 2,
        "y": rect["y"] + rect["height"] / 2,
        "duration": duration_ms / 1000,
    })


def mock_server_get(path: str, base: str = "http://127.0.0.1:8611"):
    """查询 mock 服务器状态（/requests /reset /health）。"""
    with urllib.request.urlopen(base + path, timeout=5) as resp:
        import json

        return json.loads(resp.read().decode("utf-8"))


def flutter_textfield(driver, index: int):
    """按出现顺序取第 index 个 Flutter 输入框。

    Flutter 的 TextField 在 iOS 语义树中暴露为 XCUIElementTypeTextField。
    """
    fields = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
    if len(fields) <= index:
        raise NoSuchElementException(f"TextField[{index}] 不存在，共找到 {len(fields)} 个")
    return fields[index]
