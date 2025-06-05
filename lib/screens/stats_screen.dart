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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 포커스될 때마다 데이터 새로고침
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_selectedPeriod) {
        case StatsPeriod.day:
          _focusTimeData = StorageService.getDailyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareDailyData();
          
          // 일일 모드에서는 실제 오늘의 총 집중 시간을 사용
          final dateKey = _selectedDate.toIso8601String().split('T')[0];
          final todayKey = DateTime.now().toIso8601String().split('T')[0];
          
          if (dateKey == todayKey) {
            // 오늘 날짜라면 실제 저장된 데이터 사용
            _totalFocusTime = StorageService.getTodayFocusTime();
          } else {
            // 다른 날짜라면 해당 날짜의 저장된 데이터 사용
            _totalFocusTime = StorageService.prefs.getInt('focus_time_$dateKey') ?? 0;
          }
          break;
        case StatsPeriod.week:
          _focusTimeData = StorageService.getWeeklyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareWeeklyData();
          _totalFocusTime = _focusTimeData.values.fold(0, (sum, time) => sum + time);
          break;
        case StatsPeriod.month:
          _focusTimeData = StorageService.getMonthlyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareMonthlyData();
          _totalFocusTime = _focusTimeData.values.fold(0, (sum, time) => sum + time);
          break;
        case StatsPeriod.year:
          _focusTimeData = StorageService.getYearlyFocusTime(_selectedDate);
          _compareData = StorageService.getCompareYearlyData();
          _totalFocusTime = _focusTimeData.values.fold(0, (sum, time) => sum + time);
          break;
      }
      
      _categoryData = await StorageService.getCategoryAnalysis(_selectedPeriod, _selectedDate);
      _totalSessions = StorageService.getTotalSessions();
      _averageSessionLength = _totalSessions > 0 ? (_totalFocusTime / _totalSessions).round() : 0;
      _streakDays = StorageService.getStreakDays();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('통계 데이터 로딩 에러: $e'); // 디버깅용
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
        // 주 선택을 위한 개선된 달력
        final selected = await showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '주 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '원하는 주의 날짜를 선택하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar(
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
                        weekendTextStyle: TextStyle(color: Colors.red[400]),
                        defaultTextStyle: TextStyle(fontSize: 14),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        todayTextStyle: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        tableBorder: TableBorder.all(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                        // 주 전체를 하이라이트하는 스타일
                        rangeHighlightColor: AppColors.primary.withOpacity(0.1),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 현재 선택된 주 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '현재 선택: ${_getWeekRangeText(_selectedDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
        // 연도와 월을 함께 선택할 수 있는 개선된 월 선택기
        final selected = await showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildMonthYearPicker(),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '연도 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 250,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: ListView.builder(
                      itemCount: currentYear - 2019,
                      itemBuilder: (context, index) {
                        final year = currentYear - index;
                        final isSelected = _selectedDate.year == year;
                        return InkWell(
                          onTap: () => Navigator.pop(context, DateTime(year)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : null,
                              borderRadius: index == 0 
                                  ? const BorderRadius.vertical(top: Radius.circular(12))
                                  : index == currentYear - 2020
                                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                      : null,
                            ),
                            child: Text(
                              '$year년',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.getTextPrimary(isDark),
            ),
            onPressed: () {
              _loadStatsData();
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPeriodSelector(isDark),
                _buildDateSelector(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadStatsData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
          '${_totalFocusTime}분',
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
          '${(_averageSessionLength).round()}분',
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
    if (_focusTimeData.isEmpty) {
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
            '집중 시간 데이터가 없습니다',
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

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
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.primary,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = _getDateForIndex(group.x.toInt());
                      final minutes = rod.toY.toInt();
                      String tooltipText = '';
                      
                      switch (_selectedPeriod) {
                        case StatsPeriod.day:
                          tooltipText = '${date.hour}시: ${minutes}분';
                          break;
                        case StatsPeriod.week:
                          tooltipText = '${_getKoreanDayName(date)}: ${minutes}분';
                          break;
                        case StatsPeriod.month:
                          tooltipText = '${date.day}일: ${minutes}분';
                          break;
                        case StatsPeriod.year:
                          tooltipText = '${date.month}월: ${minutes}분';
                          break;
                      }
                      
                      return BarTooltipItem(
                        tooltipText,
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: _getLeftAxisInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}분',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getBottomAxisInterval(),
                      getTitlesWidget: (value, meta) {
                        final date = _getDateForIndex(value.toInt());
                        final shouldShow = _shouldShowBottomLabel(value.toInt());
                        
                        if (!shouldShow) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getChartLabel(date),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDark),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getLeftAxisInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.getBorder(isDark),
                      strokeWidth: 0.5,
                    );
                  },
                ),
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
                final minutes = entry.value;
                final hours = minutes ~/ 60;
                final remainingMinutes = minutes % 60;
                String timeText = '';
                
                if (hours > 0) {
                  timeText = '${hours}시간 ${remainingMinutes}분';
                } else {
                  timeText = '${remainingMinutes}분';
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
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
                        width: 70,
                        child: Text(
                          timeText,
                          style: TextStyle(
                            color: AppColors.getTextPrimary(isDark),
                            fontSize: 11,
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
        height: 200,
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
        children: [
          // 제목을 가운데 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          
          // 파이 차트를 가운데에 배치
          Center(
            child: Container(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: _getPieChartSections(),
                  centerSpaceRadius: 25,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 범례를 가운데 정렬
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: _categoryData.entries.map((entry) {
                final color = _getCategoryColor(_categoryData.keys.toList().indexOf(entry.key));
                final percentage = (entry.value / totalTime * 100).round();
                final minutes = entry.value;
                final hours = minutes ~/ 60;
                final remainingMinutes = minutes % 60;
                String timeText = '';
                
                if (hours > 0) {
                  timeText = '${hours}시간 ${remainingMinutes}분';
                } else {
                  timeText = '${remainingMinutes}분';
                }
                
                return Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: AppColors.getTextPrimary(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              '$timeText ($percentage%)',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 요약 카드들을 가운데 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCategorySummaryCard(
                '총 카테고리',
                '${_categoryData.length}개',
                isDark,
              ),
              _buildCategorySummaryCard(
                '주요 활동',
                maxCategory.key,
                isDark,
              ),
              _buildCategorySummaryCard(
                '총 시간',
                '${totalTime}분',
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
      constraints: const BoxConstraints(minWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.getTextSecondary(isDark),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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

  String _getKoreanDayName(DateTime date) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday - 1];
  }

  double _getLeftAxisInterval() {
    final maxValue = _getMaxValue();
    if (maxValue <= 60) return 15; // 15분 간격
    if (maxValue <= 240) return 30; // 30분 간격
    if (maxValue <= 480) return 60; // 1시간 간격
    return 120; // 2시간 간격
  }

  double _getBottomAxisInterval() {
    switch (_selectedPeriod) {
      case StatsPeriod.day:
        return 2; // 2시간마다
      case StatsPeriod.week:
        return 1; // 매일
      case StatsPeriod.month:
        return 5; // 5일마다
      case StatsPeriod.year:
        return 2; // 2개월마다
    }
  }

  bool _shouldShowBottomLabel(int index) {
    switch (_selectedPeriod) {
      case StatsPeriod.day:
        return index % 2 == 0; // 짝수 시간만
      case StatsPeriod.week:
        return true; // 모든 요일
      case StatsPeriod.month:
        return index % 5 == 0; // 5일마다
      case StatsPeriod.year:
        return index % 2 == 0; // 2개월마다
    }
  }

  String _getChartLabel(DateTime date) {
    switch (_selectedPeriod) {
      case StatsPeriod.day:
        return '${date.hour}시';
      case StatsPeriod.week:
        return _getKoreanDayName(date);
      case StatsPeriod.month:
        return '${date.day}일';
      case StatsPeriod.year:
        return '${date.month}월';
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
    
    for (var entry in _categoryData.entries) {
      final percentage = entry.value / total;
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(_categoryData.keys.toList().indexOf(entry.key)),
          value: entry.value.toDouble(),
          title: '${(percentage * 100).round()}%',
          radius: 50, // 반지름을 더 작게 조정
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
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

  // 주 범위 텍스트를 반환하는 헬퍼 메서드
  String _getWeekRangeText(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)}';
  }

  // 연도와 월을 함께 선택할 수 있는 위젯
  Widget _buildMonthYearPicker() {
    final now = DateTime.now();
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '월 선택',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // 연도 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: selectedYear > 2020 ? () {
                    setState(() {
                      selectedYear--;
                      if (selectedYear == now.year && selectedMonth > now.month) {
                        selectedMonth = now.month;
                      }
                    });
                  } : null,
                  icon: Icon(Icons.chevron_left, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$selectedYear년',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: selectedYear < now.year ? () {
                    setState(() {
                      selectedYear++;
                    });
                  } : null,
                  icon: Icon(Icons.chevron_right, color: AppColors.primary),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 월 선택 그리드
            Container(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isAvailable = selectedYear < now.year || 
                                     (selectedYear == now.year && month <= now.month);
                  final isSelected = month == selectedMonth && selectedYear == _selectedDate.year;
                  
                  return InkWell(
                    onTap: isAvailable ? () {
                      Navigator.pop(context, DateTime(selectedYear, month));
                    } : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary 
                            : isAvailable 
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${month}월',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? Colors.white 
                                : isAvailable 
                                    ? AppColors.primary 
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 현재 선택된 월 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '현재 선택: ${DateFormat('yyyy년 MM월').format(_selectedDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 