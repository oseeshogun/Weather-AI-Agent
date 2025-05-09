import '../services/weather_service.dart';

class WeatherFormatter {
  // Format current weather data for chat display
  static String formatCurrentWeather(WeatherData weather, {bool isFrench = true}) {
    final temp = weather.temperature.toStringAsFixed(1);
    final feelsLike = weather.feelsLike.toStringAsFixed(1);
    final description = weather.description;
    final humidity = weather.humidity.toString();
    final windSpeed = weather.windSpeed.toStringAsFixed(1);
    
    if (isFrench) {
      return '''
Météo actuelle à ${weather.cityName}, ${weather.countryCode}:
🌡️ Température: $temp°C
🤔 Ressenti: $feelsLike°C
🌥️ Conditions: $description
💧 Humidité: $humidity%
💨 Vent: $windSpeed m/s
''';
    } else {
      return '''
Current weather in ${weather.cityName}, ${weather.countryCode}:
🌡️ Temperature: $temp°C
🤔 Feels like: $feelsLike°C
🌥️ Conditions: $description
💧 Humidity: $humidity%
💨 Wind: $windSpeed m/s
''';
    }
  }

  // Format forecast data for chat display
  static String formatForecast(List<ForecastData> forecast, {bool isFrench = true, int days = 3}) {
    // Group forecast by day (limit to specified number of days)
    final Map<String, List<ForecastData>> dailyForecasts = {};
    
    for (var item in forecast) {
      // Extract date from datetime string (format: "2023-05-09 12:00:00")
      final date = item.dateTime.split(' ')[0];
      
      if (!dailyForecasts.containsKey(date)) {
        if (dailyForecasts.length >= days) continue; // Skip if we already have enough days
        dailyForecasts[date] = [];
      }
      
      dailyForecasts[date]?.add(item);
    }
    
    // Format the output
    final StringBuffer result = StringBuffer();
    
    if (isFrench) {
      result.writeln('Prévisions pour les prochains jours:');
    } else {
      result.writeln('Forecast for the coming days:');
    }
    
    dailyForecasts.forEach((date, items) {
      // Calculate average temperature and find most common condition
      double avgTemp = 0;
      Map<String, int> conditionCount = {};
      
      for (var item in items) {
        avgTemp += item.temperature;
        
        if (!conditionCount.containsKey(item.description)) {
          conditionCount[item.description] = 0;
        }
        conditionCount[item.description] = (conditionCount[item.description] ?? 0) + 1;
      }
      
      avgTemp /= items.length;
      
      // Find most common condition
      String? mostCommonCondition;
      int maxCount = 0;
      
      conditionCount.forEach((condition, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonCondition = condition;
        }
      });
      
      // Format date
      final dateParts = date.split('-');
      final formattedDate = '${dateParts[2]}/${dateParts[1]}';
      
      if (isFrench) {
        result.writeln('📅 $formattedDate: ${avgTemp.toStringAsFixed(1)}°C, $mostCommonCondition');
      } else {
        result.writeln('📅 $formattedDate: ${avgTemp.toStringAsFixed(1)}°C, $mostCommonCondition');
      }
    });
    
    return result.toString();
  }

  // Extract city name from user message
  static String? extractCityFromMessage(String message) {
    // Common patterns for city mentions in weather queries
    final List<RegExp> patterns = [
      // French patterns
      RegExp(r"(?:météo|temps|climat|température).*?(?:à|a|en|pour|dans|de)\s+([A-Za-z\s]+?)(?:\s+(?:aujourd'hui|demain|ce soir|cette semaine|\?|\.|,|$))", caseSensitive: false),
      // English patterns
      RegExp(r"(?:weather|temperature|forecast|climate).*?(?:in|at|for|of)\s+([A-Za-z\s]+?)(?:\s+(?:today|tomorrow|this morning|tonight|now|\?|\.|,|$))", caseSensitive: false),
      // Question patterns
      RegExp(r"(?:comment|what|how).*?(?:est|is).*?(?:météo|temps|weather).*?(?:à|a|en|in|at)\s+([A-Za-z\s]+?)(?:\s+(?:\?|\.|,|$))", caseSensitive: false),
      // Simple location patterns
      RegExp(r"(?:à|a|in|at)\s+([A-Za-z\s]+?)(?:\s+(?:aujourd'hui|demain|today|tomorrow|\?|\.|,|$))", caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null && match.groupCount >= 1) {
        String city = match.group(1)!.trim();
        // Clean up the city name
        city = city.replaceAll(RegExp(r"(\?|\.|,|!)$"), '').trim();
        return city;
      }
    }
    
    return null;
  }
  
  // Determine if a message is asking about weather
  static bool isWeatherQuery(String message) {
    final weatherKeywords = [
      // French keywords
      'météo', 'temps', 'climat', 'température', 'pluie', 'neige', 'orage',
      'ensoleillé', 'nuageux', 'humidité', 'vent', 'prévision', 'degrés',
      // English keywords
      'weather', 'temperature', 'climate', 'rain', 'snow', 'storm', 'sunny',
      'cloudy', 'humidity', 'wind', 'forecast', 'degrees', 'celsius', 'fahrenheit'
    ];
    
    final lowerMessage = message.toLowerCase();
    
    for (var keyword in weatherKeywords) {
      if (lowerMessage.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
}
