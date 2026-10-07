$ErrorActionPreference = "Stop"

$path = ".\lib\main.dart"

if (-not (Test-Path $path)) {
    throw "File not found: $path"
}

$resolved = (Resolve-Path $path).Path
$text = [System.IO.File]::ReadAllText($resolved)

if ($text.Contains("List<Product> homeCheapest = [];")) {
    Write-Host "Patch already applied."
    exit 0
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = ".\lib\main.dart.before-home-cheapest-$stamp"
Copy-Item $path $backup -Force

function Replace-Once {
    param(
        [string]$Source,
        [string]$Old,
        [string]$New,
        [string]$Label
    )

    $count = ([regex]::Matches($Source, [regex]::Escape($Old))).Count

    if ($count -ne 1) {
        throw "Unsafe patch at '$Label': found $count matches instead of 1."
    }

    return $Source.Replace($Old, $New)
}

$title = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String("0JvRg9GH0YjQuNC1INGG0LXQvdGLINGB0LXQudGH0LDRgQ==")
)
$subtitle = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String("0J7QtNC10LbQtNCwLCDQvtCx0YPQstGMINC4INGC0LXRhdC90LjQutCwINC/0L4g0YHQsNC80YvQvCDQvdC40LfQutC40Lwg0YbQtdC90LDQvA==")
)

$old = @'
      id: (json['id'] as num?)?.toInt() ?? 0,
'@
$new = @'
      id: (json['id'] as num?)?.toInt() ??
          (json['product_id'] as num?)?.toInt() ??
          0,
'@
$text = Replace-Once $text $old $new "product_id fallback"

$old = @'
  List<Product> products = [];
  Set<int> favoriteIds = {};
'@
$new = @'
  List<Product> products = [];
  List<Product> homeCheapest = [];
  bool homeCheapestLoading = true;
  Set<int> favoriteIds = {};
'@
$text = Replace-Once $text $old $new "home cheapest state"

$old = @'
    loadFavorites();
    loadProducts(reset: true);
  }

  @override
  void dispose() {
'@
$new = @'
    loadFavorites();
    loadProducts(reset: true);
    loadHomeCheapest();
  }

  Future<void> loadHomeCheapest() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/home-cheapest?limit=12'),
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
'@
$text = Replace-Once $text $old $new "loadHomeCheapest"

$old = @'
  Widget build(BuildContext context) {
    final filteredProducts = visibleProducts;

    return Scaffold(
'@
$new = @'
  Widget build(BuildContext context) {
    final filteredProducts = visibleProducts;

    final isHomeView =
        !showFavoritesOnly &&
        searchController.text.trim().isEmpty &&
        minPriceController.text.trim().isEmpty &&
        maxPriceController.text.trim().isEmpty &&
        selectedCategory == 'all' &&
        selectedBrand == 'all' &&
        selectedStore == 'all' &&
        selectedMinDiscount == 0 &&
        !multiStoreOnly;

    return Scaffold(
'@
$text = Replace-Once $text $old $new "isHomeView"

$old = @'
                                    slivers: [
                                      SliverPadding(
'@

$new = @"
                                    slivers: [
                                      if (isHomeView)
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
                                                Row(
                                                  children: [
                                                    const Expanded(
                                                      child: Text(
                                                        '$title',
                                                        style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .local_fire_department_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$subtitle',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        Colors.grey.shade700,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                if (homeCheapestLoading)
                                                  const SizedBox(
                                                    height: 220,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  )
                                                else if (homeCheapest.isNotEmpty)
                                                  SizedBox(
                                                    height: 330,
                                                    child:
                                                        ListView.separated(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount:
                                                          homeCheapest.length,
                                                      separatorBuilder:
                                                          (_, _) =>
                                                              const SizedBox(
                                                        width: 14,
                                                      ),
                                                      itemBuilder:
                                                          (context, index) {
                                                        final product =
                                                            homeCheapest[index];

                                                        return SizedBox(
                                                          width: 210,
                                                          child: ProductCard(
                                                            product: product,
                                                            imageUrl:
                                                                product.imageUrl ??
                                                                    '',
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
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                if (homeCheapest.isNotEmpty)
                                                  const SizedBox(height: 12),
                                                if (homeCheapest.isNotEmpty)
                                                  Divider(
                                                    color:
                                                        Colors.grey.shade300,
                                                    height: 1,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      SliverPadding(
"@

$text = Replace-Once $text $old $new "home cheapest sliver"

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($resolved, $text, $utf8)

Write-Host "Patch applied successfully."
Write-Host "Backup: $backup"
Write-Host "Next: flutter analyze"
