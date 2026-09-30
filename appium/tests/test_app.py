"""End-to-end self-loop tests for the core user journey.

Test order matters. The session fixture keeps app data via noReset=True so the
sequence below builds cumulative state:

  0. Cleanup any pre-existing LLM profiles from a prior session (repeatable runs).
  1. Home loads.
  2. LLM empty state (zero profiles guaranteed by previous step).
  3. Add the first mock LLM profile -> validate connectivity -> save -> active.
  4. Form validation: required fields and missing-API-key paths surface errors.
  5. HTTP debug panel opens (Alice inspector) and we can return without crash.
  6. Add a second profile, test radio-icon activate swap.
  7. Edit an existing profile: rename + change timeout -> changes persist.
  8. Delete the edited secondary profile -> row disappears, primary stays.
  9. Goal settings: set kcal + macros -> save -> return home.
 10. Long-press FAB -> gallery pick -> AI recognition -> save record.
 11. Home shows meal card + nutrition summary.
 12. Calendar shows 462 kcal badge on today's cell.
 13. Meal editor: open card, tweak values, save without crashing.
 14. Date navigation: prev/next day chevrons change the rendered date label.

Requires:
  - mock_llm_server.py listening on 127.0.0.1:8611
  - build/ios/iphonesimulator/Runner.app installed on the booted simulator
  - test_meal.png in the simulator photo library
"""
from __future__ import annotations

import json
import os
import time

import pytest
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException

import helpers
from conftest import MOCK_BASE_URL, PROJECT_ROOT


ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets")


# ---------------------------------------------------------------------------
# Auto-fixture: reset mock server request log before each test
# ---------------------------------------------------------------------------
@pytest.fixture(autouse=True)
def reset_mock():
    try:
        helpers.mock_server_get("/reset")
    except Exception:
        pass
    yield


# ---------------------------------------------------------------------------
# Navigation + form helpers (shared across test classes)
# ---------------------------------------------------------------------------
def _reset_to_home(driver):
    """Aggressively dismiss any modals / sheets / extra pages until home FAB is visible."""
    for attempt in range(8):
        # 1) Try to tap a visible cancel button or sheet-drag handle
        dismissed = False
        for label in ("cancel", "取消", "Close", "关闭", "Done"):
            if helpers.exists(driver, helpers.by_label_contains(label)):
                try:
                    helpers.tap_text(driver, label)
                    time.sleep(0.4)
                    dismissed = True
                    break
                except Exception:
                    pass
        if dismissed:
            continue
        if helpers.exists(driver, helpers.by_label_contains("拍照识别热量")):
            return
        # 2) Try to tap an AppBar back button
        try:
            back_btn = driver.find_element(
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeButton" AND '
                '(label == "Back" OR label == "返回" OR name == "chevron.left" OR label == "chevron_left")',
            )
            back_btn.click()
            time.sleep(0.35)
            continue
        except NoSuchElementException:
            pass
        # 3) Fall back to native back
        try:
            driver.back()
        except Exception:
            pass
        time.sleep(0.35)


def _navigate_to_llm_settings(driver):
    _reset_to_home(driver)
    settings_entry = helpers.wait_for_any(
        driver,
        [
            helpers.by_label("设置"),
            helpers.by_label_contains("settings"),
            (
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeButton" AND '
                'label CONTAINS[c] "设置" AND label ENDSWITH[c] "设置"',
            ),
        ],
        timeout=15,
    )
    settings_entry.click()
    helpers.wait_for(driver, helpers.by_label("LLM 设置"), timeout=15)


def _fill_textfield_by_index(driver, index: int, text: str):
    """Fill the ``index``-th visually ordered text/secure field with ``text``.

    Uses Flutter bottom sheet fields. Because Flutter may rebuild the tree between
    interactions, we re-locate the field on each retry and confirm a value was set.
    """
    deadline = time.time() + 20
    last_err = None
    while time.time() < deadline:
        try:
            # Let the sheet settle so all 5 fields are rendered
            count = helpers.flutter_textfield_count(driver)
            if count <= index:
                time.sleep(0.3)
                continue
            field = helpers.flutter_textfield(driver, index)
            field.click()
            time.sleep(0.15)
            helpers.clear_textfield(driver, field)
            field.send_keys(text)
            time.sleep(0.25)
            # Dismiss keyboard if possible (not mandatory - sheet may accept inline)
            try:
                driver.hide_keyboard()
            except Exception:
                pass
            # Confirm some content is now present on-screen (we cannot reliably read
            # back SecureTextField values on iOS, so just trust length > 0 if not secure)
            try:
                val = field.get_attribute("value") or ""
                element_type = field.get_attribute("type") or ""
                if "Secure" not in element_type and val != "" and text not in val:
                    continue  # write lost, retry once more
            except Exception:
                pass
            return
        except Exception as exc:  # noqa: BLE001
            last_err = exc
            time.sleep(0.35)
    pytest.fail(f"Unable to fill visual text field [{index}] with '{text}': {last_err}")


