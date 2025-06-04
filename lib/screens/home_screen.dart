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

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
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
                  onPomodoroTap: () => _navigateToTimer(TimerType.pomodoro),
                  onFreeTimerTap: () => _navigateToTimer(TimerType.freeTimer),
                  onStopwatchTap: () => _navigateToTimer(TimerType.stopwatch),
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
                
                // 숲 진행 상황
                ForestProgressCard(
                  totalTrees: _totalTrees,
                  forestLevel: _forestLevel,
                ).animate().fadeIn(
                  delay: 400.ms,
                  duration: 600.ms,
                ).slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 400.ms,
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
                const SizedBox(height: 100), // 하단 여백
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
              '오늘도 집중해보세요 🌱',
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
              // 새로운 정밀 타이머 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrecisionTimerScreen(
                    initialMode: TimerMode.pomodoro,
                  ),
                ),
              ).then((_) => _loadData());
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
            icon: Icons.forest_outlined,
            activeIcon: Icons.forest,
            label: '내 숲',
            isActive: false,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForestScreen(),
                ),
              ).then((_) => _loadData()); // 돌아올 때 데이터 새로고침
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
              ).then((_) => _loadData()); // 돌아올 때 데이터 새로고침
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
              ).then((_) => _loadData()); // 돌아올 때 데이터 새로고침
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

  void _navigateToTimer(TimerType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(timerType: type),
      ),
    ).then((_) => _loadData()); // 돌아올 때 데이터 새로고침
  }
} 