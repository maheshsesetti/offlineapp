import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
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
      home: const MyHomePage(title: 'Flutter Attendence List'),
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
  late Timer _timer;
  late String _currentTime;
  final Box<AttendanceModel> attendanceBox = Hive.box<AttendanceModel>(
    'attendanceBox',
  );
  final _nameController = TextEditingController(text: "Mahesh");

  @override
  void initState() {
     debugPrint("attendance list in hive ${attendanceBox.getAt(0)}");
    super.initState();
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkIn() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final entry = AttendanceModel(name: name, checkIn: DateTime.now());
      attendanceBox.add(entry);
      debugPrint("attendance list in hive $attendanceBox");
      _nameController.clear();
      setState(() {});
    }
  }


void _checkOut(int index) {
  final entry = attendanceBox.getAt(index);
  if (entry != null && entry.checkOut == null) {
    entry.checkOut = DateTime.now();
    entry.save(); // Save the update
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(8, 8),
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
                  Text(
                    "Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  attendanceBox.getAt(0)?.checkIn != null ? Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "Check In: ${attendanceBox.getAt(0)?.checkIn != null ? _formatDateTime(attendanceBox.getAt(0)!.checkIn!) : 'N/A'}"
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      attendanceBox.getAt(0)?.checkOut != null ? Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text("Check Out: ${attendanceBox.getAt(0)?.checkOut != null ? _formatDateTime(attendanceBox.getAt(0)!.checkOut!) : 'N/A'}"),
                        ),
                      ) :SizedBox(),
                    ],
                  ) :SizedBox(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size.fromWidth(double.maxFinite),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                     attendanceBox.getAt(0)?.checkIn == null? _checkIn() : _checkOut(0);
                    },
                    label: Text(attendanceBox.getAt(0)?.checkIn == null?"CheckIn" :"CheckOut"),
                    icon: Icon(Icons.calendar_month),
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: const Text('No Attendence List Found')),
        ],
      ),
    );
  }
}
