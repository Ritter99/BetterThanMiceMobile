import 'dart:math';
import 'dart:typed_data';

import 'package:better_than_mice/classes/MapAPI.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Map extends StatefulWidget {
  final TurtleBotAPI turtleBotAPI;
  final int currentX;
  final int currentY;
  final Timer mapTimer;
  Map({
    Key key,
    @required this.turtleBotAPI,
    @required this.currentX,
    @required this.currentY,
    @required this.mapTimer,
  }) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  TurtleBotAPI turtleBotAPI;
  List<int> gridState = [];
  Widget mapImage;
  int currentX;
  int currentY;
  Timer mapTimer;

  @override
  void initState() {
    turtleBotAPI = widget.turtleBotAPI;
    currentX = widget.currentX;
    currentY = widget.currentY;
    mapTimer = widget.mapTimer;
    startTimer();
    super.initState();
  }

  @override
  void dispose() {
    mapTimer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 2);
    mapTimer = new Timer.periodic(oneSec, (timer) async {
      turtleBotAPI.getMap().then((value) => updateGridState(value));
    });
  }

  void updateGridState(List<int> newGridState) {
    // print(newGridState);
    if (newGridState.length > 0) {
      BMP332Header header = BMP332Header(
          sqrt(newGridState.length).round(), sqrt(newGridState.length).round());
      Uint8List bmp = header.appendBitmap(Uint8List.fromList(newGridState));
      Image newImage = Image.memory(
        bmp,
        width: 1000,
      );
      setState(() {
        gridState = newGridState;
        mapImage = newImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double _turtleBotWidth = 20.0;
    double _width = sqrt(gridState.length);
    double _height = sqrt(gridState.length);
    int _currentX = widget.currentX;
    int _currentY = widget.currentY;

    _currentX += (_width ~/ 2);
    _currentY += (_height ~/ 2);
    return ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(20.0),
      ),
      child: (_width == 0 || _height == 0)
          ? Center(
              child: Text(
                "Loading map...",
                style: TextStyle(color: Colors.black45, fontSize: 20),
              ),
            )
          : Container(
              width: _width + 4,
              height: _height + 4,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: _width + 4,
                      height: _height + 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          width: 2.0,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                      child: Container(
                        width: _width,
                        height: _height,
                        child: (mapImage == null) ? Container() : mapImage,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_currentX - (_turtleBotWidth / 2),
                        _currentY - (_turtleBotWidth / 4)),
                    child: Image(
                      height: _turtleBotWidth,
                      image: AssetImage(
                        'lib/assets/icons/mouse_icon.png',
                      ),
                    ),
                  ),
                ],
              ),
            ),

      // Transform.rotate(
      //   angle: pi * 1.8,
      //   child: Transform.translate(
      //     offset: Offset(30, 100),
      //     child: Transform.scale(
      //       scale: 7,
      //       child: (mapImage == null) ? Container() : mapImage,
      //     ),
      //   ),
      // ),
    );
  }
}

class BMP332Header {
  int _width; // NOTE: width must be multiple of 4 as no account is made for bitmap padding
  int _height;

  Uint8List _bmp;
  int _totalHeaderSize;

  BMP332Header(this._width, this._height) : assert(_width & 3 == 0) {
    int baseHeaderSize = 54;
    _totalHeaderSize = baseHeaderSize + 1024; // base + color map
    int fileLength = _totalHeaderSize + _width * _height; // header + bitmap
    _bmp = new Uint8List(fileLength);
    ByteData bd = _bmp.buffer.asByteData();
    bd.setUint8(0, 0x42);
    bd.setUint8(1, 0x4d);
    bd.setUint32(2, fileLength, Endian.little); // file length
    bd.setUint32(10, _totalHeaderSize, Endian.little); // start of the bitmap
    bd.setUint32(14, 40, Endian.little); // info header size
    bd.setUint32(18, _width, Endian.little);
    bd.setUint32(22, _height, Endian.little);
    bd.setUint16(26, 1, Endian.little); // planes
    bd.setUint32(28, 8, Endian.little); // bpp
    bd.setUint32(30, 0, Endian.little); // compression
    bd.setUint32(34, _width * _height, Endian.little); // bitmap size
    // leave everything else as zero

    // there are 256 possible variations of pixel
    // build the indexed color map that maps from packed byte to RGBA32
    // better still, create a lookup table see: http://unwind.se/bgr233/
    for (int rgb = 0; rgb < 256; rgb++) {
      int offset = baseHeaderSize + rgb * 4;

      int red = rgb & 0xe0;
      int green = rgb & 0xe0;
      int blue = rgb & 0xe0;

      bd.setUint8(offset + 3, 255); // A
      bd.setUint8(offset + 2, red); // R
      bd.setUint8(offset + 1, green); // G
      bd.setUint8(offset, blue); // B
    }
  }

  /// Insert the provided bitmap after the header and return the whole BMP
  Uint8List appendBitmap(Uint8List bitmap) {
    int size = _width * _height;
    assert(bitmap.length == size);
    _bmp.setRange(_totalHeaderSize, _totalHeaderSize + size, bitmap);
    return _bmp;
  }
}
