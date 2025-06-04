import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정 값들
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _darkModeEnabled = false;
  int _defaultPomodoroTime = 25;
  int _breakTime = 5;
  int _dailyGoal = 120; // 분 단위 (2시간)
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (_isDisposed) return;
    
    if (mounted && !_isDisposed) {
      setState(() {
        _notificationsEnabled = StorageService.isNotificationEnabled();
        _soundEnabled = StorageService.isSoundEnabled();
        _darkModeEnabled = StorageService.isDarkModeEnabled();
        _defaultPomodoroTime = StorageService.getDefaultPomodoroTime();
        _breakTime = StorageService.getBreakTime();
        // 일일 목표는 임시로 고정값 사용 (향후 확장 가능)
      });
    }
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
        title: Text(
          '설정',
          style: TextStyle(
            color: AppColors.getTextPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 카테고리 관리 섹션 추가
              _buildCategorySettings(isDark),
              const SizedBox(height: 20),
              
              _buildGeneralSettings(isDark),
              const SizedBox(height: 20),
              
              _buildTimerSettings(isDark),
              const SizedBox(height: 20),
              
              _buildNotificationSettings(isDark),
              const SizedBox(height: 20),
              
              _buildDataSettings(isDark),
              const SizedBox(height: 20),
              
              _buildAboutSettings(isDark),
              const SizedBox(height: 100), // 네비게이션 바 공간
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySettings(bool isDark) {
    return _buildSettingsSection(
      title: '카테고리 관리',
      isDark: isDark,
      children: [
        _buildActionTile(
          title: '카테고리 설정',
          subtitle: '집중 카테고리 추가, 수정, 정렬',
          icon: Icons.category,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.3,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildGeneralSettings(bool isDark) {
    return _buildSettingsSection(
      title: '일반 설정',
      isDark: isDark,
      children: [
        _buildSwitchTile(
          title: '다크 모드',
          subtitle: '어두운 테마 사용',
          icon: Icons.dark_mode,
          value: _darkModeEnabled,
          onChanged: (value) async {
            setState(() {
              _darkModeEnabled = value;
            });
            await StorageService.setDarkModeEnabled(value);
            // 실제로는 앱 재시작이나 테마 변경 로직이 필요
            _showSnackBar('다크 모드 설정이 변경되었습니다');
          },
          isDark: isDark,
        ),
        _buildNumberTile(
          title: '일일 목표',
          subtitle: '하루 집중 목표 시간',
          icon: Icons.flag,
          value: _dailyGoal ~/ 60,
          unit: '시간',
          min: 1,
          max: 8,
          onChanged: (value) {
            setState(() {
              _dailyGoal = value * 60;
            });
            _showSnackBar('일일 목표가 ${value}시간으로 설정되었습니다');
          },
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.3,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildTimerSettings(bool isDark) {
    return _buildSettingsSection(
      title: '타이머 설정',
      isDark: isDark,
      children: [
        _buildNumberTile(
          title: '기본 포모도로 시간',
          subtitle: '집중 세션 기본 시간',
          icon: Icons.timer,
          value: _defaultPomodoroTime,
          unit: '분',
          min: 15,
          max: 60,
          step: 5,
          onChanged: (value) async {
            setState(() {
              _defaultPomodoroTime = value;
            });
            await StorageService.setDefaultPomodoroTime(value);
            _showSnackBar('기본 포모도로 시간이 ${value}분으로 설정되었습니다');
          },
          isDark: isDark,
        ),
        _buildNumberTile(
          title: '휴식 시간',
          subtitle: '집중 후 휴식 시간',
          icon: Icons.coffee,
          value: _breakTime,
          unit: '분',
          min: 5,
          max: 30,
          step: 5,
          onChanged: (value) async {
            setState(() {
              _breakTime = value;
            });
            await StorageService.setBreakTime(value);
            _showSnackBar('휴식 시간이 ${value}분으로 설정되었습니다');
          },
          isDark: isDark,
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

  Widget _buildNotificationSettings(bool isDark) {
    return _buildSettingsSection(
      title: '알림 설정',
      isDark: isDark,
      children: [
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '집중 완료 및 휴식 알림',
          icon: Icons.notifications,
          value: _notificationsEnabled,
          onChanged: (value) async {
            setState(() {
              _notificationsEnabled = value;
            });
            await StorageService.setNotificationEnabled(value);
            _showSnackBar(value ? '알림이 활성화되었습니다' : '알림이 비활성화되었습니다');
          },
          isDark: isDark,
        ),
        _buildSwitchTile(
          title: '사운드',
          subtitle: '알림음 및 효과음',
          icon: Icons.volume_up,
          value: _soundEnabled,
          onChanged: (value) async {
            setState(() {
              _soundEnabled = value;
            });
            await StorageService.setSoundEnabled(value);
            _showSnackBar(value ? '사운드가 활성화되었습니다' : '사운드가 비활성화되었습니다');
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '알림 권한 확인',
          subtitle: '시스템 알림 권한 상태 확인',
          icon: Icons.security,
          onTap: () async {
            final hasPermission = await NotificationService.hasPermission();
            _showSnackBar(hasPermission ? '알림 권한이 허용되어 있습니다' : '알림 권한이 필요합니다');
          },
          isDark: isDark,
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

  Widget _buildDataSettings(bool isDark) {
    return _buildSettingsSection(
      title: '데이터 관리',
      isDark: isDark,
      children: [
        _buildActionTile(
          title: '데이터 백업',
          subtitle: '내 데이터를 안전하게 백업',
          icon: Icons.backup,
          onTap: () {
            _showComingSoonDialog('데이터 백업');
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '데이터 복원',
          subtitle: '백업된 데이터 복원',
          icon: Icons.restore,
          onTap: () {
            _showComingSoonDialog('데이터 복원');
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '모든 데이터 초기화',
          subtitle: '앱의 모든 데이터를 삭제합니다',
          icon: Icons.delete_forever,
          iconColor: AppColors.error,
          onTap: () {
            _showResetConfirmDialog();
          },
          isDark: isDark,
        ),
      ],
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

  Widget _buildAboutSettings(bool isDark) {
    return _buildSettingsSection(
      title: '앱 정보',
      isDark: isDark,
      children: [
        _buildActionTile(
          title: 'Focus Forest 버전',
          subtitle: '1.0.0',
          icon: Icons.info,
          onTap: () {
            _showAboutDialog();
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '개인정보 처리방침',
          subtitle: '개인정보 보호 정책',
          icon: Icons.privacy_tip,
          onTap: () {
            _showComingSoonDialog('개인정보 처리방침');
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '서비스 약관',
          subtitle: '이용 약관 및 조건',
          icon: Icons.article,
          onTap: () {
            _showComingSoonDialog('서비스 약관');
          },
          isDark: isDark,
        ),
        _buildActionTile(
          title: '문의하기',
          subtitle: '개발자에게 문의하기',
          icon: Icons.email,
          onTap: () {
            _showContactDialog();
          },
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(
      delay: 800.ms,
      duration: 600.ms,
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: 800.ms,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          ),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            child: child,
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildNumberTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required String unit,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - step) : null,
              icon: const Icon(Icons.remove),
              iconSize: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value$unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + step) : null,
              icon: const Icon(Icons.add),
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showComingSoonDialog(String feature) {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('준비 중'),
          ],
        ),
        content: Text(
          '$feature 기능은 곧 추가될 예정입니다.\n조금만 기다려주세요! 😊',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('데이터 초기화'),
          ],
        ),
        content: const Text(
          '모든 집중 기록, 나무, 통계가 삭제됩니다.\n정말로 초기화하시겠습니까?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearAllData();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('모든 데이터가 초기화되었습니다');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.forest, color: AppColors.treeGreen, size: 24),
            SizedBox(width: 8),
            Text('Focus Forest'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '버전 1.0.0',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text(
              '집중할 때마다 나무가 자라는\n생산성 앱입니다. 🌱',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '포모도로 기법을 활용해 집중하고,\n나만의 숲을 만들어보세요!',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.email, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('문의하기'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '개발자에게 문의사항이나 제안을\n보내주세요! 😊',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: AppColors.textSecondary, size: 16),
                SizedBox(width: 8),
                Text(
                  'support@focusforest.app',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
} 