// main.dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'login_page.dart';
import 'screens/dashboard_page.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/api_config.dart';
import 'screens/notification_list_page.dart';
import 'theme/app_theme.dart';

const String oneSignalAppId = ApiConfig.oneSignalAppId;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize OneSignal first so it's ready for any subsequent calls
  OneSignal.Debug.setLogLevel(OSLogLevel.none); 
  OneSignal.initialize(oneSignalAppId);

  // 2. Load session (which may call _registerOneSignalIdentity)
  final bool isLoggedIn = await AuthService.loadSession();

  // Lapor ke backend saat user klik notifikasi pengumuman (read tracking).
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    final logId = data?['log_id'];
    
    if (logId != null) {
      NotificationService.markAsRead(logId.toString());
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  });

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiGapin',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      // Gunakan builder untuk membungkus seluruh navigasi dengan Guard Izin Notifikasi
      builder: (context, child) {
        return NotificationGuard(child: child!);
      },
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/notifications': (context) => const NotificationListPage(),
      },
    );
  }
}

/// Widget yang memaksa pengguna memberikan izin notifikasi.
/// Jika izin tidak diberikan, aplikasi akan menampilkan layar "Lock Screen".
class NotificationGuard extends StatefulWidget {
  final Widget child;
  const NotificationGuard({super.key, required this.child});

  @override
  State<NotificationGuard> createState() => _NotificationGuardState();
}

class _NotificationGuardState extends State<NotificationGuard> with WidgetsBindingObserver {
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cek ulang saat user kembali ke aplikasi (misal setelah buka settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    // Cek status izin saat ini via OneSignal SDK
    bool status = OneSignal.Notifications.permission;
    
    // Jika belum diizinkan, tampilkan dialog permintaan (hanya muncul jika belum ditolak permanen)
    if (!status) {
      status = await OneSignal.Notifications.requestPermission(true);
    }

    if (mounted) {
      setState(() {
        _hasPermission = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika izin belum diberikan, tampilkan layar peringatan yang memblokir akses
    if (!_hasPermission) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade800, Colors.red.shade900],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 100, color: Colors.white),
                  const SizedBox(height: 32),
                  const Text(
                    'IZIN NOTIFIKASI WAJIB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda wajib mengaktifkan notifikasi untuk menggunakan SiGapin.\n\nHal ini diperlukan agar Anda tidak melewatkan informasi darurat dan broadcast penting dari kampus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('BERIKAN IZIN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Jika dialog izin tidak muncul, harap buka:\nPengaturan HP > Aplikasi > SiGapin > Notifikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Jika sudah diizinkan, tampilkan konten asli aplikasi (Navigator/Routes)
    return widget.child;
  }
}
