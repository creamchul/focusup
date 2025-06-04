import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<FocusCategoryModel> _categories = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_isDisposed) return;
    
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryService.getCategories();
      if (mounted && !_isDisposed) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
        _showErrorMessage('카테고리 로딩에 실패했습니다: $e');
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted || _isDisposed) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted || _isDisposed) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFavorite(String categoryId) async {
    if (_isDisposed) return;
    
    final success = await CategoryService.toggleFavorite(categoryId);
    if (success && mounted && !_isDisposed) {
      await _loadCategories();
      _showSuccessMessage('즐겨찾기가 업데이트되었습니다');
    } else if (mounted && !_isDisposed) {
      _showErrorMessage('즐겨찾기 업데이트에 실패했습니다');
    }
  }

  Future<void> _reorderCategories(int oldIndex, int newIndex) async {
    if (_isDisposed) return;
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    final success = await CategoryService.reorderCategories(_categories);
    if (!success && mounted && !_isDisposed) {
      // 실패시 되돌리기
      await _loadCategories();
      _showErrorMessage('순서 변경에 실패했습니다');
    } else if (success && mounted && !_isDisposed) {
      _showSuccessMessage('카테고리 순서가 변경되었습니다');
    }
  }

  void _showCategoryDialog({FocusCategoryModel? category}) {
    if (!mounted || _isDisposed) return;
    
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    IconData selectedIcon = category?.icon ?? Icons.category_outlined;
    Color selectedColor = category?.color ?? AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? '카테고리 수정' : '새 카테고리'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이름 입력
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '카테고리 이름',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 설명 입력
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: '설명 (선택사항)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                
                // 아이콘 선택
                Row(
                  children: [
                    Text(
                      '아이콘: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(Theme.of(context).brightness == Brightness.dark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showIconPicker(setModalState, selectedIcon, (icon) {
                        selectedIcon = icon;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          selectedIcon,
                          color: selectedColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 색상 선택
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '색상:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(Theme.of(context).brightness == Brightness.dark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FocusCategoryModel.getAvailableColors().map((color) {
                        final isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(
                                color: Colors.white,
                                width: 3,
                              ) : null,
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: isSelected ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorMessage('카테고리 이름을 입력하세요');
                  return;
                }

                final newCategory = FocusCategoryModel(
                  id: category?.id ?? '',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                  isDefault: category?.isDefault ?? false,
                  isFavorite: category?.isFavorite ?? false,
                  order: category?.order ?? 0,
                  createdAt: category?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                bool success;
                if (isEditing) {
                  success = await CategoryService.updateCategory(newCategory);
                } else {
                  success = await CategoryService.addCategory(newCategory);
                }

                if (mounted) {
                  Navigator.pop(context);
                }
                
                if (success && mounted && !_isDisposed) {
                  await _loadCategories();
                  _showSuccessMessage(isEditing ? '카테고리가 수정되었습니다' : '새 카테고리가 추가되었습니다');
                } else if (mounted && !_isDisposed) {
                  _showErrorMessage(isEditing ? '카테고리 수정에 실패했습니다' : '카테고리 추가에 실패했습니다');
                }
              },
              child: Text(isEditing ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(StateSetter setModalState, IconData currentIcon, Function(IconData) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('아이콘 선택'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: FocusCategoryModel.getAvailableIcons().length,
            itemBuilder: (context, index) {
              final icon = FocusCategoryModel.getAvailableIcons()[index];
              final isSelected = icon == currentIcon;
              
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    onSelected(icon);
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.getBorder(Theme.of(context).brightness == Brightness.dark),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.getTextPrimary(Theme.of(context).brightness == Brightness.dark),
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(FocusCategoryModel category) async {
    if (category.isDefault) {
      _showErrorMessage('기본 카테고리는 삭제할 수 없습니다');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('카테고리 삭제'),
        content: Text('${category.name} 카테고리를 삭제하시겠습니까?\n삭제된 카테고리는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await CategoryService.deleteCategory(category.id);
      if (success) {
        await _loadCategories();
        _showSuccessMessage('카테고리가 삭제되었습니다');
      } else {
        _showErrorMessage('카테고리 삭제에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
            tooltip: '새 카테고리 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState(isDark)
              : _buildCategoryList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '카테고리가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 카테고리를 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('카테고리 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(20),
      onReorder: _reorderCategories,
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category, isDark);
      },
    );
  }

  Widget _buildCategoryCard(FocusCategoryModel category, bool isDark) {
    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: AppColors.getSurface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.getBorder(isDark),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: category.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              if (category.isFavorite)
                Icon(
                  Icons.star,
                  color: AppColors.warning,
                  size: 20,
                ),
              if (category.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '기본',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: category.description.isNotEmpty
              ? Text(
                  category.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 즐겨찾기 토글
              IconButton(
                icon: Icon(
                  category.isFavorite ? Icons.star : Icons.star_border,
                  color: category.isFavorite ? AppColors.warning : AppColors.textSecondary,
                ),
                onPressed: () => _toggleFavorite(category.id),
                tooltip: category.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
              ),
              
              // 더보기 메뉴
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showCategoryDialog(category: category);
                      break;
                    case 'delete':
                      _deleteCategory(category);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  if (!category.isDefault)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
              
              // 드래그 핸들
              ReorderableDragStartListener(
                index: _categories.indexOf(category),
                child: Icon(
                  Icons.drag_handle,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: _categories.indexOf(category) * 100),
      duration: 400.ms,
    ).slideX(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: _categories.indexOf(category) * 100),
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    );
  }
} 