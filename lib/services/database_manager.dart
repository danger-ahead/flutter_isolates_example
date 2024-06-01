import 'dart:async';
import 'dart:isolate';

import 'package:hive/hive.dart';
import 'package:isolates_hive_example/enums.dart';

void databaseOperations(SendPort sendPort) async {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  late final Box hive;
  Timer? timer;

  await for (List message in receivePort) {
    Enum command = message[0];
    SendPort replyPort = message[1];

    switch (command) {
      case Database.init:
        try {
          String path = message[2];
          Hive.init(path);
          hive = await Hive.openBox('myBox');
          replyPort.send(true);
        } catch (e) {
          replyPort.send(false);
        }
        break;

      case Database.store:
        final int key = hive.get('key', defaultValue: 0);
        hive.put('key', key + 1);
        replyPort.send(true);

      case Database.get:
        final int key = hive.get('key', defaultValue: 0);
        replyPort.send(key);
        break;

      case Database.periodicallyGet:
        if (timer != null && timer.isActive) {
          timer.cancel();
        }
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          final int key = hive.get('key', defaultValue: 0);
          hive.put('key', key + 1);
          replyPort.send(key);
        });
        break;

      case Database.reset:
        hive.put('key', 0);
        replyPort.send(true);
        break;

      case Database.dispose:
        await hive.close();
        timer?.cancel();
        replyPort.send(true);
        break;
    }
  }
}

class DatabaseManager {
  late Isolate isolate;
  late SendPort sendPort0;
  late ReceivePort receivePort0;

  Future<void> start() async {
    receivePort0 = ReceivePort();
    isolate = await Isolate.spawn(databaseOperations, receivePort0.sendPort);
    sendPort0 = await receivePort0.first;
  }

  Future<void> initDatabase(String path) async {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.init, responsePort.sendPort, path]);
    return await responsePort.first;
  }

  Future<void> store() async {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.store, responsePort.sendPort]);
    return await responsePort.first;
  }

  Future<int> get() async {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.get, responsePort.sendPort]);
    return await responsePort.first;
  }

  ReceivePort periodicallyGet() {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.periodicallyGet, responsePort.sendPort]);
    return responsePort;
  }

  Future<void> reset() async {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.reset, responsePort.sendPort]);
    return await responsePort.first;
  }

  void dispose() async {
    ReceivePort responsePort = ReceivePort();
    sendPort0.send([Database.dispose, responsePort.sendPort]);
    await responsePort.first;
    isolate.kill(priority: Isolate.immediate);
  }
}
