// =============================================================================
// weather_utils.dart
//
// Integração com a API Open-Meteo para exibição do clima na tela inicial.
//
// Cache:
//   - Dados meteorológicos: SharedPreferences, expiram à meia-noite do dia atual
//   - Coordenadas GPS: SharedPreferences, expiram após 30 minutos (1.800.000 ms)
//
// Modelos de dados (definidos neste arquivo):
//   - [IWeather]:         dados do clima do momento atual + próximos 3 dias
//   - [IWeatherResponse]: resposta bruta da API Open-Meteo (dados horários/diários)
//   - [DailyWeather]:     resumo diário (min/max temperatura + código meteorológico)
//   - [IResponseError]:   exceção para erros da API
// =============================================================================

// Dart SDK
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

// SECTION: Geolocalização e cidade

/// Retorna o nome da cidade correspondente às coordenadas, ou null se indisponível.
Future<String?> getCityName(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      return placemarks.first.locality == "" || placemarks.first.locality == null ? placemarks.first.subAdministrativeArea : placemarks.first.locality;
    }
  } catch (e) {
    print("Erro ao buscar cidade: $e");
  }
  return null;
}

// SECTION: Gradiente e saudação

/// Retorna o gradiente do card de clima: azul (dia, antes das 18h) ou azul escuro (noite).
LinearGradient getGradient() {
  int hour = DateTime.now().hour;

  if (hour >= 18) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(224, 3, 46, 54),
        Color.fromARGB(255, 0, 20, 30),
      ],
      transform: GradientRotation(285 * 3.1415927 / 180),
    );
  } else {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(0, 180, 219, 1),
        Color.fromRGBO(0, 131, 176, 1),
      ],
      transform: GradientRotation(75 * 3.1415927 / 180),
    );
  }
}

/// Retorna a saudação personalizada para o usuário logado com base na hora do dia.
Future<String> getMessage() async {
  int hour = DateTime.now().hour;
  String? username = (await SessionUtils.getUser())?['name'];
  if (username == null || username.isEmpty) {
    if (hour >= 18) {
      return "Boa noite";
    } else if (hour >= 12) {
      return "Boa tarde";
    } else {
      return "Bom dia";
    }
  } else {
    if (hour >= 18) {
      return "Boa noite, $username";
    } else if (hour >= 12) {
      return "Boa tarde, $username";
    } else {
      return "Bom dia, $username";
    }
  }
}

// SECTION: Mapeamento de código meteorológico

/// Converte o [weathercode] da API Open-Meteo para o nome do asset SVG correspondente.
/// O nome retornado corresponde a um arquivo em assets/weather/.
String getWeatherIconByCode(int weathercode, bool isNight) {
  switch (weathercode) {
    case 0: // clear
      return 'clear-${isNight ? 'night' : 'day'}';
    case 1: // partly cloudy
      return 'partly-cloudy-${isNight ? 'night' : 'day'}';
    case 2: // fog
      return 'fog-${isNight ? 'night' : 'day'}';
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
      return 'clear-${isNight ? 'night' : 'day'}';
  }
}

// SECTION: Busca e cache de dados do clima

/// Busca os dados do clima para as coordenadas fornecidas.
///
/// Usa cache do SharedPreferences que expira à meia-noite do dia atual.
/// Se o cache ainda for válido, retorna os dados em cache sem chamada HTTP.
Future<IWeather> getWeather(double latitude, double longitude, int currentHour) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? cachedData = prefs.getString('weather_data');
  int? cacheTimestamp = prefs.getInt('weather_timestamp');

  int cacheDuration = 86400000 - (DateTime.now().millisecondsSinceEpoch % 86400000);
  int currentTime = DateTime.now().millisecondsSinceEpoch;

  if (cachedData != null && cacheTimestamp != null && (currentTime - cacheTimestamp < cacheDuration)) {
    final jsonMap = jsonDecode(cachedData);
    final weather = IWeather.fromJson(jsonMap);
    weather.city = await getCityName(latitude, longitude) ?? "Em casa?";
    return weather;
  }

  final weatherUrl = Uri.parse("https://api.open-meteo.com/v1/forecast");
  final weatherResponse =
      await http.get(weatherUrl.replace(queryParameters: {"latitude": latitude.toString(), "longitude": longitude.toString(), "hourly": "temperature_2m,weathercode", "daily": "temperature_2m_min,temperature_2m_max,weathercode", "timezone": "auto"}));

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
      }));

  final weather = getWeatherData(currentHour, response);
  weather.city = await getCityName(latitude, longitude) ?? "Em casa?";

  prefs.setString('weather_data', jsonEncode(weather.toJson()));
  prefs.setInt('weather_timestamp', currentTime);

  return weather;
}

