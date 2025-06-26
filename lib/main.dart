import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:offlineapp/internet_checker.dart';
import 'package:offlineapp/model/attendance_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
        textTheme: GoogleFonts.poppinsTextTheme(),
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AttendanceWidget(),
          CalenderWidget(),
          // Expanded(flex: 2, child: const Text('No Attendence List Found')),
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

  dynamic lat = 0.0;
  dynamic lng = 0.0;

  @override
  void initState() {
   
    super.initState();
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
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  void _checkIn() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final today = _formatDate(DateTime.now());

    AttendanceModel? entry = attendanceBox.get(today);
    if (entry == null) {
      entry = AttendanceModel(
        name: name,
        checkIn: DateTime.now(),
        checkInLatitude: lat,
        checkInLongitude: lng,
        date: today,
      );
    } else {
      if (entry.checkIn == null) {
        entry.checkIn = DateTime.now();
        entry.checkInLatitude = lat;
        entry.checkInLongitude = lng;
      }
    }

    attendanceBox.put(today, entry);
    _nameController.clear();
    setState(() {});
  }

  void _checkOut() {
    final today = _formatDate(DateTime.now());

    AttendanceModel? entry = attendanceBox.get(today);
    if (entry == null) {
      entry = AttendanceModel(
        name: _nameController.text.trim(),
        checkOut: DateTime.now(),
        checkOutLatitude: lat,
        checkOutLongitude: lng,
        date: today,
      );
    } else {
      if (entry.checkOut == null) {
        entry.checkOut = DateTime.now();
        entry.checkOutLatitude = lat;
        entry.checkOutLongitude = lng;
      }
    }

    attendanceBox.put(today, entry);
    setState(() {});
  }

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

    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    lat = position.latitude;
    lng = position.longitude;
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text(
          "Location permission was denied. Try again by restarting the app.",
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
          "Please enable location permission manually from app settings.",
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = _formatDate(DateTime.now());
    final AttendanceModel? todayEntry = attendanceBox.get(today);

    

    final hasCheckedIn = todayEntry?.checkIn != null;
    final hasCheckedOut = todayEntry?.checkOut != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(8, 8),
            color: Colors.blue.withAlpha(30),
          ),
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
          const FittedBox(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          hasCheckedIn
              ? Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          "Check In: ${_formatDateTime(todayEntry!.checkIn!)}",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    hasCheckedOut
                        ? Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: Text(
                                "Check Out: ${_formatDateTime(todayEntry.checkOut!)}",
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ],
                )
              : const SizedBox(),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromWidth(double.maxFinite),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: !hasCheckedOut
                ? () {
                    handleLocationPermission();
                    if (!hasCheckedIn) {
                      _checkIn();
                    } else {
                      _checkOut();
                    }
                  }
                : null,
            label: Text(!hasCheckedIn ? "CheckIn" : "CheckOut"),
            icon: const Icon(Icons.calendar_month),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

class CalenderWidget extends StatefulWidget {
  const CalenderWidget({super.key});

  @override
  State<CalenderWidget> createState() => _CalenderWidgetState();
}

class _CalenderWidgetState extends State<CalenderWidget> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        child: SfCalendar(
          view: CalendarView.day,
           allowedViews: [
          CalendarView.day,
          CalendarView.week,
          CalendarView.workWeek,
          CalendarView.month,
          CalendarView.schedule,
          CalendarView.timelineDay,
          CalendarView.timelineWeek,
          CalendarView.timelineWorkWeek,
          CalendarView.timelineMonth
        ],
          dataSource: _getCalendarDataSource(),
          timeSlotViewSettings: const TimeSlotViewSettings(
            timeIntervalHeight: 100,
            startHour: 9,
            endHour: 20,
            nonWorkingDays: <int>[DateTime.saturday, DateTime.sunday]
          ),
        ),
      ),
    );
  }

  
}

_AppointmentDataSource _getCalendarDataSource() {
  List<Appointment> appointments = <Appointment>[];
  appointments.add(Appointment(
    startTime: DateTime.now(),
    endTime: DateTime.now().add(Duration(minutes: 10)),
    subject: 'Meeting',
    color: Colors.blue,
    startTimeZone: '',
    endTimeZone: '',
  ));

  return _AppointmentDataSource(appointments);
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source){
   appointments = source; 
  }
}
