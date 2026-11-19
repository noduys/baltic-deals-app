import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'barcode_scanner_page.dart';
import 'widgets/empty_state.dart';
import 'price_alerts_page.dart';
import 'l10n/app_localizations.dart';

final ValueNotifier<Locale?> _appLocaleNotifier = ValueNotifier<Locale?>(null);
const String _webVapidKey =
    'BAeMMjHE9TkBtALMEoekwr0FlmgyjY6eeo03QFnlGFoqs8XNVY9mRYx4lqrLiCoRaoNT411Q7djVorhbuGLB6MI';

final GlobalKey<NavigatorState> _globalNavigatorKey = GlobalKey<NavigatorState>();

// Кэш скидок главной страницы с временем жизни
List<Product>? _cachedHomeDiscounts;

Future<String> _getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('device_id');
  if (existing != null && existing.isNotEmpty) return existing;

  final created = 'bd-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}';
  await prefs.setString('device_id', created);
  return created;
}

Future<void> _registerPushToken(String token) async {
  try {
    final deviceId = await _getDeviceId();
    final response = await http.post(
      Uri.parse('https://baltic-deals-api.noduys.workers.dev/push-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'deviceId': deviceId}),
    );

    debugPrint('Push token register status: ${response.statusCode}');
    debugPrint('Push token register body: ${response.body}');
  } catch (error, stackTrace) {
    debugPrint('Push token register error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _handlePushMessage(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'price_alert') return;

  final productIdStr = data['productId']?.toString();
  if (productIdStr == null || productIdStr.isEmpty) return;
  final productId = int.tryParse(productIdStr);
  if (productId == null || productId <= 0) return;

  try {
    final uri = Uri.parse(
      'https://baltic-deals-api.noduys.workers.dev/offers?productId=$productId',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return;

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final productJson = decoded['product'] as Map<String, dynamic>?;
    if (productJson == null) return;

    final product = Product.fromJson(productJson);

    final navigator = _globalNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          imageUrl: product.imageUrl ?? '',
          isFavorite: false,
          onFavorite: () {},
          onOpenStore: () {},
          priceFormatter: (v) => v.toStringAsFixed(2),
        ),
      ),
    );
  } catch (e) {
    debugPrint('handlePushMessage error: $e');
  }
}

Future<void> _setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken(vapidKey: _webVapidKey);

    if (token == null || token.isEmpty) {
      debugPrint('FCM TOKEN: не получен');
    } else {
      debugPrint('FCM TOKEN: $token');
      await _registerPushToken(token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM MESSAGE RECEIVED');
      debugPrint('FCM message id: ${message.messageId}');
      debugPrint('FCM title: ${message.notification?.title}');
      debugPrint('FCM body: ${message.notification?.body}');
      debugPrint('FCM data: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM OPENED APP: ${message.data}');
      _handlePushMessage(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM INITIAL MESSAGE: ${initialMessage.data}');
      _handlePushMessage(initialMessage);
    }

    messaging.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('FCM TOKEN REFRESHED: $newToken');
        await _registerPushToken(newToken);
      },
      onError: (Object error) {
        debugPrint('FCM token refresh error: $error');
      },
    );
  } catch (error, stackTrace) {
    debugPrint('FCM setup error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BalticDealsApp());

  await _setupFirebaseMessaging();
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProductsPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final String splashImage = localeCode == 'ru'
        ? 'assets/images/splash_ru.jpg'
        : 'assets/images/splash_en.jpg';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(splashImage, fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Container(height: 6, color: Colors.white),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 6,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BalticDealsApp extends StatefulWidget {
  const BalticDealsApp({super.key});

  @override
  State<BalticDealsApp> createState() => _BalticDealsAppState();
}

class _BalticDealsAppState extends State<BalticDealsApp> {
  @override
  void initState() {
    super.initState();
    _loadLocale();
    _appLocaleNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _appLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');
    if (code != null && code.isNotEmpty) {
      _appLocaleNotifier.value = Locale(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: _appLocaleNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: _globalNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Baltic Deals',
          locale: locale,
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'Baltic Deals',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: ThemeMode.system,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF176B5B),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F6F7),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF176B5B),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121415),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

enum SortMode {
  discountHigh,
  savingsHigh,
  priceLow,
  priceHigh,
  brand,
}

class AppProductImagePlaceholder extends StatelessWidget {
  const AppProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/illustrations/product.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.offline,
      subtitle: message,
      actionLabel: AppLocalizations.of(context)!.retry,
      onAction: onRetry,
    );
  }
}

class AppDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AppDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? brand;
  final String? category;
  final String? gender;
  final String? imageUrl;
  final String? productUrl;
  final String storeName;
  final String country;
  final double currentPrice;
  final bool hasCoupon;
  final double? oldPrice;
  final String currency;
  final int? discountPercent;
  final int storesCount;
  final double savingsAmount;
  final String? homeSection;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.gender,
    required this.imageUrl,
    required this.productUrl,
    required this.storeName,
    required this.country,
    required this.currentPrice,
    required this.oldPrice,
    required this.currency,
    required this.discountPercent,
    required this.hasCoupon,
    required this.storesCount,
    required this.savingsAmount,
    required this.homeSection,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id']?.toString() ?? '') ??
          int.tryParse(json['product_id']?.toString() ?? '') ??
          0,
      name: json['name']?.toString() ?? 'Без названия',
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      gender: json['gender']?.toString(),
      imageUrl: json['image_url']?.toString(),
      productUrl: json['product_url']?.toString(),
      storeName: json['store_name']?.toString() ?? 'Магазин',
      country: json['country']?.toString() ?? 'EE',
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '') ?? 0,
      oldPrice: double.tryParse(json['old_price']?.toString() ?? ''),
      currency: json['currency']?.toString() ?? 'EUR',
      discountPercent: int.tryParse(json['discount_percent']?.toString() ?? ''),
      hasCoupon: (json['has_coupon']?.toString() == '1') || (json['has_coupon'] == true),
      storesCount: int.tryParse(json['stores_count']?.toString() ?? '') ?? 1,
      savingsAmount: double.tryParse(json['savings_amount']?.toString() ?? '') ?? 0,
      homeSection: json['home_section']?.toString(),
    );
  }
}

class ProductsPage extends StatefulWidget {
  final String? initialStore;
  final String? storeTitle;

