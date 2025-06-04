import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../widgets/focus_stats_card.dart';
import '../widgets/quick_action_buttons.dart';
import '../widgets/recent_sessions_card.dart';
import '../widgets/forest_progress_card.dart';
import 'timer_screen.dart';
import 'precision_timer_screen.dart';
import '../services/precision_timer_service.dart';
import 'forest_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../services/reward_service.dart';
import '../models/reward_models.dart';
import '../utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todayFocusTime = 0;
  int _totalSessions = 0;
  int _streakDays = 0;
  int _totalTrees = 0;
  int _forestLevel = 0;
  late final RewardService _rewardService;

  @override
  void initState() {
    super.initState();
    _loadData();
    _rewardService = RewardService();
    _loadRewardData();
  }

  Future<void> _loadData() async {
    setState(() {
      _todayFocusTime = StorageService.getTodayFocusTime();
      _totalSessions = StorageService.getTotalSessions();
      _streakDays = StorageService.getStreakDays();
      _totalTrees = StorageService.getTotalTrees();
      _forestLevel = StorageService.getForestLevel();
    });
  }

  Future<void> _loadRewardData() async {
    await _rewardService.loadUserProgress();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.pets,
              color: Colors.brown[600],
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Focus Safari',
              style: TextStyle(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: AppColors.getTextPrimary(isDark),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                _buildHeader(isDark),
                const SizedBox(height: 32),
                
                // 보상 시스템 UI
                _buildRewardSection(isDark),
                const SizedBox(height: 24),
                
                // 오늘의 집중 상태
                FocusStatsCard(
                  todayFocusTime: _todayFocusTime,
                  streakDays: _streakDays,
                  totalSessions: _totalSessions,
                ).animate().fadeIn(duration: 600.ms).slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutQuart,
                ),
                const SizedBox(height: 24),
                
                // 빠른 시작 버튼들
                QuickActionButtons(
                  onTimerTap: () => _navigateToTimer(),
                  onStopwatchTap: () => _navigateToStopwatch(),
                ).animate().fadeIn(
                  delay: 200.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 200.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutQuart,
                ),
                const SizedBox(height: 24),
                
                // 최근 세션
                RecentSessionsCard().animate().fadeIn(
                  delay: 600.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 600.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutQuart,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    final greeting = _getGreeting();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '오늘도 동물 친구들과 집중해보세요 🦁',
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
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrecisionTimerScreen(
                    initialMode: TimerMode.timer,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fast_forward,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '스킵 타이머',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorder(isDark),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: '홈',
            isActive: true,
            isDark: isDark,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.pets_outlined,
            activeIcon: Icons.pets,
            label: '사파리',
            isActive: false,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForestScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
          _buildNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: '통계',
            isActive: false,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
          _buildNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: '설정',
            isActive: false,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive 
                  ? AppColors.primary 
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive 
                    ? AppColors.primary 
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침이에요! ☀️';
    } else if (hour < 18) {
      return '좋은 오후에요! 🌤️';
    } else {
      return '좋은 저녁이에요! 🌙';
    }
  }

  void _navigateToTimer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrecisionTimerScreen(
          initialMode: TimerMode.timer,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToStopwatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrecisionTimerScreen(
          initialMode: TimerMode.stopwatch,
        ),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildRewardSection(bool isDark) {
    return AnimatedBuilder(
      animation: _rewardService,
      builder: (context, child) {
        final progress = _rewardService.userProgress;
        return Column(
          children: [
            // 레벨 및 경험치
            _buildLevelCard(isDark, progress),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // 스트릭 카드
                Expanded(child: _buildStreakCard(isDark, progress)),
                const SizedBox(width: 12),
                // 동물 카드
                Expanded(child: _buildAnimalCard(isDark, progress)),
              ],
            ),
            const SizedBox(height: 16),
            
            // 칭호 및 통계
            _buildStatsCard(isDark, progress),
          ],
        );
      },
    );
  }

  Widget _buildLevelCard(bool isDark, UserProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '레벨 ${progress.currentLevel}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    progress.currentTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: TitleData.getTitleColor(progress.currentTitle),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '경험치 ${progress.currentLevelExp}/${progress.expToNextLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _rewardService.getLevelProgress(),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildStreakCard(bool isDark, UserProgress progress) {
    final streakEmoji = _rewardService.getStreakEmoji();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (streakEmoji.isNotEmpty) ...[
                Text(
                  streakEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.local_fire_department,
                color: progress.currentStreak > 0 ? Colors.orange : AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.currentStreak}일',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: progress.currentStreak > 0 ? Colors.orange : AppColors.textSecondary,
            ),
          ),
          Text(
            '연속 집중',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 200.ms,
      duration: 600.ms,
    ).slideX(
      begin: -0.2,
      end: 0,
      delay: 200.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildAnimalCard(bool isDark, UserProgress progress) {
    final animalEmoji = AnimalData.getAnimalEmoji(progress.animal.type);
    final animalName = AnimalData.getAnimalName(progress.animal.type);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            animalEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            animalName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          Text(
            '유대 ${progress.animal.bondLevel}',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 400.ms,
      duration: 600.ms,
    ).slideX(
      begin: 0.2,
      end: 0,
      delay: 400.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildStatsCard(bool isDark, UserProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer,
            label: '총 집중',
            value: '${progress.totalFocusMinutes}분',
            color: AppColors.primary,
          ),
          _buildStatItem(
            icon: Icons.psychology,
            label: '세션 수',
            value: '${progress.totalSessions}회',
            color: AppColors.success,
          ),
          _buildStatItem(
            icon: Icons.emoji_events,
            label: '배지',
            value: '${progress.earnedBadges.length}개',
            color: AppColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 600.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.2,
      end: 0,
      delay: 600.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
} 