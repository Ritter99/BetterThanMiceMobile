import 'package:better_than_mice/classes/MapAPI.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './elements/Map.dart';

enum MappingState {
  Disconnected,
  Connecting,
  Start,
  Mapping,
  PausedMapping,
  FinishedMapping,
  PathFound
}

String ipAddress = '10.11.1.184';
int portNumber = 5140;

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

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double xPosition = 0.0;
  double yPosition = 0.0;
  MappingState currentMappingState = MappingState.Disconnected;
  List<Widget> bottomButtonList = [];
  final MapAPI mapApi = new MapAPI();

  void updateCoordinates(double newX, double newY) {
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
          },
        ),
      ];
    } else if (currentMappingState == MappingState.Mapping) {
      bottomButtonList = [
        CustomButton(
          title: 'Pause Mapping',
          color: Colors.orange[300],
          onTap: () {
            print('Pause mapping');
            setMappingState(MappingState.PausedMapping);
          },
        ),
        Container(height: 16),
        CustomButton(
          title: 'Stop Mapping',
          color: Colors.red[300],
          onTap: () {
            print('Stop mapping');
            setMappingState(MappingState.Start);
          },
        ),
        Container(height: 16),
        Row(
          children: [
            CustomButton(
              title: 'Finish Mapping',
              color: Colors.yellow[600],
              onTap: () {
                print('Finish mapping');
                setMappingState(MappingState.FinishedMapping);
              },
            ),
            Text('<- Temp!')
          ],
        ),
      ];
    } else if (currentMappingState == MappingState.PausedMapping) {
      bottomButtonList = [
        CustomButton(
          title: 'Resume Mapping',
          color: Colors.tealAccent[400],
          onTap: () {
            print('Resume mapping');
            setMappingState(MappingState.Mapping);
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
          title: 'Find Path',
          color: Colors.yellow[600],
          onTap: () {
            print('Find Path');
            setMappingState(MappingState.PathFound);
          },
        ),
      ];
    } else if (currentMappingState == MappingState.PathFound) {
      bottomButtonList = [
        Text(
          'Path Found',
          style: TextStyle(color: Colors.blue[300], fontSize: 30.0),
        ),
        Container(height: 16),
        CustomButton(
          title: 'Return to Start',
          color: Colors.tealAccent[400],
          onTap: () {
            print('Return to Start');
            setMappingState(MappingState.Mapping);
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
            bool success = await mapApi.testConnection(ipAddress, portNumber);
            if (success) {
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
                ? ConnectingScreen()
                : MappingArea(
                    mapAPI: mapApi,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    currentMappingState: currentMappingState),
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
  }) : super(key: key);

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
                ipAddress = text;
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
                portNumber = int.parse(text);
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
  }) : super(key: key);

  final MapAPI mapAPI;
  final double xPosition;
  final double yPosition;
  final MappingState currentMappingState;

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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Expanded(
                      child: Row(
                        children: [
                          Container(width: 20),
                          Text(
                            'Turtle Drone:',
                            style:
                                TextStyle(fontSize: 24, color: Colors.black45),
                            textAlign: TextAlign.start,
                          ),
                        ],
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
            flex: 4,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  width: 2.0,
                  color: Colors.black45,
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment(0.0, 0.8),
                    child: Text(
                      'Start',
                      style: TextStyle(color: Colors.black26, fontSize: 30.0),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0.0, 0.8),
                    child: Image(
                      height: 40.0,
                      image: AssetImage(
                        'lib/assets/icons/mouse_icon.png',
                      ),
                    ),
                  ),
                  Map(mapAPI: mapAPI),
                  Center(
                    child: (currentMappingState == MappingState.FinishedMapping)
                        ? Opacity(
                            opacity: 0.5,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: MediaQuery.of(context).size.width * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.tealAccent[400],
                                borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.3),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width * 0.5,
                              ),
                            ),
                          )
                        : Container(),
                  ),
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
