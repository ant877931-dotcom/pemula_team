import 'package:flutter/material.dart';
import 'package:midbank/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://hwvkzhcmgzrbsojsyzso.supabase.co',
    anonKey: 'sb_publishable_52JXlePIvKxODzfa-VWwDw_0-uTWyod',
  );

  await NotificationService.init(); 

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
    fontFamily: 'RobotoSlab',
  ),
    home: LoginScreen()
  )
  );
}
