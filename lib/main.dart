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
              'Не удалось загрузить товары',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
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
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
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
    scrollController.addListener(_onScroll);
    loadFavorites();
    loadProducts(reset: true);
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
    if (reset) {
      setState(() {
        loadingMore = false;
        error = null;
        hasMore = true;

        // Показываем большой loader только при самой первой загрузке.
        // При поиске и фильтрах оставляем экран на месте,
        // чтобы TextField не терял фокус после первой буквы.
        loading = products.isEmpty;
      });
    }

    final offset = reset ? 0 : products.length;

    try {
      final queryParameters = <String, String>{
        'country': 'EE',
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

      if (!mounted) return;

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
      selectedStore = 'all';
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
          imageUrl: proxyImage(product.imageUrl),
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

    if (uri == null) {
      showMessage('Некорректная ссылка на товар');
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!opened) {
      showMessage('Не удалось открыть магазин');
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

  @override
  Widget build(BuildContext context) {
    final filteredProducts = visibleProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Baltic Deals',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: showFavoritesOnly
                ? 'Показать все товары'
                : 'Показать избранное',
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
            tooltip: 'Обновить',
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
                                                    proxyImage(
                                                  product
                                                      .imageUrl,
                                                ),
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
  });

  @override
  State<FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<FiltersBar> {
  bool expanded = false;

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
        hintText: 'Поиск по товару или бренду',
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
      decoration: _fieldDecoration('Категория'),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Все')),
        DropdownMenuItem(value: 'shoes', child: Text('Обувь')),
        DropdownMenuItem(value: 'clothing', child: Text('Одежда')),
        DropdownMenuItem(value: 'sports', child: Text('Спорт')),
      ],
      onChanged: widget.onCategoryChanged,
    );

    final brandField = DropdownButtonFormField<String>(
      initialValue: widget.availableBrands.contains(widget.selectedBrand)
          ? widget.selectedBrand
          : 'all',
      isExpanded: true,
      decoration: _fieldDecoration('Бренд'),
      items: [
        const DropdownMenuItem(
          value: 'all',
          child: Text('Все бренды'),
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
  decoration: _fieldDecoration('Магазин'),
  items: const [
    DropdownMenuItem(
      value: 'all',
      child: Text('Все магазины'),
    ),
    DropdownMenuItem(
      value: 'Sportland Estonia',
      child: Text('Sportland Estonia'),
    ),
    DropdownMenuItem(
      value: 'Weekend Estonia',
      child: Text('Weekend Estonia'),
    ),
    DropdownMenuItem(
      value: 'Rademar Estonia',
      child: Text('Rademar Estonia'),
    ),
    DropdownMenuItem(
      value: 'ABOUT YOU Estonia',
      child: Text('ABOUT YOU Estonia'),
    ),
  ],
  onChanged: widget.onStoreChanged,
);
    final minPriceField = TextField(
      controller: widget.minPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onMinPriceChanged,
      decoration: _fieldDecoration('Цена от').copyWith(suffixText: '€'),
    );

    final maxPriceField = TextField(
      controller: widget.maxPriceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onMaxPriceChanged,
      decoration: _fieldDecoration('Цена до').copyWith(suffixText: '€'),
    );

    final discountField = DropdownButtonFormField<int>(
      initialValue: widget.selectedMinDiscount,
      decoration: _fieldDecoration('Скидка от'),
      items: const [
        DropdownMenuItem(value: 0, child: Text('Любая')),
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
      decoration: _fieldDecoration('Сортировка'),
      items: const [
        DropdownMenuItem(
          value: SortMode.discountHigh,
          child: Text('Самая большая скидка', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.savingsHigh,
          child: Text('Максимальная экономия', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceLow,
          child: Text('Сначала дешевле', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.priceHigh,
          child: Text('Сначала дороже', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: SortMode.brand,
          child: Text('По бренду', overflow: TextOverflow.ellipsis),
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
        label: const Text('Есть в нескольких магазинах'),
      ),
    );

    final resetButton = SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: widget.onReset,
        icon: const Icon(Icons.filter_alt_off),
        label: const Text('Сбросить'),
      ),
    );

    final countText = Text(
      'Найдено: ${widget.resultCount} • Загружено: ${widget.loadedCount}',
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
                      expanded ? 'Скрыть фильтры' : 'Фильтры',
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
                      storeField,
const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 280, child: searchField),
          SizedBox(width: 150, child: categoryField),
          SizedBox(width: 180, child: brandField),
          SizedBox(width: 190, child: storeField),
          SizedBox(width: 120, child: minPriceField),
          SizedBox(width: 120, child: maxPriceField),
          SizedBox(width: 145, child: discountField),
          SizedBox(width: 235, child: sortField),
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
            'Все загруженные товары показаны',
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
            'Загрузить ещё $pageLabel',
          ),
        ),
      ),
    );
  }

  String get pageLabel => '40 товаров';
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
              'Ничего не найдено',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasMore) ...[
              const SizedBox(height: 10),
              Text(
                'Попробуй изменить поиск или фильтры.',
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
                  label: const Text('Загрузить ещё'),
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
              flex: 6,
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
                            label: 'Сравнение цен',
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
                            ? 'Убрать из избранного'
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
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
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
                            '${product.storesCount} магазина',
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
                    const SizedBox(height: 7),
                    Text(
                      isMultiStore
                          ? 'Лучшая цена • ${product.storeName}'
                          : '${product.storeName} • ${product.country}',
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
                                'Экономия до ${priceFormatter(product.savingsAmount)} €',
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
                                '${priceFormatter(product.currentPrice)} €',
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
      'КУПОН',
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
                                    '${priceFormatter(product.oldPrice!)} €',
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
                          isMultiStore ? 'Сравнить магазины' : 'Подробнее',
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
                    'Размеры: $label',
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
          json['store_name']?.toString() ?? 'Магазин',
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
          json['store_name']?.toString() ?? 'Магазин',
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
            'Цель сохранена на сервере: ${widget.priceFormatter(roundedTarget)} €',
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
            'Сервер временно недоступен. Цель сохранена только на этом устройстве.',
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
          content: Text('Отслеживание цены отключено на сервере'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось отключить цель на сервере. Попробуйте ещё раз.',
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
              title: const Text('Отслеживать снижение цены'),
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
                        final raw =
                            controller.text.trim().replaceAll(',', '.');
                        final value = double.tryParse(raw);

                        if (value == null || value <= 0) {
                          setDialogState(() {
                            validationError =
                                'Введите корректную цену';
                          });
                          return;
                        }

                        Navigator.of(dialogContext).pop(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Цель сохраняется на сервере Baltic Deals. Push-уведомления подключим позже через Firebase.',
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
                    child: const Text('Отключить'),
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw =
                        controller.text.trim().replaceAll(',', '.');
                    final value = double.tryParse(raw);

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        validationError =
                            'Введите корректную цену';
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
              : 'Товар',
        ),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? 'Убрать из избранного'
                : 'Добавить в избранное',
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
                                    ? 'Цена достигнута!'
                                    : priceAlertTarget == null
                                        ? 'Отслеживать снижение цены'
                                        : 'Цель: ${widget.priceFormatter(priceAlertTarget!)} €',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                priceAlertTriggered &&
                                        priceAlertTarget != null
                                    ? 'Сработало при ${widget.priceFormatter(priceAlertTriggeredPrice ?? widget.product.currentPrice)} € • цель ${widget.priceFormatter(priceAlertTarget!)} €'
                                    : priceAlertTarget == null
                                        ? 'Сохраним желаемую цену для этого товара'
                                        : widget.product.currentPrice <=
                                                priceAlertTarget!
                                            ? 'Цена уже достигла заданного уровня'
                                            : 'Текущая цена выше цели на ${widget.priceFormatter(widget.product.currentPrice - priceAlertTarget!)} €',
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
                                ? 'Задать'
                                : 'Изменить',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                AppDetailRow(
                  icon: Icons.category_outlined,
                  label: 'Категория',
                  value: _categoryLabel(
                    product.category,
                  ),
                ),
                AppDetailRow(
                  icon: Icons.person_outline,
                  label: 'Пол',
                  value:
                      product.gender?.isNotEmpty == true
                          ? product.gender!
                          : 'Не указано',
                ),
                AppDetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Магазин',
                  value: product.storeName,
                ),
                AppDetailRow(
                  icon: Icons.public,
                  label: 'Страна',
                  value: product.country,
                ),

                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Размеры',
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
                          '${allSizes.where(isSizeAvailable).length} доступно',
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
                          'Загружаем доступные размеры…',
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
                            'Не удалось загрузить размеры',
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
                            'Данные о размерах для этого товара пока не загружены.',
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
                        ? 'Выбери размер, чтобы сравнить магазины'
                        : 'Выбран размер: $selectedSize',
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
                    'Недоступные сейчас размеры показаны серым.',
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
                            'Выбранный размер сейчас недоступен',
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
                                          'Размер $selectedSize · ${selectedStores.length} ${selectedStores.length == 1 ? 'магазин' : 'магазина'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (bestPrice != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'Лучшая цена: ${widget.priceFormatter(bestPrice)} €',
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
                                                      'Лучшая цена',
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
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton(
                                        onPressed: () =>
                                            openSizeStore(store),
                                        child: const Text('Открыть'),
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
                          'Не удалось загрузить предложения',
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
                        child: const Text('Повторить'),
                      ),
                    ],
                  )
                else if (offers.isEmpty)
                  Text(
                    'Предложений пока нет',
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
                  'История цены',
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
                            'Не удалось загрузить историю цены',
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
                        value:
                            '${widget.priceFormatter(product.currentPrice)} €',
                      ),
                      _PriceStat(
                        label: 'Минимум',
                        value:
                            '${widget.priceFormatter(minHistoryPrice ?? product.currentPrice)} €',
                      ),
                      _PriceStat(
                        label: 'Максимум',
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
                        ? 'История только начала собираться. Новые точки появятся при изменении цены.'
                        : 'Точек истории: ${history.length}',
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
                        'Перейти в магазин',
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
        return 'Обувь';
      case 'clothing':
        return 'Одежда';
      case 'sports':
        return 'Спорт';
      default:
        return category?.isNotEmpty == true
            ? category!
            : 'Не указано';
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
    label: 'КУПОН',
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
              child: const Text('Открыть'),
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
              'Не удалось загрузить товары',
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
                'Повторить',
              ),
            ),
          ],
        ),
      ),
    );
  }
}



