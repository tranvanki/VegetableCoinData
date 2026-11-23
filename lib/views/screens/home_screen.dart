import 'package:flutter/material.dart' hide SearchBar;
import 'package:hhmmobile/views/screens/market/market_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    //safe Area on top
    return MarketScreen();
  }
}
