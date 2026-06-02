import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/product/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MarketService _marketService = const MarketService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _didLoadRouteQuery = false;
  String? _error;

  List<ProductModel> _products = <ProductModel>[];
  List<_CategoryItem> _categories = <_CategoryItem>[];

  int? _selectedCategory;
  String? _selectedCondition;
  String _sort = 'relevance';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadRouteQuery) return;

    final String query =
        GoRouterState.of(context).uri.queryParameters['query'] ?? '';
    if (query.isNotEmpty) {
      _searchController.text = query;
      _load();
    }

    _didLoadRouteQuery = true;
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
      if (_categories.isEmpty) {
        final List<Map<String, dynamic>> rawCategories = await _marketService
            .getProductCategories();
        _categories = _flattenCategories(rawCategories);
      }

      final List<ProductModel> response = await _marketService.searchProducts(
        search: _searchController.text.trim(),
        condition: _selectedCondition,
        category: _selectedCategory,
      );

      if (!mounted) return;
      setState(() {
        _products = _sortProducts(response);
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

  List<ProductModel> _sortProducts(List<ProductModel> input) {
    final List<ProductModel> output = List<ProductModel>.from(input);
    if (_sort == 'lowest') {
      output.sort((a, b) => a.price.compareTo(b.price));
      return output;
    }
    if (_sort == 'highest') {
      output.sort((a, b) => b.price.compareTo(a.price));
      return output;
    }
    return output;
  }

  List<_CategoryItem> _flattenCategories(List<Map<String, dynamic>> raw) {
    final List<_CategoryItem> output = <_CategoryItem>[];

    void walk(Map<String, dynamic> node) {
      final int id = int.tryParse(node['id']?.toString() ?? '') ?? 0;
      final String name = node['name']?.toString() ?? '';
      if (id > 0 && name.isNotEmpty) {
        output.add(_CategoryItem(id: id, name: name));
      }

      final List<dynamic> children =
          (node['children'] as List<dynamic>?) ?? const <dynamic>[];
      for (final child in children) {
        if (child is Map) {
          walk(Map<String, dynamic>.from(child));
        }
      }
    }

    for (final Map<String, dynamic> item in raw) {
      walk(item);
    }

    return output;
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
        title: const Text('Buscar produtos'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppTextField(
              controller: _searchController,
              label: 'Buscar',
              hintText: 'Nome do produto',
              autofocus: true,
              prefixIcon: const Icon(
                Icons.search_outlined,
                color: AppColors.gray500,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _selectedCondition == null,
                          onSelected: (_) {
                            setState(() => _selectedCondition = null);
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Novo'),
                          selected: _selectedCondition == 'new',
                          onSelected: (_) {
                            setState(() => _selectedCondition = 'new');
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Usado'),
                          selected: _selectedCondition == 'used',
                          onSelected: (_) {
                            setState(() => _selectedCondition = 'used');
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text('Relevancia'),
                    ),
                    DropdownMenuItem(
                      value: 'lowest',
                      child: Text('Menor preco'),
                    ),
                    DropdownMenuItem(
                      value: 'highest',
                      child: Text('Maior preco'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      _sort = value;
                      _products = _sortProducts(_products);
                    });
                  },
                ),
              ],
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, int index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('Categorias'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                        _load();
                      },
                    );
                  }

                  final _CategoryItem category = _categories[index - 1];
                  return FilterChip(
                    label: Text(category.name),
                    selected: _selectedCategory == category.id,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category.id);
                      _load();
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: _categories.length + 1,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppButtonText(label: 'Buscar', onTap: _load),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }

    if (_products.isEmpty) {
      return const EmptyStateWidget(
        title: 'Nenhum produto encontrado',
        subtitle: 'Ajuste os filtros e tente novamente.',
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 1024
            ? 4
            : width > 720
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (_, int index) {
            final ProductModel product = _products[index];

            return ProductCard(
              product: product,
              onTap: () => context.go('/product/${product.id}'),
              onAdd: () async {
                final CartProvider cartProvider = context.read<CartProvider>();
                final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                  context,
                );

                await cartProvider.addItem(context, product);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Produto adicionado ao carrinho'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.id, required this.name});

  final int id;
  final String name;
}

class AppButtonText extends StatelessWidget {
  const AppButtonText({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
