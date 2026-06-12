import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/navigation/app_router.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'core/database/models/cart_item_model.dart';
import 'core/database/models/order_model.dart';
import 'core/database/models/product_model.dart';
import 'core/database/models/user_model.dart';
import 'core/network/sync_provider.dart';

const String backgroundSyncTask = "com.zentromart.backgroundSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return true;
  });
}

void main() async {
  print("=== DART MAIN() IS RUNNING ===");
  // Safe initialization wrapper block
  WidgetsFlutterBinding.ensureInitialized();

  Isar? isar;
  try {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      isar = Isar.getInstance()!;
    } else {
      isar = await Isar.open(
        [CartItemModelSchema, OrderModelSchema, OrderItemModelSchema, ProductModelSchema, UserModelSchema],
        directory: dir.path,
      );
    }
  } catch (e, stackTrace) {
    print('Isar Initialization Error: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Text('Database Error:\n$e\n$stackTrace', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
    return;
  }

  // Initialize Workmanager without 'await' so it doesn't block the app from loading
  // if the Android native side hangs.
  try {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    Workmanager().registerPeriodicTask(
      "1",
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print("Workmanager initialization failed: $e\n$stackTrace");
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar!),
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
      debugShowCheckedModeBanner: false,
      title: 'Tawi-Tawi Workspace',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AppRouter(),
    );
  }
}
