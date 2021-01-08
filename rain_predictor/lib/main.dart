import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:rain_predictor/forecast.dart';

const FORECAST_URL = "https://ws1.smn.gob.ar/v1/forecast/location/";

const String channel = "SINGLE";
const String channel_name = "Default channel";
const String channel_description = "Single channel";
const int id = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher_foreground');
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: selectNotification,
  );

  const androidPlatformChannelSpecifics = AndroidNotificationDetails(
    channel,
    channel_name,
    channel_description,
    importance: Importance.low,
    priority: Priority.defaultPriority,
    showWhen: false,
    ongoing: true,
    enableVibration: false,
    visibility: NotificationVisibility.public,
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_foreground')
  );
  const platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  runApp(MyApp(flutterLocalNotificationsPlugin, platformChannelSpecifics));
}

Future selectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: $payload');
  }
}

Future<Forecast> fetchForecast(int days) async {
  final rosarioId = 2278;
  final response = await http.get(
    '$FORECAST_URL$rosarioId',
    headers: {
      "Authorization": "JWT eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3ZWIiLCJzY29wZXMiOiJST0xFX1VTRVJfRk9SRUNBU1QsUk9MRV9VU0VSX0dFT1JFRixST0xFX1VTRVJfSElTVE9SWSxST0xFX1VTRVJfSU1BR0VTLFJPTEVfVVNFUl9NQVAsUk9MRV9VU0VSX1NUQVRJU1RJQ1MsUk9MRV9VU0VSX1dBUk5JTkcsUk9MRV9VU0VSX1dFQVRIRVIiLCJpYXQiOjE2MTAxMTIxMTYsImV4cCI6MTYxMDE5ODUxNn0.fkOYzNVN1KriOKtHnPi0mDKgNmnrj_QdM3vrGytvpFc",
    }
  );

  if (response.statusCode == 200) {
    return Forecast.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}

List<int> getRainProbabilities(Forecast forecast) {
  final probabitiesPerDay = forecast.forecastData.map(
          (forecastData) =>
          [
            forecastData.earlyMorningProbStart,
            forecastData.earlyMorningProbEnd,
            forecastData.morningProbStart,
            forecastData.morningProbEnd,
            forecastData.afternoonProbStart,
            forecastData.afternoonProbEnd,
            forecastData.nightProbStart,
            forecastData.nightProbEnd,
          ]
              .map((e) => e == null ? -1 : e)
              .reduce(max)
  ).toList();

  return probabitiesPerDay;
}

String stringForDay(int rainDay) {
  final now = DateTime.now();
  final dateFormat = DateFormat('EEEE');

  switch(rainDay) {
    case -1:
      return "No hay lluvia";
    case 0:
      return "Hoy";
    case 1:
      return "Mañana";
    case 2:
      return "Pasado Mañana";
    case 3:
    case 4:
    case 5:
    case 6:
      return dateFormat.format(now.add(Duration(days: rainDay)));
  }
}

String stringForProbability(int maxProbability) {
  if(maxProbability <= 10) {
    return "No hay lluvia";
  }

  if(maxProbability <= 40) {
    return "Lluvia improbable";
  }

  if(maxProbability <= 70) {
    return "Lluvia probable";
  }

  return "Llueve casi seguro";
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationDetails _platformChannelSpecifics;

  const MyApp(this._flutterLocalNotificationsPlugin, this._platformChannelSpecifics);

  void _notif() async {
    final forecast = await fetchForecast(1);
    final rainProbabilities = getRainProbabilities(forecast);
    final maxRainProbability = rainProbabilities.reduce(max);
    final rainDay = rainProbabilities.indexOf(maxRainProbability);

    await _flutterLocalNotificationsPlugin.show(
      id,
      stringForDay(rainDay),
      stringForProbability(maxRainProbability),
      _platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    _notif();

    return MaterialApp(
      title: 'Predictor de Lluvia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
          title: 'Configuración del Predictor de Lluvia',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  _MyHomePageState() : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(),
    );
  }
}
