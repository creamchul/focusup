import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 통계 데이터
  int _totalFocusTime = 0;
  int _totalSessions = 0;
  int _averageSessionLength = 0;
  int _streakDays = 0;
  int _todayFocusTime = 0;
  List<int> _weeklyData = [];
  List<int> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStatsData() {
    setState(() {
      _totalFocusTime = StorageService.getTotalFocusTime();
      _totalSessions = StorageService.getTotalSessions();
      _averageSessionLength = _totalSessions > 0 ? (_totalFocusTime / _totalSessions).round() : 0;
      _streakDays = StorageService.getStreakDays();
      _todayFocusTime = StorageService.getTodayFocusTime();
      _weeklyData = StorageService.getWeeklyFocusTime();
      _monthlyData = StorageService.getMonthlyFocusTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(isDark),
            
            // 탭 바
            _buildTabBar(isDark),
            
            // 탭 뷰
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(isDark),
                  _buildChartsTab(isDark),
                  _buildInsightsTab(isDark),
                ],
              ),
            ),
          ],
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
                '통계 📊',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '집중 패턴을 분석해보세요',
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.analytics,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: '개요'),
          Tab(text: '차트'),
          Tab(text: '인사이트'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => _loadStatsData(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 오늘의 요약
            _buildTodaySummary(isDark),
            const SizedBox(height: 20),
            
            // 전체 통계 카드들
            _buildStatsCards(isDark),
            const SizedBox(height: 20),
            
            // 이번 주 미니 차트
            _buildWeeklyMiniChart(isDark),
            const SizedBox(height: 20),
            
            // 목표 진행률
            _buildGoalProgress(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary(bool isDark) {
    final hours = _todayFocusTime ~/ 60;
    final minutes = _todayFocusTime % 60;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 집중',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.today,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '집중 시간',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hours > 0 ? '${hours}시간 ${minutes}분' : '${minutes}분',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _streakDays > 0 ? '${_streakDays}일 연속!' : '시작해보세요!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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

  Widget _buildStatsCards(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '총 집중 시간',
                value: '${(_totalFocusTime / 60).floor()}h ${_totalFocusTime % 60}m',
                icon: Icons.timer,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '총 세션 수',
                value: '$_totalSessions회',
                icon: Icons.play_circle,
                color: AppColors.treeGreen,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '평균 세션',
                value: '${_averageSessionLength}분',
                icon: Icons.trending_up,
                color: AppColors.warning,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '연속 일수',
                value: '${_streakDays}일',
                icon: Icons.local_fire_department,
                color: AppColors.coral,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMiniChart(bool isDark) {
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
          Text(
            '이번 주 집중 시간',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: _weeklyData.isNotEmpty ? _weeklyData.reduce((a, b) => a > b ? a : b).toDouble() * 1.2 : 100,
                barGroups: _weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(
                          weekdays[value.toInt() % 7],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
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

  Widget _buildGoalProgress(bool isDark) {
    const dailyGoal = 120; // 2시간 목표
    final progress = _todayFocusTime / dailyGoal;
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘 목표 달성률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1 ? AppColors.treeGreen : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: AppColors.getBorder(isDark),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1 ? AppColors.treeGreen : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1 
                ? '🎉 목표 달성! 정말 잘하고 있어요!'
                : '목표까지 ${dailyGoal - _todayFocusTime}분 남았어요!',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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

  Widget _buildChartsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // 주간 차트
          _buildWeeklyChart(isDark),
          const SizedBox(height: 20),
          
          // 월간 차트
          _buildMonthlyChart(isDark),
          const SizedBox(height: 20),
          
          // 시간대별 차트 (임시 데이터)
          _buildHourlyChart(isDark),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool isDark) {
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
          Text(
            '주간 집중 트렌드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.getBorder(isDark),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(
                          weekdays[value.toInt() % 7],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _weeklyData.isNotEmpty ? _weeklyData.reduce((a, b) => a > b ? a : b).toDouble() * 1.2 : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(bool isDark) {
    // 월간 데이터를 주간으로 그룹화
    final weeklyAverages = <double>[];
    for (int i = 0; i < _monthlyData.length; i += 7) {
      final weekData = _monthlyData.skip(i).take(7);
      final average = weekData.isNotEmpty ? weekData.reduce((a, b) => a + b) / weekData.length : 0.0;
      weeklyAverages.add(average);
    }

    double maxValue = 100.0;
    if (weeklyAverages.isNotEmpty) {
      final max = weeklyAverages.reduce((a, b) => a > b ? a : b);
      maxValue = max * 1.2;
    }

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
          Text(
            '월간 집중 패턴',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                barGroups: weeklyAverages.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.treeGreen,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt() + 1}주',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(bool isDark) {
    // 임시 시간대별 데이터 (실제로는 시간대별 집중 패턴을 저장해야 함)
    final hourlyData = [
      0, 0, 0, 0, 0, 0, 15, 30, 45, 60, 75, 90, 
      45, 30, 60, 75, 90, 120, 90, 60, 30, 15, 0, 0
    ];

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
          Text(
            '시간대별 집중 패턴',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '어느 시간대에 가장 집중을 잘하는지 확인해보세요',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 140,
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.warning.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // 개인화된 인사이트들
          _buildInsightCard(
            icon: Icons.trending_up,
            title: '집중력 개선 추천',
            content: _getProductivityInsight(),
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          _buildInsightCard(
            icon: Icons.schedule,
            title: '최적 집중 시간',
            content: _getOptimalTimeInsight(),
            color: AppColors.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          _buildInsightCard(
            icon: Icons.local_fire_department,
            title: '습관 형성 팁',
            content: _getHabitInsight(),
            color: AppColors.coral,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          _buildInsightCard(
            icon: Icons.eco,
            title: '환경 보호 기여',
            content: _getEnvironmentInsight(),
            color: AppColors.treeGreen,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required bool isDark,
  }) {
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextPrimary(isDark),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getProductivityInsight() {
    if (_averageSessionLength < 20) {
      return '평균 집중 시간이 ${_averageSessionLength}분입니다. 포모도로 기법(25분)을 활용하여 조금 더 긴 집중을 시도해보세요. 짧은 집중도 좋지만, 깊은 집중을 위해서는 최소 20분 이상이 효과적입니다.';
    } else if (_averageSessionLength > 60) {
      return '평균 ${_averageSessionLength}분의 긴 집중을 하고 계시네요! 훌륭합니다. 다만 너무 긴 집중은 피로를 유발할 수 있으니, 중간중간 5-10분 휴식을 취하는 것을 권장합니다.';
    } else {
      return '평균 ${_averageSessionLength}분의 집중 시간은 매우 이상적입니다! 지금처럼 꾸준히 유지하시되, 가끔은 더 긴 집중에도 도전해보세요.';
    }
  }

  String _getOptimalTimeInsight() {
    final weeklyData = StorageService.getWeeklyFocusTime();
    if (weeklyData.isEmpty) return '더 많은 데이터가 필요합니다.';
    
    final maxIndex = weeklyData.indexOf(weeklyData.reduce((a, b) => a > b ? a : b));
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    
    return '이번 주 데이터를 보면 ${weekdays[maxIndex]}에 가장 많이 집중했습니다. 이 패턴을 활용해서 중요한 작업은 ${weekdays[maxIndex]}에 계획해보세요!';
  }

  String _getHabitInsight() {
    if (_streakDays == 0) {
      return '습관 형성의 첫 걸음을 시작해보세요! 작은 것부터 시작하는 것이 중요합니다. 하루에 단 15분이라도 꾸준히 집중하는 습관을 만들어보세요.';
    } else if (_streakDays < 7) {
      return '${_streakDays}일 연속 집중 중이시네요! 일주일 달성까지 ${7 - _streakDays}일 남았습니다. 습관이 형성되려면 평균 21일이 걸리니 꾸준히 해보세요.';
    } else if (_streakDays < 21) {
      return '${_streakDays}일 연속! 훌륭한 성과입니다. 21일 달성까지 ${21 - _streakDays}일 남았어요. 21일이 지나면 집중이 자연스러운 습관이 될 거예요!';
    } else {
      return '${_streakDays}일 연속 집중! 이미 습관이 완전히 형성되었습니다. 이제는 집중의 질을 높이는 데 집중해보세요. 정말 대단합니다! 🎉';
    }
  }

  String _getEnvironmentInsight() {
    final trees = StorageService.getTotalTrees();
    final co2Saved = trees * 21.8; // 나무 1그루가 1년에 약 21.8kg CO2 흡수
    
    return '지금까지 ${trees}그루의 나무를 심었습니다! 이는 연간 약 ${co2Saved.toStringAsFixed(1)}kg의 CO2를 흡수하는 효과와 같습니다. 집중할 때마다 지구 환경에도 기여하고 있어요! 🌍';
  }
} 