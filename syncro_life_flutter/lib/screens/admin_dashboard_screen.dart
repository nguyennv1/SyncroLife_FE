import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/custom_icons.dart';
import '../models/app_state.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedSubscriptionFilter = 'All';

  // Account registration form controllers
  final TextEditingController _usernameRegController = TextEditingController();
  final TextEditingController _passwordRegController = TextEditingController();
  final TextEditingController _confirmPasswordRegController = TextEditingController();
  bool _isRegistering = false;
  String? _regErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadAdminData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usernameRegController.dispose();
    _passwordRegController.dispose();
    _confirmPasswordRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;

    // Filter users list based on query and filters
    final List<dynamic> allUsers = appState.adminUsers.isNotEmpty
        ? appState.adminUsers
        : _getMockUsers(); // fallback to rich mock data if empty

    final filteredUsers = allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final fullName = (user['fullName'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? user['roleName'] ?? 'Customer').toString().toLowerCase();
      final plan = (user['subscriptionPlan'] ?? 'Free').toString().toLowerCase();

      final matchesQuery = username.contains(_searchQuery.toLowerCase()) ||
          fullName.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRoleFilter == 'All' ||
          role == _selectedRoleFilter.toLowerCase();

      final matchesSub = _selectedSubscriptionFilter == 'All' ||
          plan == _selectedSubscriptionFilter.toLowerCase();

      return matchesQuery && matchesRole && matchesSub;
    }).toList();

    // Stats calculations
    final totalUsers = allUsers.length;
    final adminsCount = allUsers.where((u) => (u['role'] ?? u['roleName'] ?? 'Customer').toString().toLowerCase() == 'admin').length;
    final customersCount = totalUsers - adminsCount;
    
    final premiumUsers = allUsers.where((u) {
      final plan = (u['subscriptionPlan'] ?? 'Free').toString().toLowerCase();
      return plan != 'free';
    }).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.cardDark,
          elevation: 0,
          title: Row(
            children: [
              const LightningBoltIcon(size: 24, tint: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                "Admin Console",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: AppColors.textLight,
              ),
              onPressed: () {
                appState.toggleTheme();
              },
              tooltip: 'Toggle Theme',
            ),
            // Logout Button
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.overlapRed),
              onPressed: () => _showLogoutDialog(context, appState),
              tooltip: 'Log Out',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Overview", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Revenue", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Accounts", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            indicatorColor: AppColors.primaryBlue,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textMuted,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await appState.loadAdminData();
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.cardDark,
          child: TabBarView(
            children: [
              // Tab 1: Overview
              _buildOverviewTab(
                context: context,
                appState: appState,
                filteredUsers: filteredUsers,
                totalUsers: totalUsers,
                adminsCount: adminsCount,
                customersCount: customersCount,
                premiumUsers: premiumUsers,
                allUsers: allUsers,
              ),
              // Tab 2: Revenue
              _buildRevenueTab(context, appState),
              // Tab 3: Accounts (Admin-only Register)
              _buildAccountsTab(context, appState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab({
    required BuildContext context,
    required AppState appState,
    required List<dynamic> filteredUsers,
    required int totalUsers,
    required int adminsCount,
    required int customersCount,
    required int premiumUsers,
    required List<dynamic> allUsers,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome header
          Text(
            "System Overview",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Real-time monitoring and subscription management",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Stat Cards Grid
          _buildStatsGrid(
            total: totalUsers,
            admins: adminsCount,
            customers: customersCount,
            premium: premiumUsers,
          ),
          const SizedBox(height: 24),

          // Subscription breakdown and charts section
          _buildSubscriptionChartSection(allUsers),
          const SizedBox(height: 24),

          // Users list header and filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "User Accounts (${filteredUsers.length})",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildFilterChips(),
            ],
          ),
          const SizedBox(height: 12),

          // Search field
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search by username, full name, email...",
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              fillColor: AppColors.cardDark,
              filled: true,
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // User List or Loading Shimmer
          appState.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                )
              : filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserListItem(context, user);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab(BuildContext context, AppState appState) {
    final revenue = appState.adminRevenue ?? {};
    final double todayRev = (revenue['today'] ?? 0.0).toDouble();
    final double monthRev = (revenue['month'] ?? 0.0).toDouble();
    final double yearRev = (revenue['year'] ?? 0.0).toDouble();
    final List<dynamic> dailyList = revenue['daily'] ?? [];
    final List<dynamic> monthlyList = revenue['monthly'] ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Text(
            "Revenue Statistics",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Real-time payment reports and system revenues",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Revenue Stat Cards Grid
          _buildRevenueGrid(todayRev, monthRev, yearRev),
          const SizedBox(height: 28),

          // Monthly breakdown chart section
          _buildMonthlyRevenueChartSection(monthlyList),
          const SizedBox(height: 24),

          // Daily breakdown section
          Text(
            "Daily Revenue (Last 30 Days)",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          appState.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                )
              : dailyList.isEmpty
                  ? _buildEmptyRevenueState()
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dailyList.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B), height: 1),
                        itemBuilder: (context, index) {
                          // reverse order to show newest date first
                          final item = dailyList[dailyList.length - 1 - index];
                          final dateStr = item['date']?.toString() ?? 'N/A';
                          final double amount = (item['amount'] ?? 0.0).toDouble();
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 18),
                            ),
                            title: Text(
                              dateStr,
                              style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            trailing: Text(
                              _formatRevenue(amount),
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildRevenueGrid(double today, double month, double year) {
    return Column(
      children: [
        _buildLargeRevenueCard(
          title: "TODAY'S REVENUE",
          value: _formatRevenue(today),
          icon: Icons.today,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallRevenueCard(
                title: "THIS MONTH",
                value: _formatRevenue(month),
                icon: Icons.calendar_month,
                gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallRevenueCard(
                title: "THIS YEAR",
                value: _formatRevenue(year),
                icon: Icons.star,
                gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildLargeRevenueCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          )
        ],
      ),
    );
  }

  Widget _buildSmallRevenueCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueChartSection(List<dynamic> monthlyList) {
    double maxAmt = 1.0;
    for (var m in monthlyList) {
      double amt = (m['amount'] ?? 0.0).toDouble();
      if (amt > maxAmt) maxAmt = amt;
    }

    final List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Revenue (Current Year)",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (monthlyList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text("No records for this year", style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
            )
          else
            ...monthlyList.map((m) {
              int monthIdx = (m['month'] ?? 1) - 1;
              String mName = monthIdx >= 0 && monthIdx < 12 ? monthNames[monthIdx] : "Month";
              double amt = (m['amount'] ?? 0.0).toDouble();
              double progress = maxAmt > 0 ? amt / maxAmt : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(mName, style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_formatRevenue(amt), style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyRevenueState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Icon(Icons.monetization_on_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            "No revenue data recorded",
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatRevenue(double amount) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) matchFunc = (Match match) => '${match[1]},';
    return '${amount.toInt().toString().replaceAllMapped(reg, matchFunc)}₫';
  }

  Widget _buildStatsGrid({
    required int total,
    required int admins,
    required int customers,
    required int premium,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Total Users",
                value: total.toString(),
                icon: Icons.people,
                gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Plus Active",
                value: premium.toString(),
                icon: Icons.card_membership,
                gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Admins",
                value: admins.toString(),
                icon: Icons.admin_panel_settings,
                gradientColors: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Customers",
                value: customers.toString(),
                icon: Icons.person_outline,
                gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionChartSection(List<dynamic> users) {
    // Plan distribution calculation
    final planCounts = <String, int>{'Free': 0, 'Plus': 0};
    for (var u in users) {
      final plan = (u['subscriptionPlan'] ?? u['subscriptionType'] ?? 'Free').toString();
      final cleanPlan = plan.toLowerCase().contains('plus') ? 'Plus' : 'Free';
      planCounts[cleanPlan] = (planCounts[cleanPlan] ?? 0) + 1;
    }

    final total = users.isEmpty ? 1 : users.length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subscription Plan Shares",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Chart bar representation
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: planCounts.entries.map((entry) {
                  final pct = (entry.value / total);
                  if (pct == 0) return const SizedBox.shrink();
                  Color color = entry.key.toLowerCase().contains('free')
                      ? AppColors.textMuted.withOpacity(0.5)
                      : AppColors.primaryBlue;
                  return Expanded(
                    flex: (pct * 100).round(),
                    child: Tooltip(
                      message: "${entry.key}: ${entry.value}",
                      child: Container(
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: planCounts.entries.map((entry) {
              Color color = entry.key.toLowerCase().contains('free')
                  ? AppColors.textMuted.withOpacity(0.5)
                  : AppColors.primaryBlue;
              final pct = (entry.value / total * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${entry.key} ($pct%)",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.tune, color: AppColors.textLight),
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() {
          if (value.startsWith('role:')) {
            _selectedRoleFilter = value.split(':')[1];
          } else if (value.startsWith('sub:')) {
            _selectedSubscriptionFilter = value.split(':')[1];
          } else if (value == 'reset') {
            _selectedRoleFilter = 'All';
            _selectedSubscriptionFilter = 'All';
          }
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text("Filter by Role", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'role:All',
          child: Row(
            children: [
              Icon(_selectedRoleFilter == 'All' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("All Roles"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'role:Admin',
          child: Row(
            children: [
              Icon(_selectedRoleFilter == 'Admin' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("Admins"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'role:Customer',
          child: Row(
            children: [
              Icon(_selectedRoleFilter == 'Customer' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("Customers"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Text("Filter by Plan", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'sub:All',
          child: Row(
            children: [
              Icon(_selectedSubscriptionFilter == 'All' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("All Plans"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sub:Free',
          child: Row(
            children: [
              Icon(_selectedSubscriptionFilter == 'Free' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("Free Plan"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sub:Plus',
          child: Row(
            children: [
              Icon(_selectedSubscriptionFilter == 'Plus' ? Icons.check_circle : Icons.circle_outlined, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Text("Plus Plan"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'reset',
          child: Text("Reset All Filters", style: TextStyle(color: AppColors.overlapRed)),
        ),
      ],
    );
  }

  Widget _buildUserListItem(BuildContext context, Map<String, dynamic> user) {
    final username = (user['username'] ?? '').toString();
    final fullName = (user['fullName'] ?? user['name'] ?? 'No Name').toString();
    final email = (user['email'] ?? 'No Email').toString();
    final role = (user['role'] ?? user['roleName'] ?? 'Customer').toString();
    final plan = (user['subscriptionPlan'] ?? user['subscriptionType'] ?? 'Free').toString();
    final bool isDeleted = user['isDeleted'] == true;
    final gender = (user['gender'] ?? 'N/A').toString();

    final isAdmin = role.toLowerCase() == 'admin';

    // Initials for avatar
    String initials = '';
    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      if (parts.isNotEmpty) {
        initials += parts[0][0].toUpperCase();
        if (parts.length > 1 && parts[parts.length - 1].isNotEmpty) {
          initials += parts[parts.length - 1][0].toUpperCase();
        }
      }
    }
    if (initials.isEmpty) {
      initials = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDeleted
              ? AppColors.overlapRed.withOpacity(0.3)
              : AppColors.isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? AppColors.primaryBlue.withOpacity(0.2)
              : AppColors.accentTeal.withOpacity(0.2),
          child: Text(
            initials,
            style: TextStyle(
              color: isAdmin ? AppColors.primaryBlue : AppColors.accentTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Role Badge
            _buildBadge(
              label: role,
              color: isAdmin ? AppColors.primaryBlue : AppColors.accentTeal,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "@$username | $email",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!isAdmin) ...[
                  _buildBadge(
                    label: plan.toLowerCase().contains('plus') ? 'Plus' : 'Free',
                    color: plan.toLowerCase().contains('plus') ? AppColors.primaryBlue : AppColors.textMuted,
                    filled: false,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  "Gender: $gender",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                if (isDeleted) ...[
                  const SizedBox(width: 8),
                  _buildBadge(
                    label: "DELETED",
                    color: AppColors.overlapRed,
                    filled: true,
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _showUserDetailsSheet(context, user),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color, bool filled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : Colors.transparent,
        border: filled ? null : Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            "No users found matching filters",
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final plan = (user['subscriptionPlan'] ?? 'Free').toString();
        final gender = (user['gender'] ?? 'N/A').toString();
        final dob = (user['dateOfBirth'] ?? user['dob'] ?? 'N/A').toString();
        final formattedDob = dob.contains('T') ? dob.split('T')[0] : dob;
        final role = (user['role'] ?? user['roleName'] ?? 'Customer').toString();
        final bool isAdmin = role.toLowerCase() == 'admin';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user['fullName'] ?? 'User Details',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "@${user['username'] ?? 'username'}",
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildDetailRow("Email", user['email'] ?? 'N/A'),
              _buildDetailRow("Role", (user['role'] ?? user['roleName'] ?? 'Customer').toString()),
              if (!isAdmin) _buildDetailRow("Subscription Plan", plan.toLowerCase().contains('plus') ? 'Plus' : 'Free'),
              _buildDetailRow("Gender", gender),
              _buildDetailRow("Date of Birth", formattedDob),
              _buildDetailRow("Account Status", user['isDeleted'] == true ? "Deleted" : "Active"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          Text(value, style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Log Out", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to log out from Admin Console?", style: TextStyle(color: AppColors.textMuted)),
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
            child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockUsers() {
    return [
      {
        'userId': '1',
        'username': 'admin',
        'fullName': 'System Administrator',
        'email': 'admin@syncrolife.com',
        'gender': 'Male',
        'dateOfBirth': '1990-01-01',
        'role': 'Admin',
        'subscriptionPlan': 'Free',
        'isDeleted': false
      },
      {
        'userId': '2',
        'username': 'johndoe',
        'fullName': 'John Doe',
        'email': 'john@gmail.com',
        'gender': 'Male',
        'dateOfBirth': '1995-05-15',
        'role': 'Customer',
        'subscriptionPlan': 'Plus',
        'isDeleted': false
      },
      {
        'userId': '3',
        'username': 'janesmith',
        'fullName': 'Jane Smith',
        'email': 'jane.smith@outlook.com',
        'gender': 'Female',
        'dateOfBirth': '1998-08-22',
        'role': 'Customer',
        'subscriptionPlan': 'Plus',
        'isDeleted': false
      },
      {
        'userId': '4',
        'username': 'bobmiller',
        'fullName': 'Bob Miller',
        'email': 'bob.miller@yahoo.com',
        'gender': 'Male',
        'dateOfBirth': '1987-11-30',
        'role': 'Customer',
        'subscriptionPlan': 'Free',
        'isDeleted': false
      },
      {
        'userId': '5',
        'username': 'alice_w',
        'fullName': 'Alice Wonder',
        'email': 'alice@gmail.com',
        'gender': 'Female',
        'dateOfBirth': '1993-02-14',
        'role': 'Customer',
        'subscriptionPlan': 'Plus',
        'isDeleted': true
      }
    ];
  }

  Widget _buildAccountsTab(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            "Account Management",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Register new system accounts under administrator privileges",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Registration Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter credentials to register a new user in the system.",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),

                if (_regErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _regErrorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Username field
                Text(
                  "Username",
                  style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameRegController,
                  style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "e.g., johndoe (no spaces)",
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    fillColor: AppColors.backgroundDark,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                Text(
                  "Password",
                  style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordRegController,
                  obscureText: true,
                  style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Minimum 8 characters, no spaces",
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    fillColor: AppColors.backgroundDark,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password field
                Text(
                  "Confirm Password",
                  style: TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordRegController,
                  obscureText: true,
                  style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Confirm password",
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    fillColor: AppColors.backgroundDark,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isRegistering ? null : () => _handleRegister(appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Register Account",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister(AppState appState) async {
    final username = _usernameRegController.text.trim();
    final password = _passwordRegController.text;
    final confirmPassword = _confirmPasswordRegController.text;

    setState(() {
      _regErrorMessage = null;
    });

    if (username.isEmpty) {
      setState(() {
        _regErrorMessage = "Username cannot be empty.";
      });
      return;
    }
    if (username.contains(" ")) {
      setState(() {
        _regErrorMessage = "Username cannot contain spaces.";
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _regErrorMessage = "Password cannot be empty.";
      });
      return;
    }
    if (password.contains(" ")) {
      setState(() {
        _regErrorMessage = "Password cannot contain spaces.";
      });
      return;
    }
    if (password.length < 8) {
      setState(() {
        _regErrorMessage = "Password must be at least 8 characters long.";
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _regErrorMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await appState.registerUser(username, password, confirmPassword);
      // Clear form
      _usernameRegController.clear();
      _passwordRegController.clear();
      _confirmPasswordRegController.clear();
      
      // Reload users list
      await appState.loadAdminData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account registered successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _regErrorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
}
