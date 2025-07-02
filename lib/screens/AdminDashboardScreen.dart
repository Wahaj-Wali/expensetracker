import 'package:ExpenseTracker/Services/AdminService.dart';
import 'package:ExpenseTracker/screens/CategoriesPage.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ExpenseTracker/Services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final AdminStatsService _adminStatsService = AdminStatsService();
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _adminStatsService.getDashboardData();
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showUserDetails(String userType) {
    final totalUsers = dashboardData['totalUsers'] ?? 0;
    final activeUsers = dashboardData['activeUsers'] ?? 0;
    final userTypesDistribution =
        dashboardData['userTypesDistribution'] as Map<String, int>? ?? {};
    final platformUsageStats =
        dashboardData['platformUsageStats'] as Map<String, int>? ?? {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$userType Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userType == 'Total Users') ...[
                  Text('Total Users: $totalUsers'),
                  const SizedBox(height: 16),
                  const Text('User Types:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...userTypesDistribution.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      )),
                  const SizedBox(height: 16),
                  const Text('Platform Usage:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...platformUsageStats.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      )),
                ] else if (userType == 'Active Users') ...[
                  Text('Active Users (Last 30 days): $activeUsers'),
                  const SizedBox(height: 16),
                  Text(
                      'Activity Rate: ${totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1) : 0}%'),
                  const SizedBox(height: 8),
                  Text('Inactive Users: ${totalUsers - activeUsers}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match Transactionpage
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: const Color.fromRGBO(127, 61, 255, 1),
          tabs: const [
            Tab(text: 'Statistics'),
            Tab(text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Statistics Tab
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsOverview(),
                        const SizedBox(height: 24),
                        _buildChartsSection(),
                        const SizedBox(height: 24),
                        _buildTopUsersSection(),
                        const SizedBox(height: 24),
                        _buildSalesTaxSection(),
                      ],
                    ),
                  ),
                ),
          // Categories Tab
          const CategoriesPage(),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Match Transactionpage
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showUserDetails('Total Users'),
                child: _buildStatCard(
                  title: 'Total Users',
                  value: '${dashboardData['totalUsers'] ?? 0}',
                  icon: Icons.people,
                  color: const Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _showUserDetails('Active Users'),
                child: _buildStatCard(
                  title: 'Active Users',
                  value: '${dashboardData['activeUsers'] ?? 0}',
                  icon: Icons.people_alt,
                  color: const Color.fromRGBO(0, 168, 107, 1),
                ),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildCategorySalesTaxChart(),
        const SizedBox(height: 24),
        _buildMonthlyTrendsChart(),
        const SizedBox(height: 24),
        _buildAccountTypesChart(),
      ],
    );
  }

  Widget _buildCategorySalesTaxChart() {
    final salesTaxStats =
        dashboardData['salesTaxStats'] as Map<String, dynamic>? ?? {};
    final categoryTaxes =
        salesTaxStats['categoryTaxes'] as Map<String, double>? ?? {};

    if (categoryTaxes.isEmpty) {
      return _buildEmptyChart('No sales tax data available');
    }

    // Get top 8 categories by tax
    final sortedCategories = categoryTaxes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(8).toList();

    // Use pastel colors for the pie chart
    final colors = [
      const Color(0xFFB5B9FF), // pastel blue
      const Color(0xFFFFB5E2), // pastel pink
      const Color(0xFFB5FFD9), // pastel green
      const Color(0xFFFFF5B5), // pastel yellow
      const Color(0xFFFFD6B5), // pastel orange
      const Color(0xFFFFB5B5), // pastel red
      const Color(0xFFCBB5FF), // pastel purple
      const Color(0xFFB5FFF6), // pastel teal
    ];

    final totalTax = categoryTaxes.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category-wise Sales Tax Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: category.value,
                    title: totalTax > 0
                        ? '${((category.value / totalTax) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.key,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsChart() {
    final monthlyTrends =
        dashboardData['monthlyTrends'] as List<Map<String, dynamic>>? ?? [];

    if (monthlyTrends.isEmpty) {
      return _buildEmptyChart('No monthly trends data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Transaction Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: null,
                  verticalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black87),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyTrends.length) {
                          final month = monthlyTrends[index]['month'];
                          return Text(
                            month.split('-')[1],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black87),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: monthlyTrends.length > 1
                    ? (monthlyTrends.length - 1).toDouble()
                    : 1,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value['expense'].toDouble());
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color.fromRGBO(253, 60, 74, 1),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: const Color.fromRGBO(253, 60, 74, 1),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color.fromRGBO(253, 60, 74, 0.3),
                          const Color.fromRGBO(253, 60, 74, 0.05),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: monthlyTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value['income'].toDouble());
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color.fromRGBO(0, 168, 107, 1),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: const Color.fromRGBO(0, 168, 107, 1),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color.fromRGBO(0, 168, 107, 0.3),
                          const Color.fromRGBO(0, 168, 107, 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(253, 60, 74, 1),
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 8),
              const Text('Expenses', style: TextStyle(color: Colors.black87)),
              const SizedBox(width: 24),
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 168, 107, 1),
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 8),
              const Text('Income', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypesChart() {
    final accountTypes =
        dashboardData['accountTypesDistribution'] as Map<String, int>? ?? {};

    if (accountTypes.isEmpty) {
      return _buildEmptyChart('No account types data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Types Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: accountTypes.values
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() *
                    1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final types = accountTypes.keys.toList();
                        if (index >= 0 && index < types.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              types[index],
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups:
                    accountTypes.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: type.value.toDouble(),
                        color: const Color.fromRGBO(127, 61, 255, 1),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersSection() {
    final topUsers =
        dashboardData['topSpendingUsers'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Spending Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (topUsers.isEmpty)
            const Center(
              child: Text(
                'No user data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topUsers.length,
              itemBuilder: (context, index) {
                final user = topUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color.fromRGBO(127, 61, 255, 1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user['email'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      trailing: Text(
                        'PKR ${_formatAmount(user['totalExpense'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(253, 60, 74, 1),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSalesTaxSection() {
    final salesTaxStats =
        dashboardData['salesTaxStats'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Tax Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTaxStatCard(
                  title: 'Total Taxable Amount',
                  value:
                      'PKR ${_formatAmount(salesTaxStats['totalTaxableAmount'] ?? 0.0)}',
                  color: const Color.fromRGBO(127, 61, 255, 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTaxStatCard(
                  title: 'Total Tax Amount',
                  value:
                      'PKR ${_formatAmount(salesTaxStats['totalTaxAmount'] ?? 0.0)}',
                  color: const Color.fromRGBO(253, 60, 74, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Category-wise Tax Breakdown',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 8),
          ...((salesTaxStats['categoryTaxes'] as Map<String, double>? ?? {}))
              .entries
              .take(5)
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(color: Colors.black87)),
                        Text(
                          'PKR ${_formatAmount(entry.value)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTaxStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
