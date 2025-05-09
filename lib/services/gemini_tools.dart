import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/weather_service.dart';
import '../utils/weather_formatter.dart';

part 'gemini_tools.g.dart';

class GeminiTools {
  GeminiTools(this.ref);

  final Ref ref;
  
  // Provider for logging state (you can implement this if needed)
  // final logStateNotifierProvider = StateNotifierProvider<LogStateNotifier, List<LogEntry>>((ref) => LogStateNotifier());

  // Weather fetch tool declaration
  FunctionDeclaration get fetchWeatherFuncDecl => FunctionDeclaration(
    'fetch_weather',
    'Fetch current weather information for a specific city',
    parameters: {
      'city': Schema.string(
        description: 'Name of the city to get weather information for',
      ),
    },
  );

  List<Tool> get tools => [
    Tool.functionDeclarations([fetchWeatherFuncDecl]),
  ];
  
  Future<Map<String, Object?>> handleFunctionCall(
    String functionName,
    Map<String, Object?> arguments,
  ) async {
    // You can implement logging here if needed
    // final logStateNotifier = ref.read(logStateNotifierProvider.notifier);
    // logStateNotifier.logFunctionCall(functionName, arguments);
    
    return switch (functionName) {
      'fetch_weather' => await handleFetchWeather(arguments),
      _ => handleUnknownFunction(functionName),
    };
  }

  Future<Map<String, Object?>> handleFetchWeather(Map<String, Object?> arguments) async {
    try {
      final String city = arguments['city'] as String;
      
      // Get the weather service from provider
      final weatherService = ref.read(weatherServiceProvider);
      
      // Fetch current weather data
      final weatherData = await weatherService.getCurrentWeatherByCity(city);
      
      // Fetch forecast data (limited to 5 items for brevity)
      final forecastData = await weatherService.getForecastByCity(city);
      final limitedForecast = forecastData.take(5).toList();
      
      // Format the response
      final currentWeatherText = WeatherFormatter.formatCurrentWeather(weatherData);
      final forecastText = WeatherFormatter.formatForecast(limitedForecast);
      
      // Combine the data
      final functionResults = {
        'success': true,
        'current_weather': {
          'city': weatherData.cityName,
          'country': weatherData.countryCode,
          'temperature': weatherData.temperature,
          'feels_like': weatherData.feelsLike,
          'description': weatherData.description,
          'humidity': weatherData.humidity,
          'wind_speed': weatherData.windSpeed,
          'icon': weatherData.icon,
        },
        'forecast': limitedForecast.map((item) => {
          'date_time': item.dateTime,
          'temperature': item.temperature,
          'description': item.description,
          'icon': item.icon,
          'wind_speed': item.windSpeed,
        }).toList(),
        'formatted_text': '$currentWeatherText\n\n$forecastText',
      };
      
      // You can implement logging here if needed
      // final logStateNotifier = ref.read(logStateNotifierProvider.notifier);
      // logStateNotifier.logFunctionResults(functionResults);
      
      return functionResults;
    } catch (e) {
      // You can implement logging here if needed
      // final logStateNotifier = ref.read(logStateNotifierProvider.notifier);
      // logStateNotifier.logError('Error fetching weather data: $e');
      
      return {
        'success': false,
        'reason': 'Error fetching weather data: $e',
      };
    }
  }

  Map<String, Object?> handleUnknownFunction(String functionName) {
    // You can implement logging here if needed
    // final logStateNotifier = ref.read(logStateNotifierProvider.notifier);
    // logStateNotifier.logWarning('Unsupported function call $functionName');
    
    return {
      'success': false,
      'reason': 'Unsupported function call $functionName',
    };
  }
}

@Riverpod(keepAlive: true)
GeminiTools geminiTools(Ref ref) => GeminiTools(ref);
