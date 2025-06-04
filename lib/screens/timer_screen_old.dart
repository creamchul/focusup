import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';
import '../services/precision_timer_service.dart';
import '../services/storage_service.dart';

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
  late final PrecisionTimerService _timerService;
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
    _timerService = PrecisionTimerService();
    
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
    
    // 세션 복구 시도
    _timerService.recoverSession();
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
      print('타이머 화면 카테고리 로딩: ${categories.length}개');
      print('카테고리 목록: ${categories.map((c) => c.name).join(', ')}');
      
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
        _timerService.startTimer(
          duration: Duration(minutes: _selectedMinutes),
          categoryId: _selectedCategory?.id,
        );
        break;
      case TimerType.freeTimer:
        _timerService.startTimer(
          duration: Duration(minutes: _selectedMinutes),
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
            Text(
              '${_formatDuration(_timerService.currentDuration)} 동안 집중했습니다!',
              style: const TextStyle(fontSize: 16),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 8),
              Text(
                '카테고리: ${_selectedCategory!.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _timerService.stopTimer();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTimerTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 개발자 모드 토글 버튼
          IconButton(
            icon: Icon(
              _timerService.isDeveloperMode ? Icons.developer_mode : Icons.developer_mode_outlined,
              color: _timerService.isDeveloperMode ? AppColors.primary : Colors.grey,
            ),
            onPressed: () {
              _timerService.toggleDeveloperMode();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 개발자 모드 UI
            if (_timerService.isDeveloperMode) _buildDeveloperModeUI(),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 카테고리 선택
                    _buildCategorySelector(),
                    
                    const SizedBox(height: 40),
                    
                    // 타이머 원형 디스플레이
                    Expanded(child: _buildTimerDisplay()),
                    
                    const SizedBox(height: 40),
                    
                    // 시간 설정 (자유타이머/포모도로만)
                    if (widget.timerType != TimerType.stopwatch)
                      _buildTimeSelector(),
                    
                    const SizedBox(height: 32),
                    
                    // 컨트롤 버튼들
                    _buildControlButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperModeUI() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '개발자 모드 (속도: ${_timerService.speedMultiplier}x)',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _timerService.status == TimerStatus.running
                      ? () => _timerService.setSpeedMultiplier(1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _timerService.speedMultiplier == 1 
                        ? AppColors.primary 
                        : Colors.grey[300],
                    foregroundColor: _timerService.speedMultiplier == 1 
                        ? Colors.white 
                        : Colors.black54,
                  ),
                  child: const Text('1x'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _timerService.status == TimerStatus.running
                      ? () => _timerService.setSpeedMultiplier(12)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _timerService.speedMultiplier == 12 
                        ? AppColors.primary 
                        : Colors.grey[300],
                    foregroundColor: _timerService.speedMultiplier == 12 
                        ? Colors.white 
                        : Colors.black54,
                  ),
                  child: const Text('12x'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _timerService.status == TimerStatus.running
                      ? () => _timerService.setSpeedMultiplier(60)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _timerService.speedMultiplier == 60 
                        ? AppColors.primary 
                        : Colors.grey[300],
                    foregroundColor: _timerService.speedMultiplier == 60 
                        ? Colors.white 
                        : Colors.black54,
                  ),
                  child: const Text('60x'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _timerService.status == TimerStatus.running
                      ? () => _timerService.fastForward(duration: const Duration(minutes: 5))
                      : null,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: const Text('+5분'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _timerService.status == TimerStatus.running
                      ? () => _timerService.fastForward(duration: const Duration(minutes: 1))
                      : null,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: const Text('+1분'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: _isLoadingCategories
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('카테고리 로딩 중...'),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<FocusCategoryModel>(
                value: _selectedCategory,
                hint: const Text('카테고리 선택'),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: _categories.map((category) {
                  return DropdownMenuItem<FocusCategoryModel>(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(category.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _timerService.status == TimerStatus.running
                    ? null // 타이머 실행 중일 때는 카테고리 변경 불가
                    : (FocusCategoryModel? newCategory) {
                        setState(() {
                          _selectedCategory = newCategory;
                        });
                      },
              ),
            ),
    );
  }

  Widget _buildTimerDisplay() {
    final progress = widget.timerType == TimerType.stopwatch 
        ? 0.0 
        : _timerService.progress;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _timerService.status == TimerStatus.running
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 진행률 원형 게이지
                if (widget.timerType != TimerType.stopwatch)
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                
                // 시간 텍스트
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.timerType == TimerType.stopwatch
                            ? _formatDuration(_timerService.currentDuration)
                            : _formatDuration(_timerService.remainingTime),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      children: [
        Text(
          '시간 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _getTimeOptions().length,
            itemBuilder: (context, index) {
              final minutes = _getTimeOptions()[index];
              final isSelected = minutes == _selectedMinutes;
              
              return GestureDetector(
                onTap: _timerService.status == TimerStatus.running
                    ? null
                    : () {
                        setState(() {
                          _selectedMinutes = minutes;
                        });
                      },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      '${minutes}분',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        // 정지/리셋 버튼
        Expanded(
          child: OutlinedButton(
            onPressed: _timerService.status == TimerStatus.stopped
                ? null
                : () {
                    if (_timerService.status == TimerStatus.running ||
                        _timerService.status == TimerStatus.paused) {
                      _timerService.stopTimer();
                    }
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '정지',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 메인 액션 버튼
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _getMainButtonAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _getMainButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimerTitle() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        return '포모도로 타이머';
      case TimerType.freeTimer:
        return '자유 타이머';
      case TimerType.stopwatch:
        return '스톱워치';
    }
  }

  String _getStatusText() {
    switch (_timerService.status) {
      case TimerStatus.stopped:
        return '시작 준비';
      case TimerStatus.running:
        return '집중 중';
      case TimerStatus.paused:
        return '일시정지';
      case TimerStatus.completed:
        return '완료!';
    }
  }

  String _getMainButtonText() {
    switch (_timerService.status) {
      case TimerStatus.stopped:
        return '시작';
      case TimerStatus.running:
        return '일시정지';
      case TimerStatus.paused:
        return '재개';
      case TimerStatus.completed:
        return '새로 시작';
    }
  }

  VoidCallback? _getMainButtonAction() {
    if (_selectedCategory == null && widget.timerType != TimerType.stopwatch) {
      return null; // 카테고리가 선택되지 않은 경우
    }

    switch (_timerService.status) {
      case TimerStatus.stopped:
        return _startTimer;
      case TimerStatus.running:
        return _timerService.pauseTimer;
      case TimerStatus.paused:
        return _timerService.resumeTimer;
      case TimerStatus.completed:
        return () {
          _timerService.stopTimer();
          _startTimer();
        };
    }
  }

  List<int> _getTimeOptions() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        return [15, 25, 30, 45, 60];
      case TimerType.freeTimer:
        return [5, 10, 15, 30, 45, 60, 90, 120];
      case TimerType.stopwatch:
        return [];
    }
  }
} 