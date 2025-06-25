import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:offlineapp/internet_checker.dart';
import 'package:offlineapp/model/attendance_model.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory dir = await getApplicationDocumentsDirectory();
  var path = dir.path;
  Hive
    ..init(path)
    ..registerAdapter(AttendanceModelAdapter());
  await Hive.openBox<AttendanceModel>("attendanceBox");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: ConnectivityWrapper(
        child: const MyHomePage(title: 'Flutter Attendence '),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AttendanceWidget(),
          Expanded(flex: 2, child: const Text('No Attendence List Found')),
        ],
      ),
    );
  }
}

class AttendanceWidget extends StatefulWidget {
  const AttendanceWidget({super.key});

  @override
  State<AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  late Timer _timer;
  late String _currentTime;
  final Box<AttendanceModel> attendanceBox = Hive.box<AttendanceModel>(
    'attendanceBox',
  );
  final _nameController = TextEditingController(text: "Mahesh");

  //bool isButtonEnabled = false;

  dynamic lat = 0.0;
  dynamic lng = 0.0;

  bool isFlag = false;

  @override
  void initState() {
    // debugPrint("attendance list in hive ${attendanceBox.getAt(0)}");
    super.initState();
    checkDate();
    //checkButtonState();
    Future.delayed(Duration.zero, () => handleLocationPermission());
    _currentTime = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  void _updateTime() {
    final String formattedDateTime = _formatDateTime(DateTime.now());
    setState(() {
      _currentTime = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime); // AM/PM format
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime); // AM/PM format
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkIn() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final entry = AttendanceModel(
        name: name,
        checkIn: DateTime.now(),
        checkInLatitude: lat,
        checkInLongitude: lng,
        date: _formatDate(DateTime.now()),
      );
      attendanceBox.add(entry);

      debugPrint("attendance list in hive $attendanceBox");
      _nameController.clear();
      checkDate();
      setState(() {});
    }
  }

  void _checkOut(int index) {
    final entry = attendanceBox.getAt(index);
    if (entry != null && entry.checkOut == null) {
      entry.checkOut = DateTime.now();
      entry.checkOutLatitude = lat;
      entry.checkOutLongitude = lng;
      entry.save();
      checkDate();
    }
  }

  void checkDate() {
    if (attendanceBox.values.isNotEmpty) {
      for (var e in attendanceBox.values) {
        if (e.date.toString() == _formatDate(DateTime.now())) {
          isFlag = true;
          break;
        }
      }
    }
  }

  // void checkButtonState() {
  //   final now = DateTime.now();
  //   final targetTime = DateTime(now.year, now.month, now.day + 1, 0, 1);

  //   if (now.isAfter(targetTime)) {
  //     setState(() => isButtonEnabled = true);
  //   } else {
  //     final duration = targetTime.difference(now);
  //     Timer(duration, () {
  //       setState(() => isButtonEnabled = true);
  //     });
  //   }
  // }

  Future<void> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showServiceDisabledDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.denied) {
      _showPermissionDeniedDialog();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    // All good, proceed
    Position position = await Geolocator.getCurrentPosition();
    lat = position.latitude;
    lng = position.longitude;
    print("User location: $position");
  }

  Future<void> _showServiceDisabledDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Location Disabled"),
        content: const Text(
          "Please enable location services to use this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  Future<void> _showRationaleDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Location Permission Needed"),
        content: const Text(
          "This app needs your location permission to function properly. Please allow location access.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text(
          "Location permission was denied. You can try again by restarting the app.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Permanently Denied"),
        content: const Text(
          "Location permission is permanently denied. Please enable it manually in app settings.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(offset: Offset(8, 8), color: Colors.blue.withAlpha(30)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueAccent, Colors.blue.shade200],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: Text(
              "Attendance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.cover,
            child: Text(
              _currentTime,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          attendanceBox.isNotEmpty &&
                  attendanceBox.getAt(0)?.checkIn != null &&
                  isFlag
              ? Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          "Check In: ${attendanceBox.getAt(0)?.checkIn != null ? _formatDateTime(attendanceBox.getAt(0)!.checkIn!) : 'N/A'}",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    attendanceBox.isNotEmpty &&
                            attendanceBox.getAt(0)?.checkOut != null &&
                            isFlag
                        ? Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: Text(
                                  "Check Out: ${attendanceBox.getAt(0)?.checkOut != null ? _formatDateTime(attendanceBox.getAt(0)!.checkOut!) : 'N/A'}",
                                ),
                              ),
                            ),
                          )
                        : SizedBox(),
                  ],
                )
              : SizedBox(),
          SizedBox(height: 5),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              fixedSize: Size.fromWidth(double.maxFinite),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed:
                attendanceBox.isEmpty ||
                    attendanceBox.getAt(0)?.checkOut == null ||
                    !isFlag
                ? () {
                    if (attendanceBox.isEmpty ||
                        attendanceBox.getAt(0)?.checkIn == null) {
                      handleLocationPermission();
                      _checkIn();
                    } else {
                      handleLocationPermission();
                      _checkOut(0);
                    }
                  }
                : null,
            label: Text(
              attendanceBox.isEmpty || attendanceBox.getAt(0)?.checkIn == null
                  ? "CheckIn"
                  : "CheckOut",
            ),
            icon: Icon(Icons.calendar_month),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}
