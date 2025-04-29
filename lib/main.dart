import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/auth_view_model.dart';
import 'package:workmanagement/repositories/itask_repository.dart';
import 'package:workmanagement/repositories/task_repository.dart';
import 'package:workmanagement/viewmodels/calendar_viewmodel.dart';
import 'package:workmanagement/viewmodels/settings_viewmodel.dart';
import 'package:workmanagement/views/splash_screen.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        Provider<ITaskRepository>(create: (_) => TaskRepository()),
        ChangeNotifierProxyProvider<AuthViewModel, SettingsViewModel>(
          create: (context) => SettingsViewModel(context.read<AuthViewModel>()),
          update:
              (context, authViewModel, previousSettingsViewModel) =>
                  SettingsViewModel(authViewModel),
        ),
        ChangeNotifierProxyProvider<ITaskRepository, TaskViewModel>(
          create: (context) => TaskViewModel(context.read<ITaskRepository>()),
          update: (context, repo, previousViewModel) => TaskViewModel(repo),
        ),
        ChangeNotifierProxyProvider<TaskViewModel, CalendarViewModel>(
          create: (context) => CalendarViewModel(context.read<TaskViewModel>()),
          update:
              (context, taskViewModel, previousCalendarViewModel) =>
                  CalendarViewModel(taskViewModel),
        ),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();

    if (settingsViewModel.isLoadingTheme) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      title: 'TaskFlow',
      themeMode: settingsViewModel.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
