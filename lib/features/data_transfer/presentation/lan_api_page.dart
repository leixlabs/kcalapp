import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/lan_api_server.dart';

class LanApiPage extends ConsumerStatefulWidget {
  const LanApiPage({super.key});

  @override
  ConsumerState<LanApiPage> createState() => _LanApiPageState();
}

class _LanApiPageState extends ConsumerState<LanApiPage> {
  LanApiServer? _server;
  bool _isStarting = false;
  bool _isStopping = false;
  bool _isDisposed = false;
  String? _error;

  @override
  void dispose() {
    _isDisposed = true;
    final server = _server;
    if (server != null) unawaited(server.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = _server;
    final isRunning = server?.isRunning ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('局域网只读 API')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRunning ? Icons.wifi : Icons.wifi_off,
                        color: isRunning
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRunning ? '服务运行中' : '服务已停止',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isRunning)
                        OutlinedButton(
                          onPressed: _isStopping ? null : _stopServer,
                          child: _isStopping
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('停止'),
                        )
                      else
                        FilledButton(
                          onPressed: _isStarting ? null : _startServer,
                          child: _isStarting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('启动'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '仅在此页面打开期间运行。使用同一局域网内的电脑或其他设备访问；离开本页时服务会自动停止。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isRunning && server != null) ...[
            const SizedBox(height: 12),
            _buildAddressesCard(theme, server),
            const SizedBox(height: 12),
            _buildTokenCard(theme, server),
          ],
          const SizedBox(height: 16),
          _buildEndpointsCard(theme),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: theme.colorScheme.outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '餐食和目标属于个人健康数据。访问接口必须携带上方令牌；停止服务或离开本页后，令牌立即失效。HTTP 未加密，令牌会在局域网中明文传输，请只在可信网络使用。',
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

  Widget _buildAddressesCard(ThemeData theme, LanApiServer server) {
    final port = server.boundPort;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '局域网地址',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final address in server.addresses)
              _CopyableValue(
                value: Uri(
                  scheme: 'http',
                  host: address,
                  port: port,
                  queryParameters: {'token': server.accessToken},
                ).toString(),
                tooltip: '复制带令牌的地址',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(ThemeData theme, LanApiServer server) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '访问令牌',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _CopyableValue(value: server.accessToken ?? '', tooltip: '复制令牌'),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '可用接口',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const _EndpointDescription(
              endpoint: 'GET /api/v1/meals?from=&to=',
              description: '读取指定时间范围内的餐食和食材明细',
            ),
            const _EndpointDescription(
              endpoint: 'GET /api/v1/goals',
              description: '读取每日营养目标',
            ),
            const _EndpointDescription(
              endpoint: 'GET /api/v1/health',
              description: '检查服务状态',
            ),
            const SizedBox(height: 8),
            Text(
              '认证：URL 参数 ?token=<令牌> 或请求头 Authorization: Bearer <令牌>。打开局域网地址可查看完整 API 文档。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startServer() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });

    final server = LanApiServer(
      loadMeals: () => ref.read(mealRepositoryProvider).getAllMeals(),
      loadGoals: () => ref.read(goalRepositoryProvider).getAllGoals(),
    );
    _server = server;
    try {
      await server.start();
      if (_isDisposed) {
        await server.stop();
        return;
      }
      if (mounted) setState(() => _isStarting = false);
    } on SocketException catch (error) {
      await server.stop();
      if (mounted) {
        setState(() {
          _server = null;
          _isStarting = false;
          _error = '无法启动服务：$error';
        });
      }
    } catch (error) {
      await server.stop();
      if (mounted) {
        setState(() {
          _server = null;
          _isStarting = false;
          _error = '无法启动服务：$error';
        });
      }
    }
  }

  Future<void> _stopServer() async {
    final server = _server;
    if (server == null) return;
    setState(() => _isStopping = true);
    await server.stop();
    if (mounted) {
      setState(() {
        _server = null;
        _isStopping = false;
      });
    }
  }
}

class _EndpointDescription extends StatelessWidget {
  const _EndpointDescription({
    required this.endpoint,
    required this.description,
  });

  final String endpoint;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              endpoint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(description, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CopyableValue extends StatelessWidget {
  const _CopyableValue({required this.value, required this.tooltip});

  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          tooltip: tooltip,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('已复制')));
            }
          },
          icon: const Icon(Icons.copy),
        ),
      ],
    );
  }
}
