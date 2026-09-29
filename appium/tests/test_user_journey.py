"""Core Appium journey: configure LLM, recognize a meal, and review that day."""
from __future__ import annotations

import time

import pytest
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException

import helpers
from conftest import MOCK_BASE_URL


MEAL_NAME = "测试早餐组合"
MOCK_SERVER_URL = MOCK_BASE_URL.removesuffix("/v1")


def _fill_field(driver, index: int, value: str) -> None:
    deadline = time.time() + 20
    last_error = None
    while time.time() < deadline:
        try:
            field = helpers.flutter_textfield(driver, index)
            field.click()
            helpers.clear_textfield(driver, field)
            field.send_keys(value)
            try:
                driver.hide_keyboard()
            except Exception:
                pass
            return
        except Exception as error:
            last_error = error
            time.sleep(0.3)
    pytest.fail(f"Could not fill LLM form field {index}: {last_error}")


def _open_llm_settings(driver) -> None:
    settings = helpers.wait_for_any(
        driver,
        [
            helpers.by_label("设置"),
            (
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeButton" AND label CONTAINS[c] "设置"',
            ),
        ],
        timeout=15,
    )
    settings.click()
    helpers.wait_for(driver, helpers.by_label("LLM 设置"), timeout=15)


def _return_home_from_settings(driver) -> None:
    try:
        back_button = driver.find_element(
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeButton" AND '
            '(label == "Back" OR label == "返回" OR name == "arrow_back")',
        )
        back_button.click()
    except NoSuchElementException:
        driver.back()
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)


def _wait_for_image_request() -> list[dict]:
    deadline = time.time() + 15
    while time.time() < deadline:
        requests = helpers.mock_server_get("/requests", MOCK_SERVER_URL)
        image_requests = [request for request in requests if request.get("has_image") is True]
        if image_requests:
            return image_requests
        time.sleep(0.25)
    return []


def _select_test_photo(driver) -> None:
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
        thumbnails = driver.find_elements(
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeImage" AND label BEGINSWITH "Photo,"',
        )
        if thumbnails:
            thumbnail = thumbnails[0]
            rect = thumbnail.rect
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
    pytest.fail("Photo picker did not show the imported simulator test image")


def _open_calendar_and_select_today(driver) -> None:
    date_button = helpers.wait_for_any(
        driver,
        [
            helpers.by_label_contains("选择日期"),
            helpers.by_label_contains("今天"),
            helpers.by_label_contains("昨日"),
        ],
        timeout=12,
    )
    date_button.click()
    helpers.wait_for(driver, helpers.by_label_contains("日历"), timeout=15)

    today = time.localtime()
    today_label = f"{today.tm_year}年{today.tm_mon}月{today.tm_mday}日"
    locator = (
        AppiumBy.IOS_PREDICATE,
        'type == "XCUIElementTypeStaticText" AND label CONTAINS[c] '
        f'"{today_label}"',
    )
    today_cell = helpers.wait_for(driver, locator, timeout=15)
    today_cell.click()
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=15)


def test_configure_recognize_and_review_daily_detail(driver):
    """Run the three requested stages in order, sharing only this journey's state."""
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=25)

    # 1. Configure and validate a new profile. New profiles are active by default;
    # the subsequent image recognition verifies that the selected profile works.
    helpers.mock_server_get("/reset", MOCK_SERVER_URL)
    _open_llm_settings(driver)
    helpers.tap_text(driver, "添加新配置")
    helpers.wait_for(driver, helpers.by_label("添加配置"), timeout=10)

    run_id = str(time.time_ns())
    profile_name = f"Appium Journey {time.strftime('%H%M%S')}-{run_id[-6:]}"
    profile_model = f"appium-vision-{run_id}"
    _fill_field(driver, 0, profile_name)
    _fill_field(driver, 1, MOCK_BASE_URL)
    _fill_field(driver, 2, profile_model)
    _fill_field(driver, 3, "appium-test-key")
    _fill_field(driver, 4, "30")

    helpers.tap_text(driver, "验证连通性")
    helpers.wait_for(driver, helpers.by_label_contains("连通正常"), timeout=20)
    validation_requests = helpers.mock_server_get("/requests", MOCK_SERVER_URL)
    assert any(
        request.get("has_image") is False and request.get("model") == profile_model
        for request in validation_requests
    ), (
        "LLM connectivity validation did not reach the mock server"
    )

    helpers.tap_text(driver, "保存")
    helpers.wait_for(driver, helpers.by_label_contains(profile_name), timeout=20)

    # 2. Recognize a simulator photo and persist the deterministic mock result.
    _return_home_from_settings(driver)
    fab = helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"))
    helpers.long_press(driver, fab)
    _select_test_photo(driver)

    helpers.wait_for(driver, helpers.by_label("AI 识别结果"), timeout=45)
    name_fields = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
    recognized_names = [field.get_attribute("value") or "" for field in name_fields]
    assert MEAL_NAME in recognized_names, (
        f"Unexpected recognition result name field values: {recognized_names}"
    )

    helpers.tap_text(driver, "保存记录")
    helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)
    assert helpers.scroll_to_text(driver, MEAL_NAME, max_swipes=8), (
        "Saved recognition result is missing from the home diary"
    )
    image_requests = _wait_for_image_request()
    assert any(request.get("model") == profile_model for request in image_requests), (
        "Recognition did not use the LLM profile just configured and activated"
    )

    # 3. Review the saved meal on home, select its date in the calendar, and
    # inspect the day's saved meal details.
    assert helpers.exists(driver, helpers.by_label_contains(MEAL_NAME))
    _open_calendar_and_select_today(driver)
    assert helpers.scroll_to_text(driver, MEAL_NAME, max_swipes=8), (
        "The selected day's home view does not contain the saved meal"
    )

    meal_card = helpers.wait_for_clickable(
        driver, helpers.by_label_contains(MEAL_NAME), timeout=12
    )
    meal_card.click()

    # 新 UI：点击餐食进入查看页（MealViewPage），不再直接进编辑页
    # 查看页顶部显示餐食名，底部有"修改"按钮
    helpers.wait_for(driver, helpers.by_label_contains(MEAL_NAME), timeout=15)

    # 检查食材在查看页中可见
    for ingredient in ("饺子", "鸡蛋", "橘子"):
        found = False
        for _ in range(6):
            if helpers.exists(driver, helpers.by_label_contains(ingredient)):
                found = True
                break
            helpers.scroll_down(driver, ratio=0.35)
            time.sleep(0.25)
        assert found, f"Meal view is missing ingredient {ingredient!r}"
    assert helpers.exists(driver, helpers.by_label_contains("462")), (
        "Meal view does not show the expected total of 462 kcal"
    )

    # 点击"修改"按钮进入编辑页
    helpers.tap_text(driver, "修改", timeout=12)
    helpers.wait_for(driver, helpers.by_label("编辑餐食"), timeout=15)

    editor_fields = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
    values = [field.get_attribute("value") or "" for field in editor_fields]
    assert MEAL_NAME in values, f"Editor does not show the saved meal name: {values}"
    for ingredient in ("饺子", "鸡蛋", "橘子"):
        found = False
        for _ in range(6):
            editor_fields = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
            values = [field.get_attribute("value") or "" for field in editor_fields]
            if ingredient in values:
                found = True
                break
            helpers.scroll_down(driver, ratio=0.35)
            time.sleep(0.25)
        assert found, f"Editor is missing ingredient {ingredient!r}: {values}"
    assert helpers.exists(driver, helpers.by_label_contains("462 kcal")), (
        "Editor does not show the expected total of 462 kcal"
    )