  const ProductsPage({
    super.key,
    this.initialStore,
    this.storeTitle,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool get isStoreCatalog => widget.initialStore != null;
  static const String apiBase = 'https://br-divine-cherry-b9sd15fj-outletapi.compute.c-7.eu-central-1.aws.neon.tech';
  static const int pageSize = 40;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? searchDebounce;
  Timer? priceDebounce;

  String _lastSearchQuery = '';

  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;

  List<Product> products = [];
  int productsRequestId = 0;
  List<Product> homeCheapest = [];
  bool homeCheapestLoading = true;
  Set<int> favoriteIds = {};
  bool showFavoritesOnly = false;

  String selectedCategory = 'all';
  String selectedGender = 'all';
  String selectedBrand = 'all';
  String selectedStore = 'all';
  int selectedMinDiscount = 0;
  SortMode selectedSort = SortMode.discountHigh;
  bool multiStoreOnly = false;

  final ValueNotifier<double> _updateProgress = ValueNotifier(0.0);

  Future<void> _downloadAndInstall(String apkUrl) async {
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Требуется разрешение на установку приложений'),
            ),
          );
          return;
        }
      }
    }

    _updateProgress.value = 0.0;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Загрузка обновления'),
        content: ValueListenableBuilder<double>(
          valueListenable: _updateProgress,
          builder: (_, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value > 0 ? value : null),
              const SizedBox(height: 12),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/baltic_deals_update.apk';
      await Dio().download(
        apkUrl,
        apkPath,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) _updateProgress.value = received / total;
        },
      );
      
        if (!context.mounted) return;
        Navigator.pop(context);

      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка установки: ${result.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  Future<void> checkForAppUpdate({bool manual = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_update_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Проверяем не чаще раза в 24 часа, если пользователь не нажал "вручную"
      if (!manual && now - lastCheck < 24 * 60 * 60 * 1000) {
        return;
      }
      await prefs.setInt('last_update_check', now);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final uri = Uri.parse('$apiBase/app-version');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version']?.toString() ?? '';
        final downloadUrl =
            data['apk_url']?.toString() ?? data['url']?.toString() ?? '';

        bool isNewer(String current, String latest) {
          final c = current.split('.').map(int.tryParse).toList();
          final l = latest.split('.').map(int.tryParse).toList();
          for (var i = 0; i < 3; i++) {
            final cPart = i < c.length ? (c[i] ?? 0) : 0;
            final lPart = i < l.length ? (l[i] ?? 0) : 0;
            if (lPart > cPart) return true;
            if (lPart < cPart) return false;
          }
          return false;
        }

        if (latestVersion.isNotEmpty && isNewer(currentVersion, latestVersion)) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Color(0xFF176B5B)),
                  SizedBox(width: 10),
                  Text('Обновление приложения'),
                ],
              ),
              content: Text(
                'Доступна новая версия: $latestVersion.\n'
                'Установленная версия: $currentVersion.\n\n'
                'Хотите загрузить обновление сейчас?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Позже'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Обновить'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (downloadUrl.isNotEmpty) {
                      _downloadAndInstall(downloadUrl);
                    }
                  },
                ),
              ],
            ),
          );
        } else if (manual) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('У вас установлена последняя версия')),
          );
        }
      }
    } catch (_) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось проверить наличие обновлений')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedStore = widget.initialStore ?? 'all';
    scrollController.addListener(_onScroll);
    loadFavorites();
    loadProducts(reset: true);
    if (!isStoreCatalog) {
      loadHomeCheapest();
    }
    checkForAppUpdate();
  }

  Future<void> _saveHomeToCache(List<Product> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((p) => {
      'id': p.id,
      'name': p.name,
      'brand': p.brand,
      'category': p.category,
      'gender': p.gender,
      'image_url': p.imageUrl,
      'product_url': p.productUrl,
      'store_name': p.storeName,
      'country': p.country,
      'current_price': p.currentPrice,
      'old_price': p.oldPrice,
      'currency': p.currency,
      'discount_percent': p.discountPercent,
      'stores_count': p.storesCount,
      'savings_amount': p.savingsAmount,
      'home_section': p.homeSection,
    }).toList();
    await prefs.setString('home_cache', jsonEncode(jsonList));
  }

  Future<List<Product>> _loadHomeFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('home_cache');
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => Product.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      loadMore();
    }
  }

    Future<void> loadHomeCheapest({bool force = false}) async {
    // 1. Если кэш в памяти есть — используем его
    if (!force && _cachedHomeDiscounts != null) {
      setState(() {
        homeCheapest = _cachedHomeDiscounts!;
        homeCheapestLoading = false;
      });
      return;
    }

    // 2. Если кэша в памяти нет — грузим из SharedPreferences (мгновенно)
    if (!force) {
      final localCache = await _loadHomeFromCache();
      if (localCache.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          homeCheapest = localCache;
          homeCheapestLoading = false;
        });
      }
    }

    // 3. Идем в сеть за свежими данными
    try {
      const sections = <String, String>{
        'beauty': 'beauty',
        'fashion': 'clothing',
        'shoes': 'shoes',
        'tech': 'electronics',
      };

      final futures = sections.entries.map((entry) async {
        final uri = Uri.parse('$apiBase/products').replace(
          queryParameters: {
            'category': entry.value,
            'limit': '20',
            'offset': '0',
          },
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) return <Product>[];

        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final items = decoded['products'] as List<dynamic>? ?? const [];

        return items.map((item) {
          final json = Map<String, dynamic>.from(item as Map<String, dynamic>);
          json['home_section'] = entry.key;
          return Product.fromJson(json);
        }).toList();
      }).toList();

      final results = await Future.wait(futures);
      final loaded = results.expand((list) => list).toList();

      loaded.sort((a, b) {
        final discountCompare = (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0);
        if (discountCompare != 0) return discountCompare;
        final savingsCompare = b.savingsAmount.compareTo(a.savingsAmount);
        if (savingsCompare != 0) return savingsCompare;
        return a.currentPrice.compareTo(b.currentPrice);
      });

      _cachedHomeDiscounts = loaded;
      await _saveHomeToCache(loaded);

      if (!mounted) return;

      setState(() {
        homeCheapest = loaded;
        homeCheapestLoading = false;
      });
    } catch (e) {
      debugPrint('Home discounts load error: $e');
      if (!mounted) return;
      setState(() {
        homeCheapestLoading = false;
      });
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList('favorite_product_ids') ?? [];

    if (!mounted) return;

    setState(() {
      favoriteIds = values.map(int.tryParse).whereType<int>().toSet();
    });
  }

  Future<void> toggleFavorite(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      if (favoriteIds.contains(product.id)) {
        favoriteIds.remove(product.id);
      } else {
        favoriteIds.add(product.id);
      }
    });

    await prefs.setStringList(
      'favorite_product_ids',
      favoriteIds.map((id) => '$id').toList(),
    );
  }

  Future<void> loadProducts({required bool reset}) async {
    final requestId = ++productsRequestId;

    if (reset) {
      setState(() {
        loadingMore = false;
        error = null;
        hasMore = true;
        loading = products.isEmpty;
      });
    }

    final offset = reset ? 0 : products.length;

    try {
      final queryParameters = <String, String>{
        'limit': '$pageSize',
        'offset': '$offset',
      };

      final search = searchController.text.trim();
      if (search.isNotEmpty) queryParameters['search'] = search;
      if (selectedCategory != 'all') queryParameters['category'] = selectedCategory;
      if (selectedGender != 'all') queryParameters['gender'] = selectedGender;
      if (selectedBrand != 'all') queryParameters['brand'] = selectedBrand;
      if (selectedStore != 'all') queryParameters['store'] = selectedStore;

      final minPrice = double.tryParse(minPriceController.text.trim());
      final maxPrice = double.tryParse(maxPriceController.text.trim());

      if (minPrice != null) queryParameters['minPrice'] = '$minPrice';
      if (maxPrice != null) queryParameters['maxPrice'] = '$maxPrice';
      if (selectedMinDiscount > 0) queryParameters['minDiscount'] = '$selectedMinDiscount';

      if (multiStoreOnly || selectedSort == SortMode.savingsHigh) {
        queryParameters['multiStoreOnly'] = 'true';
      }

      if (selectedSort == SortMode.savingsHigh) {
        queryParameters['sort'] = 'savings';
      }

      final uri = Uri.parse('$apiBase/products').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('API ответил с ошибкой: ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = decoded['products'] as List<dynamic>? ?? [];

      final loadedProducts = items
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted || requestId != productsRequestId) return;

      setState(() {
        if (reset) {
          products = loadedProducts;
        } else {
          products.addAll(loadedProducts);
        }
        loading = false;
        loadingMore = false;
        hasMore = loadedProducts.length == pageSize;
      });
    } catch (e) {
      if (!mounted || requestId != productsRequestId) return;
      setState(() {
        loading = false;
        loadingMore = false;
        error = e.toString();
      });
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    setState(() {
      loadingMore = true;
    });
    await loadProducts(reset: false);
  }

  Future<void> refreshProducts() async {
    if (!isStoreCatalog) {
      loadHomeCheapest(force: true);
    }
    await loadProducts(reset: true);
  }

  List<Product> get visibleProducts {
    final result = products.where((product) {
      if (!showFavoritesOnly) return true;
      return favoriteIds.contains(product.id);
    }).toList();

    switch (selectedSort) {
      case SortMode.savingsHigh:
        result.sort((a, b) => b.savingsAmount.compareTo(a.savingsAmount));
        break;
      case SortMode.discountHigh:
        result.sort((a, b) {
          final discountCompare =
              (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0);
          if (discountCompare != 0) return discountCompare;
          return a.currentPrice.compareTo(b.currentPrice);
        });
        break;
      case SortMode.priceLow:
        result.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case SortMode.priceHigh:
        result.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case SortMode.brand:
        result.sort((a, b) {
          final brandA = (a.brand ?? '').toLowerCase();
          final brandB = (b.brand ?? '').toLowerCase();
          final brandCompare = brandA.compareTo(brandB);
          if (brandCompare != 0) return brandCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return result;
  }

  void onSearchChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _lastSearchQuery) return; // Пропускаем дублирующие вызовы

    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _lastSearchQuery = trimmed;
      loadProducts(reset: true);
    });
  }

  void onPriceChanged(String value) {
    priceDebounce?.cancel();
    priceDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      loadProducts(reset: true);
    });
  }

  List<String> get availableBrands {
    final brands = products
        .map((product) => product.brand?.trim())
        .whereType<String>()
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return brands;
  }

  void resetFilters() {
    searchDebounce?.cancel();
    _lastSearchQuery = '';
    setState(() {
      searchController.clear();
      minPriceController.clear();
      maxPriceController.clear();
      selectedCategory = 'all';
      selectedGender = 'all';
      selectedBrand = 'all';
      selectedStore = widget.initialStore ?? 'all';
      selectedMinDiscount = 0;
      selectedSort = SortMode.discountHigh;
      multiStoreOnly = false;
    });
    loadProducts(reset: true);
  }

  void openDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          imageUrl: product.imageUrl ?? '',
          isFavorite: favoriteIds.contains(product.id),
          onFavorite: () => toggleFavorite(product),
          onOpenStore: () => openProduct(product),
          priceFormatter: price,
        ),
      ),
    );
  }

  Future<void> openProduct(Product product) async {
    final value = product.productUrl;
    if (value == null || value.isEmpty) {
      showMessage('Ссылка на товар отсутствует');
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) {
      showMessage('Некорректная ссылка на товар');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened) {
      showMessage('Не удалось открыть страницу магазина');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String price(double value) {
    return value.toStringAsFixed(2);
  }

  List<Product> _homeProductsFor(String section) {
    final items =
        homeCheapest.where((product) => product.homeSection == section).toList();

    items.sort((a, b) {
      final discountCompare =
          (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0);
      if (discountCompare != 0) return discountCompare;

      final savingsCompare = b.savingsAmount.compareTo(a.savingsAmount);
      if (savingsCompare != 0) return savingsCompare;

      return a.currentPrice.compareTo(b.currentPrice);
    });

    return items.take(10).toList();
  }

  Widget _buildHomeSection({
    required String section,
    required String title,
    required IconData icon,
  }) {
    final items = _homeProductsFor(section);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 310,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 600
                    ? (constraints.maxWidth * 0.45).clamp(220.0, 320.0)
                    : 220.0;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return SizedBox(
                      width: cardWidth,
                      child: ProductCard(
                        product: product,
                        imageUrl: product.imageUrl ?? '',
                        isFavorite: favoriteIds.contains(product.id),
                        onFavorite: () => toggleFavorite(product),
                        onDetails: () => openDetails(product),
                        priceFormatter: price,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openStoreCatalog(String store) {
    final title = store.replaceAll(' Estonia', '');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductsPage(
          initialStore: store,
          storeTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = visibleProducts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.storeTitle ?? 'Baltic Deals',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: showFavoritesOnly
                ? AppLocalizations.of(context)!.showAll
                : AppLocalizations.of(context)!.favorites,
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.refresh,
            onPressed: refreshProducts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.trackPrice,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PriceAlertsPage()),
              );
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.checkUpdates,
            icon: const Icon(Icons.system_update_alt),
            onPressed: () => checkForAppUpdate(manual: true),
          ),
          PopupMenuButton<String?>(
            tooltip: AppLocalizations.of(context)!.language,
            icon: const Icon(Icons.language),
            onSelected: (langCode) async {
              if (langCode == 'about') {
                final info = await PackageInfo.fromPlatform();
                if (!mounted) return;
                showAboutDialog(
                  context: context,
                  applicationName: 'Baltic Deals',
                  applicationVersion: '${info.version} (${info.buildNumber})',
                  applicationIcon: const Icon(Icons.local_offer, color: Color(0xFF176B5B)),
                );
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              if (langCode == null || langCode.isEmpty) {
                await prefs.remove('app_locale');
                _appLocaleNotifier.value = null;
              } else {
                await prefs.setString('app_locale', langCode);
                _appLocaleNotifier.value = Locale(langCode);
              }
            },
            itemBuilder: (menuContext) => [
              PopupMenuItem(
                value: null,
                child: Text(AppLocalizations.of(context)!.systemLanguage),
              ),
              PopupMenuItem(
                value: 'ru',
                child: Text(AppLocalizations.of(context)!.russian),
              ),
              PopupMenuItem(
                value: 'et',
                child: Text(AppLocalizations.of(context)!.estonian),
              ),
              PopupMenuItem(
                value: 'lv',
                child: Text(AppLocalizations.of(context)!.latvian),
              ),
              PopupMenuItem(
                value: 'lt',
                child: Text(AppLocalizations.of(context)!.lithuanian),
              ),
              PopupMenuItem(
                value: 'en',
                child: Text(AppLocalizations.of(context)!.english),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('О приложении'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/baltic-deals-bg-new.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.30),
            ),
          ),
          loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF176B5B)),
                      const SizedBox(height: 20),
                      Text(
                        'Загружаем товары...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              : error != null && products.isEmpty
                  ? AppErrorView(
                      message: error!,
                      onRetry: refreshProducts,
                    )
                  : Column(
                      children: [
                        if (showFavoritesOnly)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Row(
                              children: [
                                const Icon(Icons.favorite),
                                const SizedBox(width: 8),
                                Text(
                                  'Избранное: ${favoriteIds.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showFavoritesOnly = false;
                                    });
                                  },
                                  child: const Text('Показать все'),
                                ),
                              ],
                            ),
                          ),
                        FiltersBar(
                          searchController: searchController,
                          minPriceController: minPriceController,
                          maxPriceController: maxPriceController,
                          selectedCategory: selectedCategory,
                          selectedGender: selectedGender,
                          selectedBrand: selectedBrand,
                          selectedStore: selectedStore,
                          availableBrands: availableBrands,
                          selectedMinDiscount: selectedMinDiscount,
                          selectedSort: selectedSort,
                          multiStoreOnly: multiStoreOnly,
                          onMultiStoreOnlyChanged: (value) {
                            setState(() {
                              multiStoreOnly = value;
                            });
                            loadProducts(reset: true);
                          },
                          onSearchChanged: onSearchChanged,
                          onCategoryChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedCategory = value;
                            });
                            loadProducts(reset: true);
                          },
                          onGenderChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedGender = value;
                            });
                            loadProducts(reset: true);
                          },
                          onBrandChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedBrand = value;
                            });
                            loadProducts(reset: true);
                          },
                          onStoreChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedStore = value;
                            });
                            loadProducts(reset: true);
                          },
                          onMinPriceChanged: onPriceChanged,
                          onMaxPriceChanged: onPriceChanged,
                          onDiscountChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedMinDiscount = value;
                            });
                            loadProducts(reset: true);
                          },
                          onSortChanged: (value) {
                            if (value == null) return;
                            final previousSort = selectedSort;
                            setState(() {
                              selectedSort = value;
                            });
                            if (previousSort == SortMode.savingsHigh ||
                                value == SortMode.savingsHigh) {
                              loadProducts(reset: true);
                            }
                          },
                          onReset: resetFilters,
                          onOpenStoreCatalog: _openStoreCatalog,
                          resultCount: filteredProducts.length,
                          loadedCount: products.length,
                          showStoreFilter: true,
                        ),
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? EmptyView(
                                  hasMore: hasMore,
                                  loadingMore: loadingMore,
                                  onLoadMore: loadMore,
                                )
                              : RefreshIndicator(
                                  onRefresh: refreshProducts,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double width = constraints.maxWidth;

                                      final int columns;
                                      if (isStoreCatalog) {
                                        if (width >= 1200) {
                                          columns = 4;
                                        } else if (width >= 750) {
                                          columns = 3;
                                        } else {
                                          columns = 2;
                                        }
                                      } else {
                                        columns = 1;
                                      }

                                      final double aspectRatio;
                                      if (columns == 1) {
                                        aspectRatio = 0.68;
                                      } else if (columns >= 3) {
                                        aspectRatio = 0.65;
                                      } else {
                                        aspectRatio = 0.60;
                                      }

                                      return CustomScrollView(
                                        controller: scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        slivers: [
                                          if (!isStoreCatalog &&
                                              homeCheapest.isNotEmpty)
                                            SliverToBoxAdapter(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  20,
                                                  20,
                                                  20,
                                                  6,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      AppLocalizations.of(context)!.weeklyTopDeals,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      AppLocalizations.of(context)!.homeSubtitle,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 18),
                                                    _buildHomeSection(
                                                      section: 'beauty',
                                                      title: AppLocalizations.of(context)!.beauty,
                                                      icon: Icons.spa_outlined,
                                                    ),
                                                    _buildHomeSection(
                                                      section: 'fashion',
                                                      title: AppLocalizations.of(context)!.clothing,
                                                      icon: Icons.checkroom_outlined,
                                                    ),
                                                    _buildHomeSection(
                                                      section: 'shoes',
                                                      title: AppLocalizations.of(context)!.shoes,
                                                      icon: Icons.shopping_bag_outlined,
                                                    ),
                                                    _buildHomeSection(
                                                      section: 'tech',
                                                      title: AppLocalizations.of(context)!.technology,
                                                      icon: Icons.devices_outlined,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (isStoreCatalog ||
                                              searchController.text.trim().isNotEmpty ||
                                              selectedCategory != 'all' ||
                                              selectedGender != 'all' ||
                                              selectedBrand != 'all' ||
                                              selectedStore != 'all' ||
                                              minPriceController.text.trim().isNotEmpty ||
                                              maxPriceController.text.trim().isNotEmpty ||
                                              selectedMinDiscount > 0 ||
                                              showFavoritesOnly)
                                            SliverPadding(
                                              padding: const EdgeInsets.fromLTRB(
                                                20,
                                                20,
                                                20,
                                                10,
                                              ),
                                              sliver: SliverGrid(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: columns,
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                  childAspectRatio: aspectRatio,
                                                ),
                                                delegate:
                                                    SliverChildBuilderDelegate(
                                                  (context, index) {
                                                    final product =
                                                        filteredProducts[index];
                                                    return ProductCard(
                                                      product: product,
                                                      imageUrl:
                                                          product.imageUrl ?? '',
                                                      isFavorite: favoriteIds
                                                          .contains(product.id),
                                                      onFavorite: () =>
                                                          toggleFavorite(product),
                                                      onDetails: () =>
                                                          openDetails(product),
                                                      priceFormatter: price,
                                                    );
                                                  },
                                                  childCount:
                                                      filteredProducts.length,
                                                ),
                                              ),
                                            ),
                                          SliverToBoxAdapter(
                                            child: PaginationFooter(
                                              loadingMore: loadingMore,
                                              hasMore: hasMore,
                                              loadedCount: products.length,
                                              onLoadMore: loadMore,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }
}

class FiltersBar extends StatefulWidget {
  final TextEditingController searchController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final String selectedCategory;
  final String selectedGender;
  final String selectedBrand;
  final String selectedStore;
  final List<String> availableBrands;
  final int selectedMinDiscount;
  final SortMode selectedSort;
  final bool multiStoreOnly;
  final ValueChanged<bool> onMultiStoreOnlyChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onStoreChanged;
  final ValueChanged<String> onMinPriceChanged;
  final ValueChanged<String> onMaxPriceChanged;
  final ValueChanged<int?> onDiscountChanged;
  final ValueChanged<SortMode?> onSortChanged;
  final VoidCallback onReset;
  final ValueChanged<String> onOpenStoreCatalog;
  final int resultCount;
  final int loadedCount;
  final bool showStoreFilter;

  const FiltersBar({
    super.key,
    required this.searchController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.selectedCategory,
    required this.selectedGender,
    required this.selectedBrand,
    required this.selectedStore,
    required this.availableBrands,
    required this.selectedMinDiscount,
    required this.selectedSort,
    required this.multiStoreOnly,
    required this.onMultiStoreOnlyChanged,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onGenderChanged,
    required this.onBrandChanged,
    required this.onStoreChanged,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    required this.onDiscountChanged,
    required this.onSortChanged,
    required this.onReset,
    required this.onOpenStoreCatalog,
    required this.resultCount,
    required this.loadedCount,
    this.showStoreFilter = true,
  });

  @override
  State<FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<FiltersBar> {
  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildStoreField({required bool inBottomSheet}) {
    return InkWell(
      onTap: () async {
        final selected = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => StoreSelectionScreen(
              currentStore: widget.selectedStore,
            ),
          ),
        );
        if (selected != null && mounted) {
          if (inBottomSheet) {
            Navigator.pop(context);
          }
          if (selected == 'all') {
            widget.onStoreChanged(selected);
          } else {
            widget.onOpenStoreCatalog(selected);
          }
        }
      },
      child: InputDecorator(
        decoration: _fieldDecoration(AppLocalizations.of(context)!.store),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.selectedStore == 'all'
                    ? 'Все магазины'
                    : _storeDisplayName(widget.selectedStore),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final searchField = TextField(
      controller: widget.searchController,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  widget.searchController.clear();
                  widget.onSearchChanged('');
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Использование value вместо initialValue обеспечивает точный сброс формы
    final categoryField = DropdownButtonFormField<String>(
      initialValue: widget.selectedCategory,
      isExpanded: true,
      isDense: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.category),
      items: [
        DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.all)),
        DropdownMenuItem(value: 'clothing', child: Text(AppLocalizations.of(context)!.clothing)),
        DropdownMenuItem(value: 'shoes', child: Text(AppLocalizations.of(context)!.shoes)),
        DropdownMenuItem(value: 'accessories', child: Text(AppLocalizations.of(context)!.accessories)),
        DropdownMenuItem(value: 'beauty', child: Text(AppLocalizations.of(context)!.beauty)),
        DropdownMenuItem(value: 'perfume', child: Text(AppLocalizations.of(context)!.perfume)),
        DropdownMenuItem(value: 'electronics', child: Text(AppLocalizations.of(context)!.technology)),
        DropdownMenuItem(value: 'home', child: Text(AppLocalizations.of(context)!.home)),
        DropdownMenuItem(value: 'sports', child: Text(AppLocalizations.of(context)!.sport)),
      ],
      onChanged: widget.onCategoryChanged,
    );

    final genderField = DropdownButtonFormField<String>(
      initialValue: widget.selectedGender,
      isExpanded: true,
      isDense: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.gender),
      items: [
        DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.all)),
        DropdownMenuItem(value: 'men', child: Text(AppLocalizations.of(context)!.men)),
        DropdownMenuItem(value: 'women', child: Text(AppLocalizations.of(context)!.women)),
        DropdownMenuItem(value: 'kids', child: Text(AppLocalizations.of(context)!.kids)),
      ],
      onChanged: widget.onGenderChanged,
    );

    final brandField = DropdownButtonFormField<String>(
      initialValue: widget.availableBrands.contains(widget.selectedBrand)
          ? widget.selectedBrand
          : 'all',
      isExpanded: true,
      isDense: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.brand),
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Text(AppLocalizations.of(context)!.allBrands),
        ),
        ...widget.availableBrands.map(
          (brand) => DropdownMenuItem(
            value: brand,
            child: Text(brand, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      onChanged: widget.onBrandChanged,
    );

    final minPriceField = TextField(
      controller: widget.minPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onMinPriceChanged,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.minPrice).copyWith(suffixText: '€'),
    );

    final maxPriceField = TextField(
      controller: widget.maxPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onMaxPriceChanged,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.maxPrice).copyWith(suffixText: '€'),
    );

    final discountField = DropdownButtonFormField<int>(
      initialValue: widget.selectedMinDiscount,
      isDense: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.minDiscount),
      items: const [
        DropdownMenuItem(value: 0, child: Text('Любая')),
        DropdownMenuItem(value: 20, child: Text('20%')),
        DropdownMenuItem(value: 30, child: Text('30%')),
        DropdownMenuItem(value: 40, child: Text('40%')),
        DropdownMenuItem(value: 50, child: Text('50%')),
        DropdownMenuItem(value: 60, child: Text('60%')),
        DropdownMenuItem(value: 70, child: Text('70%')),
        DropdownMenuItem(value: 80, child: Text('80%')),
        DropdownMenuItem(value: 90, child: Text('90%')),
        DropdownMenuItem(value: 95, child: Text('95%')),
      ],
      onChanged: widget.onDiscountChanged,
    );

    final sortField = DropdownButtonFormField<SortMode>(
      initialValue: widget.selectedSort,
      isExpanded: true,
      isDense: true,
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _fieldDecoration(AppLocalizations.of(context)!.sort),
      items: [
        DropdownMenuItem(
          value: SortMode.discountHigh,
          child: Text(AppLocalizations.of(context)!.biggestDiscount, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.savingsHigh,
          child: Text(AppLocalizations.of(context)!.maximumSavings, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceLow,
          child: Text(AppLocalizations.of(context)!.priceLow, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceHigh,
          child: Text(AppLocalizations.of(context)!.priceHigh, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.brand,
          child: Text(AppLocalizations.of(context)!.byBrand, overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: widget.onSortChanged,
    );

    final multiStoreField = SizedBox(
      height: 56,
      child: FilterChip(
        selected: widget.multiStoreOnly,
        onSelected: widget.onMultiStoreOnlyChanged,
        avatar: const Icon(Icons.compare_arrows, size: 18),
        label: Text(AppLocalizations.of(context)!.multiStoreOnly),
      ),
    );

    final resetButton = SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: widget.onReset,
        icon: const Icon(Icons.filter_alt_off),
        label: Text(AppLocalizations.of(context)!.reset),
      ),
    );

    if (isMobile) {
      final activeFilters = [
        widget.selectedCategory != 'all',
        widget.selectedGender != 'all',
        widget.selectedBrand != 'all',
        widget.selectedStore != 'all' && widget.showStoreFilter,
        widget.minPriceController.text.trim().isNotEmpty,
        widget.maxPriceController.text.trim().isNotEmpty,
        widget.selectedMinDiscount > 0,
        widget.selectedSort != SortMode.discountHigh,
        widget.multiStoreOnly,
      ].where((value) => value).length;

      Future<void> openFiltersSheet() async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: false,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.98,
          ),
          builder: (sheetContext) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.filters,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.onReset();
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.reset),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          categoryField,
                          if (widget.selectedStore == 'Notino') ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Notino',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(AppLocalizations.of(context)!.all),
                                  selected: widget.selectedCategory == 'all',
                                  onSelected: (_) => widget.onCategoryChanged('all'),
                                ),
                                ChoiceChip(
                                  label: Text(AppLocalizations.of(context)!.beauty),
                                  selected: widget.selectedCategory == 'beauty',
                                  onSelected: (_) => widget.onCategoryChanged('beauty'),
                                ),
                                ChoiceChip(
                                  label: Text(AppLocalizations.of(context)!.perfume),
                                  selected: widget.selectedCategory == 'perfume',
                                  onSelected: (_) => widget.onCategoryChanged('perfume'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          genderField,
                          const SizedBox(height: 12),
                          brandField,
                          const SizedBox(height: 12),
                          if (widget.showStoreFilter) ...[
                            _buildStoreField(inBottomSheet: true),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(child: minPriceField),
                              const SizedBox(width: 12),
                              Expanded(child: maxPriceField),
                            ],
                          ),
                          const SizedBox(height: 12),
                          discountField,
                          const SizedBox(height: 12),
                          sortField,
                          const SizedBox(height: 8),
                          multiStoreField,
                          const SizedBox(height: 8),
                          resetButton,
                          const SizedBox(height: 10),
                    FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(
                              AppLocalizations.of(context)!.showAll,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: openFiltersSheet,
              icon: const Icon(Icons.tune),
              label: Text(
                activeFilters == 0
                    ? 'Фильтры'
                    : 'Фильтры • $activeFilters',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 300, child: searchField),
          SizedBox(width: 175, child: categoryField),
          SizedBox(width: 160, child: genderField),
          SizedBox(width: 175, child: brandField),
          if (widget.showStoreFilter)
            SizedBox(width: 185, child: _buildStoreField(inBottomSheet: false)),
          SizedBox(width: 115, child: minPriceField),
          SizedBox(width: 115, child: maxPriceField),
          SizedBox(width: 140, child: discountField),
          SizedBox(width: 225, child: sortField),
          multiStoreField,
          resetButton,
        ],
      ),
    );
  }
}

