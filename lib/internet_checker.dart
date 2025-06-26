import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:offlineapp/main.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    Connectivity().onConnectivityChanged.listen((_) => _checkInternet());
  }

  Future<void> _checkInternet() async {
    final active =
        await InternetConnectionChecker.createInstance().hasConnection;
    setState(() => _hasInternet = active);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return const NoInternetScreen();
    }
    return widget.child;
  }
}

// class ConnectivityWrapper extends StatefulWidget {
//   final Widget connectedChild;

//   const ConnectivityWrapper({super.key, required this.connectedChild});

//   @override
//   State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
// }

// class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
//   late Stream<List<ConnectivityResult>> _connectivityStream;
//   bool _hasInternet = true;

//   @override
//   void initState() {
//     super.initState();
//     _connectivityStream = Connectivity().onConnectivityChanged;
//     _checkInternet(); // Initial check
//   }

//   Future<void> _checkInternet() async {
//     final hasInternet = await InternetConnectionChecker.createInstance().hasConnection;
//     setState(() => _hasInternet = hasInternet);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<ConnectivityResult>>(
//       stream:  Connectivity().onConnectivityChanged,
//       builder: (context, snapshot) {
//         // Only re-check when actual event comes
//         if (snapshot.hasData) {
//           _checkInternet();
//         }

//         return _hasInternet
//             ? widget.connectedChild
//             : NoInternetScreen(onRetry: _checkInternet);
//       },
//     );
//   }
// }

class NoInternetScreen extends StatelessWidget {
  // final VoidCallback onRetry;
  const NoInternetScreen({
    super.key,
    //required this.onRetry
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Attendance"),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AttendanceWidget(),
              CalenderWidget()
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 115,
              width: double.maxFinite,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,

                    child: Icon(
                      Icons.wifi_off,
                      size: 80,
                      color: Colors.grey.shade600.withOpacity(0.2),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No Internet Connection",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text("Retry", style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