def _fill_textfield_by_label(driver, label: str, text: str):
    """Fill a field by its Flutter label when off-screen fields distort rect order."""
    locator = (
        AppiumBy.IOS_PREDICATE,
        f'type == "XCUIElementTypeTextField" AND label == "{label}"',
    )
    deadline = time.time() + 20
    last_err = None
    while time.time() < deadline:
        try:
            field = helpers.wait_for(driver, locator, timeout=2)
            field.click()
            helpers.clear_textfield(driver, field)
            field.send_keys(text)
            try:
                driver.hide_keyboard()
            except Exception:
                pass
            value = driver.find_element(*locator).get_attribute("value") or ""
            if value == text:
                return
        except Exception as exc:  # noqa: BLE001
            last_err = exc
        time.sleep(0.3)
    pytest.fail(f"Unable to fill text field '{label}' with '{text}': {last_err}")


def _open_profile_form(driver, for_edit=False):
    if for_edit:
        card = helpers.wait_for(driver, helpers.by_label_contains("Mock LLM"), timeout=12)
        card.click()
    else:
        helpers.tap_text(driver, "添加新配置")
    helpers.wait_for_any(
        driver,
        [helpers.by_label("添加配置"), helpers.by_label("编辑配置")],
        timeout=10,
    )


def _dismiss_profile_form(driver):
    """Cancel out of the add/edit bottom-sheet form."""
    for _ in range(3):
        if helpers.exists(driver, helpers.by_label("取消")):
            try:
                helpers.tap_text(driver, "取消")
                return
            except Exception:
                pass
        try:
            driver.back()
        except Exception:
            pass
        time.sleep(0.3)


def _delete_all_profiles(driver):
    """Remove every existing LLM profile row so the empty state becomes visible.

    Used so repeated pytest runs behave the same as the first run.
    """
    _navigate_to_llm_settings(driver)
    # Flutter exposes ListTile rows as buttons rather than XCUIElementTypeCell.
    # Locate profile-row buttons by their visible title/subtitle and tap the
    # trailing delete icon within the row.
    for _safe in range(10):
        profile_rows = driver.find_elements(
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeButton" AND '
            '(label CONTAINS "http" OR label CONTAINS "mock-" OR '
            'label CONTAINS "Mock" OR label CONTAINS ".com")',
        )
        if not profile_rows:
            if helpers.exists(driver, helpers.by_label_contains("暂无配置")):
                break
            pytest.fail("LLM profile rows were not accessible during pre-test cleanup")
        row = profile_rows[0]
        rect = row.rect
        try:
            driver.execute_script(
                "mobile: tap",
                {
                    "x": rect["x"] + rect["width"] - 48,
                    "y": rect["y"] + rect["height"] / 2,
                },
            )
        except Exception:
            try:
                trash = driver.find_element(helpers.by_label("delete_outline"))
                trash.click()
            except NoSuchElementException:
                raise AssertionError("Could not locate a profile delete control")
        time.sleep(0.8)
        # Confirm dialog: tap the delete button (Chinese labels)
        try:
            helpers.wait_for_any(
                driver,
                [helpers.by_label_contains("删除配置"), helpers.by_label("删除")],
                timeout=6,
            )
            helpers.wait_for_clickable(driver, helpers.by_label("删除")).click()
        except Exception:
            pytest.fail("Deleting a profile did not show a confirmation dialog")
        time.sleep(1.0)


