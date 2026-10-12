import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AuthProvider>().refreshProfile(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  Center(
                    child: Column(
                      children: [
                        BloodDrop(size: 84, label: user.bloodGroup),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(user.fullName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            if (user.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: user.isActiveDonor
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.textSecondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            user.isActiveDonor ? 'Active Donor' : 'Inactive Donor',
                            style: TextStyle(
                              color: user.isActiveDonor ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileRow(icon: Icons.call_outlined, label: 'Phone', value: user.phone),
                          const Divider(height: 26),
                          _ProfileRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: [user.area, user.road, user.city]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', ')
                                    .isEmpty
                                ? 'Not set'
                                : [user.area, user.road, user.city]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', '),
                          ),
                          const Divider(height: 26),
                          _ProfileRow(
                            icon: Icons.cake_outlined,
                            label: 'Date of birth',
                            value: user.dateOfBirth ?? 'Not set',
                          ),
                          const Divider(height: 26),
                          _ProfileRow(
                            icon: Icons.history_rounded,
                            label: 'Last donation',
                            value: user.lastDonationDate ?? 'No record',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.critical),
                    label: const Text('Log Out', style: TextStyle(color: AppColors.critical)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
