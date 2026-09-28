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
./appium/run.sh               # Full pipeline: build -> boot sim -> install app -> push test image -> start mock -> pytest
./appium/run.sh --skip-build  # Skip the Flutter build step when the app binary already exists
```

## Running tests (real device)

Real devices require WebDriverAgent signing. Prepare:

1. Open `ios/Runner.xcworkspace` in Xcode and assign your development Team.
2. Discover the device UDID: `xcrun xctrace list devices`
3. Execute:

```bash
export APPIUM_REAL_DEVICE=1
export IOS_UDID=<your device UDID>
export XCODE_ORG_ID=<your Apple Team ID>
export MOCK_BASE_URL=http://<Mac LAN IP>:8611/v1   # real device cannot reach 127.0.0.1
./appium/run.sh --skip-build   # Build + install the debug IPA beforehand with `flutter build ios --debug`
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
| 6  | TestSecondLlmProfile    | Add second profile + tap radio icon to activate/deactivate                       |
| 7  | TestEditLlmProfile      | Rename + change timeout of a profile, changes persist after save                 |
| 8  | TestDeleteLlmProfile    | Delete via confirmation AlertDialog, row disappears, primary profile stays      |
| 9  | TestGoalSettings        | Set kcal + carbs + protein + fat goals, navigate back to home                    |
| 10 | TestRecognizeAndSave    | Long-press FAB -> gallery -> AI result page -> "保存记录", mock received image   |
| 11 | TestHomeWithData        | Meal card renders on home + nutrition progress shows macro labels               |
| 12 | TestCalendar            | Calendar page attaches kcal badge to today's cell                                |
| 13 | TestMealEditor          | Tap meal card, edit meal name/servings, save without crashing                    |
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
  `xcrun simctl addmedia booted appium/assets/test_meal.png`
- **Real device cannot reach mock server**: ensure phone + Mac share the same
  Wi-Fi, set `MOCK_BASE_URL` to the Mac's LAN IP, and allow port 8611 through
  the Mac firewall.
- **WDA signing failure**: follow
  https://appium.github.io/appium-xcuitest-driver/latest/preparation/real-device-config/
