import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

LinearGradient getGradient() {
  int hour = DateTime.now().hour;

  if (hour >= 18) {
    // Noite (após 18h)
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(224, 3, 46, 54), // rgb(3 46 54 / 88%)
        Color.fromARGB(255, 0, 20, 30), // rgb(0 20 30)
      ],
      transform: GradientRotation(285 * 3.1415927 / 180), // Rotação de 285 graus
    );
  } else {
    // Dia
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(0, 180, 219, 1), // rgb(0, 180, 219)
        Color.fromRGBO(0, 131, 176, 1), // rgb(0, 131, 176)
      ],
      transform: GradientRotation(75 * 3.1415927 / 180), // Rotação de 75 graus
    );
  }
}

String getMessage() {
  int hour = DateTime.now().hour;

  if (hour >= 18) {
    return "Boa noite!";
  } else if (hour >= 12) {
    return "Boa tarde!";
  } else {
    return "Bom dia!";
  }
}

String getWeatherIconByCode(int weathercode, bool isDay) {
  switch (weathercode) {
    case 0: // clear
      return 'clear-${isDay ? 'day' : 'night'}';
    case 1: // partly cloudy
      return 'partly-cloudy-${isDay ? 'day' : 'night'}';
    case 2: // fog
      return 'fog-${isDay ? 'day' : 'night'}';
    case 3: // drizzle
      return 'drizzle';
    case 4: // freezing drizzle
      return 'freezing-drizzle';
    case 5: // rain
      return 'rain';
    case 6: // freezing rain or snow
    case 7: // snow
      return 'snow';
    case 8: // snow grains or snow showers
    case 9: // snow showers
      return 'extreme-snow';
    case 10: // rain showers
      return 'extreme-rain';
    case 11: // thunderstorm
      return 'thunderstorm';
    case 12: // thunderstorm hail
      return 'extreme-thunderstorm';
    default:
      return 'clear-${isDay ? 'day' : 'night'}';
  }
}


Future<IWeather> getWeather(double latitude, double longitude, int currentHour) async {
  final weatherUrl = Uri.parse("https://api.open-meteo.com/v1/forecast");
  final weatherResponse = await http.get(weatherUrl.replace(queryParameters: {
    "latitude": latitude.toString(),
    "longitude": longitude.toString(),
    "hourly": "temperature_2m,weathercode",
    "daily": "temperature_2m_min,temperature_2m_max,weathercode",
    "timezone": "auto"
  }));

  if (weatherResponse.statusCode != 200) {
    throw jsonDecode(weatherResponse.body) as IResponseError;
  }

  final weatherData = jsonDecode(weatherResponse.body);
  final response = IWeatherResponse(
    time: List<String>.from(weatherData["hourly"]["time"]),
    temperature2m: List<double>.from(weatherData["hourly"]["temperature_2m"]),
    temperature2mMin: weatherData["daily"]["temperature_2m_min"][0],
    temperature2mMax: weatherData["daily"]["temperature_2m_max"][0],
    weathercode: List<int>.from(weatherData["hourly"]["weathercode"]),
    next3Days: List.generate(3, (index) {
      return DailyWeather(
        temperature2mMin: weatherData["daily"]["temperature_2m_min"][index + 1],
        temperature2mMax: weatherData["daily"]["temperature_2m_max"][index + 1],
        weathercode: weatherData["daily"]["weathercode"][index + 1],
        time: weatherData["daily"]["time"][index + 1],
      );
    })
  );

  final weather = getWeatherData(currentHour, response);

  return weather;
}

IWeather getWeatherData(int currentHour, IWeatherResponse response) {
  List<String> time = response.time.map((time) => time.split("T")[1].split(":")[0]).toList();
  int currentHourIndex = time.indexOf(currentHour.toString());

  if (currentHourIndex == -1) {
    currentHourIndex = 12;
  }

  final currentTemperature = response.temperature2m[currentHourIndex];
  final currentWeatherCode = response.weathercode[currentHourIndex];

  final next3Days = response.next3Days.map((dailyWeather) {
    return DailyWeather(
      temperature2mMin: dailyWeather.temperature2mMin,
      temperature2mMax: dailyWeather.temperature2mMax,
      weathercode: dailyWeather.weathercode,
      time: dailyWeather.time,
    );
  }).toList();

  return IWeather(
    time: response.time[currentHourIndex],
    temperature: currentTemperature,
    temperatureMin: response.temperature2mMin,
    temperatureMax: response.temperature2mMax,
    weathercode: currentWeatherCode,
    day: getDayOfWeek(DateTime.now().weekday),
    icon: getWeatherIconByCode(currentWeatherCode, currentHour < 18),
    city: "São Paulo",
    next3Days: next3Days,
  );
}

String getDayOfWeek(int day) {
  switch (day) {
    case 1:
      return "Segunda-feira";
    case 2:
      return "Terça-feira";
    case 3:
      return "Quarta-feira";
    case 4:
      return "Quinta-feira";
    case 5:
      return "Sexta-feira";
    case 6:
      return "Sábado";
    case 7:
      return "Domingo";
    default:
      return "";
  }
}

class IWeather {
  final String time;
  final double temperature;
  final double temperatureMin;
  final double temperatureMax;
  final int weathercode;
  final String day;
  final String icon;
  final String city;
  final List<DailyWeather> next3Days;

  IWeather({
    required this.time,
    required this.temperature,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.weathercode,
    required this.day,
    required this.icon,
    required this.city,
    required this.next3Days,
  });
}

class IWeatherResponse {
  final List<String> time;
  final List<double> temperature2m;
  final double temperature2mMin;
  final double temperature2mMax;
  final List<int> weathercode;
  final List<DailyWeather> next3Days;

  IWeatherResponse({
    required this.time,
    required this.temperature2m,
    required this.temperature2mMin,
    required this.temperature2mMax,
    required this.weathercode,
    required this.next3Days,
  });
}

class DailyWeather {
  final double temperature2mMin;
  final double temperature2mMax;
  final int weathercode;
  final String time;

  DailyWeather({
    required this.temperature2mMin,
    required this.temperature2mMax,
    required this.weathercode,
    required this.time,
  });
}

class IResponseError implements Exception {
  final String message;

  IResponseError(this.message);
}
