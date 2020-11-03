import 'dart:convert';

import 'package:http/http.dart' as http;

class MapAPI {
  String ipAddress;
  int portNumber;
  Future<bool> testConnection(String ipAddress, int portNumber) async {
    this.ipAddress = ipAddress;
    this.portNumber = portNumber;

    if (ipAddress == '' || portNumber == 0) {
      return false;
    }

    var url = 'http://' + ipAddress + ':' + portNumber.toString();
    var response = await http.get(url);
    Map responseBody = jsonDecode(response.body);
    print(responseBody);
    if (responseBody['message'] == 'success') {
      return true;
    }
    return false;
  }

  Future<List<List<int>>> getMap() async {
    var url =
        'http://' + this.ipAddress + ':' + this.portNumber.toString() + '/map/';
    var response = await http.get(url);
    print(response.body);
    Map responseBody = jsonDecode(response.body);
    return responseBody['message']['map']['pgm'];
  }
}
