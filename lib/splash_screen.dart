import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prsample/selectfiles.dart';

import 'colors.dart';
// import 'package:paper_reels/colors.dart';
// import 'package:paper_reels/consts.dart';
// import 'package:paper_reels/features/presentation/page/local_reel_screen/local_reel.dart';
// import 'package:paper_reels/features/presentation/page/select_files/selectfiles.dart';
// import 'package:paper_reels/features/services/notification_services/notification_services.dart';

// User? user = FirebaseAuth.instance.currentUser;

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SelectImageScreen()));
    });
    // checkInternetConnectivity();
  }

  // Future<void> checkInternetConnectivity() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //
  //   if (connectivityResult == ConnectivityResult.none) {
  //     if (kDebugMode) {
  //       print("Nointernet conection found");
  //     }
  //     // No internet connection, show a dialog
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => AlertDialog(
  //         title: Text('No Internet Connection'),
  //         content: Text('Please check your internet connection and try again.'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               // Close the app if there's no internet connection
  //               Navigator.of(context).pop();
  //               SystemNavigator.pop();
  //             },
  //             child: Text('Exit'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } else {
  //     // Internet connection is available, proceed with the splash screen
  //     Timer(const Duration(seconds: 2), checkingTheSavedData);
  //   }
  // }

  void checkingTheSavedData() async {

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SelectImageScreen()));
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VideoScreen('')));

    // print("user.....$user");
    // if (user == null) {
    //   print("object........$user");
    //   // Navigator.pushReplacement(
    //   //     context,
    //   //     PageTransition(
    //   //         child: enterPhoneNumber(),
    //   //         type: PageTransitionType.rightToLeft));
    //   Navigator.pushReplacementNamed(context, PageConst.enterPhoneNumber);
    // } else {
    //   final snapshot = await FirebaseFirestore.instance
    //       .collection('Users')
    //       .doc(FirebaseAuth.instance.currentUser!.uid)
    //       .get();
    //
    //   // print("snapshot.error....${snapshot.error}");
    //   print("snapshot.data....${snapshot.data}");
    //
    //   if (!snapshot.exists) {
    //     print('User document does not exist');
    //
    //     Navigator.pushReplacementNamed(context, PageConst.enterPhoneNumber);
    //
    //     return;
    //   }
    //   final userDoc = snapshot.data() as Map<String, dynamic>;
    //   if (userDoc == null) {
    //     print('User document is null');
    //     // Navigator.of(context).pushReplacement(
    //     //   CustomPageRoute(child: const enterPhoneNumber()),
    //     // );
    //     Navigator.pushReplacementNamed(context, PageConst.enterPhoneNumber);
    //
    //     return;
    //   }
    //
    //   final userType = userDoc['UserType'] as String?;
    //   final contentCreatorProfileStatus =
    //       userDoc['contentCreatorProfileStatus'] as String?;
    //   final userLanguage = userDoc['userLanguage'] as String?;
    //
    //   if (userType == null) {
    //     print('User type is null');
    //     // Navigator.of(context).pushReplacement(
    //     //   CustomPageRoute(child: const enterPhoneNumber()),
    //     // );
    //     Navigator.pushReplacementNamed(context, PageConst.enterPhoneNumber);
    //   } else if (userType == 'PaperReader') {
    //     print('User is a PaperReader');
    //     SendNotification(navigatorKey: navigatorKey).initialize();
    //
    //     Navigator.pushReplacementNamed(
    //       context,
    //       PageConst.bottomNavigationDrawer,
    //       arguments: {
    //         'language': userLanguage,
    //         'selectedIndex': 0,
    //       },
    //     );
    //   } else if (userType == 'ContentCreator' &&
    //       contentCreatorProfileStatus == 'Pending') {
    //     SendNotification(navigatorKey: navigatorKey).initialize();
    //
    //     Navigator.pushReplacementNamed(
    //       context,
    //       PageConst.bottomNavigationDrawer,
    //       arguments: {
    //         'language': userLanguage,
    //         'selectedIndex': 0,
    //       },
    //     );
    //   } else if (userType == 'ContentCreator' &&
    //       contentCreatorProfileStatus == 'Approved') {
    //
    //     SendNotification(navigatorKey: navigatorKey).initialize();
    //
    //
    //     Navigator.pushReplacementNamed(
    //       context,
    //       PageConst.contentCreatorBottomNavigationScreen,
    //       arguments: {
    //         'language': userLanguage,
    //         'selectedIndex': 0,
    //       },
    //     );
    //   } else {
    //     print('Unknown user type');
    //     Navigator.pushReplacementNamed(context, PageConst.enterPhoneNumber);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            Image.asset(
              'assets/pr_logo.png',
              width: 200,
              color: primarySwatch,
            ),
          ],
        ),
      ),
    );
  }
}
