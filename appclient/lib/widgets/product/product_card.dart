import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';

const String _supabaseUrl = 'https://srohkzutzaqrkdsxbnsv.supabase.co';
const String _supabaseBucket = 'mercadolocal';

String _resolveImageUrl(String? value) {
  final String rawValue = (value ?? '').trim();
  if (rawValue.isEmpty) return '';
  if (rawValue.startsWith('http')) return rawValue;

  final String normalizedPath = rawValue.replaceFirst(RegExp(r'^/+'), '');
  return '$_supabaseUrl/storage/v1/object/public/$_supabaseBucket/$normalizedPath';
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    super.key,
    this.onAdd,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final Color conditionColor = product.condition == 'new'
        ? AppColors.success
        : AppColors.warning;
    final String firstRelatedImage = product.images.isNotEmpty
        ? product.images.first.image
        : (product.firstImage ?? '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: CachedNetworkImage(
                imageUrl: _resolveImageUrl(firstRelatedImage),
                height: 112,
                width: double.infinity,
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
                    Icons.image_not_supported_outlined,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: conditionColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            product.condition == 'new' ? 'Novo' : 'Usado',
                            style: AppTextStyles.caption.copyWith(
                              color: conditionColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.store?.name ?? '-',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            Formatters.currency(product.price),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onAdd != null) ...<Widget>[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              onPressed: onAdd,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
                              ),
                              splashRadius: 18,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              color: AppColors.primary,
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
