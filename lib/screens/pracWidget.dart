import 'package:flutter/material.dart';
import 'package:prsample/customWidgets/colorDropDownWidget.dart';
import 'package:prsample/customWidgets/sizeDropDownbutton.dart';

class Practice extends StatefulWidget {
  const Practice({super.key});

  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Center(child: ColorDropdownButton()),
            IntegerDropdownButton()
          ],
        ),
      ),
    );
  }
}