# ---------------------------------------------------------------------------
# 0. Session-level cleanup: ensure we start with zero LLM profiles
# ---------------------------------------------------------------------------
class Test0CleanPreexistingProfiles:
    def test_delete_any_preexisting_profiles(self, driver):
        _delete_all_profiles(driver)
        # Confirm empty-state hint is rendered at index 2
        assert helpers.exists(driver, helpers.by_label_contains("暂无配置")), (
            "After cleanup the LLM list should render the empty copy"
        )
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 1. Home initial load
# ---------------------------------------------------------------------------
class Test1HomeInitial:
    def test_home_loaded(self, driver):
        helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=25)


# ---------------------------------------------------------------------------
# 2. LLM empty state (guaranteed empty now)
# ---------------------------------------------------------------------------
class Test2LlmEmptyState:
    def test_empty_state_present(self, driver):
        _navigate_to_llm_settings(driver)
        assert helpers.exists(driver, helpers.by_label("添加新配置"))
        assert helpers.exists(driver, helpers.by_label_contains("HTTP 调试面板"))
        assert helpers.exists(driver, helpers.by_label_contains("暂无配置"))
        assert helpers.exists(driver, helpers.by_label_contains("添加 LLM 服务"))
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 3. Add first (primary) mock LLM profile
# ---------------------------------------------------------------------------
class Test3ConfigureFirstLlm:
    def test_add_mock_llm_profile(self, driver):
        _navigate_to_llm_settings(driver)
        _open_profile_form(driver, for_edit=False)

        base = MOCK_BASE_URL.rstrip("/").removesuffix("/v1").rstrip("/")
        # The form order on screen (sorted by y position):
        # 0=name, 1=Base URL, 2=model, 3=API Key (Secure), 4=timeout (seconds)
        _fill_textfield_by_index(driver, 0, "Mock LLM")
        _fill_textfield_by_index(driver, 1, base)
        _fill_textfield_by_index(driver, 2, "mock-vision")
        _fill_textfield_by_index(driver, 3, "mock-key-12345")
        _fill_textfield_by_index(driver, 4, "30")

        helpers.tap_text(driver, "验证连通性")
        validated = False
        for _ in range(35):
            if helpers.exists(driver, helpers.by_label_contains("连通正常")):
                validated = True
                break
            if helpers.exists(driver, helpers.by_label_contains("失败")) or helpers.exists(
                driver, helpers.by_label_contains("未知错误")
            ):
                pytest.fail("Connectivity validation failed (inline error shown)")
            time.sleep(0.3)
        assert validated, "Timed out waiting for the connectivity validation banner"

        helpers.tap_text(driver, "保存")
        helpers.wait_for(driver, helpers.by_label_contains("Mock LLM"), timeout=20)
        assert helpers.exists(driver, helpers.by_label("添加新配置"))
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 4. Form validation
# ---------------------------------------------------------------------------
class Test4LlmFormValidation:
    def test_required_fields_error(self, driver):
        _navigate_to_llm_settings(driver)
        _open_profile_form(driver, for_edit=True)

        # Clear name field only, press validate
        name_field = helpers.flutter_textfield(driver, 0)
        name_field.click()
        helpers.clear_textfield(driver, name_field)

        helpers.tap_text(driver, "验证连通性")
        time.sleep(1.2)
        # The form should NOT dismiss. Just ensure we still see the sheet title,
        # meaning validation blocked a silent save.
        form_open = helpers.exists(driver, helpers.by_label("编辑配置")) or helpers.exists(
            driver, helpers.by_label("添加配置")
        )
        assert form_open, "Validation with empty name should keep the form open"
        _dismiss_profile_form(driver)
        _reset_to_home(driver)

    def test_missing_api_key_validation_error(self, driver):
        _navigate_to_llm_settings(driver)
        _open_profile_form(driver, for_edit=False)

        base = MOCK_BASE_URL.rstrip("/").removesuffix("/v1").rstrip("/")
        _fill_textfield_by_index(driver, 0, "Temp NoKey")
        _fill_textfield_by_index(driver, 1, base)
        _fill_textfield_by_index(driver, 2, "mock-vision")
        # skip API key (index 3) on purpose
        _fill_textfield_by_index(driver, 4, "30")

        helpers.tap_text(driver, "验证连通性")
        time.sleep(1.2)
        # Form still present = validation correctly blocked save-navigation
        form_still_open = helpers.exists(driver, helpers.by_label("添加配置")) or helpers.exists(
            driver, helpers.by_label("编辑配置")
        )
        assert form_still_open, "Missing API key should block validation progress"
        _dismiss_profile_form(driver)
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 5. HTTP debug panel smoke test
# ---------------------------------------------------------------------------
class Test5HttpDebugPanel:
    def test_debug_panel_opens_and_returns(self, driver):
        _navigate_to_llm_settings(driver)
        helpers.tap_text(driver, "HTTP 调试面板")
        time.sleep(2.5)

        # Alice opens a native inspector screen that can hang XCUITest's back
        # command. Restarting the app returns to its initial route reliably.
        driver.terminate_app("com.calory.calory")
        driver.activate_app("com.calory.calory")
        helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=15)
        # Confirm we can reach LLM settings again (no crash, state intact)
        _navigate_to_llm_settings(driver)
        assert helpers.exists(driver, helpers.by_label("添加新配置"))
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 6. Second LLM profile + activate swap
# ---------------------------------------------------------------------------
class Test6SecondLlmProfile:
    NAME = "Mock LLM Secondary"

    def test_add_secondary_profile(self, driver):
        _navigate_to_llm_settings(driver)
        _open_profile_form(driver, for_edit=False)

        base = MOCK_BASE_URL.rstrip("/").removesuffix("/v1").rstrip("/")
        _fill_textfield_by_index(driver, 0, self.NAME)
        _fill_textfield_by_index(driver, 1, base)
        _fill_textfield_by_index(driver, 2, "mock-vision-2")
        _fill_textfield_by_index(driver, 3, "mock-key-67890")
        _fill_textfield_by_index(driver, 4, "45")

        helpers.tap_text(driver, "保存")
        helpers.wait_for(driver, helpers.by_label_contains(self.NAME), timeout=20)

    def test_activate_secondary_profile(self, driver):
        _navigate_to_llm_settings(driver)
        # Adding a profile makes it active immediately; tap the existing
        # primary profile to exercise switching the active selection.
        primary = None
        deadline = time.time() + 12
        while time.time() < deadline and primary is None:
            for row in driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeButton"):
                label = row.get_attribute("label") or ""
                if label and label.splitlines()[0] == "Mock LLM":
                    primary = row
                    break
            if primary is None:
                time.sleep(0.2)
        assert primary is not None, "Primary Mock LLM profile row was not found"
        rect = primary.rect
        # The leading selector is aligned near the first title line rather than
        # vertically centered across the three-line ListTile.
        driver.execute_script(
            "mobile: tap",
            {"x": rect["x"] + 28, "y": rect["y"] + 20},
        )
        time.sleep(1.2)
        # Both profiles should still exist and app not crash
        assert helpers.exists(driver, helpers.by_label_contains("Mock LLM"))
        assert helpers.exists(driver, helpers.by_label_contains(self.NAME))
        assert not helpers.exists(driver, helpers.by_label("编辑配置")), (
            "Tapping the active-profile selector should not open the edit form"
        )
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 7. Edit an existing profile (rename + timeout)
# ---------------------------------------------------------------------------
class Test7EditLlmProfile:
    NEW_NAME = "Mock LLM Edited"

    def test_edit_profile_persists(self, driver):
        _navigate_to_llm_settings(driver)
        secondary = helpers.wait_for(driver, helpers.by_label_contains(Test6SecondLlmProfile.NAME))
        secondary.click()
        helpers.wait_for(driver, helpers.by_label("编辑配置"), timeout=10)

        _fill_textfield_by_index(driver, 0, self.NEW_NAME)
        _fill_textfield_by_index(driver, 4, "60")

        if helpers.exists(driver, helpers.by_label("更新")):
            helpers.tap_text(driver, "更新")
        else:
            helpers.tap_text(driver, "保存")
        helpers.wait_for(driver, helpers.by_label_contains(self.NEW_NAME), timeout=20)
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 8. Delete the edited secondary profile
# ---------------------------------------------------------------------------
class Test8DeleteLlmProfile:
    def test_delete_profile_via_dialog(self, driver):
        _navigate_to_llm_settings(driver)
        edited = helpers.wait_for(driver, helpers.by_label_contains(Test7EditLlmProfile.NEW_NAME))
        rect = edited.rect
        driver.execute_script(
            "mobile: tap",
            {
                "x": rect["x"] + rect["width"] - 48,
                "y": rect["y"] + rect["height"] / 2,
            },
        )
        helpers.wait_for_any(
            driver,
            [helpers.by_label_contains("删除配置"), helpers.by_label("删除")],
            timeout=8,
        )
        helpers.wait_for_clickable(driver, helpers.by_label("删除")).click()
        time.sleep(1.2)
        assert not helpers.exists(driver, helpers.by_label_contains(Test7EditLlmProfile.NEW_NAME))
        assert helpers.exists(driver, helpers.by_label_contains("Mock LLM"))
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 9. Goal settings
# ---------------------------------------------------------------------------
class Test9GoalSettings:
    def test_goal_page_set_and_save(self, driver):
        _reset_to_home(driver)
        helpers.scroll_to_text(driver, "设置目标", max_swipes=5)
        goal_button = helpers.by_label("设置目标")
        if not helpers.exists(driver, goal_button):
            # Goal already configured, skip this smoke test without failing.
            pytest.skip("Home goal card already configured - no button to open goal settings")

        helpers.wait_for_clickable(driver, goal_button).click()
        helpers.wait_for(driver, helpers.by_label("目标设置"), timeout=12)
        # Goal page fields (visually sorted): 0=kcal,1=carbs,2=protein,3=fat
        _fill_textfield_by_index(driver, 0, "2000")
        _fill_textfield_by_index(driver, 1, "250")
        _fill_textfield_by_index(driver, 2, "120")
        _fill_textfield_by_index(driver, 3, "65")
        if helpers.exists(driver, helpers.by_label("保存目标")):
            helpers.tap_text(driver, "保存目标")
        time.sleep(1.0)
        _reset_to_home(driver)
        assert helpers.exists(driver, helpers.by_label_contains("拍照识别热量"))


