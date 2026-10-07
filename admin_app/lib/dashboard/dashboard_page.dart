import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../auth/auth_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.isOwner = false,
  });

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isOwner ? 'لوحة تحكم المالك' : 'لوحة الإدارة',
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await AuthService.signOut();

                if (!context.mounted) return;

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _welcomeCard(),
            const SizedBox(height: 16),
            _sectionTitle('الإحصائيات'),
            const SizedBox(height: 10),
            _statsGrid(),
            const SizedBox(height: 24),
            _sectionTitle('الأقسام الرئيسية'),
            const SizedBox(height: 10),
            _sectionsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحبًا بك في مدى باي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لوحة التحكم الإدارية',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      (
        'المستخدمون',
        Icons.people_alt_outlined,
        AppColors.info,
      ),
      (
        'المعاملات',
        Icons.receipt_long_outlined,
        AppColors.primary,
      ),
      (
        'المحافظ',
        Icons.account_balance_wallet_outlined,
        AppColors.secondary,
      ),
      (
        'الخدمات',
        Icons.apps_outlined,
        AppColors.success,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.$2,
                  size: 30,
                  color: item.$3,
                ),
                const SizedBox(height: 8),
                Text(
                  item.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionsGrid() {
    final sections = [
      ('المستخدمون', Icons.people_outline),
      ('الخدمات والأسعار', Icons.apps_outlined),
      ('بوابات API', Icons.api_outlined),
      ('المحافظ', Icons.account_balance_wallet_outlined),
      ('المعاملات', Icons.swap_horiz_rounded),
      ('التقارير', Icons.bar_chart_outlined),
      ('القسائم والسندات', Icons.description_outlined),
      ('الموظفون والصلاحيات', Icons.admin_panel_settings_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final section = sections[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'قسم ${section.$1} سيتم تجهيزه في الخطوة القادمة.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    section.$2,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'مدى باي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لوحة الإدارة',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const
