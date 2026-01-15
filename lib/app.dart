import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'routes.dart';

class ClinixAIApp extends StatelessWidget {
  const ClinixAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr('appTitle'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: appRoutes,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
