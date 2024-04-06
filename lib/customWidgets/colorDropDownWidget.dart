import 'package:flutter/material.dart';

class ColorDropdownButton extends StatefulWidget {
  @override
  _ColorDropdownButtonState createState() => _ColorDropdownButtonState();
}

class _ColorDropdownButtonState extends State<ColorDropdownButton> {
  String _selectedColor = 'Red';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedColor,
      hint: Text('Select a color'),
      onChanged: (value) {
        setState(() {
          _selectedColor = value!;
        });
      },
      items: [
        'Red',
        'Blue',
        'Green',
        'Yellow',
        'Purple',
        'Orange',
        'Pink',
        'Cyan',
        'Brown',
        'Black',
      ].map<DropdownMenuItem<String>>((String color) {
        return DropdownMenuItem<String>(
          value: color,
          child: Text(color),
        );
      }).toList(),
    );
  }
}
