# Appium 端到端测试报告

- **项目**：2609-kcalapp（Flutter / iOS）
- **测试日期**：2026-09-28
- **执行方式**：`appium/.venv/bin/python -m pytest tests/ -v --tb=short`（跳过构建，直接复用已构建的模拟器包）
- **环境**：Appium 3.8.0 + XCUITest/WDA；iPhone 17 模拟器（iOS 26.5）；Python 3.12.12 / pytest 9.1.1
- **代码变更**：无（全程未修改任何项目代码）
- **日志**：`/tmp/kcalapp_pytest_run.log`

## 1. 结果总览

| 指标 | 数量 | 占比 |
| --- | ---: | ---: |
| 用例总数 | 18 | 100% |
| 通过 | 2 | 11.1% |
| 失败 | 15 | 83.3% |
| 跳过 | 1 | 5.6% |
| 总耗时 | 550.93s（9 分 11 秒） | — |

## 2. 逐用例结果

| # | 用例 | 结果 | 失败类型 |
| --- | --- | --- | --- |
| 0 | Test0CleanPreexistingProfiles::test_delete_any_preexisting_profiles | FAILED | A |
| 1 | Test1HomeInitial::test_home_loaded | PASSED | — |
| 2 | Test2LlmEmptyState::test_empty_state_present | FAILED | A |
| 3 | Test3ConfigureFirstLlm::test_add_mock_llm_profile | FAILED | A |
| 4 | Test4LlmFormValidation::test_required_fields_error | FAILED | A |
| 4 | Test4LlmFormValidation::test_missing_api_key_validation_error | FAILED | A |
| 5 | Test5HttpDebugPanel::test_debug_panel_opens_and_returns | FAILED | A |
| 6 | Test6SecondLlmProfile::test_add_secondary_profile | FAILED | A |
| 6 | Test6SecondLlmProfile::test_activate_secondary_profile | FAILED | A |
| 7 | Test7EditLlmProfile::test_edit_profile_persists | FAILED | A |
| 8 | Test8DeleteLlmProfile::test_delete_profile_via_dialog | FAILED | A |
| 9 | Test9GoalSettings::test_goal_page_set_and_save | FAILED | B |
| 10 | Test10RecognizeAndSave::test_recognize_from_gallery_and_save | FAILED | C |
| 11 | Test11HomeWithData::test_shows_meal_card | FAILED | D |
| 11 | Test11HomeWithData::test_nutrition_summary_present | PASSED | — |
| 12 | Test12Calendar::test_calendar_shows_kcal | FAILED | D |
| 13 | Test13MealEditor::test_open_editor_and_save | FAILED | D |
| 14 | Test14DateNavigation::test_prev_day_changes_date_label | SKIPPED | E |

## 3. 失败归因与证据链

### A 类：LLM 设置入口定位器不匹配（10 个用例，根因）

所有依赖 `_navigate_to_llm_settings()` 的用例均失败在同一个步骤：首页「设置」入口 15 秒内找不到。

- **测试脚本的定位方式**：`ACCESSIBILITY_ID "设置"` / `label CONTAINS "settings"` / `name == "settings_outlined"`（三选一）
- **App 实际导出的语义属性**：`IconButton(icon: Icon(Icons.settings_outlined, semanticLabel: '设置'), tooltip: '设置')` 在 XCUITest 树中导出为 `label='设置\n设置'`、`name='设置\n设置'`（tooltip 与 semanticLabel 合并为两行）
- **结论**：三个定位器全部无法命中真实元素（精确匹配 `设置` ≠ `设置\n设置`；英文 `settings` 不在 label 中；`name` 也不是 `settings_outlined`）。**这是测试脚本定位器与 App 语义导出不匹配，非 App 缺陷。**

证据：冷启动 App 后 dump 首页按钮树，设置按钮实际属性为 `{'label': '设置\n设置', 'name': '设置\n设置'}`。

### B 类：「设置目标」按钮子串误匹配（1 个用例：Test9）

