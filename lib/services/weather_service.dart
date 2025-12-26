import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = 'd0aff145298685f074cad75889241b36';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<String?> getCurrentWeather(double latitude, double longitude) async {
    try {
      final url = '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cityName = data['name'];
        final weather = data['weather'][0]['main'];
        final temp = data['main']['temp'].round();
        final description = data['weather'][0]['description'];

        return '$cityName: $weather, ${temp}°C - $description';
      } else {
        return 'Weather unavailable';
      }
    } catch (e) {
      return 'Weather unavailable';
    }
  }
}
