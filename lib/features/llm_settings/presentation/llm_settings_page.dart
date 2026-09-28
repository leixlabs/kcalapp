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
      return Scaffold(appBar: AppBar(title: const Text('LLM 设置')), body: const Center(child: CircularProgressIndicator()));
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
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('添加新配置'),
                onTap: () => _showProfileForm(context),
              ),
            );
          }
          if (index == 1) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: Colors.deepOrange),
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
                    Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text('暂无配置，请添加 LLM 服务', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                    Text('添加后即可使用拍照识别功能', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final profile = _profiles[index - 3];
          return Card(
            child: ListTile(
              leading: Icon(
                profile.isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                color: profile.isActive ? Colors.green : theme.colorScheme.outline,
              ),
              title: Text(profile.displayName),
              subtitle: Text('${profile.model}\n${profile.baseUrl}', maxLines: 2, overflow: TextOverflow.ellipsis),
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
    final timeoutCtrl = TextEditingController(text: (profile?.timeoutSeconds ?? 30).toString());
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
        isEditing: isEditing,
        existing: profile,
        onSave: () => _saveProfile(context, profile, nameCtrl, urlCtrl, modelCtrl, keyCtrl, timeoutCtrl),
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
  ) async {
    if (name.text.trim().isEmpty || url.text.trim().isEmpty || model.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写所有必填字段')));
      return;
    }

    final timeoutVal = int.tryParse(timeout.text) ?? 30;
    final dao = ref.read(llmProfileDaoProvider);
    final secureStore = ref.read(secureStoreProvider);

    if (existing != null) {
      await dao.updateProfile(LlmProfile(
        id: existing.id,
        displayName: name.text.trim(),
        baseUrl: url.text.trim(),
        model: model.text.trim(),
        timeoutSeconds: timeoutVal,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
      ));
      if (key.text.isNotEmpty) {
        await secureStore.write('${existing.id}', key.text);
      }
    } else {
      final id = await dao.insertProfile(LlmProfile(
        displayName: name.text.trim(),
        baseUrl: url.text.trim(),
        model: model.text.trim(),
        timeoutSeconds: timeoutVal,
        isActive: true,
        createdAt: DateTime.now(),
      ));
      if (key.text.isNotEmpty) {
        await secureStore.write('$id', key.text);
      }
    }

    if (mounted) {
      Navigator.pop(context);
      _loadProfiles();
    }
  }

  void _confirmDelete(LlmProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定删除「${profile.displayName}」吗？API Key 也会同时清除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final dao = ref.read(llmProfileDaoProvider);
              final secureStore = ref.read(secureStoreProvider);
              await dao.deleteProfile(profile.id!);
              await secureStore.delete('${profile.id}');
              if (mounted) {
                Navigator.pop(context);
                _loadProfiles();
              }
            },
            child: const Text('删除'),
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
  final bool isEditing;
  final LlmProfile? existing;
  final Future<void> Function() onSave;

  const _ProfileForm({
    required this.ref,
    required this.nameCtrl,
    required this.urlCtrl,
    required this.modelCtrl,
    required this.keyCtrl,
    required this.timeoutCtrl,
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

      if (name.text.trim().isEmpty || url.text.trim().isEmpty || model.text.trim().isEmpty) {
        _showResult('请先填写名称、Base URL 和模型名', success: false);
        return;
      }

      final apiKey = key.text.isNotEmpty
          ? key.text
          : (profile?.id != null ? await ref.read(secureStoreProvider).read('${profile!.id}') : null);

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
      );

      try {
        await ref.read(llmAdapterProvider).testConnection(
              profile: testProfile,
              apiKey: apiKey,
            );
        _showResult('连通正常', success: true);
      } on LlmConnectionError catch (e) {
        _showResult(_connectionErrorMessage(e), success: false);
      } catch (e) {
        _showResult('未知错误：$e', success: false);
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
        return '未知错误，请打开 HTTP 调试面板查看详情';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.isEditing ? '编辑配置' : '添加配置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: widget.nameCtrl,
            decoration: const InputDecoration(labelText: '服务名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.urlCtrl,
            decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.modelCtrl,
            decoration: const InputDecoration(labelText: '模型名', hintText: 'gpt-4o'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.keyCtrl,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: widget.isEditing ? '留空则不更新' : 'sk-...',
              prefixIcon: const Icon(Icons.key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.timeoutCtrl,
            decoration: const InputDecoration(labelText: '超时（秒）'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          if (_validationMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _validationSuccess ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _validationSuccess ? Colors.green.shade300 : Colors.red.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _validationSuccess ? Icons.check_circle : Icons.error_outline,
                    size: 18,
                    color: _validationSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationMessage!,
                      style: TextStyle(
                        color: _validationSuccess ? Colors.green.shade900 : Colors.red.shade900,
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
                    onPressed: _validating ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _validating ? null : () => widget.onSave(),
                    child: Text(widget.isEditing ? '更新' : '保存'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
