import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/custom_icons.dart';
import '../models/app_state.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool ongoingTabSelected = true;

  String _formatTimeRange(String? rawStartTime, String? rawEndTime, String fallbackTime) {
    if (rawStartTime == null) return _formatSingleTime(fallbackTime);
    try {
      final startDt = DateTime.parse(rawStartTime).toLocal();
      final String startStr = _formatDateTime(startDt);
      
      if (rawEndTime != null) {
        final endDt = DateTime.parse(rawEndTime).toLocal();
        final String endStr = _formatDateTime(endDt);
        return '$startStr to $endStr';
      }
      return startStr;
    } catch (_) {}
    return _formatSingleTime(fallbackTime);
  }

  String _formatDateTime(DateTime dt) {
    int hour = dt.hour;
    int minute = dt.minute;
    String period = hour >= 12 ? 'pm' : 'am';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    String minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String _formatSingleTime(String rawTime) {
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'pm' : 'am';
        int displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        String minuteStr = minute.toString().padLeft(2, '0');
        return '$displayHour:$minuteStr $period';
      }
    } catch (_) {}
    return rawTime;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final rawItems = ongoingTabSelected ? appState.ongoingSchedules : appState.historySchedules;

    final List<TimelineItemData> timelineItems = rawItems.map((item) {
      final title = item['title']?.toString() ?? 'Activity';
      final description = item['description']?.toString() ?? '';
      final rawTime = item['time']?.toString() ?? '12:00';
      final type = item['type']?.toString().toUpperCase() ?? 'GENERAL';
      
      final startTime = item['startTime']?.toString();
      final endTime = item['endTime']?.toString();

      Widget icon;
      switch (type) {
        case 'GYM':
          icon = DumbbellIcon(size: 22);
          break;
        case 'MEAL':
          icon = SoupIcon(size: 22);
          break;
        case 'SLEEP':
          icon = BedtimeIcon(size: 22);
          break;
        case 'WORK':
        case 'STUDY':
          icon = LaptopIcon(size: 22);
          break;
        case 'TASK':
          icon = TaskIcon(size: 22);
          break;
        case 'GENERAL':
        default:
          icon = CoffeeIcon(size: 22);
          break;
      }

      // Highlight AI suggestions
      if (title.toLowerCase() == "ai suggestion") {
        icon = DumbbellIcon(size: 22, tint: AppColors.primaryBlue);
      }

      bool isInProgress = false;
      bool isCompleted = item['isCompleted'] == true;
      if (startTime != null && endTime != null) {
        try {
          final now = DateTime.now();
          final start = DateTime.parse(startTime).toLocal();
          final end = DateTime.parse(endTime).toLocal();
          isInProgress = now.isAfter(start) && now.isBefore(end);
        } catch (_) {}
      }

      return TimelineItemData(
        title: title,
        description: description,
        time: _formatTimeRange(startTime, endTime, rawTime),
        icon: icon,
        isInProgress: isInProgress,
        isCompleted: isCompleted,
      );
    }).toList();

    // Dynamic counts from today's actual schedule (no mock fallbacks)
    int taskCount = appState.ongoingSchedules.where((e) => 
      e['type'] == 'WORK' || e['type'] == 'STUDY' || e['type'] == 'GENERAL' || e['type'] == 'TASK'
    ).length;

    int workoutCount = appState.ongoingSchedules.where((e) => e['type'] == 'GYM').length;

    int mealCount = appState.ongoingSchedules.where((e) => e['type'] == 'MEAL').length;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Syncro Life",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: appState.isDarkMode ? Colors.yellow : AppColors.primaryBlue,
                        size: 24,
                      ),
                      tooltip: appState.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      onPressed: () => appState.toggleTheme(),
                    ),
                    if (appState.isLoggedIn)
                      IconButton(
                        icon: appState.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
                              )
                            : Icon(Icons.sync, color: AppColors.accentTeal, size: 24),
                        tooltip: 'Sync Google Calendar',
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Syncing Google Calendar..."),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                try {
                                  await appState.syncGoogleCalendar();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Sync completed successfully!"),
                                        backgroundColor: AppColors.accentTeal,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Sync failed: ${e.toString().replaceAll('Exception: ', '')}"),
                                        backgroundColor: AppColors.overlapRed,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                }
                              },
                      )
                    else if (appState.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            if (appState.hasConnectionError) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF271318),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.overlapRed.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.overlapRed, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Unable to load latest data from C# API. Check backend connection.",
                        style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Sync AI Card Block
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF1E293B)),
              ),
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LightningBoltIcon(size: 24, tint: AppColors.accentTeal),
                      SizedBox(width: 8),
                      Text("Sync AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    appState.latestRecommendation != null
                        ? (appState.latestRecommendation!['reasoning']?.toString() ?? '')
                        : appState.isLoggedIn
                            ? "There are no special training or workout activities today requiring high protein. Keep maintaining your healthy lifestyle routine!"
                            : "Please sign in with Google and sync your calendar to receive smart meal suggestions from AI.",
                    style: TextStyle(fontSize: 12, color: AppColors.textLight.withOpacity(0.85), height: 1.3),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      BadgePill(text: "$taskCount tasks", color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      BadgePill(text: "$workoutCount workouts", color: Color(0xFF22C55E)),
                      SizedBox(width: 8),
                      BadgePill(text: "$mealCount meal plans", color: Color(0xFF10B981)),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 16),

            // Segmented Controller
            Container(
              decoration: BoxDecoration(
                color: appState.isDarkMode ? Color(0xFF0F172A) : Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => ongoingTabSelected = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ongoingTabSelected ? (appState.isDarkMode ? Color(0xFF1E293B) : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "On going",
                          style: TextStyle(
                            color: ongoingTabSelected ? AppColors.textLight : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => ongoingTabSelected = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !ongoingTabSelected ? (appState.isDarkMode ? Color(0xFF1E293B) : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "History",
                          style: TextStyle(
                            color: !ongoingTabSelected ? AppColors.textLight : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Section Title
            Text(
              ongoingTabSelected ? "Today’s timeline" : "Yesterday’s timeline",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textLight),
            ),
            SizedBox(height: 16),

            // Timeline Flow List
            if (timelineItems.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    ongoingTabSelected ? "No activities scheduled for today." : "No activities in history.",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ...timelineItems.asMap().entries.map((entry) {
                int index = entry.key;
                TimelineItemData item = entry.value;
                bool isLast = index == timelineItems.length - 1;
                Color dotColor = (index % 2 == 0) ? AppColors.accentTeal : AppColors.primaryBlue;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 84, // Approximate height to match the design
                              color: Color(0xFF1E293B),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: TimelineCardItem(item: item)),
                  ],
                );
              }),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class TimelineItemData {
  final String title;
  final String description;
  final String time;
  final Widget icon;
  final bool isInProgress;
  final bool isCompleted;

  TimelineItemData({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isInProgress,
    required this.isCompleted,
  });
}

class BadgePill extends StatelessWidget {
  final String text;
  final Color color;
  BadgePill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: Colors.white, 
          fontSize: 11, 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }
}

class TimelineCardItem extends StatelessWidget {
  final TimelineItemData item;
  TimelineCardItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    bool isAiSuggestion = item.title.toLowerCase() == "ai suggestion";

    // Dynamic colors for the ongoing schedule item depending on theme mode
    final Color cardBorderColor = item.isInProgress
        ? (AppColors.isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
        : (isAiSuggestion
            ? const Color(0xFF2563EB).withOpacity(0.6)
            : const Color(0xFF1E293B));

    final Color titleColor = item.isInProgress
        ? (AppColors.isDark ? Colors.white : const Color(0xFF065F46))
        : (isAiSuggestion ? AppColors.primaryBlue : AppColors.textLight);

    final Color descColor = item.isInProgress
        ? (AppColors.isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857))
        : AppColors.textMuted;

    final Color timeColor = item.isInProgress
        ? (AppColors.isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : AppColors.textMuted;

    final Color badgeBgColor = AppColors.isDark
        ? const Color(0xFF34D399).withOpacity(0.2)
        : const Color(0xFF10B981).withOpacity(0.15);

    final Color badgeBorderColor = AppColors.isDark
        ? const Color(0xFF34D399).withOpacity(0.5)
        : const Color(0xFF10B981).withOpacity(0.4);

    final Color badgeContentColor = AppColors.isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: item.isInProgress
            ? LinearGradient(
                colors: AppColors.isDark
                    ? [
                        const Color(0xFF064E3B), // Emerald/Green hue
                        const Color(0xFF022C22), // Deep dark emerald
                      ]
                    : [
                        const Color(0xFFE6FDF4), // Very soft mint
                        const Color(0xFFD1FAE5), // Soft mint green
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: item.isInProgress
            ? null
            : isAiSuggestion
                ? const Color(0xFF14243C)
                : AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: item.isInProgress ? 2.0 : 1.0,
        ),
        boxShadow: item.isInProgress
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isInProgress) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: badgeContentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "NOW",
                    style: TextStyle(
                      color: badgeContentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              item.icon,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: descColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.time,
                style: TextStyle(
                  color: timeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension IntExtension on int {
  double get dp => toDouble();
}
