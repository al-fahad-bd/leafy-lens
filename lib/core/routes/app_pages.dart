import 'package:ai_design_with_plants/features/auth/signup_binding.dart';
import 'package:ai_design_with_plants/features/auth/signup_screen.dart';
import 'package:ai_design_with_plants/features/design/design_binding.dart';
import 'package:ai_design_with_plants/features/design/design_screen.dart';
import 'package:ai_design_with_plants/features/home/get_started_binding.dart';
import 'package:ai_design_with_plants/features/home/get_started_screen.dart';
import 'package:ai_design_with_plants/features/home/home_binding.dart';
import 'package:ai_design_with_plants/features/home/home_screen.dart';
import 'package:get/get.dart';

// Import screen and binding files here
// Example:
// import 'package:ai_design_with_plants/features/splash/splash_screen.dart';
// import 'package:ai_design_with_plants/features/splash/splash_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.getStarted;

  static final routes = <GetPage>[
    GetPage(
      name: Routes.getStarted,
      page: () => const GetStartedScreen(),
      binding: GetStartedBinding(),
    ),
    GetPage(
      name: Routes.signUp,
      page: () => const SignUpScreen(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.design,
      page: () => const DesignScreen(),
      binding: DesignBinding(),
    ),
    // Add other pages here
  ];
}
