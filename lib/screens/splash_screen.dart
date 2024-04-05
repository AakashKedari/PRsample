import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prsample/screens/selectfiles.dart';
import '../colors.dart';

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SelectImageScreen()));
    });
    // checkInternetConnectivity();
  }

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
