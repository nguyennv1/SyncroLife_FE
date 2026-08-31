import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/custom_icons.dart';
import '../models/app_state.dart';
import 'login_screen.dart';
import 'upgrade_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  String _formatDobDisplay(String rawDob) {
    try {
      final dt = DateTime.parse(rawDob).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {}
    return rawDob.split('T')[0];
  }

  String _formatNumber(dynamic number) {
    if (number == null) return "0";
    try {
      double val = double.parse(number.toString());
      if (val >= 1000) {
        int intPart = val.toInt();
        String s = intPart.toString();
        return "${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}";
      }
      return val.toStringAsFixed(val % 1 == 0 ? 0 : 1);
    } catch (_) {}
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.userProfile;
    final goals = appState.userGoals;

    // Parse name and tier
    final String name = user?['fullName']?.toString() ?? user?['username']?.toString() ?? user?['name']?.toString() ?? (appState.isLoggedIn ? 'No Profile Data' : 'Guest');
    final String? rawSub = user?['subscriptionType']?.toString() ?? user?['subscriptionPlan']?.toString();
    final String subType = (rawSub != null && rawSub.isNotEmpty) ? rawSub : 'FREE';
    final String subLabel = "${subType[0].toUpperCase()}${subType.substring(1).toLowerCase()} Member";

    // Parse metrics
    final rawHeight = user?['height'];
    final rawWeight = user?['weight'];
    double heightVal = 0.0;
    double weightVal = 0.0;
    if (rawHeight != null) heightVal = double.tryParse(rawHeight.toString()) ?? 0.0;
    if (rawWeight != null) weightVal = double.tryParse(rawWeight.toString()) ?? 0.0;

    String bmi = "-";
    String bmiStatus = "-";
    if (heightVal > 0 && weightVal > 0) {
      double bmiVal = weightVal / ((heightVal / 100) * (heightVal / 100));
      bmi = bmiVal.toStringAsFixed(1);
      if (bmiVal < 18.5) {
        bmiStatus = "Underweight";
      } else if (bmiVal >= 18.5 && bmiVal < 25.0) {
        bmiStatus = "Normal";
      } else if (bmiVal >= 25.0 && bmiVal < 30.0) {
        bmiStatus = "Overweight";
      } else if (bmiVal >= 30.0) {
        bmiStatus = "Obese";
      }
    } else {
      final dbBmi = user?['bmi'];
      if (dbBmi != null && double.tryParse(dbBmi.toString()) != null && double.parse(dbBmi.toString()) > 0) {
        double bmiVal = double.parse(dbBmi.toString());
        bmi = bmiVal.toStringAsFixed(1);
        if (bmiVal < 18.5) {
          bmiStatus = "Underweight";
        } else if (bmiVal >= 18.5 && bmiVal < 25.0) {
          bmiStatus = "Normal";
        } else if (bmiVal >= 25.0 && bmiVal < 30.0) {
          bmiStatus = "Overweight";
        } else if (bmiVal >= 30.0) {
          bmiStatus = "Obese";
        }
      } else {
        bmi = "-";
        bmiStatus = "-";
      }
    }

    final String calories = user?['targetCalories'] != null 
        ? _formatNumber(user!['targetCalories']) 
        : (user?['calories'] != null ? _formatNumber(user!['calories']) : '-');
    final String budget = user?['monthlyBudget'] != null 
        ? _formatNumber(user!['monthlyBudget']) 
        : (user?['budget'] != null ? _formatNumber(user!['budget']) : '-');

    // Parse allergies
    final rawAllergies = user?['allergies'];
    List<String> allergiesList = [];
    if (rawAllergies is List) {
      allergiesList = rawAllergies.map((e) => e.toString()).toList();
    } else if (rawAllergies is String && rawAllergies.isNotEmpty) {
      allergiesList = rawAllergies.split(',').map((e) => e.trim()).toList();
    } else {
      allergiesList = [];
    }

    final String? dob = user?['dateOfBirth']?.toString() ?? user?['dob']?.toString();
    final bool isMissingMetrics = heightVal == 0 || weightVal == 0 || calories == '-' || budget == '-' || dob == null || dob.isEmpty;

    return Container(
      color: AppColors.backgroundDark,
      child: RefreshIndicator(
        onRefresh: () => appState.loadAllData(),
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.cardDark,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 16),

            // Avatar Profile Summary
            Row(
              children: [
                AvatarOutlineIcon(size: 68, imageUrl: appState.googlePhotoUrl),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name, 
                              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 24),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: appState.isDarkMode ? Colors.yellow : AppColors.primaryBlue,
                              size: 20,
                            ),
                            tooltip: appState.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            onPressed: () => appState.toggleTheme(),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
                            tooltip: 'Edit Profile',
                            onPressed: () => _showEditProfileDialog(context, appState, user),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (subType.toLowerCase() == 'plus')
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.purpleAccent, Colors.pinkAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Plus Member",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(subLabel, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      if (dob != null && dob.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.cake, color: AppColors.primaryBlue, size: 14),
                            SizedBox(width: 6),
                            Text(
                              "Born: ${_formatDobDisplay(dob)}",
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                      if (subType.toLowerCase() == 'free' && appState.isLoggedIn) ...[
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  Colors.purple.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Upgrade to Plus",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 16),

            if (isMissingMetrics) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: appState.isDarkMode ? const Color(0xFF271318) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.overlapRed.withOpacity(appState.isDarkMode ? 0.5 : 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.overlapRed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please complete your health metrics (Height, Weight, Calories, Budget, or Date of Birth) for optimal AI recommendations.",
                        style: TextStyle(
                          color: appState.isDarkMode ? AppColors.textLight : const Color(0xFF991B1B), 
                          fontSize: 11, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Health Metrics
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Health Metrics", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 17)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MetricBoxCard(
                        number: bmi,
                        label: "BMI",
                        statusLabel: bmiStatus,
                        icon: HeartbeatIcon(size: 22),
                        onTap: () => _showUpdateBmiDialog(context, appState, user),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: MetricBoxCard(
                        number: calories,
                        label: "Daily Calories",
                        statusLabel: "On track",
                        icon: BullseyeIcon(size: 22),
                        onTap: () => _showUpdateCaloriesDialog(context, appState, user),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: MetricBoxCard(
                        number: "\$$budget",
                        label: "Monthly Budget",
                        statusLabel: "Under budget",
                        icon: CoinDollarIcon(size: 22),
                        onTap: () => _showUpdateBudgetDialog(context, appState, user),
                      ),
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 16),

            // Allergies & Restrictions
            Container(
              decoration: BoxDecoration(
                color: appState.isDarkMode ? Color(0xFF1C131D) : Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appState.isDarkMode ? Color(0xFF4A1E29) : Color(0xFFFECACA)),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.overlapRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text("!", style: TextStyle(color: AppColors.overlapRed, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      SizedBox(width: 8),
                      Text("Allergies & Restrictions", style: TextStyle(color: AppColors.overlapRed, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...allergiesList.map((allergy) => GestureDetector(
                        onTap: () => _showRemoveAllergyDialog(context, appState, allergy),
                        child: Tooltip(
                          message: "Tap to remove $allergy",
                          child: ProfileAllergyPill(text: allergy, isDark: appState.isDarkMode),
                        ),
                      )),
                      GestureDetector(
                        onTap: () => _showAddAllergyDialog(context, appState),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: appState.isDarkMode ? Color(0xFF1E293B).withOpacity(0.5) : Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("+ Add", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 16),

            // Active Goals
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Active Goals", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 17)),
                    IconButton(
                      icon: Icon(Icons.add, color: AppColors.accentTeal, size: 20),
                      onPressed: () => _showAddGoalDialog(context, appState),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (goals.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("No active goals", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  )
                else
                  ...goals.map((goal) {
                    final title = goal['goalName']?.toString() ?? goal['title']?.toString() ?? 'Goal';
                    final double current = double.tryParse(goal['currentValue']?.toString() ?? '0') ?? 0.0;
                    final double target = double.tryParse(goal['targetValue']?.toString() ?? '100') ?? 100.0;
                    final String unit = goal['unit']?.toString() ?? '';
                    double fraction = target > 0 ? (current / target) : 0.0;
                    if (fraction > 1.0) fraction = 1.0;
                    if (fraction < 0.0) fraction = 0.0;
                    final percentText = "${(fraction * 100).toInt()}% ($current/$target $unit)";

                    // Time calculations
                    double? timeFraction;
                    String? timePercentText;
                    String? timeLabel = "No deadline";

                    if (goal['deadline'] != null && goal['startDate'] != null) {
                      try {
                        final start = DateTime.parse(goal['startDate'].toString());
                        final deadline = DateTime.parse(goal['deadline'].toString());
                        final now = DateTime.now();
                        final totalDuration = deadline.difference(start).inDays;
                        if (totalDuration > 0) {
                          final elapsed = now.difference(start).inDays;
                          timeFraction = elapsed / totalDuration;
                          if (timeFraction > 1.0) timeFraction = 1.0;
                          if (timeFraction < 0.0) timeFraction = 0.0;
                          timePercentText = "${(timeFraction * 100).toInt()}% time";
                          
                          final daysLeft = deadline.difference(now).inDays;
                          if (daysLeft > 0) {
                            timeLabel = "$daysLeft days left";
                          } else if (daysLeft == 0) {
                            timeLabel = "Ends today";
                          } else {
                            timeLabel = "Ended ${-daysLeft} days ago";
                          }
                        }
                      } catch (_) {}
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: GoalItemProgress(
                        title: title, 
                        fraction: fraction, 
                        percentText: percentText,
                        timeFraction: timeFraction,
                        timePercentText: timePercentText,
                        timeLabel: timeLabel,
                        onTap: () => _showEditGoalDialog(context, appState, goal),
                      ),
                    );
                  }).toList(),
              ],
            ),
            SizedBox(height: 16),

            // Menu List
            Column(
              children: [
                if (appState.isLoggedIn && subType.toLowerCase() == 'free')
                  ProfileMenuRow(
                    title: "Upgrade Account",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                      );
                    },
                  ),
                ProfileMenuRow(
                  title: "Data & Privacy",
                  onTap: () => _showDataPrivacyDialog(context),
                ),
                ProfileMenuRow(
                  title: "Contact & Support",
                  onTap: () => _showContactSupportDialog(context),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text("Log Out", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      content: Text("Are you sure you want to log out?", style: TextStyle(color: AppColors.textMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.overlapRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            appState.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.logout, color: AppColors.overlapRed, size: 18),
                label: Text("Log Out", style: TextStyle(color: AppColors.overlapRed, fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.overlapRed.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddAllergyDialog(BuildContext context, AppState appState) {
    final allergyController = TextEditingController();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text("Add Allergy", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: allergyController,
            autofocus: true,
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Allergy Name",
              labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () async {
                final newAllergy = allergyController.text.trim();
                if (newAllergy.isNotEmpty) {
                  try {
                    await appState.addAllergy(newAllergy);
                    navigator.pop();
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Error adding allergy: $e"),
                        backgroundColor: AppColors.overlapRed,
                      ),
                    );
                  }
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveAllergyDialog(BuildContext context, AppState appState, String allergy) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text("Remove Allergy", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove '$allergy'?", style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.overlapRed),
              onPressed: () async {
                try {
                  await appState.removeAllergy(allergy);
                  navigator.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Error removing allergy: $e"),
                      backgroundColor: AppColors.overlapRed,
                    ),
                  );
                }
              },
              child: const Text("Remove", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateBmiDialog(BuildContext context, AppState appState, dynamic user) {
    final heightController = TextEditingController(text: user?['height']?.toString() ?? '');
    final weightController = TextEditingController(text: user?['weight']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double height = double.tryParse(heightController.text) ?? 0.0;
            double weight = double.tryParse(weightController.text) ?? 0.0;
            double bmiVal = 0.0;
            String bmiStatus = "-";
            if (height > 0 && weight > 0) {
              bmiVal = weight / ((height / 100) * (height / 100));
              if (bmiVal < 18.5) {
                bmiStatus = "Underweight";
              } else if (bmiVal >= 18.5 && bmiVal < 25.0) {
                bmiStatus = "Normal";
              } else if (bmiVal >= 25.0 && bmiVal < 30.0) {
                bmiStatus = "Overweight";
              } else {
                bmiStatus = "Obese";
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text("Update Height & Weight", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    heightController, 
                    "Height (cm)", 
                    Icons.height, 
                    isNumeric: true,
                    onChanged: (val) => setStateDialog(() {}),
                  ),
                  _buildTextField(
                    weightController, 
                    "Weight (kg)", 
                    Icons.monitor_weight_outlined, 
                    isNumeric: true,
                    onChanged: (val) => setStateDialog(() {}),
                  ),
                  if (bmiVal > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E293B).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Real-time BMI:", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text(
                              "${bmiVal.toStringAsFixed(1)} ($bmiStatus)",
                              style: TextStyle(
                                color: bmiStatus == "Normal" ? AppColors.accentTeal : AppColors.overlapRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final double h = double.tryParse(heightController.text) ?? 0.0;
                    final double w = double.tryParse(weightController.text) ?? 0.0;

                    if (h <= 0 || h > 272) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invalid height"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                      return;
                    }

                    if (w <= 0 || w > 635) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invalid weight"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                      return;
                    }

                    int caloriesVal = 0;
                    final rawCal = user?['targetCalories'] ?? user?['calories'];
                    if (rawCal != null) caloriesVal = double.tryParse(rawCal.toString())?.toInt() ?? int.tryParse(rawCal.toString()) ?? 0;

                    double budgetVal = 0.0;
                    final rawB = user?['monthlyBudget'] ?? user?['budget'];
                    if (rawB != null) budgetVal = double.tryParse(rawB.toString()) ?? 0.0;

                    final dobStr = user?['dateOfBirth']?.toString() ?? user?['dob']?.toString() ?? '';

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await appState.updateProfile(
                        fullName: user?['fullName']?.toString() ?? user?['name']?.toString() ?? '',
                        gender: user?['gender']?.toString() ?? 'Male',
                        height: h,
                        weight: w,
                        targetCalories: caloriesVal,
                        monthlyBudget: budgetVal,
                        allergies: user?['allergies']?.toString() ?? '',
                        dateOfBirth: dobStr,
                      );
                      navigator.pop();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error updating BMI: $e"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdateCaloriesDialog(BuildContext context, AppState appState, dynamic user) {
    final caloriesController = TextEditingController(text: (user?['targetCalories'] ?? user?['calories'] ?? '').toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text("Update Daily Calories Target", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          content: _buildTextField(caloriesController, "Daily Calories Target (kcal)", Icons.local_fire_department, isNumeric: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () async {
                final int cal = int.tryParse(caloriesController.text) ?? -1;

                if (cal < 0 || cal > 20000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invalid calories"),
                      backgroundColor: AppColors.overlapRed,
                    ),
                  );
                  return;
                }

                double heightVal = 0.0;
                if (user?['height'] != null) heightVal = double.tryParse(user!['height'].toString()) ?? 0.0;
                double weightVal = 0.0;
                if (user?['weight'] != null) weightVal = double.tryParse(user!['weight'].toString()) ?? 0.0;

                double budgetVal = 0.0;
                final rawB = user?['monthlyBudget'] ?? user?['budget'];
                if (rawB != null) budgetVal = double.tryParse(rawB.toString()) ?? 0.0;

                final dobStr = user?['dateOfBirth']?.toString() ?? user?['dob']?.toString() ?? '';

                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await appState.updateProfile(
                    fullName: user?['fullName']?.toString() ?? user?['name']?.toString() ?? '',
                    gender: user?['gender']?.toString() ?? 'Male',
                    height: heightVal,
                    weight: weightVal,
                    targetCalories: cal,
                    monthlyBudget: budgetVal,
                    allergies: user?['allergies']?.toString() ?? '',
                    dateOfBirth: dobStr,
                  );
                  navigator.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Error updating calories: $e"),
                      backgroundColor: AppColors.overlapRed,
                    ),
                  );
                }
              },
              child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateBudgetDialog(BuildContext context, AppState appState, dynamic user) {
    final budgetController = TextEditingController(text: (user?['monthlyBudget'] ?? user?['budget'] ?? '').toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text("Update Monthly Food Budget", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          content: _buildTextField(budgetController, "Monthly Food Budget (\$)", Icons.attach_money, isNumeric: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () async {
                final double bud = double.tryParse(budgetController.text) ?? -1.0;

                if (bud < 0 || bud > 1000000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invalid budget"),
                      backgroundColor: AppColors.overlapRed,
                    ),
                  );
                  return;
                }

                double heightVal = 0.0;
                if (user?['height'] != null) heightVal = double.tryParse(user!['height'].toString()) ?? 0.0;
                double weightVal = 0.0;
                if (user?['weight'] != null) weightVal = double.tryParse(user!['weight'].toString()) ?? 0.0;

                int caloriesVal = 0;
                final rawCal = user?['targetCalories'] ?? user?['calories'];
                if (rawCal != null) caloriesVal = double.tryParse(rawCal.toString())?.toInt() ?? int.tryParse(rawCal.toString()) ?? 0;

                final dobStr = user?['dateOfBirth']?.toString() ?? user?['dob']?.toString() ?? '';

                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await appState.updateProfile(
                    fullName: user?['fullName']?.toString() ?? user?['name']?.toString() ?? '',
                    gender: user?['gender']?.toString() ?? 'Male',
                    height: heightVal,
                    weight: weightVal,
                    targetCalories: caloriesVal,
                    monthlyBudget: bud,
                    allergies: user?['allergies']?.toString() ?? '',
                    dateOfBirth: dobStr,
                  );
                  navigator.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Error updating budget: $e"),
                      backgroundColor: AppColors.overlapRed,
                    ),
                  );
                }
              },
              child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState, dynamic user) {
    final nameController = TextEditingController(text: user?['fullName']?.toString() ?? user?['name']?.toString() ?? '');
    
    // Normalize gender selection (Male / Female)
    String selectedGender = (user?['gender']?.toString() ?? '').trim();
    if (selectedGender.toLowerCase() == 'male' || selectedGender.toLowerCase() == 'nam' || selectedGender.toLowerCase() == 'm') {
      selectedGender = 'Male';
    } else if (selectedGender.toLowerCase() == 'female' || selectedGender.toLowerCase() == 'nữ' || selectedGender.toLowerCase() == 'f') {
      selectedGender = 'Female';
    } else {
      selectedGender = 'Male'; // default to Male
    }

    // DOB selection state
    String rawDob = user?['dateOfBirth']?.toString() ?? user?['dob']?.toString() ?? '';
    DateTime? selectedDob;
    if (rawDob.isNotEmpty) {
      selectedDob = DateTime.tryParse(rawDob)?.toLocal();
    }
    
    final dobController = TextEditingController(
      text: selectedDob != null 
          ? "${selectedDob.day.toString().padLeft(2, '0')}/${selectedDob.month.toString().padLeft(2, '0')}/${selectedDob.year}"
          : ''
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text("Update Profile", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, "Full Name", Icons.person),
                    
                    // Gender dropdown selector
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: AppColors.cardDark,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          dropdownColor: AppColors.cardDark,
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            prefixIcon: Icon(Icons.wc, color: AppColors.primaryBlue, size: 16),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male', style: TextStyle(color: AppColors.textLight)),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female', style: TextStyle(color: AppColors.textLight)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedGender = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    // Date of Birth input field (taps to select date)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: selectedDob ?? now.subtract(Duration(days: 365 * 25)),
                            firstDate: DateTime(1900),
                            lastDate: now, // Birthday must not be from the future
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.cardDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                  dialogBackgroundColor: AppColors.backgroundDark,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setStateDialog(() {
                              selectedDob = selected;
                              dobController.text = "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: _buildTextField(dobController, "Date of Birth", Icons.cake),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final String fullName = nameController.text.trim();
                    if (fullName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invalid name"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                      return;
                    }

                    if (selectedDob != null && selectedDob!.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invalid birthday"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                      return;
                    }

                    double heightVal = 0.0;
                    if (user?['height'] != null) heightVal = double.tryParse(user!['height'].toString()) ?? 0.0;
                    double weightVal = 0.0;
                    if (user?['weight'] != null) weightVal = double.tryParse(user!['weight'].toString()) ?? 0.0;

                    int caloriesVal = 0;
                    final rawCal = user?['targetCalories'] ?? user?['calories'];
                    if (rawCal != null) caloriesVal = double.tryParse(rawCal.toString())?.toInt() ?? int.tryParse(rawCal.toString()) ?? 0;

                    double budgetVal = 0.0;
                    final rawB = user?['monthlyBudget'] ?? user?['budget'];
                    if (rawB != null) budgetVal = double.tryParse(rawB.toString()) ?? 0.0;

                    final dobStrSave = selectedDob != null 
                        ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}"
                        : '';

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await appState.updateProfile(
                        fullName: fullName,
                        gender: selectedGender,
                        height: heightVal,
                        weight: weightVal,
                        targetCalories: caloriesVal,
                        monthlyBudget: budgetVal,
                        allergies: user?['allergies']?.toString() ?? '',
                        dateOfBirth: dobStrSave,
                      );
                      navigator.pop();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error updating profile: $e"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController();
    String selectedType = 'Fitness';
    DateTime selectedStart = DateTime.now();
    DateTime? selectedDeadline;

    final startController = TextEditingController(
      text: "${selectedStart.day.toString().padLeft(2, '0')}/${selectedStart.month.toString().padLeft(2, '0')}/${selectedStart.year}"
    );
    final deadlineController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text("Add New Goal", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, "Goal Name", Icons.flag),
                    
                    // Goal Type Dropdown
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: AppColors.cardDark,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          dropdownColor: AppColors.cardDark,
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Goal Type",
                            labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            prefixIcon: Icon(Icons.category, color: AppColors.primaryBlue, size: 16),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
                          ),
                          items: ['Fitness', 'Nutrition', 'Sleep', 'Work', 'Custom'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle(color: AppColors.textLight)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    _buildTextField(targetController, "Target Value", Icons.track_changes, isNumeric: true),
                    _buildTextField(unitController, "Unit (e.g. kg, kcal, km, times)", Icons.straighten),

                    // Start Date Picker
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: selectedStart,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.cardDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                  dialogBackgroundColor: AppColors.backgroundDark,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setStateDialog(() {
                              selectedStart = selected;
                              startController.text = "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
                              
                              if (selectedDeadline != null && selectedDeadline!.isBefore(selectedStart)) {
                                selectedDeadline = null;
                                deadlineController.clear();
                              }
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: _buildTextField(startController, "Start Date", Icons.calendar_today),
                        ),
                      ),
                    ),

                    // Deadline Picker
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline ?? selectedStart.add(Duration(days: 30)),
                            firstDate: selectedStart,
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.cardDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                  dialogBackgroundColor: AppColors.backgroundDark,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setStateDialog(() {
                              selectedDeadline = selected;
                              deadlineController.text = "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: _buildTextField(deadlineController, "Deadline (Optional)", Icons.event_busy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final target = double.tryParse(targetController.text) ?? 0.0;
                    final unit = unitController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Goal name is required"), backgroundColor: AppColors.overlapRed),
                      );
                      return;
                    }
                    if (target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Target value must be greater than 0"), backgroundColor: AppColors.overlapRed),
                      );
                      return;
                    }

                    final String startStr = "${selectedStart.year}-${selectedStart.month.toString().padLeft(2, '0')}-${selectedStart.day.toString().padLeft(2, '0')}";
                    final String deadlineStr = selectedDeadline != null
                        ? "${selectedDeadline!.year}-${selectedDeadline!.month.toString().padLeft(2, '0')}-${selectedDeadline!.day.toString().padLeft(2, '0')}"
                        : '';

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await appState.addGoal(
                        goalName: name,
                        goalType: selectedType,
                        targetValue: target,
                        unit: unit,
                        startDate: startStr,
                        deadline: deadlineStr,
                      );
                      navigator.pop();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error creating goal: $e"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, AppState appState, dynamic goal) {
    final goalId = goal['goalId']?.toString() ?? '';
    final mockGoalName = goal['title']?.toString() ?? goal['goalName']?.toString();
    
    final nameController = TextEditingController(text: goal['goalName']?.toString() ?? goal['title']?.toString() ?? '');
    final targetController = TextEditingController(text: (goal['targetValue'] ?? '').toString());
    final currentController = TextEditingController(text: (goal['currentValue'] ?? '').toString());
    final unitController = TextEditingController(text: goal['unit']?.toString() ?? '');
    String selectedType = goal['goalType']?.toString() ?? 'Fitness';
    bool isActive = goal['isActive'] == null ? true : (goal['isActive'] as bool);

    DateTime selectedStart = DateTime.now();
    if (goal['startDate'] != null) {
      try {
        selectedStart = DateTime.parse(goal['startDate'].toString());
      } catch (_) {}
    }

    DateTime? selectedDeadline;
    if (goal['deadline'] != null) {
      try {
        selectedDeadline = DateTime.parse(goal['deadline'].toString());
      } catch (_) {}
    }

    final startController = TextEditingController(
      text: "${selectedStart.day.toString().padLeft(2, '0')}/${selectedStart.month.toString().padLeft(2, '0')}/${selectedStart.year}"
    );
    final deadlineController = TextEditingController(
      text: selectedDeadline != null
          ? "${selectedDeadline.day.toString().padLeft(2, '0')}/${selectedDeadline.month.toString().padLeft(2, '0')}/${selectedDeadline.year}"
          : ''
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text("Edit Goal", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, "Goal Name", Icons.flag),
                    
                    // Goal Type Dropdown
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: AppColors.cardDark,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: ['Fitness', 'Nutrition', 'Sleep', 'Work', 'Custom'].contains(selectedType) ? selectedType : 'Custom',
                          dropdownColor: AppColors.cardDark,
                          style: TextStyle(color: AppColors.textLight, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Goal Type",
                            labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            prefixIcon: Icon(Icons.category, color: AppColors.primaryBlue, size: 16),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
                          ),
                          items: ['Fitness', 'Nutrition', 'Sleep', 'Work', 'Custom'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle(color: AppColors.textLight)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    _buildTextField(targetController, "Target Value", Icons.track_changes, isNumeric: true),
                    _buildTextField(currentController, "Current Progress Value", Icons.star_half, isNumeric: true),
                    _buildTextField(unitController, "Unit (e.g. kg, kcal, km, times)", Icons.straighten),

                    // Start Date Picker
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: selectedStart,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.cardDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                  dialogBackgroundColor: AppColors.backgroundDark,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setStateDialog(() {
                              selectedStart = selected;
                              startController.text = "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
                              
                              if (selectedDeadline != null && selectedDeadline!.isBefore(selectedStart)) {
                                selectedDeadline = null;
                                deadlineController.clear();
                              }
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: _buildTextField(startController, "Start Date", Icons.calendar_today),
                        ),
                      ),
                    ),

                    // Deadline Picker
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: selectedDeadline ?? selectedStart.add(Duration(days: 30)),
                            firstDate: selectedStart,
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.cardDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                  dialogBackgroundColor: AppColors.backgroundDark,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selected != null) {
                            setStateDialog(() {
                              selectedDeadline = selected;
                              deadlineController.text = "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}";
                            });
                          }
                        },
                        child: IgnorePointer(
                          child: _buildTextField(deadlineController, "Deadline (Optional)", Icons.event_busy),
                        ),
                      ),
                    ),

                    // Active Switch
                    SwitchListTile(
                      title: Text("Goal Active", style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      value: isActive,
                      activeColor: AppColors.accentTeal,
                      onChanged: (val) {
                        setStateDialog(() {
                          isActive = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Confirm delete
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.cardDark,
                        title: Text("Delete Goal", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                        content: Text("Are you sure you want to delete this goal?", style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.overlapRed),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await appState.removeGoal(goalId, mockGoalName: mockGoalName);
                        navigator.pop();
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text("Error deleting goal: $e"), backgroundColor: AppColors.overlapRed),
                        );
                      }
                    }
                  },
                  child: Text("Delete", style: TextStyle(color: AppColors.overlapRed)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final target = double.tryParse(targetController.text) ?? 0.0;
                    final current = double.tryParse(currentController.text) ?? 0.0;
                    final unit = unitController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Goal name is required"), backgroundColor: AppColors.overlapRed),
                      );
                      return;
                    }
                    if (target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Target value must be greater than 0"), backgroundColor: AppColors.overlapRed),
                      );
                      return;
                    }
                    if (current < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Current value cannot be negative"), backgroundColor: AppColors.overlapRed),
                      );
                      return;
                    }

                    final String startStr = "${selectedStart.year}-${selectedStart.month.toString().padLeft(2, '0')}-${selectedStart.day.toString().padLeft(2, '0')}";
                    final String deadlineStr = selectedDeadline != null
                        ? "${selectedDeadline!.year}-${selectedDeadline!.month.toString().padLeft(2, '0')}-${selectedDeadline!.day.toString().padLeft(2, '0')}"
                        : '';

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await appState.editGoal(
                        goalId: goalId,
                        goalName: name,
                        goalType: selectedType,
                        targetValue: target,
                        currentValue: current,
                        unit: unit,
                        startDate: startStr,
                        deadline: deadlineStr,
                        isActive: isActive,
                      );
                      navigator.pop();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error updating goal: $e"),
                          backgroundColor: AppColors.overlapRed,
                        ),
                      );
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.textLight, fontSize: 13),
        keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 16),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
        ),
      ),
    );
  }

  void _showDataPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Data & Privacy", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "By using Syncro Life, you agree to the collection and use of information to provide AI-powered synchronization and lifestyle features.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                "How we use your data:",
                style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              _buildBulletPoint("Google Calendar Integration: We load your Google Calendar event data to analyze daily schedules and dynamically suggest optimal times for workouts, meals, and tasks."),
              _buildBulletPoint("Health Metrics: We collect height, weight, daily target calories, and budget data to generate custom nutritional recommendations."),
              _buildBulletPoint("Allergies & Restrictions: Allergy information is used to filter out unsafe food recommendations."),
              _buildBulletPoint("Goal Tracking: We store your fitness and lifestyle goals to monitor your progress over time."),
              SizedBox(height: 12),
              Text(
                "Your calendar events and health data are stored securely and never shared with third parties without your explicit consent.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Contact & Support", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "For any questions, feedback, or support requests, please feel free to reach out to us at:",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    "nguyennvse180746@fpt.edu.vn",
                    style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "We will respond to your inquiry as soon as possible.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ProfileAllergyPill extends StatelessWidget {
  final String text;
  final bool isDark;
  const ProfileAllergyPill({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B1E22) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: isDark ? AppColors.overlapRed : const Color(0xFFDC2626), 
          fontSize: 11, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

class MetricBoxCard extends StatelessWidget {
  final String number;
  final String label;
  final String statusLabel;
  final Widget icon;
  final VoidCallback? onTap;

  MetricBoxCard({
    super.key, 
    required this.number, 
    required this.label, 
    required this.statusLabel, 
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF1E293B)),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            icon,
            Column(
              children: [
                Text(number, style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 17)),
                Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10), textAlign: TextAlign.center),
              ],
            ),
            Text(statusLabel, style: TextStyle(color: AppColors.accentTeal, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class GoalItemProgress extends StatelessWidget {
  final String title;
  final double fraction;
  final String percentText;
  final double? timeFraction;
  final String? timePercentText;
  final String? timeLabel;
  final VoidCallback? onTap;

  GoalItemProgress({
    super.key, 
    required this.title, 
    required this.fraction, 
    required this.percentText,
    this.timeFraction,
    this.timePercentText,
    this.timeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF1E293B)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(percentText, style: TextStyle(color: AppColors.accentTeal, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Color(0xFF1C273C),
                color: AppColors.accentTeal,
              ),
            ),
            if (timeFraction != null && timeFraction! > 0) ...[
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeLabel ?? 'Time Elapsed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(timePercentText ?? '', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: timeFraction,
                  minHeight: 4,
                  backgroundColor: Color(0xFF1C273C),
                  color: AppColors.primaryBlue,
                ),
              ),
            ] else if (timeLabel != null && timeLabel != "No deadline") ...[
              SizedBox(height: 8),
              Text(timeLabel!, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  ProfileMenuRow({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.w600)),
            Icon(Icons.keyboard_arrow_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
