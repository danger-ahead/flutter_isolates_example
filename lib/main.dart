import 'package:flutter/material.dart';
import 'package:isolates_hive_example/mixins/text_style.dart';
import 'package:isolates_hive_example/services/database_manager.dart';
import 'package:path_provider/path_provider.dart';

late final DatabaseManager databaseManager;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // create an instance of DatabaseManager
  databaseManager = DatabaseManager();

  // start the isolate and initialize the database
  await databaseManager.start();
  final documentsPath = await getApplicationDocumentsDirectory();
  databaseManager.initDatabase(documentsPath.path);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TextStyleMixin {
  int _counter = 0;

  @override
  void dispose() {
    databaseManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter using isolates and hive'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Manually fetched value: $_counter', style: textStyle),
            StreamBuilder(
                stream: databaseManager.periodicallyGet(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data is int) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                            'Value fetched and incremented every second: ${snapshot.data}',
                            style: textStyle),
                      ],
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              databaseManager.store();
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              final int value = await databaseManager.get();
              setState(() {
                _counter = value;
              });
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              databaseManager.reset();
              setState(() {
                _counter = 0;
              });
            },
            child: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
