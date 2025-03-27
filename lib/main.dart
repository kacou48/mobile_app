import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/accounts/screen/change_password.dart';
import 'package:tadiago/accounts/screen/dashbord.dart';
import 'package:tadiago/accounts/screen/favorite.dart';
import 'package:tadiago/accounts/screen/login_screen.dart';
import 'package:tadiago/accounts/screen/signup_screen.dart';
import 'package:tadiago/accounts/screen/verify_code.dart';
import 'package:tadiago/annonces/providers/ads_provider.dart';
import 'package:tadiago/annonces/screen/ads_attachement.dart';
import 'package:tadiago/annonces/screen/details_ads.dart';
import 'package:tadiago/annonces/screen/save_ads.dart';
import 'package:tadiago/annonces/screen/update_my_ads.dart';
import 'package:tadiago/annonces/screen/vendor_public_profile.dart';
import 'package:tadiago/chat/providres/chats_provider.dart';
import 'package:tadiago/chat/screen/my_chat_room.dart';
import 'package:tadiago/chat/screen/user_notification.dart';
import 'package:tadiago/components/ads_list.dart';
import 'package:tadiago/home/main_home_screen.dart';
import 'package:tadiago/home/policy_terme.dart';
import 'package:tadiago/more/providers/other_provider.dart';
import 'package:tadiago/more/screen/contact_us.dart';
import 'package:tadiago/more/screen/signale_abus.dart';
import 'package:tadiago/splash/splash_screen.dart';

void main() async {
  // Initialiser Flutter avant d'exécuter l'application
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => ChatsProvider()),
        ChangeNotifierProvider(create: (_) => OtherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tadiago',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          navigatorKey: navigatorKey,
          initialRoute: authProvider.user != null ? "/main_home_page" : "/",
          routes: {
            '/': (context) => SplashScreen(),
            '/main_home_page': (context) => const MainHomeScreen(),
            '/login_page': (context) => const LoginScreen(),
            '/register_page': (context) => const SignupScreen(),
            '/change_password': (context) => const ChangePassword(),
            '/verify_code_page': (context) => const VerifyCode(),
            '/mes_preferences': (context) => const Favorite(),
            '/update_my_ads': (context) => const UpdateMyAds(),
            '/ads_list': (context) => const AdsList(),
            '/detail_ads': (context) => const DetailAds(),
            '/public_vendor': (context) => const VendorPublicProfile(),
            '/publier_une_annones': (context) => const SaveAds(),
            '/ads_attachement': (context) => const AdsAttachement(),
            '/tableau_de_bord': (context) => const Dashbord(),
            '/user_notification': (context) => const UserNotification(),
            '/nous_contacter': (context) => const ContactUs(),
            '/signaler_abus': (context) => const SignaleAbus(),
            '/policy_terme': (context) => const PolicyTerme(),
            '/my_chat_room': (context) => const MyChatRoom(),
          },
        );
      },
    );
  }
}
