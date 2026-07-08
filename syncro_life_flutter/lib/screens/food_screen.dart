import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../models/app_state.dart';
import 'upgrade_screen.dart';

class FoodScreen extends StatefulWidget {
  FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  String? expandedMealId;
  String? expandedScanId;

  void toggleExpand(String mealId) {
    setState(() {
      expandedMealId = expandedMealId == mealId ? null : mealId;
    });
  }

  Future<void> _pickAndAnalyzeImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppColors.cardDark,
            content: Row(
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "AI is analyzing your food...",
                    style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final bytes = await image.readAsBytes();
      if (!context.mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      final result = await appState.scanFood(bytes, image.name);

      if (!context.mounted) return;
      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with details
      _showScanResultDialog(context, result);
    } catch (e) {
      if (!context.mounted) return;
      // Close loading dialog if open
      Navigator.pop(context);

      final errorMsg = e.toString().replaceAll("Exception:", "").trim();
      final isLimitExceeded = errorMsg.toLowerCase().contains("limit");

      if (isLimitExceeded) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text("Limit Reached", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              errorMsg,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Maybe Later", style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                  );
                },
                child: const Text("Upgrade to Plus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
                SizedBox(width: 8),
                Text("Scan Failed", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              errorMsg,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("OK", style: TextStyle(color: AppColors.primaryBlue)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showScanResultDialog(BuildContext context, Map<String, dynamic> result) {
    final conf = result['confidence'] ?? 1.0;
    final confPct = (conf as num) * 100;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
            SizedBox(width: 8),
            Text("AI Scan Result", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result['foodName'] ?? 'Healthy Dish',
                style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Match Confidence: ${confPct.toStringAsFixed(0)}%",
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildNutritionBadge("Calories", "${result['calories'] ?? 0} kcal", Color(0xFF3B82F6)),
                  _buildNutritionBadge("Protein", "${result['protein'] ?? 0}g", Color(0xFF10B981)),
                  _buildNutritionBadge("Carbs", "${result['carbs'] ?? 0}g", Color(0xFFF59E0B)),
                  _buildNutritionBadge("Fats", "${result['fats'] ?? 0}g", Color(0xFFEF4444)),
                  _buildNutritionBadge("Fiber", "${result['fiber'] ?? 0}g", Color(0xFF8B5CF6)),
                  _buildNutritionBadge("Sodium", "${result['sodium'] ?? 0}mg", Color(0xFF6B7280)),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "Description:",
                style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                result['description'] ?? '',
                style: TextStyle(color: AppColors.textLight.withOpacity(0.8), fontSize: 12),
              ),
              if (result['aiNotes'] != null && result['aiNotes'].toString().isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  "AI Coach Notes:",
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  result['aiNotes'],
                  style: TextStyle(color: AppColors.primaryBlue.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryBlue),
              title: Text("Take Photo", style: TextStyle(color: AppColors.textLight)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyzeImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryBlue),
              title: Text("Choose from Gallery", style: TextStyle(color: AppColors.textLight)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyzeImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.15),
            Colors.purple.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.center_focus_strong,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Nutrition Scanner",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Scan your food photo to analyze calories and macronutrients instantly.",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPickerOptions(context),
                  icon: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  label: Text("Scan Meal", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanDetailContent(dynamic scan) {
    final calories = (scan['calories'] ?? '0').toString();
    final protein = scan['protein'] ?? '0';
    final carbs = scan['carbs'] ?? '0';
    final fats = scan['fats'] ?? '0';
    final fiber = scan['fiber'] ?? '0';
    final sodium = scan['sodium'] ?? '0';
    final description = (scan['description'] ?? 'No details provided.').toString();
    final aiNotes = (scan['aiNotes'] ?? '').toString();

    return Padding(
      padding: EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nutrition Values (Concise)",
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildNutritionBadge("Calories", "$calories kcal", Color(0xFF3B82F6)),
              _buildNutritionBadge("Protein", "${protein}g", Color(0xFF10B981)),
              _buildNutritionBadge("Carbs", "${carbs}g", Color(0xFFF59E0B)),
              _buildNutritionBadge("Fats", "${fats}g", Color(0xFFEF4444)),
              _buildNutritionBadge("Fiber", "${fiber}g", Color(0xFF8B5CF6)),
              _buildNutritionBadge("Sodium", "${sodium}mg", Color(0xFF6B7280)),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Description:",
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: AppColors.textLight.withOpacity(0.82), fontSize: 12, height: 1.5),
          ),
          if (aiNotes.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              "AI Coach Notes:",
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              aiNotes,
              style: TextStyle(color: AppColors.primaryBlue.withOpacity(0.9), fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final meals = appState.userMeals;

    return Container(
      color: AppColors.backgroundDark,
      child: RefreshIndicator(
        onRefresh: () => appState.loadAllData(),
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.cardDark,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            SizedBox(height: 16),

            // Header (Cart icon removed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Smart Meal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    Text("AI-powered nutrition", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: appState.isDarkMode ? Colors.yellow : AppColors.primaryBlue,
                    size: 24,
                  ),
                  tooltip: appState.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () => appState.toggleTheme(),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 1. Scanner Card
            _buildScannerCard(context),
            SizedBox(height: 24),

            // 2. Recent AI Scans Header
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  "Recent AI Scans",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  "(Max 5)",
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Recent Scans List
            if (appState.foodAnalysisHistory.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    "No food scanned yet.",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              )
            else
              Column(
                children: appState.foodAnalysisHistory.map((scan) {
                  final scanId = (scan['analysisId'] ?? '').toString();
                  final title = (scan['foodName'] ?? 'Scanned Dish').toString();
                  final conf = scan['confidence'] ?? 1.0;
                  final confPct = (conf as num) * 100;
                  final calLabel = "${scan['calories'] ?? 0} cal • Match Confidence: ${confPct.toStringAsFixed(0)}%";

                  List<MealTag> tags = [
                    MealTag("AI Scan", Colors.purple),
                  ];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: MealCardItem(
                      title: title,
                      tags: tags,
                      calLabel: calLabel,
                      iconContent: _buildMealAvatar(title),
                      isExpanded: expandedScanId == scanId,
                      onClick: () {
                        setState(() {
                          expandedScanId = expandedScanId == scanId ? null : scanId;
                        });
                      },
                      detailedContent: _buildScanDetailContent(scan),
                    ),
                  );
                }).toList(),
              ),

            SizedBox(height: 24),

            // 3. Recommended Meals Header
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  "Healthy Recommendations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Dishes loading state / Recommended Meals List
            if (appState.isLoading && meals.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryBlue),
                ),
              )
            else if (meals.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, color: AppColors.textMuted, size: 48),
                      SizedBox(height: 16),
                      Text(
                        "No healthy meals found.",
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: meals.map((meal) {
                  final mealId = (meal['mealId'] ?? meal['MealId'] ?? '').toString();
                  final title = (meal['name'] ?? meal['Name'] ?? 'Healthy Dish').toString();
                  final calLabel = "${meal['calories'] ?? meal['Calories'] ?? 0} cal";

                  // Dynamically map tags based on database properties
                  List<MealTag> tags = [];
                  final category = meal['category'] ?? meal['Category'];
                  if (category != null && category.toString().isNotEmpty) {
                    tags.add(MealTag(category.toString(), Color(0xFF0D9488)));
                  }

                  final proteinVal = meal['protein'] ?? meal['Protein'];
                  if (proteinVal != null) {
                    double p = double.tryParse(proteinVal.toString()) ?? 0.0;
                    if (p >= 20.0) {
                      tags.add(MealTag("High Protein", Color(0xFF2563EB)));
                    }
                  }

                  if (meal['isVegetarian'] == true || meal['IsVegetarian'] == true) {
                    tags.add(MealTag("Vegetarian", Color(0xFF10B981)));
                  } else if (meal['isVegan'] == true || meal['IsVegan'] == true) {
                    tags.add(MealTag("Vegan", Color(0xFF10B981)));
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: MealCardItem(
                      title: title,
                      tags: tags,
                      calLabel: calLabel,
                      iconContent: _buildMealAvatar(title),
                      isExpanded: expandedMealId == mealId,
                      onClick: () => toggleExpand(mealId),
                      detailedContent: _buildDetailContent(meal),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMealAvatar(String name) {
    final lowerName = name.toLowerCase();
    String emoji = "🥗"; // Default fallback

    if (lowerName.contains("salmon") || lowerName.contains("fish")) {
      emoji = "🐟";
    } else if (lowerName.contains("avocado")) {
      emoji = "🥑";
    } else if (lowerName.contains("parfait") || lowerName.contains("yogurt") || lowerName.contains("berry") || lowerName.contains("smoothie")) {
      emoji = "🍓";
    } else if (lowerName.contains("chicken") || lowerName.contains("turkey")) {
      emoji = "🍗";
    } else if (lowerName.contains("wrap") || lowerName.contains("tortilla")) {
      emoji = "🌯";
    } else if (lowerName.contains("oat") || lowerName.contains("porridge")) {
      emoji = "🥣";
    } else if (lowerName.contains("soup") || lowerName.contains("lentil")) {
      emoji = "🍲";
    } else if (lowerName.contains("tofu") || lowerName.contains("broccoli") || lowerName.contains("buddha")) {
      emoji = "🥦";
    } else if (lowerName.contains("salad")) {
      emoji = "🥗";
    }

    return Text(
      emoji,
      style: TextStyle(fontSize: 26),
    );
  }

  Widget _buildDetailContent(dynamic meal) {
    final calories = (meal['calories'] ?? meal['Calories'] ?? '0').toString();
    final protein = meal['protein'] ?? meal['Protein'] ?? '0';
    final carbs = meal['carbs'] ?? meal['Carbs'] ?? '0';
    final fats = meal['fats'] ?? meal['Fats'] ?? '0';
    final fiber = meal['fiber'] ?? meal['Fiber'] ?? '0';
    final sodium = meal['sodium'] ?? meal['Sodium'] ?? '0';
    final description = (meal['description'] ?? meal['Description'] ?? 'No recipe instructions provided.').toString();

    return Padding(
      padding: EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition Grid Header
          Text(
            "Nutrition Values (Concise)",
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 8),

          // Horizontal Wrap of Nutrition badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildNutritionBadge("Calories", "$calories kcal", Color(0xFF3B82F6)),
              _buildNutritionBadge("Protein", "${protein}g", Color(0xFF10B981)),
              _buildNutritionBadge("Carbs", "${carbs}g", Color(0xFFF59E0B)),
              _buildNutritionBadge("Fats", "${fats}g", Color(0xFFEF4444)),
              _buildNutritionBadge("Fiber", "${fiber}g", Color(0xFF8B5CF6)),
              _buildNutritionBadge("Sodium", "${sodium}mg", Color(0xFF6B7280)),
            ],
          ),
          SizedBox(height: 16),

          // Recipe Description Section
          Text(
            "How to do :",
            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: AppColors.textLight.withOpacity(0.82), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBadge(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class MealTag {
  final String text;
  final Color color;
  MealTag(this.text, this.color);
}

class MealCardItem extends StatelessWidget {
  final String title;
  final List<MealTag> tags;
  final String calLabel;
  final Widget iconContent;
  final bool isExpanded;
  final VoidCallback onClick;
  final Widget detailedContent;

  MealCardItem({
    super.key,
    required this.title,
    required this.tags,
    required this.calLabel,
    required this.iconContent,
    required this.isExpanded,
    required this.onClick,
    required this.detailedContent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFF1E293B)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF111726),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: iconContent,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ...tags.map((tag) => Container(
                                              margin: EdgeInsets.only(right: 6),
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tag.color.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tag.text,
                                                style: TextStyle(color: tag.color, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            )),
                                        Text(calLabel, style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.primaryBlue,
                  size: 22,
                )
              ],
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: isExpanded ? detailedContent : SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}
