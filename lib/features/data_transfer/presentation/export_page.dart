import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _includePhotos = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('数据导出')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '导出格式',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    context,
                    'JSON 格式',
                    '导出完整餐食、食材和目标数据',
                    Icons.code,
                    _exportJson,
                  ),
                  const SizedBox(height: 8),
                  _buildExportButton(
                    context,
                    'CSV 格式',
                    '导出食材级明细数据',
                    Icons.table_chart,
                    _exportCsv,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('包含图片'),
              subtitle: const Text('导出时一并复制已保存的餐食图片'),
              value: _includePhotos,
              onChanged: (v) => setState(() => _includePhotos = v),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.security, color: theme.colorScheme.outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '导出文件不包含 API Key 等敏感信息',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Future<void> Function() onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isExporting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);
    try {
      final mealRepo = ref.read(mealRepositoryProvider);
      final goalRepo = ref.read(goalRepositoryProvider);
      final goals = await goalRepo.getAllGoals();
      final meals = await mealRepo.getAllMeals();

      final mealsJson = meals
          .map(
            (meal) => {
              'id': meal.id,
              'date_time': meal.dateTime.toIso8601String(),
              'meal_type': meal.mealType.name,
              'name': meal.name,
              'photo_path': meal.photoPath,
              'servings': meal.servings,
              'source': meal.source,
              'is_deleted': false,
              'created_at': meal.createdAt.toIso8601String(),
              'updated_at': meal.updatedAt.toIso8601String(),
              'food_items': meal.foodItems
                  .map(
                    (i) => {
                      'id': i.id,
                      'meal_id': i.mealId,
                      'name': i.name,
                      'weight_g': i.weightG,
                      'kcal': i.kcal,
                      'carbs_g': i.carbsG,
                      'protein_g': i.proteinG,
                      'fat_g': i.fatG,
                      'confidence': i.confidence?.name,
                      'sort_order': i.sortOrder,
                    },
                  )
                  .toList(),
            },
          )
          .toList();

      final now = DateTime.now();
      final exportData = {
        'schema_version': 1,
        'generated_at': now.toIso8601String(),
        'goals': goals
            .map(
              (g) => {
                'id': g.id,
                'effective_date': g.effectiveDate.toIso8601String(),
                'kcal': g.kcal,
                'carbs_g': g.carbsG,
                'protein_g': g.proteinG,
                'fat_g': g.fatG,
              },
            )
            .toList(),
        'meals': mealsJson,
      };

      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(dir.path, 'calory_export_${now.millisecondsSinceEpoch}.json'),
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      await Share.shareXFiles([XFile(file.path)], text: 'calory export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final mealRepo = ref.read(mealRepositoryProvider);
      final meals = await mealRepo.getAllMeals();

      final buffer = StringBuffer();
      buffer.writeln(
        'date_time,meal_type,meal_name,food_name,weight_g,kcal,carbs_g,protein_g,fat_g',
      );

      for (final meal in meals) {
        for (final item in meal.foodItems) {
          buffer.writeln(
            '${meal.dateTime.toIso8601String()},${meal.mealType.label},${_csvEscape(meal.name)},${_csvEscape(item.name)},${item.weightG},${item.kcal},${item.carbsG},${item.proteinG},${item.fatG}',
          );
        }
      }

      final now = DateTime.now();
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(dir.path, 'calory_export_${now.millisecondsSinceEpoch}.csv'),
      );
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'calory export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