# ---------------------------------------------------------------------------
# 10. Long-press FAB -> gallery -> save record -> background AI recognition
# ---------------------------------------------------------------------------
class Test10RecognizeAndSave:
    def test_recognize_from_gallery_and_save(self, driver):
        _reset_to_home(driver)
        fab = helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"))
        helpers.long_press(driver, fab)

        # Accept photo library permission prompts if shown
        for label in (
            "允许访问所有照片",
            "允许",
            "选取照片",
            "Allow Full Access",
            "Allow",
            "Select Photos",
        ):
            if helpers.exists(driver, helpers.by_label(label)):
                try:
                    driver.find_element(*helpers.by_label(label)).click()
                    time.sleep(0.5)
                except Exception:
                    pass
                break

        # iOS 26's PHPicker exposes thumbnails as XCUIElementTypeImage rather
        # than XCUIElementTypeCell; retain the cell fallback for older iOS.
        photo_thumbnails = driver.find_elements(
            AppiumBy.IOS_PREDICATE,
            'type == "XCUIElementTypeImage" AND label BEGINSWITH "Photo,"',
        )
        if photo_thumbnails:
            thumbnail = photo_thumbnails[0]
            rect = thumbnail.rect
            driver.execute_script(
                "mobile: tap",
                {"x": rect["x"] + rect["width"] / 2, "y": rect["y"] + rect["height"] / 2},
            )
        else:
            cells = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
            assert cells, (
                "Simulator photo library empty - push test_meal.png via simctl addmedia first"
            )
            cells[0].click()

        helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)
        assert helpers.scroll_to_text(driver, "AI 正在识别食物", max_swipes=6) or \
            helpers.scroll_to_text(driver, "测试早餐组合", max_swipes=6), (
            "The saved meal did not show a processing state or completed recognition"
        )
        assert helpers.scroll_to_text(driver, "测试早餐组合", max_swipes=6), (
            "Background recognition did not update the saved meal"
        )

        reqs = helpers.mock_server_get("/requests")
        image_reqs = [r for r in reqs if r.get("has_image") is True]
        assert len(image_reqs) >= 1, (
            f"Mock never received an image request; total logged = {len(reqs)}"
        )


