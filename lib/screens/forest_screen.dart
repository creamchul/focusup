import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  int _totalTrees = 0;
  int _forestLevel = 0;
  int _totalFocusTime = 0;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadForestData();
  }

  void _loadForestData() {
    setState(() {
      _totalTrees = StorageService.getTotalTrees();
      _forestLevel = StorageService.getForestLevel();
      _totalFocusTime = StorageService.getTotalFocusTime();
      _streakDays = StorageService.getStreakDays();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadForestData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 헤더
                _buildHeader(isDark),
                
                // 숲 통계 카드
                _buildForestStats(isDark),
                
                // 레벨 진행률
                _buildLevelProgress(isDark),
                
                // 나무 숲 그리드
                _buildForestGrid(isDark),
                
                // 성취 정보
                _buildAchievementInfo(isDark),
                
                const SizedBox(height: 100), // 하단 여백
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 숲 🌲',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '집중할 때마다 나무가 자라요',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.treeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.treeGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.eco,
              color: AppColors.treeGreen,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestStats(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.forest,
              label: '심은 나무',
              value: '$_totalTrees그루',
              color: AppColors.treeGreen,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.getBorder(isDark),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up,
              label: '숲 레벨',
              value: 'Lv.$_forestLevel',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.getBorder(isDark),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_fire_department,
              label: '연속 일수',
              value: '${_streakDays}일',
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.3,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(bool isDark) {
    final currentLevelTrees = _totalTrees % 10;
    final nextLevelTrees = 10;
    final progress = currentLevelTrees / nextLevelTrees;

    return Container(
      margin: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '다음 레벨까지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              Text(
                '$currentLevelTrees/$nextLevelTrees',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.getBorder(isDark),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나무 ${nextLevelTrees - currentLevelTrees}그루 더 심으면 레벨업! 🌟',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 200.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: 200.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildForestGrid(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Text(
            '내 숲',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          _totalTrees == 0 
              ? _buildEmptyForest(isDark)
              : _buildTreeGrid(isDark),
        ],
      ),
    ).animate().fadeIn(
      delay: 400.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: 400.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildEmptyForest(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.park_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              '아직 나무가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '25분 이상 집중하면 나무가 자라요 🌱',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeGrid(bool isDark) {
    final maxGridSize = 50; // 10x5 그리드
    final rows = (maxGridSize / 10).ceil();
    
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(10, (colIndex) {
              final treeIndex = rowIndex * 10 + colIndex;
              final hasTree = treeIndex < _totalTrees;
              
              return _buildTreeSpot(hasTree, treeIndex, isDark);
            }),
          ),
        );
      }),
    );
  }

  Widget _buildTreeSpot(bool hasTree, int index, bool isDark) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: hasTree 
            ? AppColors.treeGreen.withOpacity(0.2)
            : AppColors.getBorder(isDark),
        borderRadius: BorderRadius.circular(4),
      ),
      child: hasTree
          ? Icon(
              _getTreeIcon(index),
              size: 16,
              color: AppColors.treeGreen,
            )
          : Container(),
    ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1));
  }

  IconData _getTreeIcon(int index) {
    // 나무 종류를 다양하게 표시
    final icons = [
      Icons.park,
      Icons.forest,
      Icons.eco,
      Icons.nature,
    ];
    return icons[index % icons.length];
  }

  Widget _buildAchievementInfo(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
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
          Text(
            '성취 현황',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementItem(
            icon: Icons.timer,
            title: '총 집중 시간',
            description: '${(_totalFocusTime / 60).floor()}시간 ${_totalFocusTime % 60}분',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            icon: Icons.local_fire_department,
            title: '최고 연속 기록',
            description: '$_streakDays일 연속 집중',
            color: AppColors.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            icon: Icons.eco,
            title: '환경 보호 기여',
            description: '실제 나무 ${(_totalTrees * 0.1).toStringAsFixed(1)}그루 상당',
            color: AppColors.treeGreen,
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 600.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: 600.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 