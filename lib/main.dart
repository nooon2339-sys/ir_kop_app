import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_v2ray_client/flutter_v2ray_client.dart';
import 'package:clipboard/clipboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IRKopApp());
}

class IRKopApp extends StatelessWidget {
  const IRKopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IR KOP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505), // مشکی عمیق
        primaryColor: const Color(0xFF00FF41), // سبز ماتریکسی
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          secondary: Color(0xFF00BFFF), // آبی سایبری
          surface: Color(0xFF111111),
        ),
        textTheme: GoogleFonts.orbitronTextTheme(Theme.of(context).textTheme),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF00FF41), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF050505),
          selectedItemColor: const Color(0xFF00FF41),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: 'CONNECTION',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'INFO',
            ),
          ],
        ),
      ),
    );
  }
}

// --- صفحه اصلی ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final V2ray _v2ray = V2ray();
  final TextEditingController _configController = TextEditingController();
  String _status = "DISCONNECTED";
  bool _isConnected = false;
  bool _isLoading = false;
  String _savedConfig = "";

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedConfig = prefs.getString('config') ?? "";
      if (_savedConfig.isNotEmpty) {
        _configController.text = _savedConfig;
      }
    });
  }

  Future<void> _saveConfig(String config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('config', config);
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      setState(() => _isLoading = true);
      await _v2ray.stopV2Ray();
      setState(() {
        _isConnected = false;
        _status = "DISCONNECTED";
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Connection Terminated", backgroundColor: Colors.red);
    } else {
      if (_configController.text.isEmpty) {
        Fluttertoast.showToast(msg: "Please enter a config first!");
        return;
      }
      setState(() => _isLoading = true);
      await _saveConfig(_configController.text);
      
      final permission = await _v2ray.requestPermission();
      if (permission) {
        await _v2ray.startV2Ray(
          remark: "IR KOP Server",
          config: _configController.text,
          proxyOnly: false,
        );
        setState(() {
          _isConnected = true;
          _status = "CONNECTED";
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: "Secure Connection Established", backgroundColor: const Color(0xFF00FF41));
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "VPN permission denied!");
      }
    }
  }

  Future<void> _pasteConfig() async {
    final text = await FlutterClipboard.paste();
    if (text.isNotEmpty) {
      _configController.text = text;
      setState(() {});
      Fluttertoast.showToast(msg: "Config pasted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // هدر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "IR KOP",
                    style: GoogleFonts.orbitron(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FF41),
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(),
                  const Icon(Icons.shield, color: Color(0xFF00BFFF), size: 30)
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white),
                ],
              ),
              const SizedBox(height: 40),

              // وضعیت
              Text(
                _status,
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? const Color(0xFF00FF41) : const Color(0xFFFF003C),
                  letterSpacing: 3,
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 40),

              // دکمه اتصال با افکت
              GestureDetector(
                onTap: _isLoading ? null : _toggleConnection,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected
                        ? const Color(0xFF00FF41).withOpacity(0.05)
                        : const Color(0xFFFF003C).withOpacity(0.05),
                    border: Border.all(
                      color: _isConnected
                          ? const Color(0xFF00FF41)
                          : const Color(0xFFFF003C),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isConnected
                            ? const Color(0xFF00FF41).withOpacity(0.4)
                            : const Color(0xFFFF003C).withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF00FF41))
                        : Icon(
                            Icons.power_settings_new,
                            size: 90,
                            color: _isConnected
                                ? const Color(0xFF00FF41)
                                : const Color(0xFFFF003C),
                          ),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
               .shimmer(duration: 3.seconds, color: Colors.white24),

              const SizedBox(height: 30),

              // فیلد کانفیگ
              TextField(
                controller: _configController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: "Paste vless:// or vmess:// here",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF00BFFF), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF111111), width: 1),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 15),

              // دکمه پیست
              ElevatedButton.icon(
                onPressed: _pasteConfig,
                icon: const Icon(Icons.paste, color: Color(0xFF00FF41)),
                label: Text(
                  "PASTE CONFIG",
                  style: GoogleFonts.orbitron(color: const Color(0xFF00FF41), fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF00FF41), width: 1),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// --- صفحه اطلاعات و تماس با ما ---
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _contactAdmin() async {
    final Uri url = Uri.parse('tel:+989025717696');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Fluttertoast.showToast(msg: "Cannot make call");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // لوگو یا آیکون
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF00FF41), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF41).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.security, size: 50, color: Color(0xFF00FF41)),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 20),
              Text(
                "IR KOP",
                style: GoogleFonts.orbitron(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00FF41),
                  letterSpacing: 3,
                ),
              ),
              const Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              
              const SizedBox(height: 40),
              
              // کارت تماس با ادمین
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      "DEVELOPER CONTACT",
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFF00BFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "+98 0902 571 7696",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _contactAdmin,
                      icon: const Icon(Icons.call, color: Color(0xFF00FF41)),
                      label: Text(
                        "CALL ADMIN",
                        style: GoogleFonts.orbitron(color: const Color(0xFF00FF41)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF050505),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF00FF41)),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              
              const Spacer(),
              Text(
                "Secure • Private • Fast",
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00BFFF),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
