import 'package:flutter/cupertino.dart';
import 'package:house_price_prediction_app/screens/home/home_web.dart';

import '../responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      webLayout: HomeWeb(),
      mobileLayout: Placeholder(),
      tabletLayout: Placeholder(),
    );
  }
}
