import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String description;
  final String emoji;
  final String main;
  final int humidity;
  final double windSpeed;

  const WeatherData({
    required this.temperature,
    required this.description,
    required this.emoji,
    required this.main,
    required this.humidity,
    required this.windSpeed,
  });
}

class WeatherService {
  Future<WeatherData> getWeather() async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=Miami,FL,US&appid=$apiKey&units=imperial',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final main = data['weather'][0]['main'] as String;
    return WeatherData(
      temperature: (data['main']['temp'] as num).toDouble(),
      description: data['weather'][0]['description'] as String,
      emoji: _emojiForMain(main),
      main: main,
      humidity: data['main']['humidity'] as int,
      windSpeed: (data['wind']['speed'] as num).toDouble(),
    );
  }

  static String _emojiForMain(String main) {
    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return '⛈️';
      case 'drizzle':
        return '🌦️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      default:
        return '🌫️';
    }
  }
}
