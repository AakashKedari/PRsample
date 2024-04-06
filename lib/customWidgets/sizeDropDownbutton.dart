import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IntegerDropdownButton extends StatefulWidget {
  @override
  _IntegerDropdownButtonState createState() => _IntegerDropdownButtonState();
}

class _IntegerDropdownButtonState extends State<IntegerDropdownButton> {

  int _selectedInteger = 21;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: _selectedInteger,
      hint: const Text('Select an integer (21-40)'),
      onChanged: (value) {
        setState(() {
          _selectedInteger = value!;
        });
      },
      items: List.generate(20, (index) => index + 21)
          .map<DropdownMenuItem<int>>((integer) {
        return DropdownMenuItem<int>(
          value: integer,
          child: Text('$integer'),
        );
      }).toList(),
    );
  }
}