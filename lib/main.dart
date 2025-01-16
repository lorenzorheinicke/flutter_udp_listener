import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDP Listener',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UDPListenerPage(),
    );
  }
}

class UDPListenerPage extends StatefulWidget {
  const UDPListenerPage({super.key});

  @override
  State<UDPListenerPage> createState() => _UDPListenerPageState();
}

class _UDPListenerPageState extends State<UDPListenerPage> {
  static const platform = MethodChannel('com.example/udp_channel');
  List<String> messages = [];
  bool isListening = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    startUDPServer();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMessageReceived':
          final Map<dynamic, dynamic> args = call.arguments;
          setState(() {
            messages.add(
                "[RECEIVED] From ${args['senderAddress']}:${args['senderPort']} - ${args['message']}");
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    stopUDPServer();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> startUDPServer() async {
    try {
      final String result = await platform.invokeMethod('startUDPServer', {
        'port': 5555,
      });

      setState(() {
        isListening = true;
        messages.add("[INFO] $result");
      });
    } on PlatformException catch (e) {
      setState(() {
        messages.add("[ERROR] Failed to start server: ${e.message}");
        isListening = false;
      });
    }
  }

  Future<void> stopUDPServer() async {
    try {
      final String result = await platform.invokeMethod('stopUDPServer');
      setState(() {
        isListening = false;
        messages.add("[INFO] $result");
      });
    } on PlatformException catch (e) {
      setState(() {
        messages.add("[ERROR] Failed to stop server: ${e.message}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UDP Listener'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isListening ? 'Listening on port 5555' : 'Server stopped'),
                ElevatedButton(
                  onPressed: isListening ? stopUDPServer : startUDPServer,
                  child: Text(isListening ? 'Stop Server' : 'Start Server'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Text(messages[messages.length - 1 - index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
