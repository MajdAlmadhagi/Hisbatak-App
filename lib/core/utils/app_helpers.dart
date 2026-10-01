import 'package:flutter/material.dart';

class AppHelpers {

  ///Function to return user greeting message
  static String greetingMessage() {
    DateTime currentDateTime = DateTime.now();

    final int currentWeekDay = currentDateTime.weekday;

    final int currentHour = currentDateTime.hour;
    debugPrint('=============$currentHour===========');

    if (currentWeekDay == DateTime.friday) {
      return 'جمعة مباركة';
    } else {
      if (currentHour > 0 && currentHour < 12) {
        return 'صباح الخير 🌞';
      }
      return 'مساء الخير';
    }
  }
}
