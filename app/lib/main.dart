import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'data/services/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const _LogObserver();
  final store = await LocalStore.create();
  runApp(StockMarketApp(store: store));
}

class _LogObserver extends BlocObserver {
  const _LogObserver();
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
