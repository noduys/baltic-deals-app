import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _webVapidKey =
    'BAeMMjHE9TkBtALMEoekwr0FlmgyjY6eeo03QFnlGFoqs8XNVY9mRYx4lqrLiCoRaoNT411Q7djVorhbuGLB6MI';

const String _deviceIdPreferenceKey = 'app_device_id';

Future<String> _getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_deviceIdPreferenceKey)?.trim();

  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final random = Random.secure();
  final bytes = List<int>.generate(
    16,
    (_) => random.nextInt(256),
  );

  final deviceId = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();

  await prefs.setString(_deviceIdPreferenceKey, deviceId);
  return deviceId;
}

Future<void> _registerPushToken(String token) async {
  try {
    final deviceId = await _getOrCreateDeviceId();

    final response = await http.post(
      Uri.parse(
        'https://baltic-deals-api.noduys.workers.dev/push-token',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'deviceId': deviceId,
      }),
    );

    debugPrint(
      'Push token register status: ${response.statusCode}',
    );
    debugPrint(
      'Push token register body: ${response.body}',
    );
  } catch (error, stackTrace) {
    debugPrint('Push token register error: $error');
    debugPrintStack(stackTrace: stackTrace);
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

    debugPrint(
      'FCM permission: ${settings.authorizationStatus}',
    );

    final token = await messaging.getToken(
      vapidKey: _webVapidKey,
    );

    if (token == null || token.isEmpty) {
      debugPrint('FCM TOKEN: not available');
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

class BalticDealsApp extends StatefulWidget {
  const BalticDealsApp({super.key});

  static _BalticDealsAppState? _maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_BalticDealsAppState>();
  }

  @override
  State<BalticDealsApp> createState() => _BalticDealsAppState();
}

class _BalticDealsAppState extends State<BalticDealsApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');

    if (!mounted || code == null || code.isEmpty) return;

    setState(() {
      _locale = Locale(code);
    });
  }

  Future<void> setLocale(String? code) async {
    final prefs = await SharedPreferences.getInstance();

    if (code == null || code.isEmpty) {
      await prefs.remove('app_locale');

      if (!mounted) return;

      setState(() {
        _locale = null;
      });
      return;
    }

    await prefs.setString('app_locale', code);

    if (!mounted) return;

    setState(() {
      _locale = Locale(code);
    });
  }

  String? get localeCode => _locale?.languageCode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: _locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF0F766E),
          onPrimary: Colors.white,
          secondary: const Color(0xFF19A89D),
          onSecondary: Colors.white,
          surface: const Color(0xFFFFFFFF),
          error: const Color(0xFFE5484D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF172126),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF172126),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F766E),
            side: const BorderSide(color: Color(0xFFB9D8D4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7E0E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7E0E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF19A89D),
              width: 1.6,
            ),
          ),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProductsPage(),
    );
  }
}

