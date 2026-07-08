import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/app_state.dart';

class SyncScreen extends StatefulWidget {
  SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  late DateTime _focusedDate;
  late DateTime _today;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDate = _today;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final appState = Provider.of<AppState>(context, listen: false);
      // Center the calendar on the app's selected date (which defaults to today)
      _focusedDate = appState.selectedSyncDate;
      _initialized = true;
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    // weekday is 1 for Monday, 7 for Sunday.
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<Map<String, dynamic>> _getCalendarDays() {
    final monday = _getStartOfWeek(_focusedDate);
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return {
        'weekday': weekdays[index],
        'label': date.day.toString(),
        'date': date,
      };
    });
  }

  String _getMonthLabel() {
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${months[_focusedDate.month - 1]} ${_focusedDate.year}";
  }

  // 6 months is approximately 180 days
  bool get _canGoBack {
    final prevWeekDate = _focusedDate.subtract(Duration(days: 7));
    final difference = prevWeekDate.difference(_today).inDays;
    return difference >= -180;
  }

  bool get _canGoForward {
    final nextWeekDate = _focusedDate.add(Duration(days: 7));
    final difference = nextWeekDate.difference(_today).inDays;
    return difference <= 180;
  }

  void _goToPreviousWeek(AppState appState) {
    if (!_canGoBack) return;
    final currentSelected = appState.selectedSyncDate;
    DateTime newSelected;
    if (currentSelected.weekday == DateTime.monday) {
      newSelected = currentSelected.subtract(Duration(days: 1));
    } else {
      newSelected = currentSelected.subtract(Duration(days: 7));
    }
    setState(() {
      _focusedDate = newSelected;
    });
    appState.loadScheduleForDate(newSelected);
  }

  void _goToNextWeek(AppState appState) {
    if (!_canGoForward) return;
    final currentSelected = appState.selectedSyncDate;
    DateTime newSelected;
    if (currentSelected.weekday == DateTime.sunday) {
      newSelected = currentSelected.add(Duration(days: 1));
    } else {
      newSelected = currentSelected.add(Duration(days: 7));
    }
    setState(() {
      _focusedDate = newSelected;
    });
    appState.loadScheduleForDate(newSelected);
  }

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

  Color _getAccentColor(String type, String title, bool isSynced) {
    final upperType = type.toUpperCase();
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('cardio') || lowerTitle.contains('overlap') || lowerTitle.contains('conflict')) {
      return isSynced ? AppColors.accentTeal : AppColors.overlapRed;
    }

    switch (upperType) {
      case 'WORK':
      case 'STUDY':
        return AppColors.accentTeal;
      case 'MEAL':
        return AppColors.primaryBlue;
      case 'GYM':
        return AppColors.darkYellow;
      default:
        return AppColors.darkYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isSynced = appState.isSynced;

    return Container(
      color: AppColors.backgroundDark,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          SizedBox(height: 16),
          
          // Header Title and Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Smart Schedule", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  Text("AI-synced schedule", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

          // Google Calendar Integration Sync Card
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appState.isDarkMode ? Color(0xFF1E293B) : Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.accentTeal, size: 18),
                    SizedBox(width: 12),
                    Text(
                      "Google Calendar",
                      style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                appState.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
                      )
                    : InkWell(
                        onTap: () async {
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
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.sync, color: AppColors.accentTeal, size: 14),
                              SizedBox(width: 6),
                              Text(
                                "Sync",
                                style: TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),

          if (appState.hasConnectionError) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appState.isDarkMode ? Color(0xFF271318) : Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.overlapRed.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.overlapRed, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Unable to load schedules from C# API. Check backend connection.",
                      style: TextStyle(color: appState.isDarkMode ? AppColors.textLight : AppColors.overlapRed, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Calendar Week Selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: appState.isDarkMode ? Color(0xFF1E293B) : Color(0xFFE2E8F0)),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _canGoBack ? () => _goToPreviousWeek(appState) : null,
                      icon: Icon(
                        Icons.keyboard_arrow_left,
                        color: _canGoBack ? AppColors.textLight : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    Text(
                      _getMonthLabel(),
                      style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      onPressed: _canGoForward ? () => _goToNextWeek(appState) : null,
                      icon: Icon(
                        Icons.keyboard_arrow_right,
                        color: _canGoForward ? AppColors.textLight : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _getCalendarDays().map((dayData) {
                    final dayDate = dayData['date'] as DateTime;
                    final isSelected = appState.selectedSyncDate.year == dayDate.year &&
                        appState.selectedSyncDate.month == dayDate.month &&
                        appState.selectedSyncDate.day == dayDate.day;

                    return GestureDetector(
                      onTap: () => appState.loadScheduleForDate(dayDate),
                      child: _buildDay(dayData['weekday'], dayData['label'], isSelected),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          SizedBox(height: 16),

          // Warning Overlap Card (Animated Visibility)
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            child: !isSynced
                  ? Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: appState.isDarkMode ? Color(0xFF271318) : Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.overlapRed.withOpacity(0.5)),
                      ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.overlapRed, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                              "Warning: Google Calendar has events that are not loaded in the app. Tap Sync to retrieve them.",
                              style: TextStyle(color: appState.isDarkMode ? AppColors.textLight : AppColors.overlapRed, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ),

          // List of activity cards
          if (appState.isLoading && appState.selectedDateSchedules.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
            )
          else if (appState.selectedDateSchedules.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text("No events scheduled for this day.", style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            Column(
              children: appState.selectedDateSchedules.map((item) {
                final title = item['title']?.toString() ?? 'Activity';
                final desc = item['description']?.toString() ?? '';
                final rawTime = item['time']?.toString() ?? '12:00';
                final type = item['type']?.toString() ?? 'GENERAL';
                
                final startTime = item['startTime']?.toString();
                final endTime = item['endTime']?.toString();

                // Handle Cardio time shift when synced (matches mock behavior)
                String displayTime = _formatTimeRange(startTime, endTime, rawTime);
                if (title.toLowerCase() == "cardio" && isSynced) {
                  displayTime = "3:00 pm to 3:45 pm";
                }

                bool isCompleted = item['isCompleted'] == true;
                bool isCurrent = false;
                bool isFuture = false;

                if (startTime != null) {
                  try {
                    final now = DateTime.now();
                    final start = DateTime.parse(startTime.toString()).toLocal();
                    final end = endTime != null ? DateTime.parse(endTime.toString()).toLocal() : start.add(Duration(hours: 1));
                    
                    if (now.isAfter(end)) {
                      isCompleted = true; // Treats past events as completed/done
                    } else if (now.isAfter(start) && now.isBefore(end)) {
                      isCurrent = true;
                    } else if (now.isBefore(start)) {
                      isFuture = true;
                    }
                  } catch (_) {
                    if (!isCompleted) isFuture = true;
                  }
                } else {
                  if (!isCompleted) isFuture = true;
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: ActivityScheduleCard(
                    title: title,
                    duration: desc,
                    timeLabel: displayTime,
                    accent: _getAccentColor(type, title, isSynced),
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isFuture: isFuture,
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDay(String weekday, String dateLabel, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          Text(weekday, style: TextStyle(color: isSelected ? AppColors.textLight : AppColors.textMuted, fontSize: 11)),
          SizedBox(height: 4),
          Text(dateLabel, style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class SpinningProgressIcon extends StatefulWidget {
  final Color color;
  final double size;
  SpinningProgressIcon({super.key, required this.color, this.size = 20});

  @override
  State<SpinningProgressIcon> createState() => _SpinningProgressIconState();
}

class _SpinningProgressIconState extends State<SpinningProgressIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.autorenew,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}

class ActivityScheduleCard extends StatelessWidget {
  final String title;
  final String duration;
  final String timeLabel;
  final Color accent;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;

  ActivityScheduleCard({
    super.key,
    required this.title,
    required this.duration,
    required this.timeLabel,
    required this.accent,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    // Current schedule card gets a glowing highlight and subtle gradient background
    final cardDecoration = isCurrent
        ? BoxDecoration(
            color: AppColors.cardDark,
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.15),
                AppColors.cardDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 4),
              )
            ],
          )
        : BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.3), width: 1.0),
          );

    // Icon depending on state
    Widget statusIcon;
    if (isCompleted) {
      statusIcon = Icon(Icons.check_circle, color: AppColors.accentTeal, size: 20);
    } else {
      statusIcon = SpinningProgressIcon(
        color: isCurrent ? accent : AppColors.textMuted,
        size: 20,
      );
    }

    return Container(
      padding: EdgeInsets.all(18),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent) ...[
            Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withOpacity(0.5)),
              ),
              child: Text(
                "NOW",
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    statusIcon,
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            duration,
                            style: TextStyle(
                              color: isCurrent ? AppColors.textLight.withOpacity(0.7) : AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                timeLabel,
                style: TextStyle(
                  color: isCurrent ? AppColors.textLight.withOpacity(0.9) : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
