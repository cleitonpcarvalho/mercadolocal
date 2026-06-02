import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/store_model.dart';

const String _supabaseUrl = 'https://srohkzutzaqrkdsxbnsv.supabase.co';
const String _supabaseBucket = 'mercadolocal';

String _resolveImageUrl(String? value) {
  final String rawValue = (value ?? '').trim();
  if (rawValue.isEmpty) return '';
  if (rawValue.startsWith('http')) return rawValue;

  final String normalizedPath = rawValue.replaceFirst(RegExp(r'^/+'), '');
  return '$_supabaseUrl/storage/v1/object/public/$_supabaseBucket/$normalizedPath';
}

class StoreCard extends StatelessWidget {
  const StoreCard({required this.store, required this.onTap, super.key});

  final StoreModel store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: _resolveImageUrl(store.logo),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    color: AppColors.gray100,
                    width: 56,
                    height: 56,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.gray100,
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    store.name,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(store.city ?? '-', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: store.categories
                        .take(2)
                        .map(
                          (StoreCategoryModel category) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(99),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
