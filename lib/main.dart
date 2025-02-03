import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterSerialCommunicationPlugin = FlutterSerialCommunication();
  bool isConnected = false;
  List<DeviceInfo> connectedDevices = [];
  List<Uint8List> received = [];
  @override
  void initState() {
    super.initState();

    _flutterSerialCommunicationPlugin
        .getSerialMessageListener()
        .receiveBroadcastStream()
        .listen((rxData) {
      setState(() {
        received.add(rxData);
      });
      _flutterSerialCommunicationPlugin.write(rxData);
    });
    _flutterSerialCommunicationPlugin.setParameters(115200, 8, 1, 0);

    _flutterSerialCommunicationPlugin
        .getDeviceConnectionListener()
        .receiveBroadcastStream()
        .listen((event) {
      setState(() {
        isConnected = event;
      });
    });
  }

  _getAllConnectedDevicedButtonPressed() async {
    List<DeviceInfo> newConnectedDevices =
        await _flutterSerialCommunicationPlugin.getAvailableDevices();
    setState(() {
      connectedDevices = newConnectedDevices;
    });
  }

  _connectButtonPressed(DeviceInfo deviceInfo) async {
    bool isConnectionSuccess =
        await _flutterSerialCommunicationPlugin.connect(deviceInfo, 115200);
    debugPrint("Is Connection Success:  $isConnectionSuccess");
  }

  _disconnectButtonPressed() async {
    await _flutterSerialCommunicationPlugin.disconnect();
  }

  _sendMessageButtonPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0xBB, 0x00, 0x22, 0x00, 0x00, 0x22, 0x7E]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  _sendMessageButtonLeftPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0x61]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  _sendMessageButtonForwardPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0x62]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  _sendMessageButtonRightPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0x63]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  _sendMessageButtonBackPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0x64]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  void clearList() {
    setState(() {
      received = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    var openButtonText = isConnected == false ? 'Connect' : 'Disconnect';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Communication Example App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextButton(
                onPressed: _getAllConnectedDevicedButtonPressed,
                child: const Text("Get Device"),
              ),
              const SizedBox(width: 16.0),
              ...connectedDevices.asMap().entries.map((entry) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(child: Text(entry.value.productName)),
                    const SizedBox(width: 16.0),
                    FilledButton(
                      onPressed: () {
                        if (isConnected) {
                          _disconnectButtonPressed();
                        } else {
                          _connectButtonPressed(entry.value);
                        }
                      },
                      child: Text(openButtonText),
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16.0),
              TextField(
                  maxLength: 8,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Введите devAddress",
                      labelText: "devAddr",
                      fillColor: Colors.black12,
                      filled: true
                      //suffixIcon: IconButton(onPressed: (){}, icon: const Icon(Icons.clear))
                      ),

                  /*onSubmitted: (text) {
                  print("onSubmitted");
                  print("Введенный текст: $text");
                },*/
                  onChanged: (text) {
                    if (text.length == 8) {
                      print("onChanged");
                      print("Введенный текст: $text");
                    }
                  }),
              const SizedBox(height: 16.0),
              Expanded(
                flex: 8,
                //child: Card(
                //  margin: const EdgeInsets.all(5.0),
                child: ListView.builder(
                    padding: const EdgeInsets.all(0.0),
                    itemCount: received.length,
                    itemBuilder: (context, index) {
                      /*
                    OUTPUT for raw bytes
                    return Text(receiveDataList[index].toString());
                    */
                      /* output for string */
                      return Text(String.fromCharCodes(received[index]),
                          strutStyle: StrutStyle(
                            //fontFamily: 'Roboto',
                            //fontSize: 18,
                            //height: 0,
                            leading: 0,
                          ),
                          style: TextStyle(fontSize: 22));
                    }),
                //),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: clearList,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
