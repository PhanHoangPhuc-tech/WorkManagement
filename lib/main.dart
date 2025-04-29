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
import 'package:workmanagement/views/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<ITaskRepository>(create: (_) => TaskRepository()),
        ChangeNotifierProxyProvider<ITaskRepository, TaskViewModel>(
          create: (context) => TaskViewModel(context.read<ITaskRepository>()),
          update: (context, repo, previousViewModel) => TaskViewModel(repo),
        ),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProxyProvider<TaskViewModel, CalendarViewModel>(
          create: (context) => CalendarViewModel(context.read<TaskViewModel>()),
          update:
              (context, taskViewModel, previousCalendarViewModel) =>
                  CalendarViewModel(taskViewModel),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      theme: ThemeData(
        primaryColor: const Color(0xFF005AE0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005AE0),
          primary: const Color(0xFF005AE0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF005AE0),
          foregroundColor: Colors.white,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF005AE0),
          foregroundColor: Colors.white,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF005AE0);
            }
            return null;
          }),
        ),
      ),
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
