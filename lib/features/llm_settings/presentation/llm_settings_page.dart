import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/llm/llm_adapter.dart';
import '../../../app/app_language.dart';
import '../domain/llm_profile.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/l10n.dart';
import '../../../data/database/app_settings_dao.dart';

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
    final l10n = context.l10n;
    final language = ref.watch(appLanguageProvider);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.llmSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.llmSettingsTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profiles.length + 5,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.appLanguageTitle),
                trailing: DropdownButton<AppLanguage>(
                  value: language,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.system,
                      child: Text(l10n.appLanguageSystem),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.chinese,
                      child: Text(l10n.appLanguageChinese),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Text(l10n.appLanguageEnglish),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) _changeLanguage(value);
                  },
                ),
              ),
            );
          }
          if (index == 1) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: Text(l10n.llmSettingsAddProfile),
                onTap: () => _showProfileForm(context),
              ),
            );
          }
          if (index == 2) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.bug_report_outlined,
                  color: Colors.deepOrange,
                ),
                title: Text(l10n.llmSettingsHttpDebug),
                subtitle: Text(l10n.llmSettingsHttpDebugSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ref.read(aliceProvider).showInspector(),
              ),
            );
          }
          if (index == 3) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.wifi_tethering),
                title: Text(l10n.llmSettingsLanApi),
                subtitle: Text(l10n.llmSettingsLanApiSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/lan-api'),
              ),
            );
          }
          if (index == 4) {
            if (_profiles.isEmpty) {
              return EmptyState(
                icon: Icons.cloud_off,
                title: l10n.llmSettingsEmptyTitle,
                subtitle: l10n.llmSettingsEmptySubtitle,
              );
            }
            return const SizedBox.shrink();
          }
          final profile = _profiles[index - 5];
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

  Future<void> _changeLanguage(AppLanguage language) async {
    try {
      await AppSettingsDao(ref.read(databaseProvider))
          .setValue('app_language', language.storageValue);
      if (!mounted) return;
      Intl.defaultLocale = language
          .resolveLocale(PlatformDispatcher.instance.locale)
          .languageCode;
      ref.read(appLanguageProvider.notifier).state = language;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.appLanguageSaveFailed('$error'))),
      );
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.llmSettingsFillAll)));
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.llmSettingsDeleteTitle),
        content: Text(l10n.llmSettingsDeleteConfirm(profile.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.actionCancel),
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
            child: Text(l10n.actionDelete),
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
    final l10n = context.l10n;
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
        _showResult(l10n.llmSettingsFillNameUrlModel, success: false);
        return;
      }

      final apiKey = key.text.isNotEmpty
          ? key.text
          : (profile?.id != null
                ? await ref.read(secureStoreProvider).read('${profile!.id}')
                : null);

      if (apiKey == null || apiKey.isEmpty) {
        _showResult(l10n.llmSettingsFillApiKey, success: false);
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
        _showResult(l10n.llmSettingsConnectionOk, success: true);
      } on LlmConnectionFailure catch (failure) {
        final message = _connectionErrorMessage(l10n, failure.error);
        final detail = failure.detail;
        _showResult(
          detail == null
              ? l10n.llmSettingsValidateFailed(message)
              : l10n.llmSettingsValidateFailedDetail(message, detail),
          success: false,
        );
      } on LlmConnectionError catch (e) {
        _showResult(
          l10n.llmSettingsValidateFailed(_connectionErrorMessage(l10n, e)),
          success: false,
        );
      } catch (e) {
        _showResult(l10n.llmSettingsValidateFailedGeneric, success: false);
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

  String _connectionErrorMessage(AppLocalizations l10n, LlmConnectionError e) {
    switch (e) {
      case LlmConnectionError.timeout:
        return l10n.llmErrorTimeout;
      case LlmConnectionError.unauthorized:
        return l10n.llmErrorUnauthorized;
      case LlmConnectionError.rateLimited:
        return l10n.llmErrorRateLimited;
      case LlmConnectionError.serverError:
        return l10n.llmErrorServer;
      case LlmConnectionError.parseError:
        return l10n.llmErrorParse;
      case LlmConnectionError.unknown:
        return l10n.llmErrorUnknown;
      case LlmConnectionError.invalidResponse:
        return l10n.llmErrorInvalidResponse;
      case LlmConnectionError.responseFormatUnsupported:
        return switch (_responseFormat) {
          LlmResponseFormat.jsonSchema => l10n.llmErrorFormatUnsupportedSchema,
          LlmResponseFormat.jsonMode => l10n.llmErrorFormatUnsupportedJsonMode,
          LlmResponseFormat.none => l10n.llmErrorFormatUnsupportedNone,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              widget.isEditing
                  ? l10n.llmSettingsEditProfile
                  : l10n.llmSettingsAddProfileTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.llmSettingsServiceName,
              ),
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
              decoration: InputDecoration(
                labelText: l10n.llmSettingsModelName,
                hintText: 'gpt-4o',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.keyCtrl,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: widget.isEditing
                    ? l10n.llmSettingsLeaveBlank
                    : l10n.llmSettingsKeyHint,
                prefixIcon: const Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.timeoutCtrl,
              decoration: InputDecoration(labelText: l10n.llmSettingsTimeout),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<LlmResponseFormat>(
              initialValue: _responseFormat,
              decoration: InputDecoration(
                labelText: l10n.llmSettingsResponseFormat,
                prefixIcon: const Icon(Icons.data_object),
              ),
              items: LlmResponseFormat.values
                  .map(
                    (format) => DropdownMenuItem(
                      value: format,
                      child: Text(responseFormatLabel(l10n, format)),
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
                LlmResponseFormat.none => l10n.llmSettingsFormatNone,
                LlmResponseFormat.jsonMode => l10n.llmSettingsFormatJsonMode,
                LlmResponseFormat.jsonSchema =>
                  l10n.llmSettingsFormatJsonSchema,
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
                  label: Text(l10n.llmSettingsValidateConnection),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _validating
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _validating
                          ? null
                          : () => widget.onSave(_responseFormat),
                      child: Text(
                        widget.isEditing ? l10n.actionUpdate : l10n.actionSave,
                      ),
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
