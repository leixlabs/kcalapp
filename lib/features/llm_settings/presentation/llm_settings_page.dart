import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/llm/llm_adapter.dart';
import '../domain/llm_profile.dart';
import '../../../app/providers.dart';

class LlmSettingsPage extends ConsumerStatefulWidget {
  const LlmSettingsPage({super.key});

  @override
  ConsumerState<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends ConsumerState<LlmSettingsPage> {
  List<LlmProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() async {
    final dao = ref.read(llmProfileDaoProvider);
    final profiles = await dao.getAll();
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('LLM 设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Layout:
    //   index 0: "添加新配置" 卡片
    //   index 1: "HTTP 调试面板" 卡片
    //   index 2: 空状态提示（仅在 _profiles 为空时显示，否则 SizedBox.shrink）
    //   index >= 3: profile 列表项
    return Scaffold(
      appBar: AppBar(title: const Text('LLM 设置')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profiles.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('添加新配置'),
                onTap: () => _showProfileForm(context),
              ),
            );
          }
          if (index == 1) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.bug_report_outlined,
                  color: Colors.deepOrange,
                ),
                title: const Text('HTTP 调试面板'),
                subtitle: const Text('查看 LLM 请求 / 响应（alice）'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ref.read(aliceProvider).showInspector(),
              ),
            );
          }
          if (index == 2) {
            if (_profiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无配置，请添加 LLM 服务',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      '添加后即可使用拍照识别功能',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final profile = _profiles[index - 3];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: GestureDetector(
                onTap: () async {
                  if (!profile.isActive) {
                    final dao = ref.read(llmProfileDaoProvider);
                    await dao.activateProfile(profile.id!);
                    if (mounted) _loadProfiles();
                  }
                },
                child: Icon(
                  profile.isActive
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: profile.isActive
                      ? Colors.green
                      : theme.colorScheme.outline,
                ),
              ),
              title: Text(profile.displayName),
              subtitle: Text(
                '${profile.model}\n${profile.baseUrl}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              onTap: () => _showProfileForm(context, profile: profile),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(profile),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProfileForm(BuildContext context, {LlmProfile? profile}) {
    final nameCtrl = TextEditingController(text: profile?.displayName ?? '');
    final urlCtrl = TextEditingController(text: profile?.baseUrl ?? '');
    final modelCtrl = TextEditingController(text: profile?.model ?? '');
    final keyCtrl = TextEditingController();
    final timeoutCtrl = TextEditingController(
      text: (profile?.timeoutSeconds ?? 30).toString(),
    );
    final isEditing = profile != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ProfileForm(
        ref: ref,
        nameCtrl: nameCtrl,
        urlCtrl: urlCtrl,
        modelCtrl: modelCtrl,
        keyCtrl: keyCtrl,
        timeoutCtrl: timeoutCtrl,
        initialResponseFormat:
            profile?.responseFormat ?? LlmResponseFormat.jsonSchema,
        isEditing: isEditing,
        existing: profile,
        onSave: (responseFormat) => _saveProfile(
          context,
          profile,
          nameCtrl,
          urlCtrl,
          modelCtrl,
          keyCtrl,
          timeoutCtrl,
          responseFormat,
        ),
      ),
    );
  }

  Future<void> _saveProfile(
    BuildContext context,
    LlmProfile? existing,
    TextEditingController name,
    TextEditingController url,
    TextEditingController model,
    TextEditingController key,
    TextEditingController timeout,
    LlmResponseFormat responseFormat,
  ) async {
    if (name.text.trim().isEmpty ||
        url.text.trim().isEmpty ||
        model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写所有必填字段')));
      return;
    }

    final timeoutVal = int.tryParse(timeout.text) ?? 30;
    final dao = ref.read(llmProfileDaoProvider);
    final secureStore = ref.read(secureStoreProvider);

    if (existing != null) {
      await dao.updateProfile(
        LlmProfile(
          id: existing.id,
          displayName: name.text.trim(),
          baseUrl: url.text.trim(),
          model: model.text.trim(),
          timeoutSeconds: timeoutVal,
          isActive: existing.isActive,
          createdAt: existing.createdAt,
          responseFormat: responseFormat,
        ),
      );
      if (key.text.isNotEmpty) {
        await secureStore.write('${existing.id}', key.text);
      }
    } else {
      final id = await dao.insertProfile(
        LlmProfile(
          displayName: name.text.trim(),
          baseUrl: url.text.trim(),
          model: model.text.trim(),
          timeoutSeconds: timeoutVal,
          isActive: true,
          createdAt: DateTime.now(),
          responseFormat: responseFormat,
        ),
      );
      if (key.text.isNotEmpty) {
        await secureStore.write('$id', key.text);
      }
    }

    if (mounted) {
      Navigator.of(this.context).pop();
      _loadProfiles();
    }
  }

  void _confirmDelete(LlmProfile profile) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('delete profile'),
        content: Text(
          'delete profile "${profile.displayName}"? API key will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () async {
              final dao = ref.read(llmProfileDaoProvider);
              final secureStore = ref.read(secureStoreProvider);
              final nav = Navigator.of(dialogCtx);
              await dao.deleteProfile(profile.id!);
              await secureStore.delete('${profile.id}');
              if (mounted) {
                nav.pop();
                _loadProfiles();
              }
            },
            child: const Text('delete'),
          ),
        ],
      ),
    );
  }
}

