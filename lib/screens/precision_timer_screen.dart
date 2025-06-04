import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/precision_timer_service.dart';
import '../services/reward_service.dart';
import '../models/focus_category_model.dart';
import '../models/reward_models.dart';
import '../services/category_service.dart';

class PrecisionTimerScreen extends StatefulWidget {
  final TimerMode initialMode;
  final int? focusMinutes;
  final int? breakMinutes;
  final String? categoryId;

  const PrecisionTimerScreen({
    super.key,
    required this.initialMode,
    this.focusMinutes,
    this.breakMinutes,
    this.categoryId,
  });

  @override
  State<PrecisionTimerScreen> createState() => _PrecisionTimerScreenState();
}

class _PrecisionTimerScreenState extends State<PrecisionTimerScreen> with TickerProviderStateMixin {
  late final PrecisionTimerService _timerService;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  int _selectedMinutes = 25;
  
  // 카테고리 관련
  List<FocusCategoryModel> _categories = [];
  FocusCategoryModel? _selectedCategory;
  bool _isLoadingCategories = false;
  
  // dispose 상태 추적
  bool _isDisposed = false;
  
  // 5분 스킵 기능
  bool _showSkipButton = false;

  @override
  void initState() {
    super.initState();
    _timerService = PrecisionTimerService();
    
    // AnimationController 초기화
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
    
    // 설정된 시간을 타이머 서비스에 적용
    if (widget.focusMinutes != null) {
      _timerService.setTargetDuration(
        minutes: widget.focusMinutes!,
        breakMinutes: widget.breakMinutes,
        mode: widget.initialMode,
        categoryId: widget.categoryId,
      );
    }
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
    switch (widget.initialMode) {
      case TimerMode.timer:
        _timerService.setTargetDuration(
          minutes: widget.focusMinutes ?? 25,
          breakMinutes: widget.breakMinutes,
          mode: TimerMode.timer,
          categoryId: widget.categoryId,
        );
        _selectedMinutes = widget.focusMinutes ?? 25;
        break;
      case TimerMode.stopwatch:
        _selectedMinutes = 0;
        _timerService.setTargetDuration(
          minutes: 0,
          mode: TimerMode.stopwatch,
          categoryId: widget.categoryId,
        );
        break;
    }
  }

