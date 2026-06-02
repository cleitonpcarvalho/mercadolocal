import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/store/store_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MarketService _marketService = const MarketService();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = <String>[
    'Moda',
    'Eletrônicos',
    'Beleza',
    'Casa',
    'Brinquedos',
    'Automotivo',
    'Suplementos',
    'Pet Shop',
    'Esportes',
    'Papelaria',
  ];

  bool _isLoading = true;
  String? _error;

  List<ProductModel> _featuredProducts = <ProductModel>[];
  List<Map<String, dynamic>> _activeAds = <Map<String, dynamic>>[];
  List<StoreModel> _stores = <StoreModel>[];

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
        _marketService.getFeaturedProducts(),
        _marketService.getActiveBannerAds(),
        _marketService.getStores(),
      ]);

      if (!mounted) return;

      setState(() {
        _featuredProducts = (results[0] as List<ProductModel>);
        _activeAds = (results[1] as List<Map<String, dynamic>>);
        _stores = (results[2] as List<StoreModel>);
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

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/search');
      case 2:
        context.go('/orders');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/logo-mercado-local-horizontal-sem-fundo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        centerTitle: false,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 20),
            if (_isLoading)
              _buildShimmer()
            else if (_error != null)
              AppErrorWidget(message: _error!, onRetry: _load)
            else ...<Widget>[
              _buildAds(),
              const SizedBox(height: 20),
              _buildFeaturedProducts(),
              const SizedBox(height: 20),
              _buildNearbyStores(),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Busque por produtos',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray500),
              fillColor: AppColors.white,
              filled: true,
              prefixIcon: const Icon(
                Icons.search_outlined,
                color: AppColors.gray500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
            ),
            onSubmitted: (String value) {
              context.go('/search?query=${Uri.encodeComponent(value)}');
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go('/cart'),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, int index) {
          return ActionChip(
            label: Text(
              _categories[index],
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppColors.white,
            side: const BorderSide(color: AppColors.primary),
            onPressed: () => context.go(
              '/search?query=${Uri.encodeComponent(_categories[index])}',
            ),
          );
        },
      ),
    );
  }

  Widget _buildAds() {
    if (_activeAds.isEmpty) {
      return const EmptyStateWidget(
        title: 'Sem banners ativos',
        subtitle: 'Novas campanhas aparecerao aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Banners ativos', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _activeAds.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, int index) {
              final Map<String, dynamic> ad = _activeAds[index];

              return InkWell(
                onTap: () async {
                  await _marketService.registerAdClick(ad['id'] as int? ?? 0);
                  if (!mounted) return;

                  final dynamic productId = ad['product'];
                  if (productId is int) {
                    context.go('/product/$productId');
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.gray100,
                            image: ad['image'] != null
                                ? DecorationImage(
                                    image: NetworkImage(ad['image'].toString()),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad['title']?.toString() ?? '-',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) {
      return const EmptyStateWidget(
        title: 'Sem produtos em destaque',
        subtitle: 'Volte mais tarde para novas ofertas.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Produtos em destaque', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 272,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, int index) {
              final ProductModel product = _featuredProducts[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                  onAdd: () => context.go('/product/${product.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyStores() {
    if (_stores.isEmpty) {
      return const EmptyStateWidget(
        title: 'Nenhuma loja encontrada',
        subtitle: 'Tente novamente mais tarde.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Lojas proximas', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        ..._stores.map(
          (StoreModel store) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StoreCard(
              store: store,
              onTap: () => context.go('/store/${store.id}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: List<Widget>.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
