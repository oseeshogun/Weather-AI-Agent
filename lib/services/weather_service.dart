import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Weather data models
class WeatherData {
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final String description;
  final String icon;
  final double windSpeed;
  final int windDegree;
  final String cityName;
  final String countryCode;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.windDegree,
    required this.cityName,
    required this.countryCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    final sys = json['sys'];

    return WeatherData(
      temperature: main['temp'].toDouble(),
      feelsLike: main['feels_like'].toDouble(),
      tempMin: main['temp_min'].toDouble(),
      tempMax: main['temp_max'].toDouble(),
      pressure: main['pressure'],
      humidity: main['humidity'],
      description: weather['description'],
      icon: weather['icon'],
      windSpeed: wind['speed'].toDouble(),
      windDegree: wind['deg'],
      cityName: json['name'],
      countryCode: sys['country'],
    );
  }
}

class ForecastData {
  final String dateTime;
  final double temperature;
  final String description;
  final String icon;
  final double windSpeed;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.windSpeed,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];

    return ForecastData(
      dateTime: json['dt_txt'],
      temperature: main['temp'].toDouble(),
      description: weather['description'],
      icon: weather['icon'],
      windSpeed: wind['speed'].toDouble(),
    );
  }
}

class OpenWeatherMapService {
  static const String _apiKey = 'be2148b2c6ea291c1a976b10dce48dcc';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Units can be 'metric' or 'imperial'
  final String units;
  
  OpenWeatherMapService({this.units = 'metric'});

  // Get current weather by city name
  Future<WeatherData> getCurrentWeatherByCity(String city) async {
    final url = '$_baseUrl/weather?q=$city&appid=$_apiKey&units=$units';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // Get current weather by coordinates
  Future<WeatherData> getCurrentWeatherByCoordinates(double lat, double lon) async {
    final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=$units';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // Get 5-day forecast by city name
  Future<List<ForecastData>> getForecastByCity(String city) async {
    final url = '$_baseUrl/forecast?q=$city&appid=$_apiKey&units=$units';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) => ForecastData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }

  // Get 5-day forecast by coordinates
  Future<List<ForecastData>> getForecastByCoordinates(double lat, double lon) async {
    final url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=$units';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) => ForecastData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }

  // Get user's current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can get the location
    return await Geolocator.getCurrentPosition();
  }

  // Get weather for user's current location
  Future<WeatherData> getWeatherForCurrentLocation() async {
    try {
      final position = await getCurrentLocation();
      return getCurrentWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Error getting weather for current location: $e');
    }
  }

  // Get forecast for user's current location
  Future<List<ForecastData>> getForecastForCurrentLocation() async {
    try {
      final position = await getCurrentLocation();
      return getForecastByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Error getting forecast for current location: $e');
    }
  }

  // Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}

// Provider for the weather service
final weatherServiceProvider = Provider<OpenWeatherMapService>((ref) {
  return OpenWeatherMapService();
});

// Provider for current weather data (by city)
final currentWeatherProvider = FutureProvider.family<WeatherData, String>((ref, city) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getCurrentWeatherByCity(city);
});

// Provider for forecast data (by city)
final forecastProvider = FutureProvider.family<List<ForecastData>, String>((ref, city) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getForecastByCity(city);
});

// Provider for current location weather
final currentLocationWeatherProvider = FutureProvider<WeatherData>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getWeatherForCurrentLocation();
});

// Provider for current location forecast
final currentLocationForecastProvider = FutureProvider<List<ForecastData>>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getForecastForCurrentLocation();
});