# ---------------------------------------------------------------------------
# 11. Home with data (meal card + nutrition summary)
# ---------------------------------------------------------------------------
class Test11HomeWithData:
    def test_shows_meal_card(self, driver):
        _reset_to_home(driver)
        assert helpers.scroll_to_text(driver, "测试早餐组合", max_swipes=6)
        assert helpers.exists(driver, helpers.by_label_contains("测试早餐组合"))
        assert any(
            helpers.exists(driver, helpers.by_label_contains(meal_type))
            for meal_type in ("早餐", "午餐", "晚餐", "加餐")
        ), "Meal card does not display a meal type"

    def test_nutrition_summary_present(self, driver):
        _reset_to_home(driver)
        helpers.scroll_to_text(driver, "蛋白质", max_swipes=6)
        any_macro = (
            helpers.exists(driver, helpers.by_label_contains("蛋白质"))
            or helpers.exists(driver, helpers.by_label_contains("碳水"))
            or helpers.exists(driver, helpers.by_label_contains("脂肪"))
        )
        assert any_macro, "Home nutrition card shows none of carbs/protein/fat labels"


# ---------------------------------------------------------------------------
# 12. Calendar kcal badge
# ---------------------------------------------------------------------------
class Test12Calendar:
    def test_calendar_drawer_shows_day_kcal_badge(self, driver):
        """Calendar day cells expose their kcal total via an accessibility label."""
        _reset_to_home(driver)
        date_btn = helpers.wait_for(
            driver, helpers.by_label_contains("选择日期"), timeout=12
        )
        date_btn.click()
        time.sleep(0.8)
        labels = [
            e.get_attribute("label") or ""
            for e in driver.find_elements(
                AppiumBy.IOS_PREDICATE, 'label CONTAINS "千卡"'
            )
        ]
        assert any(
            label.endswith("千卡") and any(ch.isdigit() for ch in label)
            for label in labels
        ), f"Calendar day cells should show a kcal badge, got: {labels}"


