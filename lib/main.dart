import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/storage/cache_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/task_list_screen.dart';
import 'features/tasks/presentation/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Ініціалізація локального сховища (Hive + SecureStorage)
  final cacheService = CacheService();
  await cacheService.init();

  // 2. Ініціалізація Dio з Interceptors (Auth, Retry, Logging)
  final dioClient = DioClient(cacheService);

  // 3. Ініціалізація репозиторіїв
  final authRepository = AuthRepository(
    dio: dioClient.dio,
    cacheService: cacheService,
  );
  final taskRepository = TaskRepository(
    dio: dioClient.dio,
    cacheService: cacheService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => TaskProvider(taskRepository)),
      ],
      child: const TeamTasksApp(),
    ),
  );
}

class TeamTasksApp extends StatelessWidget {
  const TeamTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Tasks Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return auth.isAuthenticated
              ? const TaskListScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
