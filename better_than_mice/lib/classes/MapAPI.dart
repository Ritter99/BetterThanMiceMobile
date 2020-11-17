import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TurtleBotAPI {
  String ipAddress;
  int portNumber;
  double resolution;

  TurtleBotAPI({@required this.ipAddress, this.portNumber});

  Future<bool> testConnection() async {
    if (ipAddress == '' || portNumber == 0) {
      return false;
    }

    try {
      final url = 'http://' + ipAddress + ':' + portNumber.toString();
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      Map responseBody = jsonDecode(response.body);
      if (responseBody['message'] == 'success') {
        return true;
      }
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    }
    return false;
  }

  Future<List<int>> getMap() async {
    var url =
        'http://' + this.ipAddress + ':' + this.portNumber.toString() + '/map/';
    var response = await http.get(url);
    Map responseBody = jsonDecode(response.body);
    List<int> map = [];
    if (responseBody['message'] != null) {
      if (responseBody['message']['yaml'] != null &&
          responseBody['message']['yaml']['resolution'] != null) {
        this.resolution = responseBody['message']['yaml']['resolution'];
      }

      for (int i = responseBody['message']['map']['pgm'].length - 1;
          i > -1;
          i--) {
        List<dynamic> row = responseBody['message']['map']['pgm'][i];
        for (int j = 0; j < row.length; j++) {
          int item = row[j];
          map.add(item);
        }
      }
    }
    return map;
  }

  Future<Map<String, int>> getCurrentPosition() async {
    var url = 'http://' +
        this.ipAddress +
        ':' +
        this.portNumber.toString() +
        '/currentPosition/';
    var response = await http.get(url);
    Map<String, int> objectToReturn = {'x': 0, 'y': 0};
    try {
      Map responseBody = jsonDecode(response.body);
      if (responseBody['data'] != null &&
          responseBody['data']['x'] != null &&
          responseBody['data']['y'] != null) {
        double responseX = responseBody['data']['x'];
        double responseY = responseBody['data']['y'];
        objectToReturn['x'] = (responseX / this.resolution).round();
        objectToReturn['y'] = (responseY / this.resolution).round();
      }
    } catch (err) {
      print('Error in MapAPI.getCurrentPosition():');
      print(err);
    }
    print(objectToReturn);
    return objectToReturn;
  }

  Future<void> startWallFollower() async {
    var url = 'http://' +
        this.ipAddress +
        ':' +
        this.portNumber.toString() +
        '/start/';
    var response = await http.post(url);
    Map responseBody = jsonDecode(response.body);
    print(responseBody);
  }

  Future<void> stopWallFollower() async {
    var url = 'http://' +
        this.ipAddress +
        ':' +
        this.portNumber.toString() +
        '/stop/';
    var response = await http.post(url);
    Map responseBody = jsonDecode(response.body);
    print(responseBody);
  }
}