- **现象**：`tap_text("设置目标")` 成功但页面未跳转，随后 `ACCESSIBILITY_ID "目标设置"` 等待超时。
- **机制**：`by_label_contains("设置目标")` 使用的谓词 `label CONTAINS "设置目标"` 会**子串误匹配**首页营养卡片中的「未设置目标」文本（"未设置目标"[1:5] == "设置目标"）。`find_element` 返回的是整张卡片容器（rect 370×172），点击落在容器空白区，实际按钮的 `onPressed`（路由 `/goals`，已确认路由注册无误）未被触发。
- **结论**：测试脚本定位器精度问题。用坐标点击真实按钮后页面可正常跳转（路由 `/goals` 与页面标题「目标设置」均已核实存在）。

### C 类：未处理「未配置 LLM 服务」弹窗（1 个用例：Test10）

- **现象**：长按 FAB 后找不到相册单元格（断言误报"相册为空"）。
- **机制**：当前 App 无任何 LLM 配置（因 A 类失败，LLM 配置从未建立），长按 FAB 后 App 按设计弹出「未配置 LLM 服务」提示对话框（含「取消 / 去设置」按钮），相册选择器未打开，故相册 `XCUIElementTypeCell` 数量为 0。
- **结论**：App 行为符合设计（未配置时引导用户去设置）；测试脚本未处理该前置状态对话框，且该失败受 A 类级联影响。

### D 类：级联失败（3 个用例：Test11::test_shows_meal_card、Test12、Test13）

- 因 Test10 未完成「识别 → 保存记录」，首页无餐卡数据、日历无 kcal 徽章、餐食编辑器无卡片可点。**属上游失败的级联，不代表对应页面功能本身有缺陷。**

### E 类：显式跳过（1 个用例：Test14）

- 前后日切换箭头（chevron）按钮未导出可用的 accessibility 属性，脚本按设计 `pytest.skip("Prev-day chevron not exposed via accessibility on this build")`。**属已知限制的显式跳过，非失败。**

## 4. 通过用例观察项

| 用例 | 结论 | 观察 |
| --- | --- | --- |
| Test1HomeInitial | 通过 | 首页正常加载，FAB「拍照识别热量」可见，证明 WDA 链路与 App 启动正常 |
| Test11::test_nutrition_summary_present | 通过（弱断言） | 断言仅检查「碳水/蛋白质/脂肪」标签存在；**无数据时首页也会渲染这些标签（0 g）**，该用例无法证明营养摘要功能的真实正确性，存在假阳性风险 |

## 5. 覆盖缺口与风险评估

1. **核心用户旅程未被有效验证**：配置 LLM → 拍照识别 → 保存记录 → 首页/日历展示这一端到端链路，因关键用例（A、C 类）失败从未真正执行。App 的 AI 识别、数据持久化、日历聚合等核心功能**本次没有得到任何有效验证**。
2. **数据状态被污染**：测试运行后 App 仍处于「无 LLM 配置、无餐食记录」状态（noReset 保留），但已安装的 App 与推送的测试图片均保留在模拟器中，可随时复测。
3. **失败归因明确**：15 个失败中，10 个源于单一根因（设置入口定位器），3 个为级联；未发现 App 功能缺陷的证据。

## 6. 修复方向建议（仅供参考，本次未执行任何修改）

- **A 类**：`_navigate_to_llm_settings` 增加 `by_label_contains("设置")` 或精确匹配 `label == "设置\n设置"` 的定位方式，避免依赖 `settings_outlined` 名称与英文标签。
- **B 类**：定位「设置目标」时使用精确匹配或限定 `type == "XCUIElementTypeButton"`，避免子串命中「未设置目标」容器文本。
- **C 类**：Test10 长按 FAB 后增加对「未配置 LLM 服务」对话框的处理分支（例如先完成 LLM 配置再执行识别流程）。
- **E 类**：如希望覆盖日期切换，需在 App 侧为 chevron 按钮补充语义标签（属 App 改动，需另行评估）。

## 7. 验证方法与局限

- **方法**：完整运行 pytest（550.93s）；对失败用例进行逐项根因调查——dump 首页按钮树验证 A 类；坐标点击 + 完整元素树 dump 验证 B 类；长按 FAB 后 dump 验证 C 类；阅读 `lib/app/router.dart`、`home_page.dart`、`goal_settings_page.dart` 源码交叉确认。
- **局限**：B 类验证基于模拟器当前数据状态（无目标配置），若目标已配置，「设置目标」按钮不渲染，相关验证路径会变化；本次调查未改动任何代码，所有诊断脚本均置于 `/tmp`，未落盘到项目。
