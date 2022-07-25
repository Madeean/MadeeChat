import 'dart:async';

import 'package:flutter/cupertino.dart';

class Debouncer {
  final int miliseconds;
  Timer? _timer;

  Debouncer({required this.miliseconds});

  run(VoidCallback action) {
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: miliseconds), action);
  }
}