String _localizedFieldLabel(
  BuildContext context, {
  required String ru,
  required String en,
  required String et,
  required String lv,
  required String lt,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'et':
      return et;
    case 'lv':
      return lv;
    case 'lt':
      return lt;
    case 'ru':
      return ru;
    default:
      return en;
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
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 54,
        color: Colors.grey.shade400,
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingError,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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
      id: (json['id'] as num?)?.toInt() ??
    (json['product_id'] as num?)?.toInt() ??
    0,
      name: json['name']?.toString() ?? 'Product',
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      gender: json['gender']?.toString(),
      imageUrl: json['image_url']?.toString(),
      productUrl: json['product_url']?.toString(),
      storeName: json['store_name']?.toString() ?? 'Sportland',
      country: json['country']?.toString() ?? 'EE',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'EUR',
      discountPercent: (json['discount_percent'] as num?)?.toInt(),
      hasCoupon: (json['has_coupon'] as num?)?.toInt() == 1,
      storesCount: (json['stores_count'] as num?)?.toInt() ?? 1,
      savingsAmount:
          (json['savings_amount'] as num?)?.toDouble() ?? 0,
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
  static const String apiBase =
      'https://baltic-deals-api.noduys.workers.dev';
  static const int pageSize = 40;

  final TextEditingController searchController =
      TextEditingController();
  final TextEditingController minPriceController =
      TextEditingController();
  final TextEditingController maxPriceController =
      TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? searchDebounce;
  Timer? priceDebounce;

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
  String selectedBrand = 'all';
  String selectedStore = 'all';
  int selectedMinDiscount = 0;
  SortMode selectedSort = SortMode.discountHigh;
  bool multiStoreOnly = false;

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
}

Future<void> loadHomeCheapest() async {
  try {
    const sections = <String, String>{
      'beauty': 'beauty',
      'fashion': 'clothing',
      'shoes': 'shoes',
      'tech': 'electronics',
    };

    final loaded = <Product>[];

    for (final entry in sections.entries) {
      final uri = Uri.parse(
        '$apiBase/products',
      ).replace(
        queryParameters: {
          'category': entry.value,
          'limit': '80',
          'offset': '0',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        continue;
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      final items =
          decoded['products'] as List<dynamic>? ?? const [];

      for (final item in items) {
        final json = Map<String, dynamic>.from(
          item as Map<String, dynamic>,
        );

        json['home_section'] = entry.key;
        loaded.add(Product.fromJson(json));
      }
    }

    loaded.sort((a, b) {
      final discountCompare =
          (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0);

      if (discountCompare != 0) {
        return discountCompare;
      }

      final savingsCompare =
          b.savingsAmount.compareTo(a.savingsAmount);

      if (savingsCompare != 0) {
        return savingsCompare;
      }

      return a.currentPrice.compareTo(b.currentPrice);
    });

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

@override
void dispose() {
  searchDebounce?.cancel();
  priceDebounce?.cancel();
  searchController.dispose();
  minPriceController.dispose();
  maxPriceController.dispose();
  scrollController.dispose();
  super.dispose();
}

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 500) {
      loadMore();
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final values =
        prefs.getStringList('favorite_product_ids') ?? [];

    if (!mounted) return;

    setState(() {
      favoriteIds = values
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    });
  }

  Future<void> toggleFavorite(Product product) async {
    final prefs = await SharedPreferences.getInstance();

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

        // ÃÅ¸ÃÂ¾ÃÂºÃÂ°ÃÂ·Ã‘â€¹ÃÂ²ÃÂ°ÃÂµÃÂ¼ ÃÂ±ÃÂ¾ÃÂ»Ã‘Å’Ã‘Ë†ÃÂ¾ÃÂ¹ loader Ã‘â€šÃÂ¾ÃÂ»Ã‘Å’ÃÂºÃÂ¾ ÃÂ¿Ã‘â‚¬ÃÂ¸ Ã‘ÂÃÂ°ÃÂ¼ÃÂ¾ÃÂ¹ ÃÂ¿ÃÂµÃ‘â‚¬ÃÂ²ÃÂ¾ÃÂ¹ ÃÂ·ÃÂ°ÃÂ³Ã‘â‚¬Ã‘Æ’ÃÂ·ÃÂºÃÂµ.
        // ÃÅ¸Ã‘â‚¬ÃÂ¸ ÃÂ¿ÃÂ¾ÃÂ¸Ã‘ÂÃÂºÃÂµ ÃÂ¸ Ã‘â€žÃÂ¸ÃÂ»Ã‘Å’Ã‘â€šÃ‘â‚¬ÃÂ°Ã‘â€¦ ÃÂ¾Ã‘ÂÃ‘â€šÃÂ°ÃÂ²ÃÂ»Ã‘ÂÃÂµÃÂ¼ Ã‘ÂÃÂºÃ‘â‚¬ÃÂ°ÃÂ½ ÃÂ½ÃÂ° ÃÂ¼ÃÂµÃ‘ÂÃ‘â€šÃÂµ,
        // Ã‘â€¡Ã‘â€šÃÂ¾ÃÂ±Ã‘â€¹ TextField ÃÂ½ÃÂµ Ã‘â€šÃÂµÃ‘â‚¬Ã‘ÂÃÂ» Ã‘â€žÃÂ¾ÃÂºÃ‘Æ’Ã‘Â ÃÂ¿ÃÂ¾Ã‘ÂÃÂ»ÃÂµ ÃÂ¿ÃÂµÃ‘â‚¬ÃÂ²ÃÂ¾ÃÂ¹ ÃÂ±Ã‘Æ’ÃÂºÃÂ²Ã‘â€¹.
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

      if (search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (selectedCategory != 'all') {
        queryParameters['category'] = selectedCategory;
      }

      if (selectedBrand != 'all') {
        queryParameters['brand'] = selectedBrand;
      }
if (selectedStore != 'all') {
  queryParameters['store'] = selectedStore;
}
      final minPrice =
          double.tryParse(minPriceController.text.trim());
      final maxPrice =
          double.tryParse(maxPriceController.text.trim());

      if (minPrice != null) {
        queryParameters['minPrice'] = '$minPrice';
      }

      if (maxPrice != null) {
        queryParameters['maxPrice'] = '$maxPrice';
      }

      if (selectedMinDiscount > 0) {
        queryParameters['minDiscount'] =
            '$selectedMinDiscount';
      }

      if (
        multiStoreOnly ||
        selectedSort == SortMode.savingsHigh
      ) {
        queryParameters['multiStoreOnly'] = 'true';
      }

      if (selectedSort == SortMode.savingsHigh) {
        queryParameters['sort'] = 'savings';
      }

      final uri = Uri.parse(
        '$apiBase/products',
      ).replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'API returned ${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      final items =
          decoded['products'] as List<dynamic>? ?? [];

      final loadedProducts = items
          .map(
            (item) => Product.fromJson(
              item as Map<String, dynamic>,
            ),
          )
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
      if (!mounted) return;

      setState(() {
        loading = false;
        loadingMore = false;
        error = e.toString();
      });
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) {
      return;
    }

    setState(() {
      loadingMore = true;
    });

    await loadProducts(reset: false);
  }

  Future<void> refreshProducts() async {
    await loadProducts(reset: true);
  }

  List<Product> get visibleProducts {
    final result = products.where((product) {
      if (!showFavoritesOnly) {
        return true;
      }

      return favoriteIds.contains(product.id);
    }).toList();

    switch (selectedSort) {
      case SortMode.savingsHigh:
        result.sort(
          (a, b) =>
              b.savingsAmount.compareTo(a.savingsAmount),
        );
        break;

      case SortMode.discountHigh:
        result.sort((a, b) {
          final discountCompare =
              (b.discountPercent ?? 0)
                  .compareTo(a.discountPercent ?? 0);

          if (discountCompare != 0) {
            return discountCompare;
          }

          return a.currentPrice
              .compareTo(b.currentPrice);
        });
        break;

      case SortMode.priceLow:
        result.sort(
          (a, b) =>
              a.currentPrice.compareTo(b.currentPrice),
        );
        break;

      case SortMode.priceHigh:
        result.sort(
          (a, b) =>
              b.currentPrice.compareTo(a.currentPrice),
        );
        break;

      case SortMode.brand:
        result.sort((a, b) {
          final brandA =
              (a.brand ?? '').toLowerCase();
          final brandB =
              (b.brand ?? '').toLowerCase();

          final brandCompare =
              brandA.compareTo(brandB);

          if (brandCompare != 0) {
            return brandCompare;
          }

          return a.name
              .toLowerCase()
              .compareTo(b.name.toLowerCase());
        });
        break;
    }

    return result;
  }

  void onSearchChanged(String value) {
    searchDebounce?.cancel();

    searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        if (!mounted) return;
        loadProducts(reset: true);
      },
    );
  }

  void onPriceChanged(String value) {
    priceDebounce?.cancel();

    priceDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        if (!mounted) return;
        loadProducts(reset: true);
      },
    );
  }

  List<String> get availableBrands {
    final brands = products
        .map((product) => product.brand?.trim())
        .whereType<String>()
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(
          b.toLowerCase(),
        ),
      );

    return brands;
  }

  void resetFilters() {
    searchDebounce?.cancel();

    setState(() {
      searchController.clear();
      minPriceController.clear();
      maxPriceController.clear();
      selectedCategory = 'all';
      selectedBrand = 'all';
      selectedStore = widget.initialStore ?? 'all';
      selectedMinDiscount = 0;
      selectedSort = SortMode.discountHigh;
      multiStoreOnly = false;
    });

    loadProducts(reset: true);
  }

  String proxyImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    return Uri.parse(
      '$apiBase/image',
    ).replace(
      queryParameters: {
        'url': imageUrl,
      },
    ).toString();
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
    final l10n = AppLocalizations.of(context)!;
    final value = product.productUrl;

    if (value == null || value.isEmpty) {
      showMessage(l10n.productLinkMissing);
      return;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      showMessage(l10n.invalidProductLink);
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!opened) {
      showMessage(l10n.openStoreFailed);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String price(double value) {
    return value.toStringAsFixed(2);
  }

  List<Product> _homeProductsFor(String section) {
    final items = homeCheapest
        .where((product) => product.homeSection == section)
        .toList();

    items.sort((a, b) {
      final discountCompare =
          (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0);

      if (discountCompare != 0) {
        return discountCompare;
      }

      final savingsCompare =
          b.savingsAmount.compareTo(a.savingsAmount);

      if (savingsCompare != 0) {
        return savingsCompare;
      }

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

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 390,
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final product = items[index];

                return SizedBox(
                  width: 260,
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

  Widget _buildHomeStorePicker() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DropdownButtonFormField<String>(
        initialValue: 'all',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.stores,
          prefixIcon: const Icon(Icons.storefront_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: [
          DropdownMenuItem(
            value: 'all',
            child: Text(AppLocalizations.of(context)!.allStores),
          ),
          DropdownMenuItem(value: 'Sportland Estonia', child: Text('Sportland')),
          DropdownMenuItem(value: 'Rademar Estonia', child: Text('Rademar')),
          DropdownMenuItem(value: 'Weekend Estonia', child: Text('Weekend')),
          DropdownMenuItem(value: 'ABOUT YOU Estonia', child: Text('ABOUT YOU')),
          DropdownMenuItem(value: 'Ballzy Estonia', child: Text('Ballzy')),
          DropdownMenuItem(value: 'Sports Direct Estonia', child: Text('Sports Direct')),
          DropdownMenuItem(value: 'BestSecret', child: Text('BestSecret')),
          DropdownMenuItem(value: 'Kaup24', child: Text('Kaup24')),
          DropdownMenuItem(value: 'Denim Dream', child: Text('Denim Dream')),
          DropdownMenuItem(value: '1a.ee', child: Text('1a.ee')),
          DropdownMenuItem(value: 'Decathlon Estonia', child: Text('Decathlon')),
          DropdownMenuItem(value: 'Notino', child: Text('Notino')),
          DropdownMenuItem(value: 'Stockmann Estonia', child: Text('Stockmann')),
          DropdownMenuItem(value: 'Membershop Estonia', child: Text('Membershop')),
        ],
        onChanged: (value) {
          if (value == null || value == 'all') return;
          _openStoreCatalog(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = visibleProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.storeTitle ?? 'Baltic Deals',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
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
              showFavoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.refresh,
            onPressed: refreshProducts,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.language,
            icon: const Icon(Icons.language),
            onSelected: (value) {
              BalticDealsApp._maybeOf(context)?.setLocale(
                value == 'system' ? null : value,
              );
            },
            itemBuilder: (context) {
              final current =
                  BalticDealsApp._maybeOf(context)?.localeCode;

              Widget languageLabel(
                String? code,
                String label,
              ) {
                return Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: current == code
                          ? const Icon(Icons.check, size: 18)
                          : null,
                    ),
                    Text(label),
                  ],
                );
              }

              return [
                PopupMenuItem(
                  value: 'system',
                  child: languageLabel(
                    null,
                    AppLocalizations.of(context)!.systemLanguage,
                  ),
                ),
                PopupMenuItem(
                  value: 'et',
                  child: languageLabel('et', 'Eesti'),
                ),
                PopupMenuItem(
                  value: 'en',
                  child: languageLabel('en', 'English'),
                ),
                PopupMenuItem(
                  value: 'ru',
                  child: languageLabel('ru', 'Русский'),
                ),
                PopupMenuItem(
                  value: 'lv',
                  child: languageLabel('lv', 'Latviešu'),
                ),
                PopupMenuItem(
                  value: 'lt',
                  child: languageLabel('lt', 'Lietuvių'),
                ),
              ];
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
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null && products.isEmpty
              ? AppErrorView(
                  message: error!,
                  onRetry: refreshProducts,
                )
              : Column(
                  children: [
                    if (!isStoreCatalog) _buildHomeStorePicker(),
                    if (showFavoritesOnly)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Row(
                          children: [
                            const Icon(Icons.favorite),
                            const SizedBox(width: 8),
                            Text(
                              '${AppLocalizations.of(context)!.favorites}: ${favoriteIds.length}',
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
                              child: Text(AppLocalizations.of(context)!.showAll),
                            ),
                          ],
                        ),
                      ),
                    FiltersBar(
                      searchController: searchController,
                      minPriceController: minPriceController,
                      maxPriceController: maxPriceController,
                      selectedCategory: selectedCategory,
                      selectedBrand: selectedBrand,
                      selectedStore: selectedStore,
                      availableBrands: availableBrands,
                      selectedMinDiscount:
                          selectedMinDiscount,
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

                        if (
                          previousSort == SortMode.savingsHigh ||
                          value == SortMode.savingsHigh
                        ) {
                          loadProducts(reset: true);
                        }
                      },
                      onReset: resetFilters,
                      resultCount:
                          filteredProducts.length,
                      loadedCount: products.length,
                      showStoreFilter: false,
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
                                builder:
                                    (context, constraints) {
                                  final width =
                                      constraints.maxWidth;

                                  int columns;

                                  if (width >= 1500) {
                                    columns = 5;
                                  } else if (width >= 1180) {
                                    columns = 4;
                                  } else if (width >= 860) {
                                    columns = 3;
                                  } else if (width >= 560) {
                                    columns = 2;
                                  } else {
                                    columns = 1;
                                  }

                                  return CustomScrollView(
                                    controller:
                                        scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      if (!isStoreCatalog && homeCheapest.isNotEmpty)
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
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
                                                  AppLocalizations.of(context)!.topDeals,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${AppLocalizations.of(context)!.beauty}, '
                                                  '${AppLocalizations.of(context)!.clothing}, '
                                                  '${AppLocalizations.of(context)!.shoes}, '
                                                  '${AppLocalizations.of(context)!.technology}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
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
                                                  icon:
                                                      Icons.checkroom_outlined,
                                                ),
                                                _buildHomeSection(
                                                  section: 'shoes',
                                                  title: AppLocalizations.of(context)!.shoes,
                                                  icon:
                                                      Icons.shopping_bag_outlined,
                                                ),
                                                _buildHomeSection(
                                                  section: 'tech',
                                                  title: AppLocalizations.of(context)!.technology,
                                                  icon:
                                                      Icons.devices_outlined,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (isStoreCatalog)
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            20,
                                            20,
                                            10,
                                          ),
                                          sliver: SliverList(
                                            delegate: SliverChildBuilderDelegate(
                                              (context, index) {
                                                final product = filteredProducts[index];
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: index == filteredProducts.length - 1 ? 0 : 12,
                                                  ),
                                                  child: StoreCatalogCard(
                                                    product: product,
                                                    imageUrl: product.imageUrl ?? '',
                                                    isFavorite: favoriteIds.contains(product.id),
                                                    onFavorite: () => toggleFavorite(product),
                                                    onDetails: () => openDetails(product),
                                                    priceFormatter: price,
                                                  ),
                                                );
                                              },
                                              childCount: filteredProducts.length,
                                            ),
                                          ),
                                        )
                                      else
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            20,
                                            20,
                                            10,
                                          ),
                                          sliver: SliverGrid(
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: columns,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: columns == 1
                                                  ? 0.82
                                                  : columns == 2
                                                      ? 0.72
                                                      : 0.68,
                                            ),
                                            delegate: SliverChildBuilderDelegate(
                                              (context, index) {
                                                final product = filteredProducts[index];
                                                return ProductCard(
                                                  product: product,
                                                  imageUrl: product.imageUrl ?? '',
                                                  isFavorite: favoriteIds.contains(product.id),
                                                  onFavorite: () => toggleFavorite(product),
                                                  onDetails: () => openDetails(product),
                                                  priceFormatter: price,
                                                );
                                              },
                                              childCount: filteredProducts.length,
                                            ),
                                          ),
                                        ),
                                      SliverToBoxAdapter(
                                        child:
                                            PaginationFooter(
                                          loadingMore:
                                              loadingMore,
                                          hasMore: hasMore,
                                          loadedCount:
                                              products.length,
                                          onLoadMore:
                                              loadMore,
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
        ),    );
  }
}
class FiltersBar extends StatefulWidget {
  final TextEditingController searchController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final String selectedCategory;
  final String selectedBrand;
  final String selectedStore;
  final List<String> availableBrands;
  final int selectedMinDiscount;
  final SortMode selectedSort;
  final bool multiStoreOnly;
  final ValueChanged<bool> onMultiStoreOnlyChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onStoreChanged;
  final ValueChanged<String> onMinPriceChanged;
  final ValueChanged<String> onMaxPriceChanged;
  final ValueChanged<int?> onDiscountChanged;
  final ValueChanged<SortMode?> onSortChanged;
  final VoidCallback onReset;
  final int resultCount;
  final int loadedCount;
  final bool showStoreFilter;

  const FiltersBar({
    super.key,
    required this.searchController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.selectedCategory,
    required this.selectedBrand,
    required this.selectedStore,
    required this.availableBrands,
    required this.selectedMinDiscount,
    required this.selectedSort,
    required this.multiStoreOnly,
    required this.onMultiStoreOnlyChanged,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onStoreChanged,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    required this.onDiscountChanged,
    required this.onSortChanged,
    required this.onReset,
    required this.resultCount,
    required this.loadedCount,
    this.showStoreFilter = true,
  });

  @override
  State<FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<FiltersBar> {
  bool expanded = false;

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.6,
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
        filled: true,
        fillColor: Colors.white,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    final categoryField = DropdownButtonFormField<String>(
      initialValue: widget.selectedCategory,
      isExpanded: true,
      isDense: true,
      decoration: _fieldDecoration(
        _localizedFieldLabel(
          context,
          ru: 'Категория',
          en: 'Category',
          et: 'Kategooria',
          lv: 'Kategorija',
          lt: 'Kategorija',
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Text(AppLocalizations.of(context)!.all),
        ),
        DropdownMenuItem(
          value: 'clothing',
          child: Text(AppLocalizations.of(context)!.clothing),
        ),
        DropdownMenuItem(
          value: 'shoes',
          child: Text(AppLocalizations.of(context)!.shoes),
        ),
        DropdownMenuItem(
          value: 'accessories',
          child: Text(AppLocalizations.of(context)!.accessories),
        ),
        DropdownMenuItem(
          value: 'beauty',
          child: Text(AppLocalizations.of(context)!.beauty),
        ),
        DropdownMenuItem(
          value: 'perfume',
          child: Text(AppLocalizations.of(context)!.perfume),
        ),
        DropdownMenuItem(
          value: 'electronics',
          child: Text(AppLocalizations.of(context)!.technology),
        ),
        DropdownMenuItem(
          value: 'home',
          child: Text(AppLocalizations.of(context)!.homeCategory),
        ),
        DropdownMenuItem(
          value: 'sports',
          child: Text(AppLocalizations.of(context)!.sport),
        ),
      ],
      onChanged: widget.onCategoryChanged,
    );

    final brandField = DropdownButtonFormField<String>(
      initialValue: widget.availableBrands.contains(widget.selectedBrand)
          ? widget.selectedBrand
          : 'all',
      isExpanded: true,
      isDense: true,
      decoration: _fieldDecoration(
        _localizedFieldLabel(
          context,
          ru: 'Бренд',
          en: 'Brand',
          et: 'Bränd',
          lv: 'Zīmols',
          lt: 'Prekės ženklas',
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Text(AppLocalizations.of(context)!.allBrands),
        ),
        ...widget.availableBrands.map(
          (brand) => DropdownMenuItem(
            value: brand,
            child: Text(
              brand,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: widget.onBrandChanged,
    );

final storeField = DropdownButtonFormField<String>(
  initialValue: widget.selectedStore,
  isExpanded: true,
  isDense: true,
  decoration: _fieldDecoration(AppLocalizations.of(context)!.stores),
  items: [
    DropdownMenuItem(
      value: 'all',
      child: Text(AppLocalizations.of(context)!.allStores),
    ),
    DropdownMenuItem(value: 'Sportland Estonia', child: Text('Sportland')),
    DropdownMenuItem(value: 'Rademar Estonia', child: Text('Rademar')),
    DropdownMenuItem(value: 'Weekend Estonia', child: Text('Weekend')),
    DropdownMenuItem(value: 'ABOUT YOU Estonia', child: Text('ABOUT YOU')),
    DropdownMenuItem(value: 'Ballzy Estonia', child: Text('Ballzy')),
    DropdownMenuItem(value: 'Sports Direct Estonia', child: Text('Sports Direct')),
    DropdownMenuItem(value: 'BestSecret', child: Text('BestSecret')),
    DropdownMenuItem(value: 'Kaup24', child: Text('Kaup24')),
    DropdownMenuItem(value: 'Denim Dream', child: Text('Denim Dream')),
    DropdownMenuItem(value: '1a.ee', child: Text('1a.ee')),
    DropdownMenuItem(value: 'Decathlon Estonia', child: Text('Decathlon')),
    DropdownMenuItem(value: 'Notino', child: Text('Notino')),
    DropdownMenuItem(value: 'Stockmann Estonia', child: Text('Stockmann')),
    DropdownMenuItem(value: 'Membershop Estonia', child: Text('Membershop')),
  ],
  onChanged: widget.onStoreChanged,
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
      decoration: _fieldDecoration(AppLocalizations.of(context)!.minDiscount),
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text(AppLocalizations.of(context)!.any),
        ),
        DropdownMenuItem(value: 20, child: Text('20%')),
        DropdownMenuItem(value: 30, child: Text('30%')),
        DropdownMenuItem(value: 40, child: Text('40%')),
        DropdownMenuItem(value: 50, child: Text('50%')),
        DropdownMenuItem(value: 60, child: Text('60%')),
        DropdownMenuItem(value: 70, child: Text('70%')),
      ],
      onChanged: widget.onDiscountChanged,
    );

    final sortField = DropdownButtonFormField<SortMode>(
      initialValue: widget.selectedSort,
      isExpanded: true,
      isDense: true,
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

    final countText = Text(
      AppLocalizations.of(context)!.foundProducts(widget.resultCount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );

    if (isMobile) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.tune,
                    ),
                    label: Text(
                      expanded
                          ? AppLocalizations.of(context)!.hideFilters
                          : AppLocalizations.of(context)!.filters,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(child: countText),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      categoryField,
                      const SizedBox(height: 12),
                      brandField,
                      const SizedBox(height: 12),
                      if (widget.showStoreFilter) ...[
                        storeField,
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: multiStoreField,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: resetButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 300, child: searchField),
          SizedBox(width: 175, child: categoryField),
          SizedBox(width: 175, child: brandField),
          if (widget.showStoreFilter)
            SizedBox(width: 185, child: storeField),
          SizedBox(width: 115, child: minPriceField),
          SizedBox(width: 115, child: maxPriceField),
          SizedBox(width: 140, child: discountField),
          SizedBox(width: 225, child: sortField),
          multiStoreField,
          resetButton,
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150),
            child: countText,
          ),
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
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.loadedProducts(loadedCount),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28,
      ),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(
            Icons.expand_more,
          ),
          label: Text(
            AppLocalizations.of(context)!.loadMore,
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noProducts,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasMore) ...[
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.tryDifferentSearch,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              if (loadingMore)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(AppLocalizations.of(context)!.loadMore),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class StoreCatalogCard extends StatelessWidget {
  final Product product;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onDetails;
  final String Function(double) priceFormatter;

  const StoreCatalogCard({
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
    final hasOldPrice =
        product.oldPrice != null && product.oldPrice! > product.currentPrice;
    final brand = (product.brand?.trim().isNotEmpty ?? false)
        ? product.brand!.trim()
        : product.storeName;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onDetails,
        child: SizedBox(
          height: 176,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFF7F9F9),
                      padding: const EdgeInsets.all(10),
                      child: imageUrl.isEmpty
                          ? const AppProductImagePlaceholder()
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
                              errorBuilder: (context, error, stackTrace) =>
                                  const AppProductImagePlaceholder(),
                            ),
                    ),
                    if (product.discountPercent != null &&
                        product.discountPercent! > 0)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _CardBadge(
                          label: '-${product.discountPercent}%',
                          backgroundColor: const Color(0xFFE5484D),
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: isFavorite
                                  ? AppLocalizations.of(context)!.removeFavorite
                                  : AppLocalizations.of(context)!.addFavorite,
                              onPressed: onFavorite,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 21,
                                color: isFavorite
                                    ? const Color(0xFFE5484D)
                                    : const Color(0xFF4B5560),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              product.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 3,
                              children: [
                                Text(
                                  '${priceFormatter(product.currentPrice)} €',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                if (hasOldPrice)
                                  Text(
                                    '${priceFormatter(product.oldPrice!)} €',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 1),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 25,
                              color: Color(0xFF66727A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final hasOldPrice =
        product.oldPrice != null && product.oldPrice! > product.currentPrice;
    final isMultiStore = product.storesCount > 1;
    final hasSavings = isMultiStore && product.savingsAmount > 0;
    final category = product.category?.trim().toLowerCase();
    final showSizePreview =
        category != 'beauty' && category != 'perfume';

    final brand = (product.brand?.trim().isNotEmpty ?? false)
        ? product.brand!.trim()
        : product.storeName;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 154,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF7F9F9),
                    padding: const EdgeInsets.all(10),
                    child: imageUrl.isEmpty
                        ? const AppProductImagePlaceholder()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (context, error, stackTrace) {
                              return const AppProductImagePlaceholder();
                            },
                          ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    right: 58,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (product.discountPercent != null &&
                            product.discountPercent! > 0)
                          _CardBadge(
                            label: '-${product.discountPercent}%',
                            backgroundColor: const Color(0xFFE5484D),
                            foregroundColor: Colors.white,
                          ),
                        if (isMultiStore)
                          _CardBadge(
                            label: AppLocalizations.of(context)!.storesCount(product.storesCount),
                            backgroundColor: const Color(0xFFE5F4F2),
                            foregroundColor: const Color(0xFF0F766E),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.96),
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite
                            ? AppLocalizations.of(context)!.removeFavorite
                            : AppLocalizations.of(context)!.addFavorite,
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 21,
                          color: isFavorite
                              ? const Color(0xFFE5484D)
                              : const Color(0xFF4B5560),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isMultiStore
                                ? '${AppLocalizations.of(context)!.bestPrice} · ${product.storeName}'
                                : product.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isMultiStore
                                  ? const Color(0xFF0F766E)
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: isMultiStore
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasSavings) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.savings_outlined,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.savingsUpTo(
                                  priceFormatter(product.savingsAmount),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (showSizePreview)
                      ProductCardSizePreview(productId: product.id),
                    const Spacer(),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${priceFormatter(product.currentPrice)} €',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        if (hasOldPrice)
                          Text(
                            '${priceFormatter(product.oldPrice!)} €',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (product.hasCoupon)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5F3),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFB8DED9),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.coupon,
                              style: TextStyle(
                                color: const Color(0xFF0F766E),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2C9CC3),
                              Color(0xFF5ED6D0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x260B7285),
                              offset: Offset(0, 3),
                              blurRadius: 7,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: onDetails,
                          icon: Icon(
                            isMultiStore
                                ? Icons.compare_arrows
                                : Icons.info_outline,
                            size: 18,
                          ),
                          label: Text(
                            isMultiStore ? AppLocalizations.of(context)!.compareStores : AppLocalizations.of(context)!.details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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

  static const String _apiBase =
      'https://baltic-deals-api.noduys.workers.dev';

  static final Map<int, Future<List<String>>> _cache = {};

  Future<List<String>> _loadSizes() {
    return _cache.putIfAbsent(productId, () async {
      try {
        final uri = Uri.parse('$_apiBase/sizes').replace(
          queryParameters: {
            'productId': productId.toString(),
          },
        );

        final response = await http.get(uri);

        if (response.statusCode != 200) {
          return <String>[];
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          return <String>[];
        }

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _loadSizes(),
      builder: (context, snapshot) {
        final sizes = snapshot.data;

        if (sizes == null || sizes.isEmpty) {
          return const SizedBox.shrink();
        }

        final visible = sizes.take(4).toList();
        final remaining = sizes.length - visible.length;

        final label = [
          ...visible,
          if (remaining > 0) '+$remaining',
        ].join(' • ');

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.sizesLabel(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
  final int storeProductId;
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
    required this.storeProductId,
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

  factory StoreOffer.fromJson(
    Map<String, dynamic> json,
  ) {
    return StoreOffer(
      storeProductId:
          (json['store_product_id'] as num?)?.toInt() ?? 0,
      storeName:
          json['store_name']?.toString() ?? 'Store',
      country:
          json['country']?.toString() ?? '',
      productUrl:
          json['product_url']?.toString() ?? '',
      currentPrice:
          (json['current_price'] as num?)?.toDouble() ?? 0,
      oldPrice:
          (json['old_price'] as num?)?.toDouble(),
      currency:
          json['currency']?.toString() ?? 'EUR',
      availability:
          json['availability']?.toString(),
      discountPercent:
          (json['discount_percent'] as num?)?.toInt(),
          hasCoupon:
    (json['has_coupon'] as num?)?.toInt() == 1,
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

  factory ProductSizeOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductSizeOption(
      size: json['size']?.toString() ?? '',
      availability:
          json['availability']?.toString(),
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

  factory ProductSizeStore.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSizes =
        json['sizes'] as List<dynamic>? ?? [];

    return ProductSizeStore(
      storeName:
          json['store_name']?.toString() ?? 'Store',
      country:
          json['country']?.toString() ?? '',
      currentPrice:
          (json['current_price'] as num?)?.toDouble() ?? 0,
      currency:
          json['currency']?.toString() ?? 'EUR',
      productUrl:
          json['product_url']?.toString() ?? '',
      sizes: rawSizes
          .map(
            (item) => ProductSizeOption.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .where((item) => item.size.isNotEmpty)
          .toList(),
    );
  }

  bool hasSize(String size) {
    return sizes.any(
      (item) =>
          item.size == size &&
          item.availability != 'out_of_stock',
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

  factory PriceHistoryPoint.fromJson(
    Map<String, dynamic> json,
  ) {
    return PriceHistoryPoint(
      price:
          (json['price'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(
        json['recorded_at']?.toString() ?? '',
      ),
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
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  static const String apiBase =
      'https://baltic-deals-api.noduys.workers.dev';

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

  String get _priceAlertKey =>
      'price_alert_target_${widget.product.id}';

  Future<void> loadPriceAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId();
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
          'deviceId': deviceId,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final alert = decoded['alert'];

          if (alert is Map) {
            final rawTarget = alert['target_price'];
            final serverTarget = rawTarget is num
                ? rawTarget.toDouble()
                : double.tryParse(rawTarget?.toString() ?? '');

            final rawTriggered = alert['is_triggered'];
            final serverTriggered =
                rawTriggered == true ||
                rawTriggered == 1 ||
                rawTriggered?.toString() == '1';

            final rawTriggeredPrice = alert['triggered_price'];
            final serverTriggeredPrice = rawTriggeredPrice is num
                ? rawTriggeredPrice.toDouble()
                : double.tryParse(
                    rawTriggeredPrice?.toString() ?? '',
                  );

            final serverTriggeredAt =
                alert['triggered_at']?.toString();

            if (serverTarget != null && serverTarget > 0) {
              await prefs.setDouble(_priceAlertKey, serverTarget);

              if (!mounted) return;
              setState(() {
                priceAlertTarget = serverTarget;
                priceAlertTriggered = serverTriggered;
                priceAlertTriggeredPrice =
                    serverTriggeredPrice;
                priceAlertTriggeredAt =
                    serverTriggeredAt;
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
    } catch (_) {
      // Keep the locally cached value when the API is temporarily unavailable.
    }

    if (!mounted) return;
    setState(() {
      priceAlertTarget = localValue;
      priceAlertLoading = false;
    });
  }

  Future<void> savePriceAlert(double target) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId();
    final roundedTarget = double.parse(target.toStringAsFixed(2));

    try {
      final response = await http.post(
        Uri.parse(
          'https://baltic-deals-api.noduys.workers.dev/price-alert',
        ),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': widget.product.id,
          'targetPrice': roundedTarget,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('API ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true) {
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
            AppLocalizations.of(context)!.targetSavedServer(
              '${widget.priceFormatter(roundedTarget)} €',
            ),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.serverUnavailableSavedLocally,
          ),
        ),
      );
    }
  }

  Future<void> removePriceAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId();

    try {
      final uri = Uri.parse(
        'https://baltic-deals-api.noduys.workers.dev/price-alert',
      ).replace(
        queryParameters: {
          'productId': widget.product.id.toString(),
          'deviceId': deviceId,
        },
      );

      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('API ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true) {
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.priceTrackingDisabled,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.priceTrackingDisableFailed,
          ),
        ),
      );
    }
  }

  Future<void> showPriceAlertDialog() async {
    final initialTarget = priceAlertTarget ??
        (widget.product.currentPrice * 0.9);

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
                      AppLocalizations.of(context)!.currentPriceLabel(
                        '${widget.priceFormatter(widget.product.currentPrice)} €',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.desiredPrice,
                        hintText: AppLocalizations.of(context)!.priceExample,
                        errorText: validationError,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        final raw =
                            controller.text.trim().replaceAll(',', '.');
                        final value = double.tryParse(raw);

                        if (value == null || value <= 0) {
                          setDialogState(() {
                            validationError =
                                AppLocalizations.of(context)!.invalidPrice;
                          });
                          return;
                        }

                        Navigator.of(dialogContext).pop(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.priceAlertInfo,
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
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(-1),
                    child: Text(AppLocalizations.of(context)!.disable),
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final raw =
                        controller.text.trim().replaceAll(',', '.');
                    final value = double.tryParse(raw);

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        validationError =
                            AppLocalizations.of(context)!.invalidPrice;
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(AppLocalizations.of(context)!.save),
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
      final uri = Uri.parse(
        '$apiBase/offers',
      ).replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'API returned ${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      final items =
          decoded['offers'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        offers = items
            .map(
              (item) => StoreOffer.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        offersLoading = false;
        offersError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        offersLoading = false;
        offersError = e.toString();
      });
    }
  }

  Future<void> loadSizes() async {
    try {
      final uri = Uri.parse(
        '$apiBase/sizes',
      ).replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'API returned ${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      final rawSizes =
          decoded['all_sizes'] as List<dynamic>? ?? [];

      final rawStores =
          decoded['stores'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        allSizes = rawSizes
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();

        sizeStores = rawStores
            .map(
              (item) => ProductSizeStore.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        sizesLoading = false;
        sizesError = null;

        if (
          selectedSize != null &&
          !allSizes.contains(selectedSize)
        ) {
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
      final uri = Uri.parse(
        '$apiBase/price-history',
      ).replace(
        queryParameters: {
          'productId': '${widget.product.id}',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'API returned ${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      final items =
          decoded['history'] as List<dynamic>? ?? [];

      final stats =
          decoded['stats'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        history = items
            .map(
              (item) => PriceHistoryPoint.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        minHistoryPrice =
            (stats?['min_price'] as num?)?.toDouble();

        maxHistoryPrice =
            (stats?['max_price'] as num?)?.toDouble();

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

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  }

  List<ProductSizeStore> storesForSize(String size) {
    return sizeStores
        .where((store) => store.hasSize(size))
        .toList();
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

  Future<void> openSizeStore(
    ProductSizeStore store,
  ) async {
    final uri =
        Uri.tryParse(store.productUrl);

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final hasOldPrice =
        product.oldPrice != null &&
            product.oldPrice! > product.currentPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.brand?.isNotEmpty == true
              ? product.brand!
              : AppLocalizations.of(context)!.product,
        ),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? AppLocalizations.of(context)!.removeFavorite
                : AppLocalizations.of(context)!.addFavorite,
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });

              widget.onFavorite();
            },
            icon: Icon(
              isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: isFavorite
                  ? const Color(0xFFE5484D)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;

          final image = Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: widget.imageUrl.isEmpty
                ? const AppProductImagePlaceholder()
                : Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    webHtmlElementStrategy:
                        WebHtmlElementStrategy.prefer,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const AppProductImagePlaceholder();
                    },
                  ),
          );

          final info = SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (product.brand != null &&
                    product.brand!.isNotEmpty)
                  Text(
                    product.brand!.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${product.storeName} • ${product.country}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  crossAxisAlignment:
                      WrapCrossAlignment.end,
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
                          color: Colors.grey.shade600,
                          decoration:
                              TextDecoration.lineThrough,
                        ),
                      ),
                    if (product.discountPercent != null &&
                        product.discountPercent! > 0)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius:
                              BorderRadius.circular(20),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
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
                              ? Colors.grey.shade100
                              : Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: priceAlertTarget == null
                            ? Colors.grey.shade300
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
                              ? Theme.of(context)
                                  .colorScheme
                                  .tertiary
                              : priceAlertTarget == null
                                  ? Colors.grey.shade700
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                priceAlertTriggered &&
                                        priceAlertTarget != null
                                    ? AppLocalizations.of(context)!.targetReached
                                    : priceAlertTarget == null
                                        ? AppLocalizations.of(context)!.trackPrice
                                        : AppLocalizations.of(context)!.targetValue(
                                            '${widget.priceFormatter(priceAlertTarget!)} €',
                                          ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                priceAlertTriggered &&
                                        priceAlertTarget != null
                                    ? AppLocalizations.of(context)!.triggeredAtTarget(
                                        '${widget.priceFormatter(priceAlertTriggeredPrice ?? widget.product.currentPrice)} €',
                                        '${widget.priceFormatter(priceAlertTarget!)} €',
                                      )
                                    : priceAlertTarget == null
                                        ? AppLocalizations.of(context)!.priceAlertPrompt
                                        : widget.product.currentPrice <=
                                                priceAlertTarget!
                                            ? AppLocalizations.of(context)!.priceAlreadyReached
                                            : AppLocalizations.of(context)!.priceAboveTarget(
                                                '${widget.priceFormatter(widget.product.currentPrice - priceAlertTarget!)} €',
                                              ),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
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
                const SizedBox(height: 24),
                AppDetailRow(
                  icon: Icons.category_outlined,
                  label: AppLocalizations.of(context)!.category,
                  value: _categoryLabel(
                    product.category,
                  ),
                ),
                AppDetailRow(
                  icon: Icons.person_outline,
                  label: AppLocalizations.of(context)!.gender,
                  value:
                      product.gender?.isNotEmpty == true
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
                    if (!sizesLoading &&
                        sizesError == null &&
                        allSizes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.availableCount(
                            allSizes.where(isSizeAvailable).length,
                          ),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.loadingSizes,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (sizesError != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.loadSizesFailed,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
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
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  )
                else if (allSizes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.noSizeData,
                            style: TextStyle(
                              color: Colors.grey.shade700,
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
                        ? AppLocalizations.of(context)!.chooseSize
                        : AppLocalizations.of(context)!.selectedSize(selectedSize!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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
                                    selectedSize =
                                        selected ? size : null;
                                  });
                                }
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.unavailableSizesGray,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (selectedSize != null) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final selectedStores =
                            storesForSize(selectedSize!);
                        final bestPrice =
                            bestPriceForSize(selectedSize!);

                        if (selectedStores.isEmpty) {
                          return Text(
                            AppLocalizations.of(context)!.selectedSizeUnavailable,
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                                  const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.sizeStoreCount(
                                            selectedSize!,
                                            selectedStores.length,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (bestPrice != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            AppLocalizations.of(context)!.bestPriceValue(
                                              '${widget.priceFormatter(bestPrice)} €',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
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
                                margin: const EdgeInsets.only(
                                  bottom: 8,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.storefront_outlined,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    store.storeName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                if (bestPrice != null &&
                                                    (store.currentPrice -
                                                            bestPrice)
                                                        .abs() <
                                                        0.001) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      AppLocalizations.of(context)!.bestPrice,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
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
                                            Text(
                                              AppLocalizations.of(context)!.inStock,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton(
                                        onPressed: () =>
                                            openSizeStore(store),
                                        child: Text(AppLocalizations.of(context)!.open),
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
                Text(
                  AppLocalizations.of(context)!.storePrices,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (offersLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (offersError != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.loadOffersFailed,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            offersLoading = true;
                            offersError = null;
                          });
                          loadOffers();
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  )
                else if (offers.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.noOffers,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final offer in offers)
                        _OfferCard(
                          offer: offer,
                          priceFormatter:
                              widget.priceFormatter,
                          onOpen: () =>
                              openOffer(offer),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.priceHistory,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (historyLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 24,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (historyError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.loadPriceHistoryFailed,
                            style: TextStyle(
                              color: Colors.grey.shade700,
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
                          child: Text(AppLocalizations.of(context)!.retry),
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
                        label: AppLocalizations.of(context)!.now,
                        value:
                            '${widget.priceFormatter(product.currentPrice)} €',
                      ),
                      _PriceStat(
                        label: AppLocalizations.of(context)!.minimum,
                        value:
                            '${widget.priceFormatter(minHistoryPrice ?? product.currentPrice)} €',
                      ),
                      _PriceStat(
                        label: AppLocalizations.of(context)!.maximum,
                        value:
                            '${widget.priceFormatter(maxHistoryPrice ?? product.currentPrice)} €',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: PriceHistoryChart(
                      history: history,
                      fallbackPrice:
                          product.currentPrice,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    history.length <= 1
                        ? AppLocalizations.of(context)!.historyStarted
                        : AppLocalizations.of(context)!.historyPoints(history.length),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onOpenStore,
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.goToStore,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: image,
                ),
                Expanded(
                  flex: 5,
                  child: info,
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 420,
                  width: double.infinity,
                  child: image,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 520,
                    maxHeight:
                        MediaQuery.sizeOf(context).height,
                  ),
                  child: info,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryLabel(String? category) {
    switch (category) {
      case 'shoes':
        return AppLocalizations.of(context)!.shoes;
      case 'clothing':
        return AppLocalizations.of(context)!.clothing;
      case 'sports':
        return AppLocalizations.of(context)!.sport;
      default:
        return category?.isNotEmpty == true
            ? category!
            : AppLocalizations.of(context)!.notSpecified;
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
    final hasOldPrice =
        offer.oldPrice != null &&
            offer.oldPrice! > offer.currentPrice;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.country,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment:
                        WrapCrossAlignment.center,
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
    label: AppLocalizations.of(context)!.coupon,
    backgroundColor: Colors.blue.shade50,
    foregroundColor: Colors.blue.shade800,
  ),
                      if (hasOldPrice)
                        Text(
                          '${priceFormatter(offer.oldPrice!)} €',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration:
                                TextDecoration.lineThrough,
                          ),
                        ),
                      if (offer.discountPercent != null &&
                          offer.discountPercent! > 0)
                        Text(
                          '-${offer.discountPercent}%',
                          style: const TextStyle(
                            color: Color(0xFFE5484D),
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
              child: Text(AppLocalizations.of(context)!.open),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
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
    final prices = history.isEmpty
        ? <double>[fallbackPrice]
        : history.map((e) => e.price).toList();

    return CustomPaint(
      painter: _PriceHistoryPainter(
        prices: prices,
        lineColor:
            Theme.of(context).colorScheme.primary,
        gridColor: Colors.grey.shade300,
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

    final minPrice =
        prices.reduce((a, b) => a < b ? a : b);
    final maxPrice =
        prices.reduce((a, b) => a > b ? a : b);

    final range =
        (maxPrice - minPrice).abs() < 0.001
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
          : left +
              width * i / (prices.length - 1);

      final normalized =
          (prices[i] - minPrice) / range;

      final y =
          top + height * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        4,
        pointPaint,
      );
    }

    if (prices.length > 1) {
      canvas.drawPath(
        path,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _PriceHistoryPainter oldDelegate,
  ) {
    return oldDelegate.prices != prices ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class ProductImagePlaceholder
    extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 54,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              AppLocalizations.of(context)!.loadingError,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            FilledButton.icon(
              onPressed: onRetry,
              icon:
                  const Icon(
                Icons.refresh,
              ),
               label: Text(
                AppLocalizations.of(context)!.retry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}