import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ForestProgressCard extends StatelessWidget {
  final int totalTrees;
  final int forestLevel;

  const ForestProgressCard({
    super.key,
    required this.totalTrees,
    required this.forestLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.park,
                color: AppColors.treeGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '나의 숲',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.treeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Level $forestLevel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.treeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.forest,
                color: AppColors.treeGreen,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalTrees그루의 나무',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getForestDescription(totalTrees),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _getProgressValue(totalTrees),
            backgroundColor: AppColors.getBorder(isDark),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.treeGreen),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            _getNextLevelText(totalTrees),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getForestDescription(int trees) {
    if (trees == 0) return '아직 나무가 없어요';
    if (trees < 10) return '작은 새싹들이 자라고 있어요';
    if (trees < 30) return '푸르른 숲이 만들어지고 있어요';
    if (trees < 60) return '울창한 숲이 되었어요';
    if (trees < 100) return '거대한 숲이 펼쳐져 있어요';
    return '당신만의 마법 같은 숲이에요';
  }

  double _getProgressValue(int trees) {
    if (trees < 10) return trees / 10;
    if (trees < 30) return (trees - 10) / 20;
    if (trees < 60) return (trees - 30) / 30;
    if (trees < 100) return (trees - 60) / 40;
    return 1.0;
  }

  String _getNextLevelText(int trees) {
    if (trees < 10) return '다음 레벨까지 ${10 - trees}그루';
    if (trees < 30) return '다음 레벨까지 ${30 - trees}그루';
    if (trees < 60) return '다음 레벨까지 ${60 - trees}그루';
    if (trees < 100) return '다음 레벨까지 ${100 - trees}그루';
    return '최고 레벨 달성!';
  }
} 