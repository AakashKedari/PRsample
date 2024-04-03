import 'package:flutter/material.dart';

class VerticalSlider extends StatefulWidget {
  @override
  _VerticalSliderState createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        value: _value,
        min: 0.0,
        max: 1.0,
        onChanged: (newValue) {
          setState(() {
            _value = newValue;
          });
        },
        activeColor: Colors.white,
        inactiveColor: Colors.grey[300],
      ),
    );
  }
}