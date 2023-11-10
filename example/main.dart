// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:observable/observable.dart';

void main() {
  // Listen to an observable
  homeViewModel.count.watch((s) => print(s));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Granular rebuilds - Rebuilding only stateful elements in the tree.
        Observer(
          // Pattern match over
          (c) => switch (homeViewModel.count.state) {
            Some(value: var v) => Text('$v'),
            Waiting() => const Text('Waiting'),
            Error(error: var e, stackTrace: var s) => Text('Error${e}'),
            None() => const SizedBox.shrink(),
            _ => const SizedBox.shrink(),
          },
        ),
        ElevatedButton(
            onPressed: () => homeViewModel.inc(),
            child: const Text('Increase')),
        ElevatedButton(
            onPressed: () => homeViewModel.dec(),
            child: const Text('Decrease')),
      ],
    );
  }
}

class HomeViewModel {
  // Declare an observable with no initial value. Initialises in a state of [None].
  final count = Observable<int>();

  // Update based on the state of an observable.
  Future<void> inc() => switch (count.state) {
        Some(value: var v) => count.update(v + 1),
        _ => count.update(0),
      };

  // Optionally skip the waiting state
  Future<void> dec() => switch (count.state) {
        Some(value: var v) => count.update(v - 1, skipWaiting: true),
        _ => count.update(0, skipWaiting: true),
      };
}

final homeViewModel = HomeViewModel();

Future<int> getNumbers(int value, bool increase) async => await Future.delayed(
    const Duration(seconds: 1), () => increase ? value + 1 : value - 1);
