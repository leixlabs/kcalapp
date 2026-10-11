import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class CaloryApp extends ConsumerWidget {
  const CaloryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final alice = ref.watch(aliceProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: ref.watch(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => Navigator(
        key: alice.getNavigatorKey(),
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child!),
      ),
    );
  }
}
