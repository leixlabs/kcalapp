"""Shared utilities for Appium tests: element lookup, long press, waits, scrolling."""
from __future__ import annotations

import time
import urllib.request

from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

DEFAULT_TIMEOUT = 10


def by_label(text: str):
    """Find by Flutter semantic label (accessibility id).

    Flutter exports Text widget content as accessibility label by default.
    """
    return (AppiumBy.ACCESSIBILITY_ID, text)


def by_label_contains(text: str):
    """Predicate-based lookup matching label or name containing ``text`` (case-insensitive)."""
    escaped = text.replace('"', '\\"')
    return (AppiumBy.IOS_PREDICATE, f'label CONTAINS[c] "{escaped}" OR name CONTAINS[c] "{escaped}"')


def by_label_exact_or_contains(exact: str, contains: str | None = None):
    """Try exact accessibility id first, then fall back to predicate contains.

    Flutter sometimes puts display text on a descendant StaticText rather than the
    interactive element itself; this helper bridges the two cases.
    """
    contains = contains or exact
    return by_label_contains(contains)


def wait_for(driver, locator, timeout=DEFAULT_TIMEOUT):
    return WebDriverWait(driver, timeout).until(EC.presence_of_element_located(locator))


def wait_for_clickable(driver, locator, timeout=DEFAULT_TIMEOUT):
    return WebDriverWait(driver, timeout).until(EC.element_to_be_clickable(locator))


def wait_for_any(driver, locators: list[tuple], timeout=DEFAULT_TIMEOUT):
    """Return the first locator that yields an element within ``timeout``."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        for loc in locators:
            try:
                el = driver.find_element(*loc)
                return el
            except NoSuchElementException:
                pass
        time.sleep(0.2)
    raise NoSuchElementException(f"None of {len(locators)} locators appeared in time")


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


def count(driver, locator) -> int:
    try:
        return len(driver.find_elements(*locator))
    except NoSuchElementException:
        return 0


def wait_gone(driver, locator, timeout=DEFAULT_TIMEOUT) -> bool:
    """Wait until element disappears; return True if it did."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        if not exists(driver, locator):
            return True
        time.sleep(0.3)
    return False


def long_press(driver, element, duration_ms: int = 900):
    """Native XCUITest long press via mobile:touchAndHold.

    Used for the FAB which opens the gallery picker on long-press.
    """
    rect = element.rect
    driver.execute_script("mobile: touchAndHold", {
        "x": rect["x"] + rect["width"] / 2,
        "y": rect["y"] + rect["height"] / 2,
        "duration": duration_ms / 1000,
    })


def scroll_down(driver, ratio: float = 0.5):
    """Perform a swipe-down gesture to scroll content up.

    ``ratio`` controls swipe length relative to screen height.
    """
    size = driver.get_window_size()
    start_x = size["width"] * 0.5
    start_y = size["height"] * (0.5 + ratio / 2)
    end_y = size["height"] * (0.5 - ratio / 2)
    driver.execute_script("mobile: swipe", {
        "direction": "up",
        "x": start_x,
        "y": start_y,
        "endX": start_x,
        "endY": end_y,
    })


def scroll_up(driver, ratio: float = 0.5):
    size = driver.get_window_size()
    start_x = size["width"] * 0.5
    start_y = size["height"] * (0.5 - ratio / 2)
    end_y = size["height"] * (0.5 + ratio / 2)
    driver.execute_script("mobile: swipe", {
        "direction": "down",
        "x": start_x,
        "y": start_y,
        "endX": start_x,
        "endY": end_y,
    })


def scroll_to_text(driver, text: str, max_swipes: int = 8, timeout_per_swipe: float = 0.5):
    """Repeatedly scroll down until an element with ``text`` in its label is visible."""
    loc = by_label_contains(text)
    for _ in range(max_swipes):
        if exists(driver, loc):
            return True
        scroll_down(driver)
        time.sleep(timeout_per_swipe)
    return exists(driver, loc)


def clear_textfield(driver, element):
    """Clear a Flutter TextField / SecureTextField reliably even when the IME is slow.

    Uses select-all via gesture fallback on failure of plain .clear().
    """
    for _ in range(3):
        try:
            element.click()
            element.clear()
            val = element.get_attribute("value") or ""
            if val == "":
                return
        except Exception:
            pass
        time.sleep(0.2)
    # Fallback: send backspace characters
    current = element.get_attribute("value") or ""
    if current:
        element.send_keys("\b" * len(current) * 2)


def send_keys_cleared(driver, element, text: str):
    clear_textfield(driver, element)
    element.send_keys(text)
    try:
        driver.hide_keyboard()
    except Exception:
        pass


def mock_server_get(path: str, base: str = "http://127.0.0.1:8611"):
    """Query the mock LLM server endpoints (``/requests``, ``/reset``, ``/health``)."""
    with urllib.request.urlopen(base + path, timeout=5) as resp:
        import json

        return json.loads(resp.read().decode("utf-8"))


def _collect_sorted_textfields(driver):
    """Gather every TextField and SecureTextField on screen, sorted by visual
    (top->bottom, then left->right) screen position so indices match the order
    a human would fill a form.

    A naive ``TextField_list + SecureTextField_list`` concatenation breaks the
    form order whenever a SecureTextField (e.g. API Key) sits between regular
    TextFields.
    """
    a = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
    b = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeSecureTextField")
    combined = []
    for el in list(a) + list(b):
        try:
            rect = el.rect
            combined.append((rect.get("y", 0), rect.get("x", 0), el))
        except Exception:
            continue
    combined.sort(key=lambda t: (t[0], t[1]))
    return [t[2] for t in combined]


def flutter_textfield(driver, index: int):
    """Return the ``index``-th Flutter TextField / SecureTextField on screen in visual order."""
    ordered = _collect_sorted_textfields(driver)
    if len(ordered) <= index:
        raise NoSuchElementException(
            f"TextField[{index}] not found; only {len(ordered)} fields visible in this frame"
        )
    return ordered[index]


def flutter_textfield_count(driver) -> int:
    return len(_collect_sorted_textfields(driver))
