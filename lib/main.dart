import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

import 'model_data.dart';

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
  TxRxData txrxDada = TxRxData();
  @override
  void initState() {
    super.initState();

    _flutterSerialCommunicationPlugin
        .getSerialMessageListener()
        .receiveBroadcastStream()
        .listen((rxData) {
      setState(() {
        received.add(rxData);
        /*  if (received.last == "\r") {
          received = [];
        }*/
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

  _sendRequest() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0x64]));
  }

  _sendData(TxRxData data) async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList(data as List<int>));
  }

  int Head = 0xAB;
  _sendData3() async {
    txrxDada.Head = Head;
    List<int> list = [];
    list.add(txrxDada.Head);
    for (var i = 0; i < _targetDevAddr.length / 2; i++) {
      String str = _targetDevAddr[i * 2] + _targetDevAddr[i * 2 + 1];
      list.add(int.parse(str, radix: 16));
    }
    print(list);
    bool isMessageSent =
        await _flutterSerialCommunicationPlugin.write(Uint8List.fromList(list));
  }

  void clearList() {
    setState(() {
      received = [];
    });
  }

  String _targetDevAddr = '';

  _changeTargetDevAddr(String text) {
    //setState(() => _targetDevAddr = text);
    setState(() {
      print("Введенный текст: $text");
      if (text.length == 8) {
        print("onChanged");
        print("Введенный текст: $text");
        _targetDevAddr = text;
      } else {
        _targetDevAddr = '';
      }
    });
  }

  // Функция для преобразования списка Uint8List в строку
  String _convertUint8ListToString(List<Uint8List> list) {
    return list.map((uint8list) => utf8.decode(uint8list)).join(' ');
  }

  final TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    var openButtonText = isConnected == false ? 'Connect' : 'Disconnect';
    // bool _isCorrectDevAddr = false;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Communication Example App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              TextButton(
                onPressed: _getAllConnectedDevicedButtonPressed,
                child: const Text("Get Device"),
              ),
              const SizedBox(width: 4.0),
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
              const SizedBox(height: 4.0),
              TextField(
                maxLength: 8,
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Введите devAddress",
                  labelText: "devAddr",
                  /*errorText: null,
                  suffixIcon: IconButton(
                      onPressed: _controller.clear,
                      icon: const Icon(Icons.clear)),*/
                ),

                onSubmitted: _changeTargetDevAddr,
                // onChanged: _changeTargetDevAddr
              ),
              const SizedBox(height: 16.0),
              Text("Введенный текст: $_targetDevAddr"),
              FilledButton(
                  onPressed: isConnected ? _sendData3 : null,
                  child: const Text("Send dev Addr")),
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
                      String displayText = received
                          .map((uint8list) => utf8.decode(uint8list))
                          .join(' ');
                      return Text(
                          utf8.decode(received[
                              index]), //String.fromCharCodes(received[index]),
                          strutStyle: const StrutStyle(
                            //fontFamily: 'Roboto',
                            //fontSize: 18,
                            //height: 0,
                            leading: 0,
                          ),
                          style: const TextStyle(fontSize: 22));
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
