import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = "ba64ff0d702293062b2cf4f82bb926c1";

  static Future<Map<String, dynamic>> getWeather({
    required double lat,
    required double lon,
  }) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon"
        "&units=metric&lang=ru&appid=$apiKey";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception("Ошибка получения погоды: ${res.body}");
    }

    return jsonDecode(res.body);
  }
}
