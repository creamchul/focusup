import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../models/stats_period.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  StatsPeriod _selectedPeriod = StatsPeriod.day;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  
  // 통계 데이터
  int _totalFocusTime = 0;
  int _totalSessions = 0;
  int _averageSessionLength = 0;
  int _streakDays = 0;
  Map<DateTime, int> _focusTimeData = {};
  Map<String, int> _compareData = {};
  Map<String, int> _categoryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_selectedPeriod) {
        case StatsPeriod.day:
          _focusTimeData = StorageService.getDailyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareDailyData();
          break;
        case StatsPeriod.week:
          _focusTimeData = StorageService.getWeeklyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareWeeklyData();
          break;
        case StatsPeriod.month:
          _focusTimeData = StorageService.getMonthlyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareMonthlyData();
          break;
        case StatsPeriod.year:
          _focusTimeData = StorageService.getYearlyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareYearlyData();
          break;
      }
      
      _categoryData = await StorageService.getCategoryAnalysis(_selectedPeriod, _selectedDate);
      _totalFocusTime = _focusTimeData.values.fold(0, (sum, time) => sum + time);
      _totalSessions = StorageService.getTotalSessions();
      _averageSessionLength = _totalSessions > 0 ? (_totalFocusTime / _totalSessions).round() : 0;
      _streakDays = StorageService.getStreakDays();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 에러 처리를 여기에 추가할 수 있습니다
        });
      }
    }
  }

  void _showDatePicker() async {
    final now = DateTime.now();
    DateTime? selectedDate;

    switch (_selectedPeriod) {
      case StatsPeriod.day:
        selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: now,
        );
        break;
      case StatsPeriod.week:
        // 주 선택을 위한 달력
        final selected = await showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '주 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: now,
                    focusedDay: _focusedDate,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                      final weekEnd = weekStart.add(const Duration(days: 6));
                      return day.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                             day.isBefore(weekEnd.add(const Duration(days: 1)));
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      // 선택된 날짜가 속한 주의 월요일을 반환
                      final weekStart = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
                      Navigator.pop(context, weekStart);
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        selectedDate = selected;
        break;
      case StatsPeriod.month:
        // 월 선택을 위한 목록
        final currentYear = now.year;
        final months = <String>[];
        final monthValues = <DateTime>[];
        
        // 2020년부터 현재년도까지의 월 목록 생성
        for (int year = 2020; year <= currentYear; year++) {
          final maxMonth = year == currentYear ? now.month : 12;
          for (int month = 1; month <= maxMonth; month++) {
            months.add('${year}년 ${month}월');
            monthValues.add(DateTime(year, month));
          }
        }

        final selected = await showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '월 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    width: double.maxFinite,
                    child: ListView.builder(
                      reverse: true, // 최신 월이 위에 오도록
                      itemCount: months.length,
                      itemBuilder: (context, index) {
                        final reverseIndex = months.length - 1 - index;
                        final isSelected = isSameMonth(_selectedDate, monthValues[reverseIndex]);
                        return ListTile(
                          title: Text(
                            months[reverseIndex],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            monthValues[reverseIndex],
                          ),
                          tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        selectedDate = selected;
        break;
      case StatsPeriod.year:
        // 연도 선택을 위한 다이얼로그
        final int currentYear = now.year;
        selectedDate = await showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '연도 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: 200,
                    child: ListView.builder(
                      itemCount: currentYear - 2019,
                      itemBuilder: (context, index) {
                        final year = currentYear - index;
                        final isSelected = _selectedDate.year == year;
                        return ListTile(
                          title: Text(
                            '$year년',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            DateTime(year),
                          ),
                          tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
    }

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate!;
        _focusedDate = selectedDate;
        _loadStatsData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '통계',
          style: TextStyle(
            color: AppColors.getTextPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPeriodSelector(isDark),
                _buildDateSelector(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryCards(isDark),
                        const SizedBox(height: 16),
                        _buildBarChart(isDark),
                        const SizedBox(height: 16),
                        _buildComparisonChart(isDark),
                        const SizedBox(height: 16),
                        _buildCategoryChart(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _loadStatsData();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPeriodText(period),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    String title = '';
    VoidCallback? onPrevious;
    VoidCallback? onNext;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case StatsPeriod.day:
        title = DateFormat('yyyy년 MM월 dd일').format(_selectedDate);
        onPrevious = () {
          setState(() {
            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            _loadStatsData();
          });
        };
        onNext = _selectedDate.isBefore(now) ? () {
          setState(() {
            _selectedDate = _selectedDate.add(const Duration(days: 1));
            _loadStatsData();
          });
        } : null;
        break;
      case StatsPeriod.week:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        title = '${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)}';
        onPrevious = () {
          setState(() {
            _selectedDate = _selectedDate.subtract(const Duration(days: 7));
            _loadStatsData();
          });
        };
        onNext = weekStart.isBefore(now.subtract(const Duration(days: 7))) ? () {
          setState(() {
            _selectedDate = _selectedDate.add(const Duration(days: 7));
            _loadStatsData();
          });
        } : null;
        break;
      case StatsPeriod.month:
        title = DateFormat('yyyy년 MM월').format(_selectedDate);
        onPrevious = () {
          setState(() {
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
            _loadStatsData();
          });
        };
        onNext = _selectedDate.isBefore(DateTime(now.year, now.month - 1)) ? () {
          setState(() {
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
            _loadStatsData();
          });
        } : null;
        break;
      case StatsPeriod.year:
        title = '${_selectedDate.year}년';
        onPrevious = () {
          setState(() {
            _selectedDate = DateTime(_selectedDate.year - 1);
            _loadStatsData();
          });
        };
        onNext = _selectedDate.year < now.year ? () {
          setState(() {
            _selectedDate = DateTime(_selectedDate.year + 1);
            _loadStatsData();
          });
        } : null;
        break;
    }

    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          '총 집중 시간',
          '${(_totalFocusTime / 60).round()}시간',
          Icons.timer,
          isDark,
        ),
        _buildSummaryCard(
          '총 세션 수',
          '$_totalSessions회',
          Icons.repeat,
          isDark,
        ),
        _buildSummaryCard(
          '평균 세션',
          '${(_averageSessionLength / 60).round()}분',
          Icons.analytics,
          isDark,
        ),
        _buildSummaryCard(
          '연속 달성',
          '$_streakDays일',
          Icons.local_fire_department,
          isDark,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '집중 시간 추이',
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue() * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 60).round()}h',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = _getDateForIndex(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: _selectedPeriod == StatsPeriod.month ? 1 : 0,
                            child: Text(
                              _getChartLabel(date),
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(bool isDark) {
    final entries = _compareData.entries.toList();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기간별 총 집중시간',
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final maxValue = _getCompareMaxValue();
                final percentage = maxValue > 0 ? (entry.value / maxValue).toDouble() : 0.0;
                final color = AppColors.primary.withOpacity(0.8 - (index * 0.2));
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(isDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.getBackground(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(entry.value / 60).round()}시간',
                          style: TextStyle(
                            color: AppColors.getTextPrimary(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(bool isDark) {
    if (_categoryData.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(isDark)),
        ),
        child: Center(
          child: Text(
            '카테고리 데이터가 없습니다',
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // 총 시간 계산
    final totalTime = _categoryData.values.fold(0, (sum, time) => sum + time);
    // 가장 많이 사용된 카테고리 찾기
    var maxCategory = _categoryData.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '카테고리 분석',
                style: TextStyle(
                  color: AppColors.getTextPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieChartSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._categoryData.entries.map((entry) {
                        final color = _getCategoryColor(_categoryData.keys.toList().indexOf(entry.key));
                        final percentage = (entry.value / totalTime * 100).round();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: AppColors.getTextPrimary(isDark),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(entry.value / 60).round()}분 ($percentage%)',
                                      style: TextStyle(
                                        color: AppColors.getTextSecondary(isDark),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategorySummaryCard(
                '총 카테고리',
                '${_categoryData.length}개',
                isDark,
              ),
              _buildCategorySummaryCard(
                '가장 많이 한 활동',
                maxCategory.key,
                isDark,
              ),
              _buildCategorySummaryCard(
                '총 집중 시간',
                '${(totalTime / 60).round()}시간',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySummaryCard(String title, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodText(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.day:
        return '일';
      case StatsPeriod.week:
        return '주';
      case StatsPeriod.month:
        return '월';
      case StatsPeriod.year:
        return '년';
    }
  }

  DateTime _getDateForIndex(int index) {
    switch (_selectedPeriod) {
      case StatsPeriod.day:
        return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .add(Duration(hours: index));
      case StatsPeriod.week:
        return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1))
            .add(Duration(days: index));
      case StatsPeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month, index + 1);
      case StatsPeriod.year:
        return DateTime(_selectedDate.year, index + 1);
    }
  }

  String _getChartLabel(DateTime date) {
    switch (_selectedPeriod) {
      case StatsPeriod.day:
        return DateFormat('HH').format(date);
      case StatsPeriod.week:
        return DateFormat('E').format(date);
      case StatsPeriod.month:
        return DateFormat('d').format(date);
      case StatsPeriod.year:
        return DateFormat('M').format(date);
    }
  }

  List<BarChartGroupData> _getBarGroups() {
    final List<BarChartGroupData> groups = [];
    var index = 0;
    
    for (var entry in _focusTimeData.entries) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: AppColors.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      index++;
    }
    
    return groups;
  }

  double _getMaxValue() {
    if (_focusTimeData.isEmpty) return 0;
    return _focusTimeData.values.reduce((max, value) => max > value ? max : value).toDouble();
  }

  double _getCompareMaxValue() {
    if (_compareData.isEmpty) return 0;
    return _compareData.values.reduce((max, value) => max > value ? max : value).toDouble();
  }

  List<PieChartSectionData> _getPieChartSections() {
    final total = _categoryData.values.fold(0, (sum, value) => sum + value);
    final List<PieChartSectionData> sections = [];
    var index = 0;
    
    for (var entry in _categoryData.entries) {
      final percentage = entry.value / total;
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(_categoryData.keys.toList().indexOf(entry.key)),
          value: entry.value.toDouble(),
          title: '${(percentage * 100).round()}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    }
    
    return sections;
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  // 날짜 비교 유틸리티 메서드
  bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }
} 