/// 配置表单：独立 StatefulWidget，自行管理"验证中"loading 状态。
/// 复用父 widget 传入的 ref，因为 bottom sheet 在父 widget 树内能拿到同一个 ProviderScope。
class _ProfileForm extends StatefulWidget {
  final WidgetRef ref;
  final TextEditingController nameCtrl;
  final TextEditingController urlCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController keyCtrl;
  final TextEditingController timeoutCtrl;
  final LlmResponseFormat initialResponseFormat;
  final bool isEditing;
  final LlmProfile? existing;
  final Future<void> Function(LlmResponseFormat responseFormat) onSave;

  const _ProfileForm({
    required this.ref,
    required this.nameCtrl,
    required this.urlCtrl,
    required this.modelCtrl,
    required this.keyCtrl,
    required this.timeoutCtrl,
    required this.initialResponseFormat,
    required this.isEditing,
    required this.existing,
    required this.onSave,
  });

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  bool _validating = false;
  String? _validationMessage;
  bool _validationSuccess = false;
  late LlmResponseFormat _responseFormat;

  @override
  void initState() {
    super.initState();
    _responseFormat = widget.initialResponseFormat;
  }

  Future<void> _handleValidate() async {
    if (_validating) return;
    setState(() {
      _validating = true;
      _validationMessage = null;
    });
    try {
      final ref = widget.ref;
      final name = widget.nameCtrl;
      final url = widget.urlCtrl;
      final model = widget.modelCtrl;
      final key = widget.keyCtrl;
      final timeout = widget.timeoutCtrl;
      final profile = widget.existing;

      if (name.text.trim().isEmpty ||
          url.text.trim().isEmpty ||
          model.text.trim().isEmpty) {
        _showResult('请先填写名称、Base URL 和模型名', success: false);
        return;
      }

      final apiKey = key.text.isNotEmpty
          ? key.text
          : (profile?.id != null
                ? await ref.read(secureStoreProvider).read('${profile!.id}')
                : null);

      if (apiKey == null || apiKey.isEmpty) {
        _showResult('请填写 API Key', success: false);
        return;
      }

      final timeoutVal = int.tryParse(timeout.text) ?? 30;
      final testProfile = LlmProfile(
        id: profile?.id,
        displayName: name.text.trim(),
        baseUrl: url.text.trim(),
        model: model.text.trim(),
        timeoutSeconds: timeoutVal,
        isActive: profile?.isActive ?? false,
        createdAt: profile?.createdAt ?? DateTime.now(),
        responseFormat: _responseFormat,
      );

      try {
        await ref
            .read(llmAdapterProvider)
            .testConnection(profile: testProfile, apiKey: apiKey);
        _showResult('连通正常', success: true);
      } on LlmConnectionFailure catch (failure) {
        final message = _connectionErrorMessage(failure.error);
        final detail = failure.detail;
        _showResult(
          detail == null ? '验证失败：$message' : '验证失败：$message（$detail）',
          success: false,
        );
      } on LlmConnectionError catch (e) {
        _showResult('验证失败：${_connectionErrorMessage(e)}', success: false);
      } catch (e) {
        _showResult('验证失败，请检查配置、网络或服务响应', success: false);
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  void _showResult(String msg, {required bool success}) {
    if (!mounted) return;
    setState(() {
      _validationMessage = msg;
      _validationSuccess = success;
    });
  }

  String _connectionErrorMessage(LlmConnectionError e) {
    switch (e) {
      case LlmConnectionError.timeout:
        return '连接超时，请检查 Base URL 或网络';
      case LlmConnectionError.unauthorized:
        return '鉴权失败：API Key 无效或权限不足';
      case LlmConnectionError.rateLimited:
        return '请求过于频繁，被限流';
      case LlmConnectionError.serverError:
        return 'LLM 服务端错误（5xx）';
      case LlmConnectionError.parseError:
        return '响应解析失败';
      case LlmConnectionError.unknown:
        return '验证失败，请检查 Base URL、API Key 和服务状态';
      case LlmConnectionError.invalidResponse:
        return '服务未返回有效内容，请检查模型和接口是否兼容';
      case LlmConnectionError.responseFormatUnsupported:
        return switch (_responseFormat) {
          LlmResponseFormat.jsonSchema =>
            '服务不支持 JSON Schema，请改用 JSON Mode 或关闭结构化输出',
          LlmResponseFormat.jsonMode => '服务不支持 JSON Mode，请关闭结构化输出或更换模型',
          LlmResponseFormat.none => '服务拒绝了请求，请检查模型配置',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? '编辑配置' : '添加配置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.nameCtrl,
              decoration: const InputDecoration(labelText: '服务名称'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.example.com/v1',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.modelCtrl,
              decoration: const InputDecoration(
                labelText: '模型名',
                hintText: 'gpt-4o',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.keyCtrl,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: widget.isEditing ? '留空则不更新' : 'sk-...',
                prefixIcon: const Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.timeoutCtrl,
              decoration: const InputDecoration(labelText: '超时（秒）'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<LlmResponseFormat>(
              initialValue: _responseFormat,
              decoration: const InputDecoration(
                labelText: '结构化输出格式',
                prefixIcon: Icon(Icons.data_object),
              ),
              items: LlmResponseFormat.values
                  .map(
                    (format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.label),
                    ),
                  )
                  .toList(),
              onChanged: _validating
                  ? null
                  : (format) {
                      if (format != null) {
                        setState(() => _responseFormat = format);
                      }
                    },
            ),
            const SizedBox(height: 8),
            Text(
              switch (_responseFormat) {
                LlmResponseFormat.none =>
                  '不发送 response_format，模型可能返回非 JSON 文本。',
                LlmResponseFormat.jsonMode => '使用 response_format: json_object。适用于支持 JSON Mode 但不支持 JSON Schema 的服务。',
                LlmResponseFormat.jsonSchema =>
                  '使用 response_format: json_schema，按餐食识别结构约束输出。',
              },
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            if (_validationMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _validationSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _validationSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _validationSuccess
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 18,
                      color: _validationSuccess
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationMessage!,
                        style: TextStyle(
                          color: _validationSuccess
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _validating ? null : _handleValidate,
                  icon: _validating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_protected_setup),
                  label: const Text('验证连通性'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _validating
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _validating
                          ? null
                          : () => widget.onSave(_responseFormat),
                      child: Text(widget.isEditing ? '更新' : '保存'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
