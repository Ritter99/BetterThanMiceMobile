import 'dart:async';

import 'package:better_than_mice/classes/MapAPI.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './elements/Map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum MappingState {
  Disconnected,
  Connecting,
  Start,
  Mapping,
  PausedMapping,
  FinishedMapping,
  PathFound,
}

enum ServerConnectionState {
  Connected,
  Disconnected,
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Better Than Mice',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Better Than mice'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final MyHomePageState myHomePageState = MyHomePageState();

  @override
  MyHomePageState createState() {
    return myHomePageState;
  }
}

class MyHomePageState extends State<MyHomePage> {
  final storage = new FlutterSecureStorage();
  int xPosition;
  int yPosition;
  MappingState currentMappingState = MappingState.Start;
  ServerConnectionState serverConnectionState =
      ServerConnectionState.Disconnected;
  List<Widget> bottomButtonList = [];
  String ipAddress;
  int portNumber;
  TurtleBotAPI turtleBotAPI;

  Future<void> testServer() async {
    if (turtleBotAPI != null) {
      bool success = await turtleBotAPI.testConnection();
      print('Server connected: $success');
      setState(() {
        serverConnectionState = (success)
            ? ServerConnectionState.Connected
            : ServerConnectionState.Disconnected;
      });
    }
  }

  Future<void> getLocalVariables() async {
    try {
      ipAddress = await storage.read(key: 'ipAddress');
      portNumber = int.parse(await storage.read(key: 'portNumber'));
      setState(() {
        turtleBotAPI =
            new TurtleBotAPI(ipAddress: ipAddress, portNumber: portNumber);
        currentMappingState = MappingState.Start;
      });
    } catch (err) {
      print(err);
      setState(() {
        turtleBotAPI = null;
        currentMappingState = MappingState.Disconnected;
      });
    }
  }

  void updateCoordinates(int newX, int newY) {
    setState(() {
      xPosition = newX;
      yPosition = newY;
    });
  }

  void setMappingState(MappingState newState) {
    setState(() {
      currentMappingState = newState;
    });
  }

  void updateBottomButtonList() {
    if (currentMappingState == MappingState.Start) {
      bottomButtonList = [
        CustomButton(
          title: 'Begin Mapping',
          color: Colors.tealAccent[400],
          onTap: () {
            print('Begin mapping');
            setMappingState(MappingState.Mapping);
            turtleBotAPI.startWallFollower();
          },
        ),
      ];
    } else if (currentMappingState == MappingState.Mapping) {
      bottomButtonList = [
        CustomButton(
          title: 'Finish Mapping',
          color: Colors.yellow[600],
          onTap: () {
            print('Finish mapping');
            setMappingState(MappingState.FinishedMapping);
            turtleBotAPI.stopWallFollower();
          },
        ),
      ];
    } else if (currentMappingState == MappingState.FinishedMapping) {
      bottomButtonList = [
        Text(
          'Mapping Complete',
          style: TextStyle(color: Colors.tealAccent[400], fontSize: 30.0),
        ),
        Container(height: 16),
        CustomButton(
          title: 'Done',
          color: Colors.blue[300],
          onTap: () {
            print('Done');
            setMappingState(MappingState.Start);
          },
        ),
      ];
    } else if (currentMappingState == MappingState.Disconnected) {
      bottomButtonList = [
        CustomButton(
          title: 'Connect to API',
          color: Colors.tealAccent[400],
          onTap: () async {
            print('Connect to API');
            turtleBotAPI =
                new TurtleBotAPI(ipAddress: ipAddress, portNumber: portNumber);
            bool success = await turtleBotAPI.testConnection();
            if (success) {
              storage.write(key: 'ipAddress', value: ipAddress);
              storage.write(key: 'portNumber', value: portNumber.toString());
              setMappingState(MappingState.Start);
            } else {
              print('Error');
            }
          },
        ),
      ];
    }
  }

  @override
  void initState() {
    xPosition = 0;
    yPosition = 0;

    startCoordinatesTimer();
    startConnectionTimer();
    testServer();
    getLocalVariables();
    super.initState();
  }

  void startCoordinatesTimer() {
    const oneSec = const Duration(seconds: 1);
    new Timer.periodic(oneSec, (timer) async {
      if (turtleBotAPI != null) {
        turtleBotAPI.getCurrentPosition().then((value) {
          updateCoordinates(value['x'], value['y']);
        });
      }
    });
  }

