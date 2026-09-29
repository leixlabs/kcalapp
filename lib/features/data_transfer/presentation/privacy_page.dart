import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../diary/application/diary_providers.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('隐私与数据')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPrivacyNotice(theme),
          const SizedBox(height: 16),
          _buildSectionTitle(theme, '数据管理'),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            ref,
            theme,
            icon: Icons.restaurant_menu,
            title: '清除饮食数据',
            subtitle: '删除所有餐食记录和食材',
            confirmMessage: '将删除所有餐食记录和关联的食材数据。此操作不可撤销。',
            onConfirm: () => _clearMeals(ref),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            ref,
            theme,
            icon: Icons.cloud_outlined,
            title: '清除 LLM 配置',
            subtitle: '删除所有 LLM 服务配置和 API Key',
            confirmMessage: '将删除所有 LLM 服务配置及其 API Key。此操作不可撤销。',
            onConfirm: () => _clearLlmConfigs(ref),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            ref,
            theme,
            icon: Icons.delete_forever,
            title: '清除全部本地数据',
            subtitle: '删除饮食记录、LLM 配置和所有本地文件',
            confirmMessage:
                '将删除所有本地数据：餐食记录、LLM 配置、API Key 和图片文件。清除后 App 将恢复至首次使用状态。',
            onConfirm: () => _clearAll(ref),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '隐私说明',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem(
              theme,
              Icons.person_off,
              '无账号、无自有云端',
              'App 不建立用户账号，不运营自有业务服务器。',
            ),
            _buildPrivacyItem(
              theme,
              Icons.photo_camera,
              '图片直发 LLM',
              '拍照识别时，图片会发送至你选择配置的 LLM 服务。App 无法代表该服务商的保留或训练政策。',
            ),
            _buildPrivacyItem(
              theme,
              Icons.key,
              'API Key 安全存储',
              'API Key 仅保存在系统安全存储中，不出现在数据库、日志或导出文件中。',
            ),
            _buildPrivacyItem(
              theme,
              Icons.file_download,
              '导出包含健康数据',
              '导出的文件包含饮食相关数据，请注意保管。默认不导出 API Key。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(
    ThemeData theme,
    IconData icon,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String confirmMessage,
    required Future<void> Function() onConfirm,
    bool isDanger = false,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: isDanger ? theme.colorScheme.error : null),
        title: Text(
          title,
          style: TextStyle(color: isDanger ? theme.colorScheme.error : null),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showConfirmDialog(
          context,
          ref,
          title,
          confirmMessage,
          onConfirm,
          isDanger,
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String message,
    Future<void> Function() onConfirm,
    bool isDanger,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('操作完成')));
              }
            },
            child: Text(
              '确定',
              style: TextStyle(
                color: isDanger ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearMeals(WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    await database.execute('DELETE FROM food_items');
    await database.execute('DELETE FROM meals');
    ref.invalidate(dailySummaryProvider);
    ref.invalidate(weeklyFoodCategoryProgressProvider);
  }

  Future<void> _clearLlmConfigs(WidgetRef ref) async {
    final dao = ref.read(llmProfileDaoProvider);
    final profiles = await dao.getAll();
    final secureStore = ref.read(secureStoreProvider);
    final database = ref.read(databaseProvider);
    for (final p in profiles) {
      await secureStore.delete('${p.id}');
    }
    await database.execute('DELETE FROM llm_profiles');
  }

  Future<void> _clearAll(WidgetRef ref) async {
    await _clearMeals(ref);
    final dao = ref.read(llmProfileDaoProvider);
    final profiles = await dao.getAll();
    final secureStore = ref.read(secureStoreProvider);
    final database = ref.read(databaseProvider);
    for (final p in profiles) {
      await secureStore.delete('${p.id}');
    }
    await database.execute('DELETE FROM llm_profiles');
    await database.execute('DELETE FROM daily_goals');
    await database.execute('DELETE FROM app_settings');
  }
}
