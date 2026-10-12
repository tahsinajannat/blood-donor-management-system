import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/donor_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_thread_screen.dart';

const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key});

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonorProvider>().search();
    });
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DonorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Find Donors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _GroupChip(
                        label: 'All',
                        selected: provider.bloodGroup == null,
                        onTap: () {
                          provider.setBloodGroup(null);
                          provider.search();
                        },
                      ),
                      ..._bloodGroups.map((g) => _GroupChip(
                            label: g,
                            selected: provider.bloodGroup == g,
                            onTap: () {
                              provider.setBloodGroup(g);
                              provider.search();
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Area',
                          prefixIcon: Icon(Icons.map_outlined, size: 20),
                          isDense: true,
                        ),
                        onChanged: (v) => provider.area = v,
                        onSubmitted: (_) => provider.search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          hintText: 'City',
                          prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                          isDense: true,
                        ),
                        onChanged: (v) => provider.city = v,
                        onSubmitted: (_) => provider.search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () => provider.search(),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildList(DonorProvider provider) {
    if (provider.isLoading && provider.donors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.donors.isEmpty) {
      return ErrorRetry(message: provider.error!, onRetry: () => provider.search());
    }
    if (provider.donors.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_rounded,
        title: 'No donors found',
        subtitle: 'Try a different blood group, area or city.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.search(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: provider.donors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DonorCard(donor: provider.donors[i]),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GroupChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final AppUser donor;
  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().currentUser?.id;
    final isMe = myId == donor.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            BloodDrop(size: 50, label: donor.bloodGroup),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(donor.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      if (donor.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [donor.area, donor.city].where((e) => e != null && e.isNotEmpty).join(', ').isEmpty
                        ? 'Location not set'
                        : [donor.area, donor.city].where((e) => e != null && e.isNotEmpty).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isMe)
              IconButton(
                onPressed: () async {
                  try {
                    final convId =
                        await context.read<ChatProvider>().openConversationWith(donor.id);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatThreadScreen(
                            conversationId: convId,
                            otherUserName: donor.fullName,
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not start conversation.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