  void startConnectionTimer() {
    const oneSec = const Duration(seconds: 5);
    new Timer.periodic(oneSec, (timer) async {
      testServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    updateBottomButtonList();
    return Scaffold(
      appBar: CustomAppBar(
        height: 110.0,
        title: 'Better Than Mice',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (currentMappingState == MappingState.Disconnected)
                ? ConnectingScreen(
                    myHomePageState: widget.myHomePageState,
                  )
                : MappingArea(
                    mapAPI: turtleBotAPI,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    currentMappingState: currentMappingState,
                    myHomePageState: widget.myHomePageState,
                    serverConnectionState: serverConnectionState,
                  ),
            BottomButtons(bottomButtonList: bottomButtonList),
          ],
        ),
      ),
    );
  }
}

class ConnectingScreen extends StatelessWidget {
  const ConnectingScreen({
    Key key,
    @required this.myHomePageState,
  }) : super(key: key);

  final MyHomePageState myHomePageState;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IP Address:',
              style: TextStyle(fontSize: 26),
            ),
            TextField(
              decoration:
                  InputDecoration(labelText: 'IP Address (no http/https)'),
              onChanged: (text) {
                myHomePageState.ipAddress = text;
              },
            ),
            Container(height: 20),
            Text(
              'Port Number:',
              style: TextStyle(fontSize: 26),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Port Number'),
              onChanged: (text) {
                myHomePageState.portNumber = int.parse(text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MappingArea extends StatelessWidget {
  const MappingArea({
    Key key,
    @required this.mapAPI,
    @required this.xPosition,
    @required this.yPosition,
    @required this.currentMappingState,
    @required this.myHomePageState,
    @required this.serverConnectionState,
  }) : super(key: key);

  final MyHomePageState myHomePageState;
  final TurtleBotAPI mapAPI;
  final int xPosition;
  final int yPosition;
  final MappingState currentMappingState;
  final ServerConnectionState serverConnectionState;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Server: http://' +
                                  myHomePageState.ipAddress +
                                  ':' +
                                  myHomePageState.portNumber.toString(),
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 16),
                            ),
                            Container(width: 8),
                            Icon(
                              (serverConnectionState ==
                                      ServerConnectionState.Disconnected)
                                  ? Icons.highlight_remove
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: (serverConnectionState ==
                                      ServerConnectionState.Disconnected)
                                  ? Colors.red[400]
                                  : Colors.tealAccent[400],
                            )
                          ],
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            child: Icon(
                              Icons.computer,
                              color: Colors.black45,
                            ),
                            onTap: () => myHomePageState
                                .setMappingState(MappingState.Disconnected),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Container(height: 10),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        'Turtle Bot Position:',
                        style: TextStyle(fontSize: 24, color: Colors.black45),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 40),
                      Text(
                        xPosition.toString() + 'x',
                        style: TextStyle(fontSize: 36, color: Colors.black45),
                      ),
                      Text(
                        yPosition.toString() + 'y',
                        style: TextStyle(fontSize: 36, color: Colors.black45),
                      ),
                      Container(width: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                children: [
                  Center(
                    child: Map(
                      turtleBotAPI: mapAPI,
                      currentX: xPosition,
                      currentY: yPosition,
                    ),
                  ),
                  (currentMappingState == MappingState.FinishedMapping)
                      ? Center(
                          child: Opacity(
                            opacity: 0.7,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: MediaQuery.of(context).size.width * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.blue[300],
                                borderRadius: BorderRadius.all(Radius.circular(
                                    MediaQuery.of(context).size.width * 0.3)),
                              ),
                              child: Icon(
                                Icons.check,
                                size: MediaQuery.of(context).size.width * 0.35,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({
    Key key,
    @required this.bottomButtonList,
  }) : super(key: key);

  final List<Widget> bottomButtonList;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: bottomButtonList,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final Color color;
  final onTap;
  const CustomButton({
    Key key,
    @required this.title,
    @required this.color,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.06,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.height * 0.03)),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 30.0),
          ),
        ),
      ),
      onTap: () => onTap(),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final String title;

  const CustomAppBar({
    @required this.height,
    @required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.yellow[600],
      ),
      child: Column(
        children: [
          Container(
            height: 40.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
              ),
              Container(width: 40),
              Container(
                height: 70,
                width: 70,
                child: Image(
                  image: AssetImage('lib/assets/logos/team_logo.png'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
