# UI 优化建议（简洁 & 去重方向）

## 1. 提炼重复的「营养素摘要」组件

**涉及文件：**
- `lib/features/diary/presentation/meal_editor/meal_editor_page.dart` — `_buildNutritionSummary`
- `lib/features/food_recognition/presentation/recognition_result_page.dart` — 三大营养素 Container

两处结构几乎一样：同一个 `primaryContainer` 底色、圆角 16、`spaceAround` 排列。

**建议：** 提炼为共享组件 `MacrosSummaryRow`，接受 `Nutrition` 对象和 `showKcal` 参数，两个页面共用。

```dart
// lib/core/widgets/macros_summary_row.dart
class MacrosSummaryRow extends StatelessWidget {
  final Nutrition nutrition;
  final bool showKcal;

  const MacrosSummaryRow({super.key, required this.nutrition, this.showKcal = false});
}
```

---

## 2. 提炼重复的底部保存栏

**涉及文件：**
- `lib/features/diary/presentation/meal_editor/meal_editor_page.dart` — `_buildBottomBar`
- `lib/features/food_recognition/presentation/recognition_result_page.dart` — `_buildBottomBar`
- `lib/features/goals/presentation/goal_settings_page.dart` — `bottomNavigationBar`

三处都是 `SafeArea > Padding(all: 16) > FilledButton`，只有按钮文案和可选的左侧文本不同。

**建议：** 提炼为 `BottomSaveBar`：

```dart
// lib/core/widgets/bottom_save_bar.dart
class BottomSaveBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading; // 用于 MealEditorPage 显示「合计 xxx kcal」

  const BottomSaveBar({super.key, required this.label, this.onPressed, this.leading});
}
```

---

## 3. 统一「提示信息卡」

**涉及文件：**
- `lib/features/goals/presentation/goal_settings_page.dart` — 目标生效说明卡
- `lib/features/data_transfer/presentation/export_page.dart` — 安全说明卡
- `lib/features/data_transfer/presentation/privacy_page.dart` — 各隐私说明条目
- `lib/features/food_recognition/presentation/recognition_result_page.dart` — AI 备注条

这类 `Card > Row > Icon + Text` 说明组件结构完全一致，只有颜色和图标不同。

**建议：** 提炼为 `InfoBanner`：

```dart
// lib/core/widgets/info_banner.dart
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color; // 默认使用 colorScheme.outline

  const InfoBanner({super.key, required this.icon, required this.text, this.color});
}
```

---

## 4. 消除硬编码颜色

项目已有 `AppColors` 语义色系和完善的 M3 `colorScheme`，但以下几处偏离：

| 位置 | 当前写法 | 建议替换为 |
|---|---|---|
| `recognition_result_page.dart` 保存按钮背景 | `Colors.black` | `colorScheme.primary`（或移除自定义 style） |
| `llm_settings_page.dart` 添加配置图标 | `Colors.green` | `colorScheme.primary` |
| `llm_settings_page.dart` 调试面板图标 | `Colors.deepOrange` | `colorScheme.secondary` 或 `AppColors` 新增语义色 |
| `llm_settings_page.dart` `_ProfileForm` 验证结果框 | `Colors.green.shade50 / .shade700` | `colorScheme.primaryContainer / primary` |
| `home_page.dart` 空状态文字 | `Colors.grey.shade300~500` | `colorScheme.outlineVariant / outline` |
| `nutrition_progress_card.dart` 分隔线 | `Colors.grey.withOpacity(0.15)` | `colorScheme.outlineVariant.withOpacity(0.3)` |

---

## 5. 语言一致性

`recognition_result_page.dart` 和 `llm_settings_page.dart` 中混有英文 label，与其余页面的中文产生割裂感。

| 文件 | 当前英文 | 建议中文 |
|---|---|---|
| `recognition_result_page.dart` | `'meal name'`（TextField label） | `'餐名'` |
| `recognition_result_page.dart` | `'kcal must be > 0'` | `'热量必须大于 0'` |
| `recognition_result_page.dart` | `'meal name required'` | `'请输入餐名'` |
| `llm_settings_page.dart` | `'delete profile'`（弹窗标题） | `'删除配置'` |
| `llm_settings_page.dart` | `'delete'`、`'cancel'`（弹窗按钮） | `'删除'`、`'取消'` |
| `export_page.dart` | `'export failed: $e'` | `'导出失败：$e'` |
| `export_page.dart` | `'calory export'`（分享文案） | `'饮食数据导出'` |

---

## 6. `LlmSettingsPage` 空状态复用已有组件

**涉及文件：** `lib/features/llm_settings/presentation/llm_settings_page.dart`

当 `_profiles` 为空时，目前是手写的 `Column(icon, text, text)`，而项目在 `core/widgets/states.dart` 已有 `EmptyState` 组件，直接复用即可：

```dart
// 当前
Column(
  children: [
    Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
    SizedBox(height: 8),
    Text('暂无配置，请添加 LLM 服务', ...),
    Text('添加后即可使用拍照识别功能', ...),
  ],
)

// 建议
EmptyState(
  icon: Icons.cloud_off,
  title: '暂无配置',
  subtitle: '请添加 LLM 服务后即可使用拍照识别功能',
)
```

---

## 7. 间距常量化（可选）

项目中 `SizedBox(height: 8/12/16/20/24/32)` 散落各处，无语义约定，偶有 20、28 等魔数。

**建议：** 在 `lib/app/theme.dart` 或新建 `lib/app/spacing.dart` 定义常量：

```dart
class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
```

---

## 优先级建议

| 优先级 | 项目 | 原因 |
|---|---|---|
| 🔴 高 | **4 硬编码颜色** | 影响深色模式适配，`Colors.black` 在深色模式下直接显示异常 |
| 🔴 高 | **5 语言一致性** | 用户体验直接可见，改动成本低 |
| 🟡 中 | **6 空状态复用** | 5 分钟内可完成，减少冗余代码 |
| 🟡 中 | **1 营养素摘要组件** | 减少两处几乎相同的 UI 代码 |
| 🟡 中 | **2 底部保存栏** | 减少三处重复结构 |
| 🟢 低 | **3 提示信息卡** | 收益较小，InfoBanner 可能过度抽象 |
| 🟢 低 | **7 间距常量** | 维护性收益，不影响运行时行为 |
