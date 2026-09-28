# LLM 配置调试面板 + 连通性验证按钮

## Context

当前 `lib/features/llm_settings/presentation/llm_settings_page.dart` 的 LLM 配置表单只有"取消/保存"两个按钮，配置保存后只能靠拍照识别流程间接验证 LLM 是否可用——一旦配置错误，要在 UI 里调试需要反复试错。
同时项目里 [llm_adapter.dart#L56-L84](file:///Users/lei/dev/projects/2609-kcalapp/lib/data/llm/llm_adapter.dart) 已经实现了 `testConnection()` 方法（带 `LlmConnectionError` 错误分类），但没有 UI 入口调用它。

用户希望：
1. 在 LLM 配置表单里加一个"验证连通性"按钮，保存前先用一次最简请求验证配置是否生效。
2. 加一个 request/response 调试面板，方便排查 LLM 调用问题。**采用成熟插件 + 最佳实践**：Dio + Flutter 圈内 HTTP 调试的事实标准是 `alice`（1.10.0），自带列表/详情/JSON 树状查看/统计/搜索/时间线/HAR 导出/暗色模式，无需自建 UI，集成只需一个 Dio Interceptor。

## 实施方案

### 1. 引入 alice 依赖
[pubspec.yaml](file:///Users/lei/dev/projects/2609-kcalapp/pubspec.yaml) `dependencies:` 段添加：
```yaml
  # HTTP debug inspector
  alice: ^1.10.0
  alice_dio: ^1.3.1
```
执行 `flutter pub get`。

### 2. 注入 Alice 单例（Riverpod Provider）
[lib/app/providers.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/app/providers.dart) 添加：
```dart
import 'package:alice/alice.dart';

final aliceProvider = Provider<Alice>((ref) {
  return Alice(showNotification: false, showInspectorOnShake: false);
});
```
关掉通知和摇晃触发——避免 LLM 频繁调用时打扰用户；通过显式入口打开。

### 3. 给 LlmAdapter 挂上 Alice Interceptor
[lib/data/llm/llm_adapter.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/data/llm/llm_adapter.dart)：
- 构造函数接收可选的 `Alice?` 参数。
- `LlmAdapter()` 内部 `_dio.interceptors.add(AliceDioAdapter().getInterceptor(alice))`（仅在 alice 非 null 时）。

更新 [providers.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/app/providers.dart) 的 `llmAdapterProvider`：
```dart
final llmAdapterProvider = Provider<LlmAdapter>((ref) {
  return LlmAdapter(alice: ref.watch(aliceProvider));
});
```
这样 `recognizeFood` 和 `testConnection` 的请求/响应都会被 alice 记录，调试面板里能看到完整 payload、状态码、耗时、错误。

### 4. 给 MaterialApp.router 接上 Alice 的 Navigator Key
[lib/app/app.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/app/app.dart)：在 `MaterialApp.router` 用 `builder` 包一层 `Navigator`，把 alice 的 `getNavigatorKey()` 挂在外层 navigator 上——alice 的 inspector UI 推到这个外层 navigator，与 go_router 的内部导航互不干扰：
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(routerProvider);
  final alice = ref.watch(aliceProvider);
  return MaterialApp.router(
    title: '食刻',
    debugShowCheckedModeBanner: false,
    theme: lightTheme,
    darkTheme: darkTheme,
    routerConfig: router,
    builder: (context, child) => Navigator(
      key: alice.getNavigatorKey(),
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child!),
    ),
  );
}
```

### 5. 在 LLM 设置页加入"调试面板"入口
[llm_settings_page.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/features/llm_settings/presentation/llm_settings_page.dart) ListView 在"添加新配置"卡片之后插入一个新卡片：
```dart
Card(
  child: ListTile(
    leading: const Icon(Icons.bug_report_outlined, color: Colors.deepOrange),
    title: const Text('HTTP 调试面板'),
    subtitle: const Text('查看 LLM 请求/响应（alice）'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => ref.read(aliceProvider).showInspector(),
  ),
),
```
itemCount 由 `_profiles.length + 2` 调整为 `_profiles.length + 3`（插入索引 1 的位置后移原 index==1 的空状态判断到 index==2，原 index>=2 的 profile 取 `_profiles[index - 3]`）。

### 6. 在配置表单加入"验证连通性"按钮
[llm_settings_page.dart](file:///Users/lei/dev/projects/2609-kcalapp/lib/features/llm_settings/presentation/llm_settings_page.dart) `_showProfileForm` 底部的 Row（[L145-L155](file:///Users/lei/dev/projects/2609-kcalapp/lib/features/llm_settings/presentation/llm_settings_page.dart#L145-L155)）改成三按钮布局：
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    FilledButton.tonalIcon(
      onPressed: _validating ? null : () => _validateConnection(...),
      icon: _validating
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.wifi_protected_setup),
      label: const Text('验证'),
    ),
    Row(
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        const SizedBox(width: 8),
        FilledButton(onPressed: ..., child: Text(isEditing ? '更新' : '保存')),
      ],
    ),
  ],
),
```

新增 State 字段：`bool _validating = false;`

新增方法 `_validateConnection`：
1. 校验表单必填字段（name/url/model）——空就 SnackBar 提示。
2. 解析 timeout（默认 15 秒，比保存时用的 30 秒更短以快速反馈）。
3. 拿 API Key：表单 keyCtrl 非空则用之；编辑场景下若 keyCtrl 为空，从 `secureStoreProvider` 读 `existing.id` 对应的 key。
4. 构造一个临时的 `LlmProfile`（不持久化，仅用于 testConnection）：
   ```dart
   LlmProfile(
     id: existing?.id,
     displayName: name.text.trim(),
     baseUrl: urlCtrl.text.trim(),
     model: modelCtrl.text.trim(),
     timeoutSeconds: timeoutVal,
     isActive: existing?.isActive ?? false,
     createdAt: existing?.createdAt ?? DateTime.now(),
   )
   ```
5. 调用 `ref.read(llmAdapterProvider).testConnection(profile: ..., apiKey: ...)`，set `_validating = true` 前后切换按钮状态。
6. 结果展示（mounted 后 SnackBar）：
   - 成功：`✓ 连通正常`（绿色 SnackBar）
   - `LlmConnectionError.timeout` → "连接超时，请检查 Base URL 或网络"
   - `unauthorized` → "鉴权失败：API Key 无效或权限不足"
   - `rateLimited` → "请求过于频繁，被限流"
   - `serverError` → "LLM 服务端错误（5xx）"
   - `unknown` → "未知错误，请打开调试面板查看详情"
   - `parseError` → "响应解析失败"
7. 异常通过 `try/catch` 捕获 `LlmConnectionError`，其他异常 catch 后 SnackBar 显示 `$e`。

调用走的是 `llmAdapterProvider` 实例，alice interceptor 会同步记录这次请求，验证失败可直接跳调试面板看响应。

## 验证步骤

1. `flutter pub get` 拉取 alice + alice_dio。
2. `flutter run` 起应用。
3. **验证连通性按钮**：
   - 进入设置 → 添加新配置：填一个真实可用的 OpenAI 兼容端点，点"验证"，期望绿色"连通正常"。
   - 故意把 API Key 改错：点"验证"，期望 SnackBar 提示"鉴权失败"。
   - 故意把 Base URL 改成 `https://invalid.invalid/v1`：点"验证"，期望超时/未知错误。
4. **调试面板**：
   - 设置页点"HTTP 调试面板"，期望进入 alice 列表页，能看到刚才的验证请求。
   - 进入列表项 → Request/Response/Headers/Body 各 tab 正常。
   - 在主页点"拍照识别"，回到调试面板，期望看到 `/chat/completions` 的完整请求与响应。
5. 切到暗色模式确认 alice 主题正常。
