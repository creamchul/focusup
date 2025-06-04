import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/timer_service.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';

enum TimerType {
  pomodoro,
  freeTimer,
  stopwatch,
}

class TimerScreen extends StatefulWidget {
  final TimerType timerType;

  const TimerScreen({
    super.key,
    required this.timerType,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  late final TimerService _timerService;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  int _selectedMinutes = 25; // 자유 타이머용
  
  // 카테고리 관련
  List<FocusCategoryModel> _categories = [];
  FocusCategoryModel? _selectedCategory;
  bool _isLoadingCategories = false;
  
  // dispose 상태 추적
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _timerService = TimerService();
    
    // AnimationController 초기화를 try-catch로 감싸기
    try {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _progressController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    } catch (e) {
      print('AnimationController 초기화 오류: $e');
    }
    
    _timerService.addListener(_onTimerUpdate);
    _initializeTimer();
    _loadCategories();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // 리스너 제거
    try {
      _timerService.removeListener(_onTimerUpdate);
    } catch (e) {
      print('TimerService 리스너 제거 오류: $e');
    }
    
    // 애니메이션 컨트롤러 정리
    try {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      _pulseController.dispose();
    } catch (e) {
      print('PulseController dispose 오류: $e');
    }
    
    try {
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      _progressController.dispose();
    } catch (e) {
      print('ProgressController dispose 오류: $e');
    }
    
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_isDisposed) return;
    
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getCategories();
      if (mounted && !_isDisposed) {
        setState(() {
          _categories = categories;
          // 기본으로 첫 번째 카테고리 선택 (공부)
          _selectedCategory = categories.isNotEmpty ? categories[1] : null; // study 카테고리
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingCategories = false);
        print('카테고리 로딩 실패: $e');
      }
    }
  }