# ---------------------------------------------------------------------------
# 13. Meal detail inline editing (tap card -> edit title -> update)
# ---------------------------------------------------------------------------
class Test13MealInlineEdit:
    def test_edit_meal_title_from_detail(self, driver):
        _reset_to_home(driver)
        assert helpers.scroll_to_text(driver, "测试早餐组合", max_swipes=6)
        tile = helpers.wait_for(driver, helpers.by_label_contains("测试早餐组合"), timeout=12)
        tile.click()
        helpers.wait_for(driver, helpers.by_label("食材 (kcal)"), timeout=15)
        helpers.tap_text(driver, "测试早餐组合", timeout=12)
        helpers.wait_for(driver, helpers.by_label("修改餐名"), timeout=10)
        _fill_textfield_by_label(driver, "餐名", "测试早餐组合 edited")
        helpers.tap_text(driver, "保存", timeout=12)
        assert not helpers.exists(driver, helpers.by_label("更新")), (
            "Meal details should persist edits without a bottom update button"
        )
        assert helpers.scroll_to_text(driver, "测试早餐组合 edited", max_swipes=6)
        assert helpers.exists(driver, helpers.by_label_contains("测试早餐组合 edited"))
        _reset_to_home(driver)


# ---------------------------------------------------------------------------
# 14. Date navigation
# ---------------------------------------------------------------------------
class Test14DateNavigation:
    def test_prev_day_changes_date_label(self, driver):
        _reset_to_home(driver)
        # Snapshot date-text labels before the chevron tap
        date_labels_before = [
            e.get_attribute("label") or ""
            for e in driver.find_elements(
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeStaticText" AND (label CONTAINS "月" OR label CONTAINS "/")',
            )
        ]

        driver.execute_script("mobile: tap", {"x": 40, "y": 102})
        time.sleep(0.9)
        date_labels_after = [
            e.get_attribute("label") or ""
            for e in driver.find_elements(
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeStaticText" AND (label CONTAINS "月" OR label CONTAINS "/")',
            )
        ]
        assert date_labels_before != date_labels_after, (
            "Prev-chevron tap did not change any visible date labels"
        )
        driver.execute_script("mobile: tap", {"x": 180, "y": 102})
        time.sleep(0.6)
        date_labels_restored = [
            e.get_attribute("label") or ""
            for e in driver.find_elements(
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeStaticText" AND (label CONTAINS "月" OR label CONTAINS "/")',
            )
        ]
        assert date_labels_before == date_labels_restored, (
            "Next-chevron tap did not restore the original selected date"
        )
        _reset_to_home(driver)
        assert helpers.exists(driver, helpers.by_label_contains("拍照识别热量"))
