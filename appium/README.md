# Appium + WebDriverAgent self-loop tests

End-to-end verification of the core user journey on a real device or simulator:

```
Home -> Configure LLM (mock server) -> Long-press camera FAB
  -> Gallery pick -> AI Recognition -> Save record -> Home + Calendar display
```

LLM HTTP requests are hijacked by a local `mock_llm_server.py` that returns a
deterministic recognition payload. The mock logs every incoming request so the
test suite can assert at the end that an image-bearing recognition request was
actually dispatched.

## One-time environment setup

```bash
# 1. Appium 2 + XCUITest driver (includes WebDriverAgent) - use bun instead of npm
bun add -g appium
appium driver install xcuitest

# 2. Launch the Appium server in a separate terminal (keep it running)
appium

# 3. Python dependencies
cd appium
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Running tests (simulator - recommended)

```bash
./appium/run.sh               # Build -> boot selected simulator -> install app/image -> start/reuse mock -> run the core journey
./appium/run.sh --skip-build  # Skip Flutter build when the simulator app already exists
```

The default run verifies one ordered user journey:

1. Add an LLM profile, validate its connection to the mock, and save it as the
   active profile.
2. Pick the simulator photo, recognize it through the mock, save the meal, and
   verify that the image request reached the mock.
3. Verify the saved meal on the home diary, open the calendar and select today,
   then inspect the saved meal's ingredients and nutrition details.

The journey uses a uniquely named profile and leaves the resulting test data in
the simulator. It reuses a healthy Mock LLM already listening on `MOCK_PORT`;
an occupied port that is not a healthy mock is reported as an error. To run the
older granular regression cases separately:

```bash
cd appium
.venv/bin/python -m pytest tests/test_app.py -v
```

Set `IOS_DEVICE_NAME` (default `iPhone 17`) or `IOS_SIMULATOR_UDID` to select a
simulator. `MOCK_PORT`, `MOCK_BASE_URL`, and `APPIUM_SERVER` can be overridden
for custom local test environments.

## Running tests (real device)

`run.sh` is simulator-only. A real-device run additionally requires a signed
WebDriverAgent, the app installed on the device, the generated test image in
its photo library, and a mock URL reachable from the device. After preparing
those prerequisites, run the same journey directly:

```bash
export APPIUM_REAL_DEVICE=1
export IOS_UDID=<your device UDID>
export XCODE_ORG_ID=<your Apple Team ID>
export MOCK_BASE_URL=http://<Mac LAN IP>:8611/v1
cd appium && .venv/bin/python -m pytest tests/test_user_journey.py -v
```

## Test cases covered

Tests are executed in class order - app data is preserved between classes via
`noReset=True` so later tests can rely on the LLM profile created earlier.

| #  | Class                   | What it verifies                                                                 |
|----|-------------------------|----------------------------------------------------------------------------------|
| 1  | TestHomeInitial         | App boots to home screen, FAB visible                                            |
| 2  | TestLlmEmptyState       | Empty-state hint rendered when zero LLM profiles are stored                      |
| 3  | TestConfigureFirstLlm   | Add mock profile, validate connectivity, save, confirm list includes it         |
| 4  | TestLlmFormValidation   | Required-field + missing-API-key validation errors surfaced correctly           |
| 5  | TestHttpDebugPanel      | Alice HTTP inspector opens without crashing the app                              |
| 6  | TestSecondLlmProfile    | Add second profile + switch the active profile using the primary row selector    |
| 7  | TestEditLlmProfile      | Rename + change timeout of a profile, changes persist after save                 |
| 8  | TestDeleteLlmProfile    | Delete via confirmation AlertDialog, row disappears, primary profile stays      |
| 9  | TestGoalSettings        | Set kcal + carbs + protein + fat goals, navigate back to home                    |
| 10 | TestRecognizeAndSave    | Long-press FAB -> gallery -> AI result page -> "保存记录", mock received image   |
| 11 | TestHomeWithData        | Meal card renders on home + nutrition progress shows macro labels               |
| 12 | TestCalendar            | Calendar renders today's date; kcal badge is visually verified                  |
| 13 | TestMealEditor          | Edit meal name, save, and confirm the change persists                            |
| 14 | TestDateNavigation      | Prev-day chevron changes the displayed date label; next chevron restores today   |

## Layout

```
appium/
├── conftest.py            # Appium driver fixture (simulator / real device capability sets)
├── helpers.py             # Element lookup, long-press, scroll, mock queries
├── mock_llm_server.py     # Local OpenAI-compatible mock that logs requests for assertions
├── assets/
│   └── make_test_image.py # Generates a test PNG using only the Python standard library
├── tests/
│   └── test_app.py        # Core journey test cases (execute in class declaration order)
└── run.sh                 # One-click launcher script
```

## Troubleshooting

- **FAB "拍照识别热量" not found**: Flutter sometimes attaches text labels to a
  descendant StaticText rather than the button itself - use `appium inspector`
  to view the actual accessibility tree.
- **Empty photo library on simulator**: run
  `xcrun simctl addmedia booted appium/assets/test_meal.png`. On iOS 26,
  PHPicker exposes photo thumbnails as `XCUIElementTypeImage` rather than
  `XCUIElementTypeCell`; the test supports both accessibility layouts.
- **Real device cannot reach mock server**: ensure phone + Mac share the same
  Wi-Fi, set `MOCK_BASE_URL` to the Mac's LAN IP, and allow port 8611 through
  the Mac firewall.
- **WDA signing failure**: follow
  https://appium.github.io/appium-xcuitest-driver/latest/preparation/real-device-config/
