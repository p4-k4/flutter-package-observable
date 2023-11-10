// ignore_for_file: null_check_on_nullable_type_parameter, prefer_final_fields, unused_local_variable

library observable;

import 'dart:async';

import 'package:flutter/material.dart';

sealed class ObservableState<T> {
  ObservableState();

  factory ObservableState.from(T value) {
    if (value != null && T != bool) {
      return Some<T>(value);
    } else if (value != null && T == bool) {
      if (value as bool) {
        return True<T>();
      } else {
        return False<T>();
      }
    } else {
      return None<T>();
    }
  }
}

class True<T> extends ObservableState<T> {}

class False<T> extends ObservableState<T> {}

class Some<T> extends ObservableState<T> {
  Some(this.value);
  T value;
}

class None<T> extends ObservableState<T> {}

class Waiting<T> extends ObservableState<T> {}

class Error<T> extends ObservableState<T> {
  Error(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

class ErrorWithValue<T> extends ObservableState<T> {
  ErrorWithValue(this.last, this.error, this.stackTrace);
  T last;
  final Object error;
  final StackTrace stackTrace;
}

/// A generic class to represent an observable object that notifies observers
/// and watchers upon state changes. It holds a value of type [T] and maintains
/// its state as [ObservableState].
class Observable<T> {
  /// Creates an instance of [Observable] with an optional initial value.
  /// If the initial value is provided and is of type bool, it initializes
  /// the state accordingly.
  ///
  /// If the initial value is `null`, it initializes the state to [None].
  /// If the initial value is `true` or `false` and [T] is bool, it initializes
  /// the state to [True] or [False], respectively.
  /// Otherwise, it initializes the state to [Some] with the provided value.
  Observable([
    this._value,
  ]) {
    if (_value != null && T == bool && _value == false) _state = False<T>();
    if (_value != null && T == bool && _value == true) _state = True<T>();
    if (_value != null && T != bool) _state = Some<T>(_value!);
  }

  /// The internal value of the observable of type [T].
  T? _value;

  /// The current state of the observable represented as [ObservableState].
  ObservableState<T> _state = None<T>();

  /// A list of observers that are notified whenever the state changes.
  final _observers = <ObserverState>[];

  /// A list of watcher functions that are called whenever the state changes.
  final _watchers = <void Function(ObservableState<T> state)>[];

  /// Initializes the observable by setting its state based on the result
  /// of the provided asynchronous function [initialiseWith].
  ///
  /// If [initialiseWith] completes successfully, the state is set to [Some]
  /// with the resultant value. If it fails, the state is set to [Error].
  @Deprecated('Currently not available!')
  Future<void> init(FutureOr<T> Function() initialiseWith) async {
    try {
      _state = Some<T>(await initialiseWith());
      _notifyObservers();
      _notifyWatchers();
    } catch (e, s) {
      _state = Error<T>(e, s);
      _notifyObservers();
      _notifyWatchers();
    }
  }

  /// Resets the observable's state to [None] and notifies observers.
  void reset() {
    _state = None();
    _notifyObservers();
  }

  /// Registers a watcher function [func] that gets called whenever the state changes.
  void watch(void Function(ObservableState<T> state) func) {
    _watchers.add(func);
  }

  /// Notifies all registered watchers with the current state.
  _notifyWatchers() {
    for (final watcher in _watchers) {
      watcher(_state);
    }
  }

  ObservableState<T> get state {
    _registerObserver();
    return _state;
  }

  Future<void> update(
    FutureOr<T> newValue, {
    bool skipWaiting = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (_state is Waiting) return;

    T? withValue;
    if (_state is Some) withValue = (_state as Some).value;

    try {
      final ObservableState<T> previousState = _state;

      if (!skipWaiting) {
        _state = Waiting<T>();
        _notifyObservers();
      }

      final result = await newValue;
      _state = ObservableState.from(result);
      _notifyObservers();
      _notifyWatchers();
    } catch (e, s) {
      onError?.call(e, s);
      if (withValue != null) {
        _state = ErrorWithValue<T>(withValue, e, s);
      } else {
        _state = Error<T>(e, s);
      }
      _notifyObservers();
    }
  }

  /// Removes an observer from the list of registered observers.
  void _removeObserver(ObserverState observer) {
    _observers.remove(observer);
  }

  /// Registers the current observer if it's not already registered.
  void _registerObserver() {
    final currentObserver = ObserverState.current;
    if (currentObserver != null && !_observers.contains(currentObserver)) {
      _observers.add(currentObserver);
      currentObserver.addObservable<T>(this);
    }
  }

  /// Notifies all registered observers that the state has changed.
  void _notifyObservers() {
    for (final observer in _observers) {
      observer.update();
    }
  }
}

class Observer extends StatefulWidget {
  const Observer(this.builder, {super.key});
  final Widget Function(BuildContext context) builder;
  static ObserverState? current;

  @override
  ObserverState createState() => ObserverState();
}

class ObserverState extends State<Observer> {
  static ObserverState? current;
  List<Observable> observables = [];

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  void addObservable<T>(Observable<T> observable) {
    observables.add(observable);
  }

  @override
  void dispose() {
    for (var observable in observables) {
      observable._removeObserver(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previousObserver = current;
    current = this;
    var builtWidget = widget.builder(context);
    current = previousObserver;
    return builtWidget;
  }
}
