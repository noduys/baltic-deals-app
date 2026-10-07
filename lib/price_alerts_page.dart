import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertProductInfo {
  final int id;
  final String name;
  final String storeName;
  final String? imageUrl;
  final String? productUrl;
  final double currentPrice;

  AlertProductInfo({
    required this.id,
    required this.name,
    required this.storeName,
    required this.imageUrl,
    required this.productUrl,
    required this.currentPrice,
  });

  factory AlertProductInfo.fromJson(Map<String, dynamic> json) {
    return AlertProductInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Товар',
      storeName: json['store_name']?.toString() ?? 'Магазин',
      imageUrl: json['image_url']?.toString(),
      productUrl: json['product_url']?.toString(),
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PriceAlertItem {
  final int productId;
  final double targetPrice;
  AlertProductInfo? product;
  bool loading = true;
  String? error;

  PriceAlertItem({
    required this.productId,
    required this.targetPrice,
    this.product,
  });
}

class PriceAlertsPage extends StatefulWidget {
  const PriceAlertsPage({super.key});

  @override
  State<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends State<PriceAlertsPage> {
  static const String _apiBase = 'https://baltic-deals-api.noduys.workers.dev';
  List<PriceAlertItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('price_alert_target_'));

    final items = <PriceAlertItem>[];
    for (final key in keys) {
      final idStr = key.replaceFirst('price_alert_target_', '');
      final id = int.tryParse(idStr);
      final target = prefs.getDouble(key);
      if (id != null && target != null) {
        items.add(PriceAlertItem(productId: id, targetPrice: target));
      }
    }

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });

    for (final item in _items) {
      _fetchProductDetails(item);
    }
  }

  Future<void> _fetchProductDetails(PriceAlertItem item) async {
    try {
      final uri = Uri.parse('$_apiBase/products').replace(
        queryParameters: {'productId': '${item.productId}', 'limit': '1'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = decoded['products'] as List<dynamic>? ?? [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            item.product = AlertProductInfo.fromJson(list.first as Map<String, dynamic>);
            item.loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        item.loading = false;
        item.error = 'Товар не найден или удален';
      });
    }
  }

  Future<void> _removeAlert(PriceAlertItem item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('price_alert_target_${item.productId}');

    if (!mounted) return;

    setState(() {
      _items.removeWhere((i) => i.productId == item.productId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отслеживание удалено')),
    );
  }

  Future<void> _openStore(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отслеживания цен'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет активных отслеживаний',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите на колокольчик на странице любого товара, чтобы получать уведомления о снижении цены.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final product = item.product;

                    if (item.loading) {
                      return Card(
                        child: Container(
                          height: 90,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (product == null) {
                      return Card(
                        child: ListTile(
                          title: Text('Товар #${item.productId}'),
                          subtitle: Text('Цель: ${item.targetPrice.toStringAsFixed(2)} € (Нет данных)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeAlert(item),
                          ),
                        ),
                      );
                    }

                    final currentPrice = product.currentPrice;
                    final targetPrice = item.targetPrice;
                    final isReached = currentPrice <= targetPrice;
                    final diff = currentPrice - targetPrice;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isReached ? const Color(0xFF0F766E) : Colors.grey.shade200,
                          width: isReached ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: (product.imageUrl?.isNotEmpty ?? false)
                                  ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                                  : const Icon(Icons.image_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.storeName,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'Сейчас: ${currentPrice.toStringAsFixed(2)} €',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Цель: ${targetPrice.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          color: Color(0xFF0F766E),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (isReached)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5F4F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🔥 Цена достигнута!',
                                        style: TextStyle(
                                          color: Color(0xFF0F766E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Осталось подождать: -${diff.toStringAsFixed(2)} €',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'В магазин',
                                  icon: const Icon(Icons.open_in_new, color: Color(0xFF0F766E)),
                                  onPressed: () => _openStore(product.productUrl),
                                ),
                                IconButton(
                                  tooltip: 'Удалить отслеживание',
                                  icon: const Icon(Icons.notifications_off_outlined, color: Colors.grey),
                                  onPressed: () => _removeAlert(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
