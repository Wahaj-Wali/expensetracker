import 'package:ExpenseTracker/Services/AdminService.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminStatsService _adminStatsService = AdminStatsService();
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Overview Cards
                    _buildStatsOverview(),
                    const SizedBox(height: 24),

                    // Charts Section
                    _buildChartsSection(),
                    const SizedBox(height: 24),

                    // Top Users Section
                    _buildTopUsersSection(),
                    const SizedBox(height: 24),

                    // Sales Tax Section
                    _buildSalesTaxSection(),
                    const SizedBox(height: 24),

                    // User Registration Trends
                    _buildRegistrationTrendsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildStatCard(
              title: 'Total Users',
              value: '${dashboardData['totalUsers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Active Users',
              value: '${dashboardData['activeUsers'] ?? 0}',
              icon: Icons.people_alt,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Total Transactions',
              value: '${dashboardData['totalTransactions'] ?? 0}',
              icon: Icons.receipt_long,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Total Expenses',
              value:
                  'PKR ${_formatAmount(dashboardData['totalExpenses'] ?? 0.0)}',
              icon: Icons.arrow_downward,
              color: Colors.red,
            ),
            _buildStatCard(
              title: 'Total Income',
              value:
                  'PKR ${_formatAmount(dashboardData['totalIncome'] ?? 0.0)}',
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Net Balance',
              value:
                  'PKR ${_formatAmount((dashboardData['totalIncome'] ?? 0.0) - (dashboardData['totalExpenses'] ?? 0.0))}',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Category Expenses Pie Chart
        _buildCategoryExpensesChart(),
        const SizedBox(height: 24),

        // Monthly Trends Line Chart
        _buildMonthlyTrendsChart(),
        const SizedBox(height: 24),

        // Account Types Distribution
        _buildAccountTypesChart(),
      ],
    );
  }

  Widget _buildCategoryExpensesChart() {
    final categoryExpenses =
        dashboardData['categoryExpenses'] as Map<String, double>? ?? {};

    if (categoryExpenses.isEmpty) {
      return _buildEmptyChart('No category data available');
    }

    // Get top 8 categories
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category-wise Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final colors = [
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.indigo,
                  ];

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: category.value,
                    title:
                        '${((category.value / categoryExpenses.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
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
              final colors = [
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[index % colors.length],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.key,
                    style: const TextStyle(fontSize: 12),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Transaction Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(fontSize: 10),
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
                            style: const TextStyle(fontSize: 10),
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
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value['expense'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: monthlyTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value['income'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Expenses'),
              const SizedBox(width: 24),
              Container(width: 12, height: 12, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Income'),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Types Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
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
                              style: const TextStyle(fontSize: 10),
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
                        color: Colors.indigo,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Spending Users',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user['email'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    'PKR ${_formatAmount(user['totalExpense'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Tax Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTaxStatCard(
                  title: 'Total Taxable Amount',
                  value:
                      'PKR ${_formatAmount(salesTaxStats['totalTaxableAmount'] ?? 0.0)}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTaxStatCard(
                  title: 'Total Tax Amount',
                  value:
                      'PKR ${_formatAmount(salesTaxStats['totalTaxAmount'] ?? 0.0)}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaxStatCard(
            title: 'Average Tax Rate',
            value:
                '${(salesTaxStats['averageTaxRate'] ?? 0.0).toStringAsFixed(2)}%',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            'Category-wise Tax Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                        Text(entry.key),
                        Text(
                          'PKR ${_formatAmount(entry.value)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildRegistrationTrendsSection() {
    final registrationTrends =
        dashboardData['registrationTrends'] as List<Map<String, dynamic>>? ??
            [];

    if (registrationTrends.isEmpty) {
      return _buildEmptyChart('No registration trends data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Registration Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: registrationTrends
                        .map((e) => e['registrations'] as int)
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
                        if (index >= 0 && index < registrationTrends.length) {
                          final month = registrationTrends[index]['month'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              month.split('-')[1],
                              style: const TextStyle(fontSize: 10),
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
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: registrationTrends.asMap().entries.map((entry) {
                  final index = entry.key;
                  final trend = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: trend['registrations'].toDouble(),
                        color: Colors.teal,
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

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
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