class PaginationFooter extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;
  final int loadedCount;
  final VoidCallback onLoadMore;

  const PaginationFooter({
    super.key,
    required this.loadingMore,
    required this.hasMore,
    required this.loadedCount,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Все подходящие товары загружены',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more),
          label: Text('${AppLocalizations.of(context)!.loadMore} $pageLabel'),
        ),
      ),
    );
  }

  String get pageLabel => '40 товаров';
}

class UrlWatchPage extends StatefulWidget {
  const UrlWatchPage({super.key});

  @override
  State<UrlWatchPage> createState() => _UrlWatchPageState();
}

class _UrlWatchPageState extends State<UrlWatchPage> {
  static const String apiBase = 'https://baltic-deals-api.noduys.workers.dev';

  final urlController = TextEditingController();
  final targetController = TextEditingController();
  bool loading = false;
  bool checking = false;
  Map<String, dynamic>? watch;
  String? error;

  @override
  void dispose() {
    urlController.dispose();
    targetController.dispose();
    super.dispose();
  }

  Future<String> _deviceId() => _getDeviceId();

  Future<void> checkWatch() async {
    final productUrl = urlController.text.trim();
    if (productUrl.isEmpty) return;

    setState(() {
      checking = true;
      error = null;
    });

    try {
      final deviceId = await _deviceId();
      final uri = Uri.parse('$apiBase/url-price-watch').replace(
        queryParameters: {
          'productUrl': productUrl,
          'deviceId': deviceId,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Не удалось проверить отслеживание');
      }

      final row = data['watch'];
      setState(() {
        watch = row is Map ? Map<String, dynamic>.from(row) : null;
        targetController.text = watch?['target_price']?.toString() ?? '';
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> saveWatch() async {
    final productUrl = urlController.text.trim();
    final targetText = targetController.text.trim();
    final target = targetText.isEmpty ? null : double.tryParse(targetText.replaceAll(',', '.'));

    if (productUrl.isEmpty) {
      setState(() => error = 'Укажите ссылку на товар');
      return;
    }
    final parsed = Uri.tryParse(productUrl);
    if (parsed == null || (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      setState(() => error = 'Адрес должен начинаться с http:// или https://');
      return;
    }
    if (targetText.isNotEmpty && (target == null || target <= 0)) {
      setState(() => error = 'Цена должна быть больше 0');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final deviceId = await _deviceId();
      final response = await http.post(
        Uri.parse('$apiBase/url-price-watch'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productUrl': productUrl,
          'deviceId': deviceId,
          'targetPrice': target,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Не удалось сохранить отслеживание');
      }
      await checkWatch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отслеживание цены сохранено')),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteWatch() async {
    final productUrl = urlController.text.trim();
    if (productUrl.isEmpty) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final deviceId = await _deviceId();
      final uri = Uri.parse('$apiBase/url-price-watch').replace(
        queryParameters: {
          'productUrl': productUrl,
          'deviceId': deviceId,
        },
      );
      final response = await http.delete(uri);
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Не удалось удалить отслеживание');
      }
      setState(() {
        watch = null;
        targetController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отслеживание удалено')),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = watch != null && watch?['is_active']?.toString() != '0';
    final currentPrice = watch?['current_price']?.toString();
    final targetPrice = watch?['target_price']?.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание цены', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Добавить ссылку на товар',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Приложение регулярно проверяет цену и пришлет уведомление при снижении или достижении нужной цены.',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => checkWatch(),
            decoration: InputDecoration(
              labelText: 'Ссылка на товар',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Желаемая цена, € (необязательно)',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: checking ? null : checkWatch,
                  icon: checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Проверить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : saveWatch,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Отслеживать'),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Товар отслеживается',
                          style: TextStyle(fontWeight: FontWeight.w800))
                    ]),
                    if (currentPrice != null) ...[
                      const SizedBox(height: 10),
                      Text('Текущая цена: €$currentPrice'),
                    ],
                    if (targetPrice != null) ...[
                      const SizedBox(height: 4),
                      Text('Целевая цена: €$targetPrice'),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: loading ? null : deleteWatch,
                      icon: const Icon(Icons.notifications_off_outlined),
                      label: const Text('Удалить'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  const EmptyView({
    super.key,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      type: EmptyStateType.search,
      hasMore: hasMore,
      loadingMore: loadingMore,
      onLoadMore: onLoadMore,
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onDetails;
  final String Function(double) priceFormatter;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.isFavorite,
    required this.onFavorite,
    required this.onDetails,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasOldPrice =
        product.oldPrice != null && product.oldPrice! > product.currentPrice;
    final isMultiStore = product.storesCount > 1;
    final hasSavings = isMultiStore && product.savingsAmount > 0;

    final cleanUrl = imageUrl.trim();
    final hasValidUrl = cleanUrl.isNotEmpty && cleanUrl.startsWith('http');

    return Card(
      color: isDark ? const Color(0xFF1E2022) : const Color(0xFFF8F9FA),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDark ? const Color(0xFF16181A) : Colors.transparent,
                    padding: const EdgeInsets.all(12),
                    child: !hasValidUrl
                        ? const AppProductImagePlaceholder()
                        : CachedNetworkImage(
                            imageUrl: cleanUrl,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.medium,
                            placeholder: (context, url) =>
                                const AppProductImagePlaceholder(),
                            errorWidget: (context, url, error) =>
                                const AppProductImagePlaceholder(),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (product.discountPercent != null &&
                            product.discountPercent! > 0)
                          _CardBadge(
                            label: '-${product.discountPercent}%',
                            backgroundColor: const Color(0xFFD93636),
                            foregroundColor: Colors.white,
                          ),
                        if (isMultiStore)
                          _CardBadge(
                            label: 'Лучшая цена',
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.90),
                      shape: const CircleBorder(),
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        tooltip: isFavorite
                            ? 'Удалить из избранного'
                            : 'Добавить в избранное',
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color(0xFFD93636) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (product.brand?.isNotEmpty ?? false)
                                ? product.brand!.toUpperCase()
                                : product.storeName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (isMultiStore)
                          Text(
                            '${product.storesCount} маг.',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasSavings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Экономия до ${priceFormatter(product.savingsAmount)} €',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    // ProductCardSizePreview отключен для предотвращения 40 лишних сетевых запросов
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${priceFormatter(product.currentPrice)} €',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (hasOldPrice) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${priceFormatter(product.oldPrice!)} €',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCardSizePreview extends StatelessWidget {
  final int productId;

  const ProductCardSizePreview({
    super.key,
    required this.productId,
  });

  static const String _apiBase = 'https://baltic-deals-api.noduys.workers.dev';
  // Ограничиваем размер кэша (LRU), чтобы исключить утечки оперативной памяти
  static final LinkedHashMap<int, Future<List<String>>> _cache = LinkedHashMap();
  static const int _maxCacheSize = 100;

  Future<List<String>> _loadSizes() {
    if (_cache.containsKey(productId)) {
      final future = _cache.remove(productId)!;
      _cache[productId] = future;
      return future;
    }

    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    final future = _fetchSizesFromNetwork();
    _cache[productId] = future;
    return future;
  }

  Future<List<String>> _fetchSizesFromNetwork() async {
    try {
      final uri = Uri.parse('$_apiBase/sizes').replace(
        queryParameters: {
          'productId': productId.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return <String>[];

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return <String>[];

      final stores = decoded['stores'] as List<dynamic>? ?? const [];
      final available = <String>{};

      for (final storeValue in stores) {
        if (storeValue is! Map) continue;
        final sizes = storeValue['sizes'] as List<dynamic>? ?? const [];

        for (final sizeValue in sizes) {
          if (sizeValue is! Map) continue;
          final size = sizeValue['size']?.toString().trim() ?? '';
          final availability =
              sizeValue['availability']?.toString().toLowerCase() ?? '';

          if (size.isNotEmpty && availability == 'in_stock') {
            available.add(size);
          }
        }
      }

      final result = available.toList();
      result.sort((a, b) {
        final aNumber = double.tryParse(a.replaceAll(',', '.'));
        final bNumber = double.tryParse(b.replaceAll(',', '.'));

        if (aNumber != null && bNumber != null) {
          return aNumber.compareTo(bNumber);
        }
        return a.compareTo(b);
      });

      return result;
    } catch (_) {
      return <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<String>>(
      future: _loadSizes(),
      builder: (context, snapshot) {
        final sizes = snapshot.data;
        if (sizes == null || sizes.isEmpty) return const SizedBox.shrink();

        final visible = sizes.take(4).toList();
        final extraCount = sizes.length - visible.length;
        final label = extraCount > 0
            ? '${visible.join(" • ")} • +$extraCount'
            : visible.join(" • ");

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Размеры: $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _CardBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StoreOffer {
  final int storeProductIdId;
  final String storeName;
  final String country;
  final String productUrl;
  final double currentPrice;
  final double? oldPrice;
  final String currency;
  final String? availability;
  final int? discountPercent;
  final bool hasCoupon;

  const StoreOffer({
    required this.storeProductIdId,
    required this.storeName,
    required this.country,
    required this.productUrl,
    required this.currentPrice,
    required this.oldPrice,
    required this.currency,
    required this.availability,
    required this.discountPercent,
    required this.hasCoupon,
  });

  factory StoreOffer.fromJson(Map<String, dynamic> json) {
    return StoreOffer(
      storeProductIdId: (json['store_product_id'] as num?)?.toInt() ?? 0,
      storeName: json['store_name']?.toString() ?? 'Магазин',
      country: json['country']?.toString() ?? '',
      productUrl: json['product_url']?.toString() ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'EUR',
      availability: json['availability']?.toString(),
      discountPercent: (json['discount_percent'] as num?)?.toInt(),
      hasCoupon: (json['has_coupon'] as num?)?.toInt() == 1,
    );
  }
}

class ProductSizeOption {
  final String size;
  final String? availability;
  final String? ean;

  const ProductSizeOption({
    required this.size,
    required this.availability,
    required this.ean,
  });

  factory ProductSizeOption.fromJson(Map<String, dynamic> json) {
    return ProductSizeOption(
      size: json['size']?.toString() ?? '',
      availability: json['availability']?.toString(),
      ean: json['ean']?.toString(),
    );
  }
}

class ProductSizeStore {
  final String storeName;
  final String country;
  final double currentPrice;
  final String currency;
  final String productUrl;
  final List<ProductSizeOption> sizes;

  const ProductSizeStore({
    required this.storeName,
    required this.country,
    required this.currentPrice,
    required this.currency,
    required this.productUrl,
    required this.sizes,
  });

  factory ProductSizeStore.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['sizes'] as List<dynamic>? ?? [];

    return ProductSizeStore(
      storeName: json['store_name']?.toString() ?? 'Магазин',
      country: json['country']?.toString() ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'EUR',
      productUrl: json['product_url']?.toString() ?? '',
      sizes: rawSizes
          .map((item) => ProductSizeOption.fromJson(item as Map<String, dynamic>))
          .where((item) => item.size.isNotEmpty)
          .toList(),
    );
  }

  bool hasSize(String size) {
    return sizes.any(
      (item) => item.size == size && item.availability != 'out_of_stock',
    );
  }
}

class PriceHistoryPoint {
  final double price;
  final DateTime? recordedAt;

  const PriceHistoryPoint({
    required this.price,
    required this.recordedAt,
  });

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPoint(
      price: (json['price'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? ''),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onOpenStore;
  final String Function(double) priceFormatter;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.isFavorite,
    required this.onFavorite,
    required this.onOpenStore,
    required this.priceFormatter,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  static const String apiBase = 'https://baltic-deals-api.noduys.workers.dev';

  late bool isFavorite;

  bool historyLoading = true;
  String? historyError;
  List<PriceHistoryPoint> history = [];
  double? minHistoryPrice;
  double? maxHistoryPrice;

  bool offersLoading = true;
  String? offersError;
  List<StoreOffer> offers = [];

  bool sizesLoading = true;
  String? sizesError;
  List<String> allSizes = [];
  List<ProductSizeStore> sizeStores = [];
  String? selectedSize;

  bool priceAlertLoading = true;
  double? priceAlertTarget;
  bool priceAlertTriggered = false;
  double? priceAlertTriggeredPrice;
  String? priceAlertTriggeredAt;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
    loadPriceHistory();
    loadOffers();
    loadSizes();
    loadPriceAlert();
  }

  String get _priceAlertKey => 'price_alert_target_${widget.product.id}';

  Future<void> loadPriceAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final localValue = prefs.getDouble(_priceAlertKey);

    if (mounted) {
      setState(() {
        priceAlertTarget = localValue;
        priceAlertLoading = true;
      });
    }

    try {
      final uri = Uri.parse(
        'https://baltic-deals-api.noduys.workers.dev/price-alert',
      ).replace(
        queryParameters: {
          'productId': widget.product.id.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map<String, dynamic>) {
          final alert = decoded['alert'];

          if (alert is Map) {
            final rawTarget = alert['target_price'];
            final serverTarget = rawTarget is num
                ? rawTarget.toDouble()
                : double.tryParse(rawTarget?.toString() ?? '');

            final rawTriggered = alert['is_triggered'];
            final serverTriggered = rawTriggered == true ||
                rawTriggered == 1 ||
                rawTriggered?.toString() == '1';

            final rawTriggeredPrice = alert['triggered_price'];
            final serverTriggeredPrice = rawTriggeredPrice is num
                ? rawTriggeredPrice.toDouble()
                : double.tryParse(rawTriggeredPrice?.toString() ?? '');

            final serverTriggeredAt = alert['triggered_at']?.toString();

            if (serverTarget != null && serverTarget > 0) {
              await prefs.setDouble(_priceAlertKey, serverTarget);

              if (!mounted) return;
              setState(() {
                priceAlertTarget = serverTarget;
                priceAlertTriggered = serverTriggered;
                priceAlertTriggeredPrice = serverTriggeredPrice;
                priceAlertTriggeredAt = serverTriggeredAt;
                priceAlertLoading = false;
              });
              return;
            }
          } else if (alert == null) {
            await prefs.remove(_priceAlertKey);

            if (!mounted) return;
            setState(() {
              priceAlertTarget = null;
              priceAlertTriggered = false;
              priceAlertTriggeredPrice = null;
              priceAlertTriggeredAt = null;
              priceAlertLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      priceAlertTarget = localValue;
      priceAlertLoading = false;
    });
  }

  Future<void> savePriceAlert(double target) async {
    final prefs = await SharedPreferences.getInstance();
    final roundedTarget = double.parse(target.toStringAsFixed(2));

    try {
      final response = await http.post(
        Uri.parse('https://baltic-deals-api.noduys.workers.dev/price-alert'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productId': widget.product.id,
          'targetPrice': roundedTarget,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('API ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception('API rejected the alert');
      }

      await prefs.setDouble(_priceAlertKey, roundedTarget);

      if (!mounted) return;

      setState(() {
        priceAlertTarget = roundedTarget;
        priceAlertTriggered = false;
        priceAlertTriggeredPrice = null;
        priceAlertTriggeredAt = null;
        priceAlertLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Цена сохранена на сервере: ${widget.priceFormatter(roundedTarget)} €',
          ),
        ),
      );
    } catch (_) {
      await prefs.setDouble(_priceAlertKey, roundedTarget);

      if (!mounted) return;

      setState(() {
        priceAlertTarget = roundedTarget;
        priceAlertTriggered = false;
        priceAlertTriggeredPrice = null;
        priceAlertTriggeredAt = null;
        priceAlertLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Сервер временно недоступен. Цена сохранена локально на этом устройстве.',
          ),
        ),
      );
    }
  }

  Future<void> removePriceAlert() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final uri = Uri.parse(
        'https://baltic-deals-api.noduys.workers.dev/price-alert',
      ).replace(
        queryParameters: {
          'productId': widget.product.id.toString(),
        },
      );

      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('API ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception('API rejected delete');
      }

      await prefs.remove(_priceAlertKey);

      if (!mounted) return;

      setState(() {
        priceAlertTarget = null;
        priceAlertTriggered = false;
        priceAlertTriggeredPrice = null;
        priceAlertTriggeredAt = null;
        priceAlertLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отслеживание цены отключено на сервере'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось отключить запись на сервере. Попробуйте еще раз.',
          ),
        ),
      );
    }
  }

  Future<void> showPriceAlertDialog() async {
    final initialTarget =
        priceAlertTarget ?? (widget.product.currentPrice * 0.9);

    final controller = TextEditingController(
      text: initialTarget.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.trackPrice),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текущая цена: ${widget.priceFormatter(widget.product.currentPrice)} €',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Желаемая цена, €',
                        hintText: 'Например 49.99',
                        errorText: validationError,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        final raw = controller.text.trim().replaceAll(',', '.');
                        final value = double.tryParse(raw);

                        if (value == null || value <= 0) {
                          setDialogState(() {
                            validationError = 'Укажите корректную цену';
                          });
                          return;
                        }

                        Navigator.of(dialogContext).pop(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Цена отслеживается на сервере Baltic Deals. Push-уведомление придет через службу Firebase.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (priceAlertTarget != null)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(-1),
                    child: const Text('Удалить'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = controller.text.trim().replaceAll(',', '.');
                    final value = double.tryParse(raw);

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        validationError = 'Укажите корректную цену';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null) return;
    if (result < 0) {
      await removePriceAlert();
      return;
    }

    await savePriceAlert(result);
  }

  Future<void> loadOffers() async {
    try {
      final uri = Uri.parse('$apiBase/offers').replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = decoded['offers'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        offers = items
            .map((item) => StoreOffer.fromJson(item as Map<String, dynamic>))
            .toList();
        offersLoading = false;
        offersError = null;
      });
    } catch (e) {
      debugPrint('ОШИБКА ЗАГРУЗКИ ОФФЕРОВ: $e');
      if (!mounted) return;
      setState(() {
        offersLoading = false;
        offersError = 'Не удалось загрузить цены';
      });
    }
  }

  Future<void> loadSizes() async {
    try {
      final uri = Uri.parse('$apiBase/sizes').replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawSizes = decoded['all_sizes'] as List<dynamic>? ?? [];
      final rawStores = decoded['stores'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        allSizes = rawSizes
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();

        sizeStores = rawStores
            .map((item) => ProductSizeStore.fromJson(item as Map<String, dynamic>))
            .toList();

        sizesLoading = false;
        sizesError = null;

        if (selectedSize != null && !allSizes.contains(selectedSize)) {
          selectedSize = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sizesLoading = false;
        sizesError = e.toString();
      });
    }
  }

  Future<void> loadPriceHistory() async {
    try {
      final uri = Uri.parse('$apiBase/price-history').replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = decoded['history'] as List<dynamic>? ?? [];
      final stats = decoded['stats'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        history = items
            .map((item) => PriceHistoryPoint.fromJson(item as Map<String, dynamic>))
            .toList();

        minHistoryPrice = (stats?['min_price'] as num?)?.toDouble();
        maxHistoryPrice = (stats?['max_price'] as num?)?.toDouble();

        historyLoading = false;
        historyError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        historyLoading = false;
        historyError = e.toString();
      });
    }
  }

  Future<void> openOffer(StoreOffer offer) async {
    final uri = Uri.tryParse(offer.productUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  List<ProductSizeStore> storesForSize(String size) {
    return sizeStores.where((store) => store.hasSize(size)).toList();
  }

  bool isSizeAvailable(String size) {
    return sizeStores.any((store) => store.hasSize(size));
  }

  double? bestPriceForSize(String size) {
    final stores = storesForSize(size);
    if (stores.isEmpty) return null;

    var best = stores.first.currentPrice;
    for (final store in stores.skip(1)) {
      if (store.currentPrice < best) {
        best = store.currentPrice;
      }
    }
    return best;
  }

  Future<void> openSizeStore(ProductSizeStore store) async {
    final uri = Uri.tryParse(store.productUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> shareProductLink() async {
    final url = widget.product.productUrl?.trim();
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка на товар отсутствует')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ссылка скопирована для отправки')),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onOpenStore,
            icon: const Icon(Icons.open_in_new),
            label: const Text(
              'В магазин',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: shareProductLink,
            icon: const Icon(Icons.share_outlined, size: 20),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Поделиться', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContent({required bool wide}) {
    final product = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasOldPrice =
        product.oldPrice != null && product.oldPrice! > product.currentPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null && product.brand!.isNotEmpty)
          Text(
            product.brand!.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${product.storeName} • ${product.country}',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              '${widget.priceFormatter(product.currentPrice)} €',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (hasOldPrice)
              Text(
                '${widget.priceFormatter(product.oldPrice!)} €',
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (product.discountPercent != null && product.discountPercent! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD93636),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (priceAlertLoading)
          const SizedBox(
            height: 42,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: priceAlertTriggered
                  ? Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withValues(alpha: 0.55)
                  : priceAlertTarget == null
                      ? (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: priceAlertTarget == null
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  priceAlertTriggered
                      ? Icons.celebration_outlined
                      : priceAlertTarget == null
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                  color: priceAlertTriggered
                      ? Theme.of(context).colorScheme.tertiary
                      : priceAlertTarget == null
                          ? (isDark ? Colors.grey.shade400 : Colors.grey.shade700)
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceAlertTriggered && priceAlertTarget != null
                            ? AppLocalizations.of(context)!.targetReached
                            : priceAlertTarget == null
                                ? AppLocalizations.of(context)!.trackPrice
                                : AppLocalizations.of(context)!.targetValue(
                                    '${widget.priceFormatter(priceAlertTarget!)} €',
                                  ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        priceAlertTriggered && priceAlertTarget != null
                            ? 'Снизилась уже до ${widget.priceFormatter(priceAlertTriggeredPrice ?? widget.product.currentPrice)} € • цель ${widget.priceFormatter(priceAlertTarget!)} €'
                            : priceAlertTarget == null
                                ? 'Отправим уведомление при падении цен'
                                : widget.product.currentPrice <= priceAlertTarget!
                                    ? 'Цена уже достигла желаемого уровня'
                                    : 'Осталось подождать снижения на ${widget.priceFormatter(widget.product.currentPrice - priceAlertTarget!)} €',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: showPriceAlertDialog,
                  icon: Icon(
                    priceAlertTarget == null
                        ? Icons.add_alert_outlined
                        : Icons.edit_notifications_outlined,
                    size: 18,
                  ),
                  label: Text(
                    priceAlertTarget == null
                        ? AppLocalizations.of(context)!.setTarget
                        : AppLocalizations.of(context)!.changeTarget,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        AppDetailRow(
          icon: Icons.category_outlined,
          label: AppLocalizations.of(context)!.category,
          value: _categoryLabel(context, product.category),
        ),
        AppDetailRow(
          icon: Icons.person_outline,
          label: AppLocalizations.of(context)!.gender,
          value: product.gender?.isNotEmpty == true
              ? product.gender!
              : AppLocalizations.of(context)!.notSpecified,
        ),
        AppDetailRow(
          icon: Icons.storefront_outlined,
          label: AppLocalizations.of(context)!.store,
          value: product.storeName,
        ),
        AppDetailRow(
          icon: Icons.public,
          label: AppLocalizations.of(context)!.country,
          value: product.country,
        ),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.sizes,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!sizesLoading && sizesError == null && allSizes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${allSizes.where(isSizeAvailable).length} в наличии',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sizesLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Text(
                  'Проверяем наличие размеров...',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          )
        else if (sizesError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten_outlined,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Размеры временно недоступны',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      sizesLoading = true;
                      sizesError = null;
                    });
                    loadSizes();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
        else if (allSizes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Данные о размерах для этой вещи пока не поступили.',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            selectedSize == null
                ? 'Выберите размер, чтобы сравнить магазины'
                : 'Выбранный размер: $selectedSize',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in allSizes)
                ChoiceChip(
                  label: Text(size),
                  selected: selectedSize == size,
                  onSelected: isSizeAvailable(size)
                      ? (selected) {
                          setState(() {
                            selectedSize = selected ? size : null;
                          });
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Недоступные размеры выделены серым цветом.',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
              fontSize: 12,
            ),
          ),
          if (selectedSize != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final selectedStores = storesForSize(selectedSize!);
                final bestPrice = bestPriceForSize(selectedSize!);

                if (selectedStores.isEmpty) {
                  return Text(
                    'Подходящих предложений именно для вас нет в наличии',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Размер $selectedSize • ${selectedStores.length} ${selectedStores.length == 1 ? 'магазин' : 'магазинов'}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                if (bestPrice != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Лучшая цена: ${widget.priceFormatter(bestPrice)} €',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final store in selectedStores)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            store.storeName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (bestPrice != null &&
                                            (store.currentPrice - bestPrice).abs() < 0.001) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Лучшая цена',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.priceFormatter(store.currentPrice)} €',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'В наличии',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: () => openSizeStore(store),
                                child: const Text('Купить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Цены в магазинах',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (offersLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (offersError != null)
          Row(
            children: [
              const Expanded(
                child: Text('Не удалось загрузить предложения'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    offersLoading = true;
                    offersError = null;
                  });
                  loadOffers();
                },
                child: const Text('Повторить'),
              ),
            ],
          )
        else if (offers.isEmpty)
          Text(
            'Предложений пока нет',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
            ),
          )
        else
          Column(
            children: [
              for (final offer in offers)
                _OfferCard(
                  offer: offer,
                  priceFormatter: widget.priceFormatter,
                  onOpen: () => openOffer(offer),
                ),
            ],
          ),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'История цен',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (historyLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (historyError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Не удалось загрузить историю цен',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      historyLoading = true;
                      historyError = null;
                    });
                    loadPriceHistory();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
        else ...[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _PriceStat(
                label: 'Сейчас',
                value: '${widget.priceFormatter(product.currentPrice)} €',
              ),
              _PriceStat(
                label: 'Минимум',
                value: '${widget.priceFormatter(minHistoryPrice ?? product.currentPrice)} €',
              ),
              _PriceStat(
                label: 'Максимум',
                value: '${widget.priceFormatter(maxHistoryPrice ?? product.currentPrice)} €',
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: PriceHistoryChart(
              history: history,
              fallbackPrice: product.currentPrice,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            history.length <= 1
                ? 'История только начала отслеживаться. Данные будут обновляться при изменении цены.'
                : 'Всего записей: ${history.length}',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
              fontSize: 12,
            ),
          ),
        ],
        if (wide) ...[
          const SizedBox(height: 28),
          _buildActionButtons(),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanUrl = widget.imageUrl.trim();
    final hasValidUrl = cleanUrl.isNotEmpty && cleanUrl.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.brand?.isNotEmpty == true ? product.brand! : 'Товар',
        ),
        actions: [
          IconButton(
            tooltip: 'Поделиться',
            onPressed: shareProductLink,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: isFavorite
                ? 'Удалить из избранного'
                : 'Добавить в избранное',
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
              widget.onFavorite();
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFD93636) : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 850
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _buildActionButtons(),
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            final image = Container(
              color: isDark ? const Color(0xFF1E2022) : Colors.white,
              padding: const EdgeInsets.all(24),
              child: !hasValidUrl
                  ? const AppProductImagePlaceholder()
                  : CachedNetworkImage(
                      imageUrl: cleanUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const AppProductImagePlaceholder(),
                      errorWidget: (context, url, error) =>
                          const AppProductImagePlaceholder(),
                    ),
            );

            if (wide) {
              return Row(
                children: [
                  Expanded(flex: 6, child: image),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildInfoContent(wide: true),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: image,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildInfoContent(wide: false),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _categoryLabel(BuildContext context, String? category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'shoes':
        return l10n.shoes;
      case 'clothing':
        return l10n.clothing;
      case 'sports':
        return l10n.sport;
      default:
        return category?.isNotEmpty == true ? category! : l10n.notSpecified;
    }
  }
}

class _OfferCard extends StatelessWidget {
  final StoreOffer offer;
  final String Function(double) priceFormatter;
  final VoidCallback onOpen;

  const _OfferCard({
    required this.offer,
    required this.priceFormatter,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasOldPrice =
        offer.oldPrice != null && offer.oldPrice! > offer.currentPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.storeName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.country,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${priceFormatter(offer.currentPrice)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (offer.hasCoupon)
                        _CardBadge(
                          label: 'Купон',
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade800,
                        ),
                      if (hasOldPrice)
                        Text(
                          '${priceFormatter(offer.oldPrice!)} €',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (offer.discountPercent != null && offer.discountPercent! > 0)
                        Text(
                          '-${offer.discountPercent}%',
                          style: const TextStyle(
                            color: Color(0xFFD93636),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onOpen,
              child: const Text('Купить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;

  const _PriceStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryPoint> history;
  final double fallbackPrice;

  const PriceHistoryChart({
    super.key,
    required this.history,
    required this.fallbackPrice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prices = history.isEmpty
        ? <double>[fallbackPrice]
        : history.map((e) => e.price).toList();

    return CustomPaint(
      painter: _PriceHistoryPainter(
        prices: prices,
        lineColor: Theme.of(context).colorScheme.primary,
        gridColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PriceHistoryPainter extends CustomPainter {
  final List<double> prices;
  final Color lineColor;
  final Color gridColor;

  _PriceHistoryPainter({
    required this.prices,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 10.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 18.0;

    final width = size.width - left - right;
    final height = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    final range = (maxPrice - minPrice).abs() < 0.001
        ? 1.0
        : maxPrice - minPrice;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();

    for (var i = 0; i < prices.length; i++) {
      final x = prices.length == 1
          ? left + width / 2
          : left + width * i / (prices.length - 1);

      final normalized = (prices[i] - minPrice) / range;
      final y = top + height * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    if (prices.length > 1) {
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceHistoryPainter oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseShimmer = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor = baseShimmer.withValues(alpha: _animation.value);

        return Card(
          color: isDark ? const Color(0xFF1E2022) : const Color(0xFFF8F9FA),
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(color: shimmerColor),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 11, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 140, height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                      const Spacer(),
                      Container(width: 90, height: 20, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1200
            ? 4
            : width >= 750
                ? 3
                : width >= 600
                    ? 2
                    : 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 0.68 : 0.60,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        );
      },
    );
  }
}

String _storeDisplayName(String value) {
  final map = {
    'all': 'Все магазины',
    'Sportland Estonia': 'Sportland',
    'Rademar Estonia': 'Rademar',
    'Weekend Estonia': 'Weekend',
    'ABOUT YOU Estonia': 'ABOUT YOU',
    'About You Outlet Estonia': 'ABOUT YOU Outlet',
    'Ballzy Estonia': 'Ballzy',
    'Sports Direct Estonia': 'Sports Direct',
    'BestSecret': 'BestSecret',
    'Denim Dream': 'Denim Dream',
    '1a.ee': '1a.ee',
    'Decathlon Estonia': 'Decathlon',
    'Notino': 'Notino',
    'Stockmann Estonia': 'Stockmann',
    'Membershop Estonia': 'Membershop',
    'Makeup.ee': 'Makeup.ee',
    'Loverte': 'Loverte',
    'Boozt': 'Boozt',
  };
  return map[value] ?? value;
}

class StoreSelectionScreen extends StatefulWidget {
  final String currentStore;

  const StoreSelectionScreen({
    super.key,
    required this.currentStore,
  });

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  String _searchQuery = '';

  static const _stores = [
    'all',
    'Sportland Estonia',
    'Rademar Estonia',
    'Weekend Estonia',
    'ABOUT YOU Estonia',
    'About You Outlet Estonia',
    'Ballzy Estonia',
    'Sports Direct Estonia',
    'BestSecret',
    'Denim Dream',
    '1a.ee',
    'Decathlon Estonia',
    'Notino',
    'Stockmann Estonia',
    'Membershop Estonia',
    'Makeup.ee',
    'Loverte',
    'Boozt',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _stores
        .where(
          (s) => _storeDisplayName(s)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор магазина'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск магазина...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final store = filtered[index];
                final isSelected = store == widget.currentStore;
                return ListTile(
                  title: Text(_storeDisplayName(store)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, store),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}