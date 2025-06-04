import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/reward_models.dart';
import '../services/theme_service.dart';
import '../services/reward_service.dart';
import '../utils/colors.dart';
import '../constants/app_colors.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  final RewardService _rewardService = RewardService();
  UserProgress? _userProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await _rewardService.getUserProgress();
    setState(() {
      _userProgress = progress;
      _isLoading = false;
    });
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
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '내 사파리',
              style: TextStyle(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSafariContent(isDark),
    );
  }

  Widget _buildSafariContent(bool isDark) {
    if (_userProgress == null) {
      return const Center(child: Text('데이터를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 동물
          _buildCurrentAnimalCard(isDark),
          const SizedBox(height: 24),
          
          // 동물 컬렉션
          _buildAnimalCollection(isDark),
          const SizedBox(height: 24),
          
          // 진행 상황
          _buildProgressSection(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCurrentAnimalCard(bool isDark) {
    final animal = _userProgress!.animal;
    final animalEmoji = AnimalData.getAnimalEmoji(animal.type);
    final animalName = AnimalData.getAnimalName(animal.type);
    final animalDesc = AnimalData.getAnimalDescription(animal.type);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.brown.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            '현재 동물 친구',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            animalEmoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          
          Text(
            animalName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            animalDesc,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '유대 레벨 ${animal.bondLevel}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: 600.ms,
    ).slideY(
      begin: 0.2,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildAnimalCollection(bool isDark) {
    final totalHours = _userProgress!.totalFocusMinutes ~/ 60;
    final streakDays = _userProgress!.currentStreak;
    final level = _userProgress!.currentLevel;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '동물 컬렉션',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: AnimalType.values.length,
          itemBuilder: (context, index) {
            final animalType = AnimalType.values[index];
            final isUnlocked = AnimalData.isUnlocked(
              animalType, 
              totalHours, 
              streakDays, 
              level
            );
            
            return _buildAnimalCollectionItem(isDark, animalType, isUnlocked);
          },
        ),
      ],
    ).animate().fadeIn(
      delay: 200.ms,
      duration: 600.ms,
    );
  }

  Widget _buildAnimalCollectionItem(bool isDark, AnimalType type, bool isUnlocked) {
    final emoji = isUnlocked ? AnimalData.getAnimalEmoji(type) : '🔒';
    final name = isUnlocked ? AnimalData.getAnimalName(type) : '???';
    final requiredHours = AnimalData.getUnlockHours(type);
    final specialCondition = AnimalData.getSpecialUnlockCondition(type);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? AppColors.getSurface(isDark)
            : AppColors.getSurface(isDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked 
              ? Colors.brown.withOpacity(0.3)
              : AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 32,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                  ? AppColors.getTextPrimary(isDark)
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 2),
            Text(
              specialCondition.isNotEmpty 
                  ? specialCondition['description']
                  : '${requiredHours}시간',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isDark) {
    final nextAnimal = AnimalData.getNextUnlockTarget(
      _userProgress!.totalFocusMinutes ~/ 60,
      _userProgress!.currentStreak,
      _userProgress!.currentLevel,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다음 목표',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
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
          child: Column(
            children: [
              Text(
                AnimalData.getAnimalEmoji(nextAnimal),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                AnimalData.getAnimalName(nextAnimal),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AnimalData.getAnimalDescription(nextAnimal),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildProgressIndicator(isDark, nextAnimal),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: 200.ms,
      duration: 600.ms,
    );
  }

  Widget _buildProgressIndicator(bool isDark, AnimalType nextAnimal) {
    final requiredHours = AnimalData.getUnlockHours(nextAnimal);
    final currentHours = _userProgress!.totalFocusMinutes ~/ 60;
    final progress = (currentHours / requiredHours).clamp(0.0, 1.0);
    final specialCondition = AnimalData.getSpecialUnlockCondition(nextAnimal);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '집중 시간',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$currentHours / $requiredHours 시간',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.getBorder(isDark),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
        ),
        
        if (specialCondition.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '추가 조건: ${specialCondition['description']}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
} 