import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'style_selection_screen.dart';
import 'utils/ad_native.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'subscription_screen.dart';
import 'provider/subscription_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  
  const isDebug = !bool.fromEnvironment('dart.vm.product');
  
  // config.jsonからRevenueCatのAPIキーを読み込む
  final config = await loadConfig();
  final configuration = PurchasesConfiguration(
    Platform.isAndroid
      ? config['revenueCatApiKeyAndroid']
      : config['revenueCatApiKeyiOS'],
  );
  
  String appUserId = await _getOrCreateAppUserId();
  
  await Purchases.configure(configuration..appUserID = appUserId);
  
  Purchases.setDebugLogsEnabled(isDebug);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// config.jsonを読み込む関数
Future<Map<String, dynamic>> loadConfig() async {
  final configString = await rootBundle.loadString('assets/config.json');
  return json.decode(configString);
}

Future<String> _getOrCreateAppUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? appUserId = prefs.getString('app_user_id');
  
  if (appUserId == null) {
    appUserId = const Uuid().v4();
    await prefs.setString('app_user_id', appUserId);
  }
  
  return appUserId;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleShift: AI Photo Transformer',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StyleSelectionScreen(image: _image!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StyleShift',
          style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pacifico'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'privacy':
                  _launchPrivacyPolicy();
                  break;
                case 'subscription':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(),
                    ),
                  );
                  break;
                case 'review':
                  _requestReview();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'privacy',
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'subscription',
                child: Text(
                  'Subscription 👑',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'review',
                child: Text(
                  'Write a Review',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.image,
              size: MediaQuery.of(context).size.height * 0.25,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('Select a photo to apply style ✨'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'Choose Photo',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Take Photo',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 8),
            if (subscriptionState.value == true)
              const Text('You are a subscriber!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 24),)
            else
              const NativeAdWidget()
          ],
        ),
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url =
        Uri.parse('https://tsutsunoidoblog.com/style-shift-privacy-policy/');
    if (!await launchUrl(url)) {
      throw Exception('プライバシーポリシーページを開けませんでした');
    }
  }

  Future<void> _requestReview() async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  @override
  void initState() {
    super.initState();
    Purchases.addCustomerInfoUpdateListener(_customerInfoUpdated);
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      // final offerings = await Purchases.getOfferings();
      // print(offerings.current);
      // print(offerings.all);
      // print(offerings.current?.monthly?.storeProduct.priceString);
    } catch (e) {
      print('Error fetching offerings: $e');
    }
  }

  @override
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoUpdated);
    super.dispose();
  }

  void _customerInfoUpdated(CustomerInfo info) {
    ref.read(subscriptionProvider.notifier).checkSubscription();
  }
}