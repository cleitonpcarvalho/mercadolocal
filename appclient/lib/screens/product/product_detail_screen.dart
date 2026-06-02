import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/product/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketService _marketService = const MarketService();

  final PageController _pageController = PageController();

  bool _isLoading = true;
  bool _descriptionExpanded = false;
  int _activeImageIndex = 0;
  String? _error;

  ProductModel? _product;
  List<ProductModel> _relatedProducts = <ProductModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ProductModel product = await _marketService.getProductById(
        widget.productId,
      );
      final int? storeId = product.store?.id;

      List<ProductModel> related = <ProductModel>[];
      if (storeId != null && storeId > 0) {
        related = await _marketService.searchProducts(store: storeId);
      }

      if (!mounted) return;

      setState(() {
        _product = product;
        _relatedProducts = related
            .where((ProductModel item) => item.id != product.id)
            .take(6)
            .toList();
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

  Future<void> _addToCart() async {
    if (_product == null) return;

    await context.read<CartProvider>().addItem(context, _product!);
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
    final ProductModel? product = _product;

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
        title: const Text('Detalhes do produto'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      bottomNavigationBar: product == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AppButton(
                label: 'Adicionar ao carrinho',
                icon: Icons.add_shopping_cart_outlined,
                onPressed: _addToCart,
              ),
            ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(product),
      ),
    );
  }

  Widget _buildBody(ProductModel? product) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }

    if (product == null) {
      return const EmptyStateWidget(
        title: 'Produto nao encontrado',
        subtitle: 'Tente novamente em alguns instantes.',
      );
    }

    final List<String> imageUrls = product.images
        .map((ProductImageModel image) => image.image)
        .where((String image) => image.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty && product.displayImage != null) {
      imageUrls.add(product.displayImage!);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildGallery(imageUrls),
        const SizedBox(height: 14),
        Text(
          product.name,
          style: AppTextStyles.titleLarge.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Text(
              Formatters.currency(product.price),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 10),
            _buildConditionBadge(product.condition),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          product.description?.trim().isNotEmpty == true
              ? product.description!
              : 'Sem descricao cadastrada.',
          maxLines: _descriptionExpanded ? null : 3,
          overflow: _descriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(color: AppColors.gray700),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _descriptionExpanded = !_descriptionExpanded;
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          child: Text(_descriptionExpanded ? 'Mostrar menos' : 'Mostrar mais'),
        ),
        const SizedBox(height: 8),
        _buildStoreCard(product),
        const SizedBox(height: 22),
        Text('Relacionados da loja', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        if (_relatedProducts.isEmpty)
          const EmptyStateWidget(
            title: 'Sem produtos relacionados',
            subtitle: 'A loja ainda nao tem outros produtos ativos.',
          )
        else
          SizedBox(
            height: 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _relatedProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, int index) {
                final ProductModel item = _relatedProducts[index];
                return SizedBox(
                  width: 180,
                  child: ProductCard(
                    product: item,
                    onTap: () => context.go('/product/${item.id}'),
                    onAdd: () async {
                      await context.read<CartProvider>().addItem(context, item);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Produto adicionado ao carrinho'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.gray500,
          size: 44,
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (int index) {
              setState(() {
                _activeImageIndex = index;
              });
            },
            itemBuilder: (_, int index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(color: AppColors.gray100),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.gray500,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            imageUrls.length,
            (int index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 8,
              width: _activeImageIndex == index ? 20 : 8,
              decoration: BoxDecoration(
                color: _activeImageIndex == index
                    ? AppColors.primary
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionBadge(String condition) {
    final bool isNew = condition == 'new';
    final Color color = isNew ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isNew ? 'Novo' : 'Usado',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStoreCard(ProductModel product) {
    final ProductStoreSummary? store = product.store;

    return InkWell(
      onTap: store == null ? null : () => context.go('/store/${store.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store_outlined, color: AppColors.gray500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    store?.name ?? 'Loja',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store?.address?.isNotEmpty == true
                        ? store!.address!
                        : 'Endereco indisponivel',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }
}
