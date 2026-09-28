"""核心流程自循环测试。

测试顺序：
1. 配置 LLM（指向本地 mock 服务器）
2. 首页空状态确认
3. 长按 FAB → 选相册图片 → AI 识别 → 保存记录
4. 首页显示餐卡
5. 日历页显示当天热量

依赖：
  - mock_llm_server.py 已启动在 127.0.0.1:8611
  - build/ios/iphonesimulator/Runner.app 已存在
  - 有 test_meal.png 放在 assets/（或直接拖进模拟器相册）
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
# 前置：保证 mock 干净
# ---------------------------------------------------------------------------
@pytest.fixture(autouse=True)
def reset_mock():
    try:
        helpers.mock_server_get("/reset")
    except Exception:
        pass
    yield


# ---------------------------------------------------------------------------
# 1. 首页加载
# ---------------------------------------------------------------------------
class TestHomeInitial:
    def test_home_loaded(self, driver):
        # FAB 存在即认为首页加载成功（不依赖是否有历史数据，可重复跑）
        helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"), timeout=20)


# ---------------------------------------------------------------------------
# 2. 配置 LLM（mock 服务器）
# ---------------------------------------------------------------------------
class TestConfigureLlm:
    def _fill_field(self, driver, index: int, text: str):
        """填写第 index 个输入框（含 SecureTextField），支持元素失效重试。"""
        deadline = time.time() + 10
        while time.time() < deadline:
            fields = driver.find_elements(
                AppiumBy.IOS_PREDICATE,
                'type == "XCUIElementTypeTextField" OR type == "XCUIElementTypeSecureTextField"',
            )
            if len(fields) > index:
                try:
                    fields[index].click()
                    fields[index].send_keys(text)
                    try:
                        driver.hide_keyboard()
                    except Exception:
                        pass
                    return
                except Exception:
                    time.sleep(0.3)
                    continue
            time.sleep(0.3)
        pytest.fail(f"无法填写第 {index} 个输入框")

    def test_add_mock_llm_profile(self, driver):
        # 进设置
        helpers.tap_text(driver, "设置")
        helpers.wait_for(driver, helpers.by_label("LLM 设置"))

        # 点击“添加新配置”
        helpers.tap_text(driver, "添加新配置")
        helpers.wait_for(driver, helpers.by_label("添加配置"))

        # 填写表单：名称 / Base URL / 模型名 / API Key / 超时
        base = MOCK_BASE_URL.rstrip("/").removesuffix("/v1").rstrip("/")
        self._fill_field(driver, 0, "Mock LLM")
        self._fill_field(driver, 1, base)
        self._fill_field(driver, 2, "mock-vision")
        self._fill_field(driver, 3, "mock-key-12345")
        self._fill_field(driver, 4, "30")

        # 验证连通性
        helpers.tap_text(driver, "验证连通性")
        for _ in range(20):
            if helpers.exists(driver, helpers.by_label_contains("连通正常")):
                break
            if helpers.exists(driver, helpers.by_label_contains("失败")):
                pytest.fail("连通性验证失败")
            time.sleep(0.3)
        else:
            pytest.fail("等待验证结果超时")

        # 保存
        helpers.tap_text(driver, "保存")
        helpers.wait_for(driver, helpers.by_label_contains("Mock LLM"))

        driver.back()
        time.sleep(0.5)


# ---------------------------------------------------------------------------
# 3. 长按 FAB → 相册选图 → 识别 → 保存
# ---------------------------------------------------------------------------
class TestRecognizeAndSave:
    def test_recognize_from_gallery_and_save(self, driver):
        # 找到 FAB（右下角"拍照识别热量"）
        fab = helpers.wait_for(driver, helpers.by_label_contains("拍照识别热量"))
        helpers.long_press(driver, fab)

        # 选第一张（若系统权限弹窗出现则先允许）
        for label in ("允许访问所有照片", "允许", "选取照片"):
            if helpers.exists(driver, helpers.by_label(label)):
                driver.find_element(*helpers.by_label(label)).click()
                time.sleep(0.3)
                break

        cells = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
        assert len(cells) > 0, "模拟器相册没有照片，请先执行：python3 assets/make_test_image.py 并用 simctl 推入相册"
        cells[0].click()

        # mock 在本地，识别可能极快，"AI 识别中"弹窗可能一闪而过 —— 不强制等待它
        helpers.exists(driver, helpers.by_label_contains("AI 识别中"))

        # 主断言：进入结果页
        helpers.wait_for(driver, helpers.by_label("AI 识别结果"), timeout=30)

        # 结果页应有食材
        assert helpers.exists(driver, helpers.by_label_contains("测试早餐组合"))

        # 点“保存记录”
        helpers.tap_text(driver, "保存记录")

        # 应回到首页
        helpers.wait_for(driver, helpers.by_label_contains("今日饮食记录"))

        # 断言：mock 服务器收到了带图片的识别请求
        reqs = helpers.mock_server_get("/requests")
        image_reqs = [r for r in reqs if r.get("has_image") is True]
        assert len(image_reqs) >= 1, f"mock 未收到图片识别请求，共收到 {len(reqs)} 条"


# ---------------------------------------------------------------------------
# 4. 首页出现餐卡
# ---------------------------------------------------------------------------
class TestHomeWithData:
    def test_shows_meal_card(self, driver):
        assert helpers.exists(driver, helpers.by_label_contains("测试早餐组合"))
        assert helpers.exists(driver, helpers.by_label_contains("早餐"))


# ---------------------------------------------------------------------------
# 5. 日历页显示热量
# ---------------------------------------------------------------------------
class TestCalendar:
    def test_calendar_shows_kcal(self, driver):
        # 点击日期区域进日历
        helpers.tap_text(driver, "今天")
        helpers.wait_for(driver, helpers.by_label("日历"))

        # table_calendar 的 cell label 是完整格式，如 "星期一, 2026年9月28日"
        # 且若当天有数据，label 会附带热量，如 "星期一, 2026年9月28日, 462k"
        today = time.localtime()
        day_label_part = f"{today.tm_mon}月{today.tm_mday}日"

        deadline = time.time() + 10
        found_today, found_kcal = False, False
        while time.time() < deadline:
            cells = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeStaticText")
            labels = [c.get_attribute("label") or "" for c in cells]
            day_cells = [l for l in labels if day_label_part in l]
            if day_cells:
                found_today = True
                if any("462" in l for l in day_cells):
                    found_kcal = True
                    break
            time.sleep(0.3)

        assert found_today, f"日历中未找到今天 ({day_label_part})"
        assert found_kcal, f"今天 ({day_label_part}) 未显示 462kcal，可见: {day_cells}"

        driver.back()
