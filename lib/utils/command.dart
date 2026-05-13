import 'package:flutter/foundation.dart';

import 'package:habitudes/domain/models/result.dart';

/// A [Command] wraps an async operation and exposes its lifecycle state:
/// [running], [error], and [completed].
///
/// Commands prevent double-execution while [running] is true.
///
/// Use [Command0] for actions with no arguments, and [Command1] for one argument.
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  bool get error => _result is Error<T>;
  bool get completed => _result is Ok<T>;

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command1] is like [Command0] but the wrapped action takes one argument.
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  bool get error => _result is Error<T>;
  bool get completed => _result is Ok<T>;

  Future<void> execute(A arg) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action(arg);
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