/// Extrai os dados da hora atual da resposta bruta [response] e retorna um [IWeather].
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
    icon: getWeatherIconByCode(currentWeatherCode, currentHour >= 18),
    city: "",
    next3Days: next3Days,
  );
}

/// Converte o número do dia da semana (1=segunda … 7=domingo) para o nome em português.
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

/// Retorna as coordenadas GPS do usuário, usando cache de 30 minutos.
/// Solicita permissão de localização se necessário. Retorna null se negada.
Future<Map<String, double>?> getCoords() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double? latitude = prefs.getDouble('latitude');
  double? longitude = prefs.getDouble('longitude');
  int? cacheTimestamp = prefs.getInt('coords_timestamp');

  int currentTime = DateTime.now().millisecondsSinceEpoch;
  int cacheDuration = 1800000;

  if (latitude != null && longitude != null && cacheTimestamp != null && (currentTime - cacheTimestamp < cacheDuration)) {
    return {
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  LocationPermission permission = await Geolocator.requestPermission();

  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return null;
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  prefs.setDouble('latitude', position.latitude);
  prefs.setDouble('longitude', position.longitude);
  prefs.setInt('coords_timestamp', currentTime);

  return {
    "latitude": position.latitude,
    "longitude": position.longitude,
  };
}

// SECTION: Modelos de dados

/// Dados do clima do momento atual, incluindo temperatura e previsão dos próximos 3 dias.
class IWeather {
  final String time;
  final double temperature;
  final double temperatureMin;
  final double temperatureMax;
  final int weathercode;
  final String day;
  final String icon;
  String city;
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

  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'weathercode': weathercode,
      'day': day,
      'icon': icon,
      'city': city,
      'next3Days': next3Days.map((e) => e.toJson()).toList(),
    };
  }

  // Método para criar a partir de JSON
  factory IWeather.fromJson(Map<String, dynamic> json) {
    return IWeather(
      time: json['time'],
      temperature: (json['temperature'] as num).toDouble(),
      temperatureMin: (json['temperatureMin'] as num).toDouble(),
      temperatureMax: (json['temperatureMax'] as num).toDouble(),
      weathercode: json['weathercode'],
      day: json['day'],
      icon: json['icon'],
      city: json['city'],
      next3Days: (json['next3Days'] as List).map((e) => DailyWeather.fromJson(e)).toList(),
    );
  }
}

/// Resposta bruta da API Open-Meteo com dados horários e diários.
/// Processada por [getWeatherData] para gerar um [IWeather].
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

/// Resumo de um dia: temperaturas mínima/máxima e código meteorológico.
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

  Map<String, dynamic> toJson() => {
        "temperature2mMin": temperature2mMin,
        "temperature2mMax": temperature2mMax,
        "weathercode": weathercode,
        "time": time,
      };

  factory DailyWeather.fromJson(Map<String, dynamic> json) => DailyWeather(
        temperature2mMin: json["temperature2mMin"],
        temperature2mMax: json["temperature2mMax"],
        weathercode: json["weathercode"],
        time: json["time"],
      );
}

/// Exceção lançada quando a API Open-Meteo retorna um status diferente de 200.
class IResponseError implements Exception {
  final String message;

  IResponseError(this.message);
}