  void _onTimerUpdate() {
    if (_isDisposed || !mounted) return;
    
    try {
      setState(() {});
      
      if (_timerService.status == PrecisionTimerStatus.running) {
        if (!_pulseController.isAnimating && !_isDisposed) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        if (_pulseController.isAnimating && !_isDisposed) {
          _pulseController.stop();
        }
      }
      
      if (_timerService.status == PrecisionTimerStatus.completed && mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('Timer update 오류: $e');
    }
  }

  void _startTimer() {
    switch (widget.initialMode) {
      case TimerMode.timer:
        _timerService.startFreeTimer(
          minutes: _selectedMinutes,
          categoryId: _selectedCategory?.id,
        );
        break;
      case TimerMode.stopwatch:
        _timerService.startStopwatch(
          categoryId: _selectedCategory?.id,
        );
        break;
    }
  }

  void _showCompletionDialog() async {
    if (!mounted || _isDisposed) return;
    
    // 보상 지급
    final rewardService = RewardService();
    final achievements = await rewardService.grantFocusReward(
      focusMinutes: _timerService.mode == TimerMode.timer 
          ? (_timerService.phase == TimerPhase.focus 
              ? _timerService.targetDuration.inMinutes 
              : _timerService.breakDuration?.inMinutes ?? 0)
          : _timerService.elapsedTime.inMinutes,
      categoryId: _selectedCategory?.id ?? 'general',
      wasCompleted: _timerService.status == PrecisionTimerStatus.completed,
      hadBreak: _timerService.hasBreak,
    );
    
    // 브레이크 완료인지 포커스 완료인지 확인
    final isBreakCompleted = _timerService.phase == TimerPhase.rest;
    final icon = isBreakCompleted ? Icons.coffee : Icons.celebration;
    final iconColor = isBreakCompleted ? AppColors.warning : AppColors.primary;
    final title = isBreakCompleted ? '휴식 완료!' : '집중 완료!';
    
    // 동물 관련 아이콘으로 변경
    final animalIcon = isBreakCompleted ? Icons.local_cafe : Icons.pets;
    final animalEmoji = isBreakCompleted ? '☕' : '🐾';
    
    String message;
    if (isBreakCompleted) {
      message = '${_formatDuration(_timerService.breakDuration ?? Duration.zero)} 휴식을 완료했습니다!';
    } else {
      message = '${_formatDuration(_timerService.targetDuration)} 집중을 완료했습니다!';
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Text(
                animalEmoji,
                style: const TextStyle(fontSize: 48),
              ),
            const SizedBox(height: 16),
            Text(
                message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              ),
              if (!isBreakCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  '🎉 동물 친구와 더 친해졌어요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              
              // 보상 정보 표시
              if (achievements.isNotEmpty && !isBreakCompleted) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '획득한 보상',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...achievements.take(3).map((achievement) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          achievement,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )),
                      if (achievements.length > 3) ...[
                        const SizedBox(height: 8),
                        Text(
                          '그 외 ${achievements.length - 3}개의 보상',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              if (isBreakCompleted && _timerService.hasBreak)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '다음 집중을 시작하세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!isBreakCompleted || !_timerService.hasBreak) {
                // 포커스 완료이거나 브레이크가 없으면 타이머 정지
              _timerService.stopTimer();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
            ),
            child: Text(
              isBreakCompleted && _timerService.hasBreak ? '계속' : '확인', 
              style: const TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        // 타이머가 실행 중일 때는 뒤로가기 막기
        if (_timerService.status == PrecisionTimerStatus.running ||
            _timerService.status == PrecisionTimerStatus.paused) {
          _showGiveUpConfirmDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _getTitle(),
            style: TextStyle(
            color: AppColors.getTextPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: widget.initialMode == TimerMode.timer && _timerService.status == PrecisionTimerStatus.stopped ? [
            GestureDetector(
              onTap: _showTimePickerDialog,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
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
          ] : null,
        ),
        body: _buildTimerScreen(isDark),
      ),
    );
  }

  Widget _buildTimerScreen(bool isDark) {
    return Column(
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
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // 타이머가 실행 중일 때는 확인 다이얼로그 표시
              if (_timerService.status == PrecisionTimerStatus.running ||
                  _timerService.status == PrecisionTimerStatus.paused) {
                _showGiveUpConfirmDialog();
              } else {
                Navigator.pop(context);
              }
            },
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
        ],
      ),
    );
  }

  Widget _buildCategorySelection(bool isDark) {
    // 타이머가 시작된 후에는 카테고리 변경 불가
    final isTimerActive = _timerService.status != PrecisionTimerStatus.stopped;
    
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
    
    // 타이머 상태에 따라 표시할 시간 결정
    Duration displayTime;
    if (_timerService.mode == TimerMode.stopwatch) {
      displayTime = _timerService.elapsedTime;
    } else {
      // 타이머가 시작되기 전이면 설정된 시간을 표시
      if (_timerService.status == PrecisionTimerStatus.stopped) {
        displayTime = _timerService.targetDuration;
      } else {
        displayTime = _timerService.remainingTime;
      }
    }
    
    // 휴식 시간일 때 다른 색상 사용
    final isRestTime = _timerService.phase == TimerPhase.rest;
    final color = _timerService.status == PrecisionTimerStatus.running
        ? (isRestTime ? AppColors.warning : (_selectedCategory?.color ?? AppColors.primary))
        : _timerService.status == PrecisionTimerStatus.paused
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
          if (_timerService.mode != TimerMode.stopwatch)
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
          if (_timerService.status == PrecisionTimerStatus.running)
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
                    _formatTime(displayTime),
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
                _getCycleStatusText(),
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
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
    return Column(
      children: [
        // 주요 컨트롤 버튼들
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 정지 버튼 (포기로 간주)
            if (_timerService.status != PrecisionTimerStatus.stopped)
              _buildControlButton(
                icon: Icons.stop,
                label: '정지',
                color: AppColors.error,
                onTap: () {
                  _showGiveUpConfirmDialog();
                },
              ),
            
            // 메인 버튼 (시작/일시정지/재개)
            _buildMainControlButton(isDark),
            
            // 브레이크 건너뛰기 버튼 (브레이크 중일 때만)
            if (_timerService.status == PrecisionTimerStatus.running && 
                _timerService.phase == TimerPhase.rest)
              _buildControlButton(
                icon: Icons.skip_next,
                label: '건너뛰기',
                color: AppColors.warning,
                onTap: () {
                  _timerService.skipBreak();
                },
              ),
          ],
        ),
        
        // 테스트용 빨리가기 버튼
        if (_timerService.status == PrecisionTimerStatus.running) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '테스트: ',
              style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _timerService.skipFiveMinutes();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '5분 빨리가기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ),
        ],
      ),
          ),
        ],
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
      case PrecisionTimerStatus.stopped:
        icon = Icons.play_arrow;
        label = '시작';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = _startTimer;
        break;
      case PrecisionTimerStatus.running:
        icon = Icons.pause;
        label = '일시정지';
        color = AppColors.warning;
        onTap = () => _timerService.pauseTimer();
        break;
      case PrecisionTimerStatus.paused:
        icon = Icons.play_arrow;
        label = '재개';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = _startTimer;
        break;
      case PrecisionTimerStatus.completed:
        icon = Icons.refresh;
        label = '다시 시작';
        color = _selectedCategory?.color ?? AppColors.primary;
        onTap = () {
          _timerService.stopTimer();
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
      case PrecisionTimerStatus.stopped:
        message = '집중 준비가 되셨나요?\n시작 버튼을 눌러주세요! 🌱';
        break;
      case PrecisionTimerStatus.running:
        message = '집중 모드가 진행 중입니다.\n휴대폰을 내려놓고 집중해보세요! 💪';
        break;
      case PrecisionTimerStatus.paused:
        message = '타이머가 일시정지되었습니다.\n준비되면 재개 버튼을 눌러주세요 ⏸️';
        break;
      case PrecisionTimerStatus.completed:
        message = '축하합니다! 집중을 완료했습니다! 🎉\n동물 친구와 더 친해졌어요 🐾';
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

  String _getTitle() {
    if (_timerService.status != PrecisionTimerStatus.stopped) {
      if (_timerService.mode == TimerMode.timer && _timerService.hasBreak) {
        return _timerService.phase == TimerPhase.focus ? '집중 시간' : '휴식 시간';
      }
    }
    
    switch (widget.initialMode) {
      case TimerMode.timer:
    return '타이머';
      case TimerMode.stopwatch:
        return '스톱워치';
    }
  }

  String _getSubtitle() {
    if (widget.initialMode == TimerMode.timer) {
      return '원하는 시간을 설정하고 시작하세요';
    } else {
      return '집중 시간';
    }
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  String _getCycleStatusText() {
    if (_timerService.status == PrecisionTimerStatus.stopped) {
      return '시작 준비';
    }
    
    if (_timerService.mode == TimerMode.stopwatch) {
      return '경과 시간';
    }
    
    if (_timerService.hasBreak) {
      final cycles = _timerService.completedCycles;
      if (_timerService.phase == TimerPhase.focus) {
        return '${cycles + 1}번째 집중';
      } else {
        return '${cycles}번째 휴식';
      }
    } else {
      return '집중 시간';
    }
  }

  void _showStopConfirmDialog() {
    _showGiveUpConfirmDialog();
  }

  void _showGiveUpConfirmDialog() {
    if (!mounted || _isDisposed) return;
    
    // 스톱워치의 경우 10분 미만일 때만 포기로 간주
    if (_timerService.mode == TimerMode.stopwatch) {
      final elapsedMinutes = _timerService.elapsedTime.inMinutes;
      if (elapsedMinutes >= 10) {
        // 10분 이상이면 보상 지급 후 정상 종료
        _grantStopwatchReward();
        return;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('집중 포기'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '😢',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              _timerService.mode == TimerMode.stopwatch
                  ? '아직 10분이 지나지 않았어요.\n정말 포기하시겠어요?'
                  : '집중을 포기하시겠어요?\n동물 친구가 슬퍼할 거예요.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속하기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              _timerService.stopTimer(); // 타이머 정지
              Navigator.of(context).pop(); // 화면 나가기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('포기하기'),
          ),
        ],
      ),
    );
  }

  void _grantStopwatchReward() async {
    // 10분 이상 스톱워치 사용 시 보상 지급
    final rewardService = RewardService();
    final achievements = await rewardService.grantFocusReward(
      focusMinutes: _timerService.elapsedTime.inMinutes,
      categoryId: _selectedCategory?.id ?? 'general',
      wasCompleted: true,
      hadBreak: false,
    );
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('스톱워치 완료!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                '${_timerService.elapsedTime.inMinutes}분 동안 집중했습니다!\n🐾 동물 친구와 더 친해졌어요!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              
              // 보상 정보 표시
              if (achievements.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '획득한 보상',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...achievements.take(3).map((achievement) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          achievement,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )),
                      if (achievements.length > 3) ...[
                        const SizedBox(height: 8),
                        Text(
                          '그 외 ${achievements.length - 3}개의 보상',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _timerService.stopTimer();
              Navigator.of(context).pop(); // 타이머 화면도 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '집중 시간 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(Theme.of(context).brightness == Brightness.dark),
          ),
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
              children: [5, 10, 15, 25, 30, 45, 60, 90].map((minutes) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMinutes = minutes;
                      _timerService.setTargetDuration(
                        minutes: minutes,
                        mode: TimerMode.timer,
                        categoryId: _selectedCategory?.id,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedMinutes == minutes
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedMinutes == minutes ? null : Border.all(
                        color: AppColors.primary.withOpacity(0.3),
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
} 