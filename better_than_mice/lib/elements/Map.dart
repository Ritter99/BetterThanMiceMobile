import 'package:better_than_mice/classes/MapAPI.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Map extends StatefulWidget {
  final MapAPI mapAPI;
  Map({Key key, @required this.mapAPI}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  MapAPI mapAPI;
  List<List<int>> gridState = [
    [100, 100],
    [100, 100]
  ];

  @override
  void initState() {
    mapAPI = widget.mapAPI;
    startTimer();
    super.initState();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    new Timer.periodic(oneSec, (timer) async {
      List<List<int>> newGridState = await mapAPI.getMap();
      updateGridState(newGridState);
    });
  }

  void updateGridState(List<List<int>> newGridState) {
    setState(() {
      gridState = newGridState;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildGridItem(int x, int y) {
      int greyScale = gridState[x][y] ~/ 2;
      return Container(
        color: Color.fromARGB(greyScale, 0, 0, 0),
      );
    }

    _gridItemTapped(int x, int y) {
      print('$x, $y');
    }

    Widget _buildGridItems(BuildContext context, int index) {
      int gridStateLength = gridState.length;
      int x, y = 0;
      x = (index / gridStateLength).floor();
      y = (index % gridStateLength);
      return GestureDetector(
        onTap: () => _gridItemTapped(x, y),
        child: GridTile(
          child: Container(
            child: Center(
              child: _buildGridItem(x, y),
            ),
          ),
        ),
      );
    }

    Widget _buildGameBody() {
      int gridStateLength = gridState.length;
      return Column(children: <Widget>[
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridStateLength,
              ),
              itemBuilder: _buildGridItems,
              itemCount: gridStateLength * gridStateLength,
            ),
          ),
        ),
      ]);
    }

    return _buildGameBody();
  }
}
