import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FocusStatsCard extends StatelessWidget {
  final int todayFocusTime;
  final int streakDays;
  final int totalSessions;

  const FocusStatsCard({
    super.key,
    required this.todayFocusTime,
    required this.streakDays,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '오늘의 집중',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 메인 통계
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: '집중 시간',
                  value: _formatTime(todayFocusTime),
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.getBorder(isDark),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: '연속 일수',
                  value: '${streakDays}일',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 세션 수
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '총 $totalSessions개의 세션 완료',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}시간';
    }
    return '${hours}시간 ${remainingMinutes}분';
  }
} 