import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/product/product_card.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({required this.storeId, super.key});

  final int storeId;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final MarketService _marketService = const MarketService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  StoreModel? _store;
  List<ProductModel> _products = <ProductModel>[];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _marketService.getStoreById(widget.storeId),
        _marketService.searchProducts(
          store: widget.storeId,
          search: _searchController.text.trim(),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _store = results[0] as StoreModel;
        _products = results[1] as List<ProductModel>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _categoryFilters {
    final Set<String> names = _products
        .map((ProductModel product) => product.categoryName?.trim() ?? '')
        .where((String name) => name.isNotEmpty)
        .toSet();
    return names.toList()..sort();
  }

  List<ProductModel> get _filteredProducts {
    if (_selectedCategory == null) return _products;
    return _products
        .where(
          (ProductModel product) => product.categoryName == _selectedCategory,
        )
        .toList();
  }

  Future<void> _addToCart(ProductModel product) async {
    await context.read<CartProvider>().addItem(context, product);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Produto adicionado ao carrinho'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StoreModel? store = _store;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/home');
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: Text(store?.name ?? 'Loja'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(store),
      ),
    );
  }

  Widget _buildBody(StoreModel? store) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }

    if (store == null) {
      return const EmptyStateWidget(
        title: 'Loja nao encontrada',
        subtitle: 'Tente novamente mais tarde.',
      );
    }

    final List<ProductModel> products = _filteredProducts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeader(store),
        const SizedBox(height: 12),
        AppTextField(
          controller: _searchController,
          label: 'Buscar na loja',
          hintText: 'Nome do produto',
          prefixIcon: const Icon(
            Icons.search_outlined,
            color: AppColors.gray500,
          ),
          onChanged: (_) => _load(),
        ),
        const SizedBox(height: 10),
        if (_categoryFilters.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryFilters.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, int index) {
                if (index == 0) {
                  return ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  );
                }

                final String category = _categoryFilters[index - 1];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Text('Produtos da loja', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const EmptyStateWidget(
            title: 'Sem produtos no momento',
            subtitle: 'Esta loja ainda nao publicou produtos disponiveis.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (_, int index) {
              final ProductModel product = products[index];
              return ProductCard(
                product: product,
                onTap: () => context.go('/product/${product.id}'),
                onAdd: () => _addToCart(product),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHeader(StoreModel store) {
    final double latitude = store.latitude ?? -3.7319;
    final double longitude = store.longitude ?? -38.5267;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: store.logo ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.gray100,
                      width: 64,
                      height: 64,
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(store.name, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        store.description?.isNotEmpty == true
                            ? store.description!
                            : 'Sem descricao da loja.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store.address?.isNotEmpty == true
                            ? store.address!
                            : 'Endereco indisponivel',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (store.categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: store.categories
                    .map(
                      (StoreCategoryModel category) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          category.name,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mercadolocal.appclient',
                  ),
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 40,
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
    );
  }
}
