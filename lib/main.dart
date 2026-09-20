import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _webVapidKey =
    'BAeMMjHE9TkBtALMEoekwr0FlmgyjY6eeo03QFnlGFoqs8XNVY9mRYx4lqrLiCoRaoNT411Q7djVorhbuGLB6MI';

Future<void> _registerPushToken(String token) async {
  try {
    final response = await http.post(
      Uri.parse(
        'https://baltic-deals-api.noduys.workers.dev/push-token',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
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
      debugPrint('FCM TOKEN: Ð½Ðµ Ð¿Ð¾Ð»ÑƒÑ‡ÐµÐ½');
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

class BalticDealsApp extends StatelessWidget {
  const BalticDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baltic Deals',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F7),
      ),
      home: const ProductsPage(),
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
            const Text(
              'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ Ñ‚Ð¾Ð²Ð°Ñ€Ñ‹',
              style: TextStyle(
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
              label: const Text('ÐŸÐ¾Ð²Ñ‚Ð¾Ñ€Ð¸Ñ‚ÑŒ'),
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
    final response = await http.get(
      Uri.parse('$apiBase/home-cheapest?limit=30'),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    final items =
        decoded['products'] as List<dynamic>? ?? const [];

    final loaded = items
        .map(
          (item) => Product.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    if (!mounted) return;

    setState(() {
      homeCheapest = loaded;
      homeCheapestLoading = false;
    });
  } catch (e) {
    debugPrint('Home cheapest load error: $e');

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
    final value = product.productUrl;

    if (value == null || value.isEmpty) {
      showMessage('Ð¡ÑÑ‹Ð»ÐºÐ° Ð½Ð° Ñ‚Ð¾Ð²Ð°Ñ€ Ð¾Ñ‚ÑÑƒÑ‚ÑÑ‚Ð²ÑƒÐµÑ‚');
      return;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      showMessage('ÐÐµÐºÐ¾Ñ€Ñ€ÐµÐºÑ‚Ð½Ð°Ñ ÑÑÑ‹Ð»ÐºÐ° Ð½Ð° Ñ‚Ð¾Ð²Ð°Ñ€');
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!opened) {
      showMessage('ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð¾Ñ‚ÐºÑ€Ñ‹Ñ‚ÑŒ Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½');
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
    return homeCheapest
        .where((product) => product.homeSection == section)
        .toList();
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
            height: 510,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final product = items[index];

                return SizedBox(
                  width: 240,
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
          labelText: 'Открыть магазин',
          prefixIcon: const Icon(Icons.storefront_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Все магазины')),
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
                ? 'ÐŸÐ¾ÐºÐ°Ð·Ð°Ñ‚ÑŒ Ð²ÑÐµ Ñ‚Ð¾Ð²Ð°Ñ€Ñ‹'
                : 'ÐŸÐ¾ÐºÐ°Ð·Ð°Ñ‚ÑŒ Ð¸Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ðµ',
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
            tooltip: 'ÐžÐ±Ð½Ð¾Ð²Ð¸Ñ‚ÑŒ',
            onPressed: refreshProducts,
            icon: const Icon(Icons.refresh),
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
              color: Colors.white.withValues(alpha: 0.30),
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
                              'Ð˜Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ðµ: ${favoriteIds.length}',
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
                              child: const Text('ÐŸÐ¾ÐºÐ°Ð·Ð°Ñ‚ÑŒ Ð²ÑÐµ'),
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

                                  if (width >= 1400) {
                                    columns = 5;
                                  } else if (width >=
                                      1100) {
                                    columns = 4;
                                  } else if (width >= 800) {
                                    columns = 3;
                                  } else if (width >= 520) {
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
                                                const Text(
                                                  'Ð›ÑƒÑ‡ÑˆÐ¸Ðµ Ñ†ÐµÐ½Ñ‹ ÑÐµÐ¹Ñ‡Ð°Ñ',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ÐšÑ€Ð°ÑÐ¾Ñ‚Ð°, Ð¾Ð´ÐµÐ¶Ð´Ð°, Ð¾Ð±ÑƒÐ²ÑŒ Ð¸ Ñ‚ÐµÑ…Ð½Ð¸ÐºÐ° Ð¿Ð¾ Ð²Ñ‹Ð³Ð¾Ð´Ð½Ñ‹Ð¼ Ñ†ÐµÐ½Ð°Ð¼',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                _buildHomeSection(
                                                  section: 'beauty',
                                                  title: 'ÐšÑ€Ð°ÑÐ¾Ñ‚Ð°',
                                                  icon: Icons.spa_outlined,
                                                ),
                                                _buildHomeSection(
                                                  section: 'fashion',
                                                  title: 'ÐžÐ´ÐµÐ¶Ð´Ð°',
                                                  icon:
                                                      Icons.checkroom_outlined,
                                                ),
                                                _buildHomeSection(
                                                  section: 'shoes',
                                                  title: 'ÐžÐ±ÑƒÐ²ÑŒ',
                                                  icon:
                                                      Icons.shopping_bag_outlined,
                                                ),
                                                _buildHomeSection(
                                                  section: 'tech',
                                                  title: 'Ð¢ÐµÑ…Ð½Ð¸ÐºÐ°',
                                                  icon:
                                                      Icons.devices_outlined,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      SliverPadding(
                                        padding:
                                            const EdgeInsets
                                                .fromLTRB(
                                          20,
                                          20,
                                          20,
                                          10,
                                        ),
                                        sliver:
                                            SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                columns,
                                            crossAxisSpacing:
                                                16,
                                            mainAxisSpacing:
                                                16,
                                            childAspectRatio:
                                                columns == 1
                                                    ? 0.87
                                                    : 0.58,
                                          ),
                                          delegate:
                                              SliverChildBuilderDelegate(
                                            (
                                              context,
                                              index,
                                            ) {
                                              final product =
                                                  filteredProducts[
                                                      index];

                                              return ProductCard(
                                                product:
                                                    product,
                                                imageUrl:
                                                    product.imageUrl ?? '',
                                                isFavorite:
                                                    favoriteIds
                                                        .contains(
                                                  product.id,
                                                ),
                                                onFavorite: () =>
                                                    toggleFavorite(
                                                  product,
                                                ),
                                                onDetails: () =>
                                                    openDetails(
                                                  product,
                                                ),
                                                priceFormatter:
                                                    price,
                                              );
                                            },
                                            childCount:
                                                filteredProducts
                                                    .length,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
        hintText: 'ÐŸÐ¾Ð¸ÑÐº Ð¿Ð¾ Ñ‚Ð¾Ð²Ð°Ñ€Ñƒ Ð¸Ð»Ð¸ Ð±Ñ€ÐµÐ½Ð´Ñƒ',
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final categoryField = DropdownButtonFormField<String>(
      initialValue: widget.selectedCategory,
      isExpanded: true,
      isDense: true,
      decoration: _fieldDecoration('ÐšÐ°Ñ‚ÐµÐ³Ð¾Ñ€Ð¸Ñ'),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Все')),
        DropdownMenuItem(value: 'clothing', child: Text('Одежда')),
        DropdownMenuItem(value: 'shoes', child: Text('Обувь')),
        DropdownMenuItem(value: 'accessories', child: Text('Аксессуары')),
        DropdownMenuItem(value: 'beauty', child: Text('Красота')),
        DropdownMenuItem(value: 'perfume', child: Text('Парфюмерия')),
        DropdownMenuItem(value: 'electronics', child: Text('Техника')),
        DropdownMenuItem(value: 'home', child: Text('Дом')),
        DropdownMenuItem(value: 'sports', child: Text('Спорт')),
      ],
      onChanged: widget.onCategoryChanged,
    );

    final brandField = DropdownButtonFormField<String>(
      initialValue: widget.availableBrands.contains(widget.selectedBrand)
          ? widget.selectedBrand
          : 'all',
      isExpanded: true,
      isDense: true,
      decoration: _fieldDecoration('Ð‘Ñ€ÐµÐ½Ð´'),
      items: [
        const DropdownMenuItem(
          value: 'all',
          child: Text('Ð’ÑÐµ Ð±Ñ€ÐµÐ½Ð´Ñ‹'),
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
  decoration: _fieldDecoration('Магазин'),
  items: const [
    DropdownMenuItem(value: 'all', child: Text('Все магазины')),
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
      decoration: _fieldDecoration('Ð¦ÐµÐ½Ð° Ð¾Ñ‚').copyWith(suffixText: 'â‚¬'),
    );

    final maxPriceField = TextField(
      controller: widget.maxPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onMaxPriceChanged,
      decoration: _fieldDecoration('Ð¦ÐµÐ½Ð° Ð´Ð¾').copyWith(suffixText: 'â‚¬'),
    );

    final discountField = DropdownButtonFormField<int>(
      initialValue: widget.selectedMinDiscount,
      isDense: true,
      decoration: _fieldDecoration('Ð¡ÐºÐ¸Ð´ÐºÐ° Ð¾Ñ‚'),
      items: const [
        DropdownMenuItem(value: 0, child: Text('Ð›ÑŽÐ±Ð°Ñ')),
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
      decoration: _fieldDecoration('Ð¡Ð¾Ñ€Ñ‚Ð¸Ñ€Ð¾Ð²ÐºÐ°'),
      items: const [
        DropdownMenuItem(
          value: SortMode.discountHigh,
          child: Text('Ð¡Ð°Ð¼Ð°Ñ Ð±Ð¾Ð»ÑŒÑˆÐ°Ñ ÑÐºÐ¸Ð´ÐºÐ°', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.savingsHigh,
          child: Text('ÐœÐ°ÐºÑÐ¸Ð¼Ð°Ð»ÑŒÐ½Ð°Ñ ÑÐºÐ¾Ð½Ð¾Ð¼Ð¸Ñ', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceLow,
          child: Text('Ð¡Ð½Ð°Ñ‡Ð°Ð»Ð° Ð´ÐµÑˆÐµÐ²Ð»Ðµ', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceHigh,
          child: Text('Ð¡Ð½Ð°Ñ‡Ð°Ð»Ð° Ð´Ð¾Ñ€Ð¾Ð¶Ðµ', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.brand,
          child: Text('ÐŸÐ¾ Ð±Ñ€ÐµÐ½Ð´Ñƒ', overflow: TextOverflow.ellipsis),
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
        label: const Text('Ð•ÑÑ‚ÑŒ Ð² Ð½ÐµÑÐºÐ¾Ð»ÑŒÐºÐ¸Ñ… Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ð°Ñ…'),
      ),
    );

    final resetButton = SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: widget.onReset,
        icon: const Icon(Icons.filter_alt_off),
        label: const Text('Ð¡Ð±Ñ€Ð¾ÑÐ¸Ñ‚ÑŒ'),
      ),
    );

    final countText = Text(
      'ÐÐ°Ð¹Ð´ÐµÐ½Ð¾: ${widget.resultCount} â€¢ Ð—Ð°Ð³Ñ€ÑƒÐ¶ÐµÐ½Ð¾: ${widget.loadedCount}',
      style: const TextStyle(fontWeight: FontWeight.w700),
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
                      expanded ? 'Ð¡ÐºÑ€Ñ‹Ñ‚ÑŒ Ñ„Ð¸Ð»ÑŒÑ‚Ñ€Ñ‹' : 'Ð¤Ð¸Ð»ÑŒÑ‚Ñ€Ñ‹',
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
            'Ð’ÑÐµ Ð·Ð°Ð³Ñ€ÑƒÐ¶ÐµÐ½Ð½Ñ‹Ðµ Ñ‚Ð¾Ð²Ð°Ñ€Ñ‹ Ð¿Ð¾ÐºÐ°Ð·Ð°Ð½Ñ‹',
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
            'Ð—Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ ÐµÑ‰Ñ‘ $pageLabel',
          ),
        ),
      ),
    );
  }

  String get pageLabel => '40 Ñ‚Ð¾Ð²Ð°Ñ€Ð¾Ð²';
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
            const Text(
              'ÐÐ¸Ñ‡ÐµÐ³Ð¾ Ð½Ðµ Ð½Ð°Ð¹Ð´ÐµÐ½Ð¾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasMore) ...[
              const SizedBox(height: 10),
              Text(
                'ÐŸÐ¾Ð¿Ñ€Ð¾Ð±ÑƒÐ¹ Ð¸Ð·Ð¼ÐµÐ½Ð¸Ñ‚ÑŒ Ð¿Ð¾Ð¸ÑÐº Ð¸Ð»Ð¸ Ñ„Ð¸Ð»ÑŒÑ‚Ñ€Ñ‹.',
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
                  label: const Text('Ð—Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ ÐµÑ‰Ñ‘'),
                ),
            ],
          ],
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

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
                    color: Colors.white,
                    padding: const EdgeInsets.all(14),
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
                    top: 10,
                    left: 10,
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
                            label: 'Ð¡Ñ€Ð°Ð²Ð½ÐµÐ½Ð¸Ðµ Ñ†ÐµÐ½',
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Ð£Ð±Ñ€Ð°Ñ‚ÑŒ Ð¸Ð· Ð¸Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ð³Ð¾'
                            : 'Ð”Ð¾Ð±Ð°Ð²Ð¸Ñ‚ÑŒ Ð² Ð¸Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ðµ',
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
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 10),
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
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (isMultiStore)
                          Text(
                            '${product.storesCount} Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ð°',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.23,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isMultiStore
                          ? 'Ð›ÑƒÑ‡ÑˆÐ°Ñ Ñ†ÐµÐ½Ð° â€¢ ${product.storeName}'
                          : '${product.storeName} â€¢ ${product.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMultiStore
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight:
                            isMultiStore ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    if (hasSavings) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.savings_outlined, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ð­ÐºÐ¾Ð½Ð¾Ð¼Ð¸Ñ Ð´Ð¾ ${priceFormatter(product.savingsAmount)} â‚¬',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${priceFormatter(product.currentPrice)} â‚¬',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                    if (product.hasCoupon) ...[
  const SizedBox(width: 8),
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: Colors.blue.shade300,
      ),
    ),
    child: Text(
      'ÐšÐ£ÐŸÐžÐ',
      style: TextStyle(
        color: Colors.blue.shade800,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
],
                              if (hasOldPrice) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '${priceFormatter(product.oldPrice!)} â‚¬',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onDetails,
                        icon: Icon(
                          isMultiStore
                              ? Icons.compare_arrows
                              : Icons.open_in_new,
                          size: 18,
                        ),
                        label: Text(
                          isMultiStore ? 'Ð¡Ñ€Ð°Ð²Ð½Ð¸Ñ‚ÑŒ Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ñ‹' : 'ÐŸÐ¾Ð´Ñ€Ð¾Ð±Ð½ÐµÐµ',
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
        ].join(' â€¢ ');

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
                    'Ð Ð°Ð·Ð¼ÐµÑ€Ñ‹: $label',
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
          json['store_name']?.toString() ?? 'ÐœÐ°Ð³Ð°Ð·Ð¸Ð½',
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
          json['store_name']?.toString() ?? 'ÐœÐ°Ð³Ð°Ð·Ð¸Ð½',
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
            'Ð¦ÐµÐ»ÑŒ ÑÐ¾Ñ…Ñ€Ð°Ð½ÐµÐ½Ð° Ð½Ð° ÑÐµÑ€Ð²ÐµÑ€Ðµ: ${widget.priceFormatter(roundedTarget)} â‚¬',
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
            'Ð¡ÐµÑ€Ð²ÐµÑ€ Ð²Ñ€ÐµÐ¼ÐµÐ½Ð½Ð¾ Ð½ÐµÐ´Ð¾ÑÑ‚ÑƒÐ¿ÐµÐ½. Ð¦ÐµÐ»ÑŒ ÑÐ¾Ñ…Ñ€Ð°Ð½ÐµÐ½Ð° Ñ‚Ð¾Ð»ÑŒÐºÐ¾ Ð½Ð° ÑÑ‚Ð¾Ð¼ ÑƒÑÑ‚Ñ€Ð¾Ð¹ÑÑ‚Ð²Ðµ.',
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
        const SnackBar(
          content: Text('ÐžÑ‚ÑÐ»ÐµÐ¶Ð¸Ð²Ð°Ð½Ð¸Ðµ Ñ†ÐµÐ½Ñ‹ Ð¾Ñ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¾ Ð½Ð° ÑÐµÑ€Ð²ÐµÑ€Ðµ'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð¾Ñ‚ÐºÐ»ÑŽÑ‡Ð¸Ñ‚ÑŒ Ñ†ÐµÐ»ÑŒ Ð½Ð° ÑÐµÑ€Ð²ÐµÑ€Ðµ. ÐŸÐ¾Ð¿Ñ€Ð¾Ð±ÑƒÐ¹Ñ‚Ðµ ÐµÑ‰Ñ‘ Ñ€Ð°Ð·.',
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
              title: const Text('ÐžÑ‚ÑÐ»ÐµÐ¶Ð¸Ð²Ð°Ñ‚ÑŒ ÑÐ½Ð¸Ð¶ÐµÐ½Ð¸Ðµ Ñ†ÐµÐ½Ñ‹'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ð¢ÐµÐºÑƒÑ‰Ð°Ñ Ñ†ÐµÐ½Ð°: ${widget.priceFormatter(widget.product.currentPrice)} â‚¬',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Ð–ÐµÐ»Ð°ÐµÐ¼Ð°Ñ Ñ†ÐµÐ½Ð°, â‚¬',
                        hintText: 'ÐÐ°Ð¿Ñ€Ð¸Ð¼ÐµÑ€ 49.99',
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
                                'Ð’Ð²ÐµÐ´Ð¸Ñ‚Ðµ ÐºÐ¾Ñ€Ñ€ÐµÐºÑ‚Ð½ÑƒÑŽ Ñ†ÐµÐ½Ñƒ';
                          });
                          return;
                        }

                        Navigator.of(dialogContext).pop(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ð¦ÐµÐ»ÑŒ ÑÐ¾Ñ…Ñ€Ð°Ð½ÑÐµÑ‚ÑÑ Ð½Ð° ÑÐµÑ€Ð²ÐµÑ€Ðµ Baltic Deals. Push-ÑƒÐ²ÐµÐ´Ð¾Ð¼Ð»ÐµÐ½Ð¸Ñ Ð¿Ð¾Ð´ÐºÐ»ÑŽÑ‡Ð¸Ð¼ Ð¿Ð¾Ð·Ð¶Ðµ Ñ‡ÐµÑ€ÐµÐ· Firebase.',
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
                    child: const Text('ÐžÑ‚ÐºÐ»ÑŽÑ‡Ð¸Ñ‚ÑŒ'),
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('ÐžÑ‚Ð¼ÐµÐ½Ð°'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw =
                        controller.text.trim().replaceAll(',', '.');
                    final value = double.tryParse(raw);

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        validationError =
                            'Ð’Ð²ÐµÐ´Ð¸Ñ‚Ðµ ÐºÐ¾Ñ€Ñ€ÐµÐºÑ‚Ð½ÑƒÑŽ Ñ†ÐµÐ½Ñƒ';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Ð¡Ð¾Ñ…Ñ€Ð°Ð½Ð¸Ñ‚ÑŒ'),
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
              : 'Ð¢Ð¾Ð²Ð°Ñ€',
        ),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? 'Ð£Ð±Ñ€Ð°Ñ‚ÑŒ Ð¸Ð· Ð¸Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ð³Ð¾'
                : 'Ð”Ð¾Ð±Ð°Ð²Ð¸Ñ‚ÑŒ Ð² Ð¸Ð·Ð±Ñ€Ð°Ð½Ð½Ð¾Ðµ',
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
                  ? const Color(0xFFD93636)
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
                  '${product.storeName} â€¢ ${product.country}',
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
                      '${widget.priceFormatter(product.currentPrice)} â‚¬',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (hasOldPrice)
                      Text(
                        '${widget.priceFormatter(product.oldPrice!)} â‚¬',
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
                          color: const Color(0xFFD93636),
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
                                    ? 'Ð¦ÐµÐ½Ð° Ð´Ð¾ÑÑ‚Ð¸Ð³Ð½ÑƒÑ‚Ð°!'
                                    : priceAlertTarget == null
                                        ? 'ÐžÑ‚ÑÐ»ÐµÐ¶Ð¸Ð²Ð°Ñ‚ÑŒ ÑÐ½Ð¸Ð¶ÐµÐ½Ð¸Ðµ Ñ†ÐµÐ½Ñ‹'
                                        : 'Ð¦ÐµÐ»ÑŒ: ${widget.priceFormatter(priceAlertTarget!)} â‚¬',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                priceAlertTriggered &&
                                        priceAlertTarget != null
                                    ? 'Ð¡Ñ€Ð°Ð±Ð¾Ñ‚Ð°Ð»Ð¾ Ð¿Ñ€Ð¸ ${widget.priceFormatter(priceAlertTriggeredPrice ?? widget.product.currentPrice)} â‚¬ â€¢ Ñ†ÐµÐ»ÑŒ ${widget.priceFormatter(priceAlertTarget!)} â‚¬'
                                    : priceAlertTarget == null
                                        ? 'Ð¡Ð¾Ñ…Ñ€Ð°Ð½Ð¸Ð¼ Ð¶ÐµÐ»Ð°ÐµÐ¼ÑƒÑŽ Ñ†ÐµÐ½Ñƒ Ð´Ð»Ñ ÑÑ‚Ð¾Ð³Ð¾ Ñ‚Ð¾Ð²Ð°Ñ€Ð°'
                                        : widget.product.currentPrice <=
                                                priceAlertTarget!
                                            ? 'Ð¦ÐµÐ½Ð° ÑƒÐ¶Ðµ Ð´Ð¾ÑÑ‚Ð¸Ð³Ð»Ð° Ð·Ð°Ð´Ð°Ð½Ð½Ð¾Ð³Ð¾ ÑƒÑ€Ð¾Ð²Ð½Ñ'
                                            : 'Ð¢ÐµÐºÑƒÑ‰Ð°Ñ Ñ†ÐµÐ½Ð° Ð²Ñ‹ÑˆÐµ Ñ†ÐµÐ»Ð¸ Ð½Ð° ${widget.priceFormatter(widget.product.currentPrice - priceAlertTarget!)} â‚¬',
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
                                ? 'Ð—Ð°Ð´Ð°Ñ‚ÑŒ'
                                : 'Ð˜Ð·Ð¼ÐµÐ½Ð¸Ñ‚ÑŒ',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                AppDetailRow(
                  icon: Icons.category_outlined,
                  label: 'ÐšÐ°Ñ‚ÐµÐ³Ð¾Ñ€Ð¸Ñ',
                  value: _categoryLabel(
                    product.category,
                  ),
                ),
                AppDetailRow(
                  icon: Icons.person_outline,
                  label: 'ÐŸÐ¾Ð»',
                  value:
                      product.gender?.isNotEmpty == true
                          ? product.gender!
                          : 'ÐÐµ ÑƒÐºÐ°Ð·Ð°Ð½Ð¾',
                ),
                AppDetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'ÐœÐ°Ð³Ð°Ð·Ð¸Ð½',
                  value: product.storeName,
                ),
                AppDetailRow(
                  icon: Icons.public,
                  label: 'Ð¡Ñ‚Ñ€Ð°Ð½Ð°',
                  value: product.country,
                ),

                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ð Ð°Ð·Ð¼ÐµÑ€Ñ‹',
                        style: TextStyle(
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
                          '${allSizes.where(isSizeAvailable).length} Ð´Ð¾ÑÑ‚ÑƒÐ¿Ð½Ð¾',
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
                          'Ð—Ð°Ð³Ñ€ÑƒÐ¶Ð°ÐµÐ¼ Ð´Ð¾ÑÑ‚ÑƒÐ¿Ð½Ñ‹Ðµ Ñ€Ð°Ð·Ð¼ÐµÑ€Ñ‹â€¦',
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
                        const Expanded(
                          child: Text(
                            'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ Ñ€Ð°Ð·Ð¼ÐµÑ€Ñ‹',
                            style: TextStyle(
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
                          child: const Text('ÐŸÐ¾Ð²Ñ‚Ð¾Ñ€Ð¸Ñ‚ÑŒ'),
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
                            'Ð”Ð°Ð½Ð½Ñ‹Ðµ Ð¾ Ñ€Ð°Ð·Ð¼ÐµÑ€Ð°Ñ… Ð´Ð»Ñ ÑÑ‚Ð¾Ð³Ð¾ Ñ‚Ð¾Ð²Ð°Ñ€Ð° Ð¿Ð¾ÐºÐ° Ð½Ðµ Ð·Ð°Ð³Ñ€ÑƒÐ¶ÐµÐ½Ñ‹.',
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
                        ? 'Ð’Ñ‹Ð±ÐµÑ€Ð¸ Ñ€Ð°Ð·Ð¼ÐµÑ€, Ñ‡Ñ‚Ð¾Ð±Ñ‹ ÑÑ€Ð°Ð²Ð½Ð¸Ñ‚ÑŒ Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ñ‹'
                        : 'Ð’Ñ‹Ð±Ñ€Ð°Ð½ Ñ€Ð°Ð·Ð¼ÐµÑ€: $selectedSize',
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
                    'ÐÐµÐ´Ð¾ÑÑ‚ÑƒÐ¿Ð½Ñ‹Ðµ ÑÐµÐ¹Ñ‡Ð°Ñ Ñ€Ð°Ð·Ð¼ÐµÑ€Ñ‹ Ð¿Ð¾ÐºÐ°Ð·Ð°Ð½Ñ‹ ÑÐµÑ€Ñ‹Ð¼.',
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
                            'Ð’Ñ‹Ð±Ñ€Ð°Ð½Ð½Ñ‹Ð¹ Ñ€Ð°Ð·Ð¼ÐµÑ€ ÑÐµÐ¹Ñ‡Ð°Ñ Ð½ÐµÐ´Ð¾ÑÑ‚ÑƒÐ¿ÐµÐ½',
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
                                          'Ð Ð°Ð·Ð¼ÐµÑ€ $selectedSize Â· ${selectedStores.length} ${selectedStores.length == 1 ? 'ÃÂ¼ÃÂ°ÃÂ³ÃÂ°ÃÂ·ÃÂ¸ÃÂ½' : 'ÃÂ¼ÃÂ°ÃÂ³ÃÂ°ÃÂ·ÃÂ¸ÃÂ½ÃÂ°'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (bestPrice != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'Ð›ÑƒÑ‡ÑˆÐ°Ñ Ñ†ÐµÐ½Ð°: ${widget.priceFormatter(bestPrice)} â‚¬',
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
                                                    child: const Text(
                                                      'Ð›ÑƒÑ‡ÑˆÐ°Ñ Ñ†ÐµÐ½Ð°',
                                                      style: TextStyle(
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
                                              '${widget.priceFormatter(store.currentPrice)} â‚¬',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Ð’ Ð½Ð°Ð»Ð¸Ñ‡Ð¸Ð¸',
                                              style: TextStyle(
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
                                        child: const Text('ÐžÑ‚ÐºÑ€Ñ‹Ñ‚ÑŒ'),
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
                  'Ð¦ÐµÐ½Ñ‹ Ð² Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ð°Ñ…',
                  style: TextStyle(
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
                      const Expanded(
                        child: Text(
                          'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ Ð¿Ñ€ÐµÐ´Ð»Ð¾Ð¶ÐµÐ½Ð¸Ñ',
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
                        child: const Text('ÐŸÐ¾Ð²Ñ‚Ð¾Ñ€Ð¸Ñ‚ÑŒ'),
                      ),
                    ],
                  )
                else if (offers.isEmpty)
                  Text(
                    'ÐŸÑ€ÐµÐ´Ð»Ð¾Ð¶ÐµÐ½Ð¸Ð¹ Ð¿Ð¾ÐºÐ° Ð½ÐµÑ‚',
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
                const Text(
                  'Ð˜ÑÑ‚Ð¾Ñ€Ð¸Ñ Ñ†ÐµÐ½Ñ‹',
                  style: TextStyle(
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
                            'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ Ð¸ÑÑ‚Ð¾Ñ€Ð¸ÑŽ Ñ†ÐµÐ½Ñ‹',
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
                          child: const Text('ÐŸÐ¾Ð²Ñ‚Ð¾Ñ€Ð¸Ñ‚ÑŒ'),
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
                        label: 'Ð¡ÐµÐ¹Ñ‡Ð°Ñ',
                        value:
                            '${widget.priceFormatter(product.currentPrice)} â‚¬',
                      ),
                      _PriceStat(
                        label: 'ÐœÐ¸Ð½Ð¸Ð¼ÑƒÐ¼',
                        value:
                            '${widget.priceFormatter(minHistoryPrice ?? product.currentPrice)} â‚¬',
                      ),
                      _PriceStat(
                        label: 'ÐœÐ°ÐºÑÐ¸Ð¼ÑƒÐ¼',
                        value:
                            '${widget.priceFormatter(maxHistoryPrice ?? product.currentPrice)} â‚¬',
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
                        ? 'Ð˜ÑÑ‚Ð¾Ñ€Ð¸Ñ Ñ‚Ð¾Ð»ÑŒÐºÐ¾ Ð½Ð°Ñ‡Ð°Ð»Ð° ÑÐ¾Ð±Ð¸Ñ€Ð°Ñ‚ÑŒÑÑ. ÐÐ¾Ð²Ñ‹Ðµ Ñ‚Ð¾Ñ‡ÐºÐ¸ Ð¿Ð¾ÑÐ²ÑÑ‚ÑÑ Ð¿Ñ€Ð¸ Ð¸Ð·Ð¼ÐµÐ½ÐµÐ½Ð¸Ð¸ Ñ†ÐµÐ½Ñ‹.'
                        : 'Ð¢Ð¾Ñ‡ÐµÐº Ð¸ÑÑ‚Ð¾Ñ€Ð¸Ð¸: ${history.length}',
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
                    label: const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      child: Text(
                        'ÐŸÐµÑ€ÐµÐ¹Ñ‚Ð¸ Ð² Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½',
                        style: TextStyle(
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
        return 'ÐžÐ±ÑƒÐ²ÑŒ';
      case 'clothing':
        return 'ÐžÐ´ÐµÐ¶Ð´Ð°';
      case 'sports':
        return 'Ð¡Ð¿Ð¾Ñ€Ñ‚';
      default:
        return category?.isNotEmpty == true
            ? category!
            : 'ÐÐµ ÑƒÐºÐ°Ð·Ð°Ð½Ð¾';
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
                        '${priceFormatter(offer.currentPrice)} â‚¬',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (offer.hasCoupon)
  _CardBadge(
    label: 'ÐšÐ£ÐŸÐžÐ',
    backgroundColor: Colors.blue.shade50,
    foregroundColor: Colors.blue.shade800,
  ),
                      if (hasOldPrice)
                        Text(
                          '${priceFormatter(offer.oldPrice!)} â‚¬',
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
              child: const Text('ÐžÑ‚ÐºÑ€Ñ‹Ñ‚ÑŒ'),
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
            const Text(
              'ÐÐµ ÑƒÐ´Ð°Ð»Ð¾ÑÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒ Ñ‚Ð¾Ð²Ð°Ñ€Ñ‹',
              style: TextStyle(
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
              label:
                  const Text(
                'ÐŸÐ¾Ð²Ñ‚Ð¾Ñ€Ð¸Ñ‚ÑŒ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