  void _initializeTimer() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        _selectedMinutes = 25;
        break;
      case TimerType.freeTimer:
        _selectedMinutes = 30;
        break;
      case TimerType.stopwatch:
        _selectedMinutes = 0;
        break;
    }
  }

  void _onTimerUpdate() {
    // dispose된 상태에서는 setState 호출하지 않기
    if (_isDisposed || !mounted) return;
    
    try {
      setState(() {});
      
      if (_timerService.status == TimerStatus.running) {
        if (!_pulseController.isAnimating && !_isDisposed) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        if (_pulseController.isAnimating && !_isDisposed) {
          _pulseController.stop();
        }
      }
      
      if (_timerService.status == TimerStatus.completed && mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('Timer update 오류: $e');
    }
  }

  void _startTimer() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        _timerService.startPomodoro(
          minutes: _selectedMinutes,
          categoryId: _selectedCategory?.id,
        );
        break;
      case TimerType.freeTimer:
        _timerService.startFreeTimer(
          _selectedMinutes,
          categoryId: _selectedCategory?.id,
        );
        break;
      case TimerType.stopwatch:
        _timerService.startStopwatch(
          categoryId: _selectedCategory?.id,
        );
        break;
    }
  }

  void _showCompletionDialog() {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('집중 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forest, color: AppColors.treeGreen, size: 48),
            const SizedBox(height: 16),
            Text(
              '${_selectedMinutes}분 집중을 완료했습니다!\n🌳 새로운 나무가 자랐어요!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedCategory!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedCategory!.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedCategory!.icon,
                      color: _selectedCategory!.color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCategory!.name,
                      style: TextStyle(
                        color: _selectedCategory!.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 타이머 화면도 닫기
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
            
            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 카테고리 선택
                    if (!_isLoadingCategories && _categories.isNotEmpty)
                      _buildCategorySelection(isDark),
                    const SizedBox(height: 32),
                    
                    // 타이머 디스플레이
                    _buildTimerDisplay(isDark),
                    const SizedBox(height: 32),
                    
                    // 컨트롤 버튼들
                    _buildControlButtons(isDark),
                    const SizedBox(height: 32),
                    
                    // 상태 메시지
                    _buildStatusMessage(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getBorder(isDark),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.getTextPrimary(isDark),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSubtitle(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.timerType != TimerType.stopwatch)
            GestureDetector(
              onTap: _showTimePickerDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedMinutes}분',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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

  Widget _buildCategorySelection(bool isDark) {
    // 타이머가 시작된 후에는 카테고리 변경 불가
    final isTimerActive = _timerService.status != TimerStatus.initial && 
                         _timerService.status != TimerStatus.stopped;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '집중 카테고리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            if (isTimerActive) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.lock,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ],
        ),
        if (isTimerActive) ...[
          const SizedBox(height: 8),
          Text(
            '집중 중에는 카테고리를 변경할 수 없습니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory?.id == category.id;
              
              return GestureDetector(
                onTap: isTimerActive ? null : () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 12,
                    right: index == _categories.length - 1 ? 0 : 0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withOpacity(isTimerActive ? 0.7 : 1.0)
                              : category.color.withOpacity(isTimerActive ? 0.05 : 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? category.color.withOpacity(isTimerActive ? 0.7 : 1.0)
                                : category.color.withOpacity(isTimerActive ? 0.2 : 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected && !isTimerActive ? [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          category.icon,
                          color: isSelected
                              ? Colors.white.withOpacity(isTimerActive ? 0.7 : 1.0)
                              : category.color.withOpacity(isTimerActive ? 0.5 : 1.0),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? category.color.withOpacity(isTimerActive ? 0.7 : 1.0)
                              : AppColors.textSecondary.withOpacity(isTimerActive ? 0.5 : 1.0),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: index * 100),
                duration: 400.ms,
              ).slideX(
                begin: 0.3,
                end: 0,
                delay: Duration(milliseconds: index * 100),
                duration: 400.ms,
                curve: Curves.easeOutQuart,
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.3,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildTimerDisplay(bool isDark) {
    final progress = _timerService.progress;
    final color = _timerService.status == TimerStatus.running
        ? (_selectedCategory?.color ?? AppColors.primary)
        : _timerService.status == TimerStatus.paused
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.getSurface(isDark),
              border: Border.all(
                color: AppColors.getBorder(isDark),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          
          // 진행률 원
          if (widget.timerType != TimerType.stopwatch)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                );
              },
            ),
          
          // 맥박 효과 (타이머 동작 중)
          if (_timerService.status == TimerStatus.running)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 280 + (_pulseController.value * 20),
                  height: 280 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3 - (_pulseController.value * 0.3)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          
          // 시간 표시
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _timerService.formattedTime,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedCategory != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory!.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory!.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategory!.icon,
                        color: _selectedCategory!.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCategory!.name,
                        style: TextStyle(
                          color: _selectedCategory!.color,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                widget.timerType == TimerType.stopwatch 
                    ? '경과 시간'
                    : '남은 시간',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 200.ms,
      duration: 600.ms,
    ).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      delay: 200.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildControlButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 정지/리셋 버튼
        if (_timerService.status != TimerStatus.initial)
          _buildControlButton(
            icon: Icons.stop,
            label: '정지',
            color: AppColors.error,
            onTap: () {
              _timerService.resetTimer();
            },
          ),
        
        // 메인 버튼 (시작/일시정지/재개)
        _buildMainControlButton(isDark),
        
        // 일시정지 중일 때만 리셋 버튼 표시
        if (_timerService.status == TimerStatus.paused)
          _buildControlButton(
            icon: Icons.refresh,
            label: '리셋',
            color: AppColors.textSecondary,
            onTap: () {
              _timerService.resetTimer();
            },
          ),
      ],
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

  Widget _buildMainControlButton(bool isDark) {
    IconData icon;
    String label;
    Color color;
    VoidCallback onTap;

    switch (_timerService.status) {
      case TimerStatus.initial:
      case TimerStatus.stopped:
        icon = Icons.play_arrow;
        label = '시작';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = _startTimer;
        break;
      case TimerStatus.running:
        icon = Icons.pause;
        label = '일시정지';
        color = AppColors.warning;
        onTap = () => _timerService.pauseTimer();
        break;
      case TimerStatus.paused:
        icon = Icons.play_arrow;
        label = '재개';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = () => _timerService.resumeTimer();
        break;
      case TimerStatus.completed:
        icon = Icons.refresh;
        label = '다시 시작';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = () {
          _timerService.resetTimer();
          _startTimer();
        };
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(bool isDark) {
    String message = '';
    switch (_timerService.status) {
      case TimerStatus.initial:
        message = '집중 준비가 되셨나요?\n시작 버튼을 눌러주세요! 🌱';
        break;
      case TimerStatus.running:
        message = '집중 모드가 진행 중입니다.\n휴대폰을 내려놓고 집중해보세요! 💪';
        break;
      case TimerStatus.paused:
        message = '타이머가 일시정지되었습니다.\n준비되면 재개 버튼을 눌러주세요 ⏸️';
        break;
      case TimerStatus.completed:
        message = '축하합니다! 집중을 완료했습니다! 🎉\n새로운 나무가 자랐어요 🌳';
        break;
      case TimerStatus.stopped:
        message = '타이머가 정지되었습니다.\n다시 시작해보세요 🔄';
        break;
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
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.getTextPrimary(isDark),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
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

  void _showTimePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.timerType == TimerType.pomodoro ? '포모도로 시간 설정' : '집중 시간 설정',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '집중할 시간을 선택하세요',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [15, 25, 30, 45, 60, 90].map((minutes) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedMinutes == minutes
                          ? AppColors.primary
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedMinutes == minutes ? null : Border.all(
                        color: AppColors.getBorder(Theme.of(context).brightness == Brightness.dark),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${minutes}분',
                      style: TextStyle(
                        color: _selectedMinutes == minutes
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        return '포모도로 타이머';
      case TimerType.freeTimer:
        return '자유 타이머';
      case TimerType.stopwatch:
        return '스톱워치';
    }
  }

  String _getSubtitle() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        return '25분 집중, 5분 휴식';
      case TimerType.freeTimer:
        return '원하는 시간만큼 집중';
      case TimerType.stopwatch:
        return '무제한 집중 측정';
    }
  }
} 