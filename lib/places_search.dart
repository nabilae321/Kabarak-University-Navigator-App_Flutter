import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class LocationService {
  final String key = 'YOUR_API_KEY';

  Future<String?> getPlaceId(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);

    if (json.containsKey('candidates') &&
        json['candidates'] is List &&
        json['candidates'].isNotEmpty) {
      var placeId = json['candidates'][0]['place_id'] as String;
      return placeId;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPlace(String input) async {
    final placeId = await getPlaceId(input);

    if (placeId != null) {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';

      var response = await http.get(Uri.parse(url));
      var json = convert.jsonDecode(response.body);

      if (json.containsKey('result')) {
        var results = json['result'] as Map<String, dynamic>;
        return results;
      }
    }

    return null;
  }
}
