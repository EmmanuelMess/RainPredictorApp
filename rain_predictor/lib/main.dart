import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:rain_predictor/forecast.dart';

const FORECAST_URL = "https://ws1.smn.gob.ar/v1/forecast/location/";

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
    // If the server did not return a 200 OK response,
    // then throw an exception.
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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
          _flutterLocalNotificationsPlugin,
          _platformChannelSpecifics,
          title: 'Configuración del Predictor de Lluvia',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationDetails _platformChannelSpecifics;

  MyHomePage(
      this._flutterLocalNotificationsPlugin,
      this._platformChannelSpecifics,
      {Key key, this.title}
      ) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(_flutterLocalNotificationsPlugin, _platformChannelSpecifics);
}

const String channel = "SINGLE";
const String channel_name = "Default channel";
const String channel_description = "Single channel";
const int id = 0;

class _MyHomePageState extends State<MyHomePage> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final NotificationDetails _platformChannelSpecifics;

  _MyHomePageState(this._flutterLocalNotificationsPlugin, this._platformChannelSpecifics) : super();

  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
