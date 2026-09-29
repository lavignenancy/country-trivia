import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/trivia_viewmodel.dart';
import 'views/trivia_view.dart';

void main() {
  runApp(const CountryTriviaApp());
}

class CountryTriviaApp extends StatelessWidget {
  const CountryTriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TriviaViewModel()..loadGame(),
      child: MaterialApp(
        title: 'Country Trivia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const TriviaView(),
      ),
    );
  }
}
