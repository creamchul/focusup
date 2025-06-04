import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/precision_timer_service.dart';
import '../services/session_recovery_service.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';

class PrecisionTimerScreen extends StatefulWidget {
  final TimerMode initialMode;

  const PrecisionTimerScreen({
    super.key,
    this.initialMode = TimerMode.pomodoro,
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
    _tryRecoverSession();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // 현재 세션 저장
    if (_timerService.status == PrecisionTimerStatus.running ||
        _timerService.status == PrecisionTimerStatus.paused) {
      SessionRecoveryService.saveActiveSession(_timerService);
    }
    
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

  Future<void> _tryRecoverSession() async {
    final hasSession = await SessionRecoveryService.hasSavedSession();
    if (hasSession && mounted) {
      _showSessionRecoveryDialog();
    }
  }

  void _showSessionRecoveryDialog() async {
    final sessionInfo = await SessionRecoveryService.getSavedSessionInfo();
    if (sessionInfo == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('세션 복구'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이전 타이머 세션이 발견되었습니다.'),
            const SizedBox(height: 8),
            Text('모드: ${_getModeName(sessionInfo['mode'])}'),
            Text('경과 시간: ${_formatDuration(Duration(microseconds: sessionInfo['elapsedTime'] ?? 0))}'),
            if (sessionInfo['categoryId'] != null)
              Text('카테고리: ${sessionInfo['categoryId']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              SessionRecoveryService.clearSavedSession();
              Navigator.of(context).pop();
            },
            child: const Text('삭제'),
          ),
          ElevatedButton(
            onPressed: () {
              SessionRecoveryService.tryRecoverSession(_timerService);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('복구', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _initializeTimer() {
    switch (widget.initialMode) {
      case TimerMode.pomodoro:
        _selectedMinutes = 25;
        break;
      case TimerMode.freeTimer:
        _selectedMinutes = 30;
        break;
      case TimerMode.stopwatch:
        _selectedMinutes = 0;
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
      
      // 주기적으로 세션 저장
      if (_timerService.status == PrecisionTimerStatus.running) {
        SessionRecoveryService.startAutoSave(_timerService);
      }
    } catch (e) {
      print('Timer update 오류: $e');
    }
  }

  void _startTimer() {
    switch (_timerService.mode) {
      case TimerMode.pomodoro:
        _timerService.startPomodoro(
          minutes: _selectedMinutes,
          categoryId: _selectedCategory?.id,
        );
        break;
      case TimerMode.freeTimer:
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

  void _showCompletionDialog() {
    if (!mounted || _isDisposed) return;
    
    // 저장된 세션 정리
    SessionRecoveryService.clearSavedSession();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('집중 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forest, color: AppColors.treeGreen, size: 48),
            const SizedBox(height: 16),
            Text(
              '${_formatDuration(_timerService.targetDuration)} 집중을 완료했습니다!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _timerService.stopTimer();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _showSkipButton ? _timerService.fastForward5Minutes : null,
          child: Text(
            _getModeName(_timerService.mode.toString()),
            style: TextStyle(
              color: AppColors.getTextPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 카테고리 선택
              _buildCategorySelector(isDark),
              
              const SizedBox(height: 30),
              
              // 타이머 표시
              Expanded(
                child: _buildTimerDisplay(isDark),
              ),
              
              const SizedBox(height: 30),
              
              // 5분 스킵 버튼 (타이머 실행 중일 때만 표시)
              if (_timerService.status == PrecisionTimerStatus.running)
                _buildSkipButton(isDark),
              
              // 컨트롤 버튼들
              _buildControlButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    if (_isLoadingCategories) {
      return const CircularProgressIndicator();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory?.id == category.id;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected ? category.color : AppColors.getSurface(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category.color : AppColors.getBorder(isDark),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected ? Colors.white : category.color,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(delay: (index * 100).ms),
          );
        },
      ),
    );
  }

  Widget _buildTimerDisplay(bool isDark) {
    final progress = _timerService.progress;
    final displayTime = _timerService.mode == TimerMode.stopwatch 
        ? _timerService.elapsedTime 
        : _timerService.remainingTime;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 원형 진행 표시
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: _timerService.mode == TimerMode.stopwatch ? null : progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.getBorder(isDark),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _selectedCategory?.color ?? AppColors.primary,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _formatTime(displayTime),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_timerService.mode != TimerMode.stopwatch)
                    Text(
                      '목표: ${_formatTime(_timerService.targetDuration)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                ],
              ),
            ],
          ).animate(target: _timerService.status == PrecisionTimerStatus.running ? 1 : 0)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05))
            .then()
            .scale(begin: const Offset(1.05, 1.05), end: const Offset(0.95, 0.95)),
          
          const SizedBox(height: 30),
          
          // 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(), width: 1),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return GestureDetector(
      onTap: _timerService.fastForward5Minutes,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fast_forward, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              '+5분',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildControlButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 정지 버튼
        if (_timerService.status != PrecisionTimerStatus.stopped)
          _buildActionButton(
            icon: Icons.stop,
            label: '정지',
            color: Colors.red,
            onPressed: _timerService.stopTimer,
          ),
        
        // 재생/일시정지 버튼
        _buildActionButton(
          icon: _timerService.status == PrecisionTimerStatus.running 
              ? Icons.pause 
              : Icons.play_arrow,
          label: _timerService.status == PrecisionTimerStatus.running 
              ? '일시정지' 
              : (_timerService.status == PrecisionTimerStatus.stopped ? '시작' : '재개'),
          color: AppColors.primary,
          onPressed: _timerService.status == PrecisionTimerStatus.running 
              ? _timerService.pauseTimer 
              : _startTimer,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Color _getStatusColor() {
    switch (_timerService.status) {
      case PrecisionTimerStatus.running:
        return AppColors.primary;
      case PrecisionTimerStatus.paused:
        return Colors.orange;
      case PrecisionTimerStatus.completed:
        return AppColors.treeGreen;
      case PrecisionTimerStatus.stopped:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_timerService.status) {
      case PrecisionTimerStatus.running:
        return '집중 중';
      case PrecisionTimerStatus.paused:
        return '일시정지';
      case PrecisionTimerStatus.completed:
        return '완료';
      case PrecisionTimerStatus.stopped:
        return '대기';
    }
  }

  String _getModeName(String modeString) {
    if (modeString.contains('pomodoro')) return '포모도로';
    if (modeString.contains('freeTimer')) return '자유 타이머';
    if (modeString.contains('stopwatch')) return '스톱워치';
    return '타이머';
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
} 