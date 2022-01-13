import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Issue 6749',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Issue 6749'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _ref = FirebaseFirestore.instance.doc('issues/6749');
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _docStream;

  @override
  void initState() {
    super.initState();

    _docStream = _ref.snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.lightGreen,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Instructions', style: TextStyle(fontSize: 20)),
                    const Text('1. Connect to a physical device using a cable.', style: TextStyle(fontSize: 16)),
                    const Text('2. Before debugging run "adb tcpip 5555 && adb connect <device ip>"', style: TextStyle(fontSize: 16)),
                    const Text('3. Remove the cable.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('4. Now run it in debug mode.', style: TextStyle(fontSize: 16)),
                    const Text('5. Verify it can write a document.', style: TextStyle(fontSize: 16)),
                    const Text('6. Now put it into standby mode.', style: TextStyle(fontSize: 16)),
                    const Text('7. Wait 30\'ish minutes (in which time Android will shut down Wifi to save power).', style: TextStyle(fontSize: 16)),
                    const Text('8. Wake it up and add a document again.', style: TextStyle(fontSize: 16)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: const [
                          Text('If you have the firestore console open, you should see nothing happen there', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                          Text('(for potentially several minutes)', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Click the button to write to the document', style: TextStyle(fontSize: 30)),
                ),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _docStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Text('Fetching data', style: TextStyle(fontSize: 24));

                    final data = snapshot.data?.data();
                    if (data == null) {
                      return const Text('No data yet', style: TextStyle(fontSize: 20));
                    } else {
                      final local = data['local_timestamp'] as Timestamp;
                      final server = data['server_timestamp'] as Timestamp?;
                      num? diff;

                      if (server != null) {
                        diff = (server.toDate().millisecondsSinceEpoch - local.toDate().millisecondsSinceEpoch).abs() / 1000;
                      }

                      return Column(
                        children: [
                          Text('From cache: ${snapshot.data!.metadata.isFromCache}, Pending writes: ${snapshot.data!.metadata.hasPendingWrites}',
                              style: const TextStyle(fontSize: 20)),
                          const Divider(),
                          Text('Local timestamp: ${local.toDate()}', style: const TextStyle(fontSize: 20)),
                          if (server != null)
                            Text('Server timestamp: ${server.toDate()}', style: const TextStyle(fontSize: 20))
                          else
                            const Text('No server response yet', style: TextStyle(fontSize: 20)),
                          if (diff != null)
                            Text('Difference between local and server: $diff seconds',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _ref.set(<String, dynamic>{
            'local_timestamp': Timestamp.now(),
            'server_timestamp': FieldValue.serverTimestamp(),
          });
        },
        tooltip: 'Write',
        child: const Icon(Icons.add),
      ),
    );
  }
}
