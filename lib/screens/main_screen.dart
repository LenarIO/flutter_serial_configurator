import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

import '../model_data.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

  String _targetDevAddr = '';
  bool _devAddr_is_NotEmpty = false;

  _getAllConnectedDevicedButtonPressed() async {
    List<DeviceInfo> newConnectedDevices =
        await _flutterSerialCommunicationPlugin.getAvailableDevices();
    setState(() {
      connectedDevices = newConnectedDevices;
      _devAddr_is_NotEmpty = false;
    });
  }

  _connectButtonPressed(DeviceInfo deviceInfo) async {
    bool isConnectionSuccess =
        await _flutterSerialCommunicationPlugin.connect(deviceInfo, 115200);
    debugPrint("Is Connection Success:  $isConnectionSuccess");
  }

  _disconnectButtonPressed() async {
    await _flutterSerialCommunicationPlugin.disconnect();
    _devAddr_is_NotEmpty = false;
  }

  _sendMessageButtonPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0xBB, 0x00, 0x22, 0x00, 0x00, 0x22, 0x7E]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  _sendData3() async {
    txrxDada.Head = 0xAB;
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

  _changeTargetDevAddr(String text) {
    //setState(() => _targetDevAddr = text);
    setState(() {
      print("Введенный текст: $text");
      if (text.length == 8) {
        //print("onChanged");
        //print("Введенный текст: $text");
        _targetDevAddr = text;
        _devAddr_is_NotEmpty = true;
      } else {
        _targetDevAddr = '';
        //_devAddr_is_NotEmpty = false;
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
              /*TextButton(
                onPressed: _getAllConnectedDevicedButtonPressed,
                child: const Text("Get Device"),
              ),  
              const SizedBox(width: 4.0),*/
              const SizedBox(height: 40.0),
              TextField(
                maxLength: 8,
                readOnly: _devAddr_is_NotEmpty,
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
              ...connectedDevices.asMap().entries.map((entry) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(child: Text(entry.value.productName)),
                    const SizedBox(width: 16.0),
                    FilledButton(
                      onPressed: _devAddr_is_NotEmpty
                          ? () {
                              if (isConnected) {
                                _disconnectButtonPressed();
                                _devAddr_is_NotEmpty = false;
                              } else {
                                _connectButtonPressed(entry.value);
                                _devAddr_is_NotEmpty = true;
                              }
                            }
                          : null,
                      child: Text(openButtonText),
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16.0),
              Text("Введенный текст: $_targetDevAddr"),
              Text('_devAddr_is_NotEmpty: $_devAddr_is_NotEmpty'),
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
                          /*utf8.decode(received[index]), */ String
                              .fromCharCodes(received[index]),
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
          onPressed: _getAllConnectedDevicedButtonPressed, //clearList,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
