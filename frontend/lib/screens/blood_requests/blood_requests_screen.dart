import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/blood_request.dart';
import '../../providers/blood_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'blood_request_detail_screen.dart';
import 'create_blood_request_screen.dart';

class BloodRequestsScreen extends StatefulWidget {
  const BloodRequestsScreen({super.key});

  @override
  State<BloodRequestsScreen> createState() => _BloodRequestsScreenState();
}

class _BloodRequestsScreenState extends State<BloodRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BloodRequestProvider>();
      provider.loadAll();
      provider.loadMine();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Requests'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateBloodRequestScreen()),
          );
          if (created == true && mounted) {
            context.read<BloodRequestProvider>().loadAll();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RequestsList(mine: false),
          _RequestsList(mine: true),
        ],
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final bool mine;
  const _RequestsList({required this.mine});

  @override
  Widget build(BuildContext context) {
    return Consumer<BloodRequestProvider>(
      builder: (context, provider, _) {
        final isLoading = mine ? provider.isLoadingMine : provider.isLoadingAll;
        final list = mine ? provider.myRequests : provider.allRequests;

        if (isLoading && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!mine && provider.error != null && list.isEmpty) {
          return ErrorRetry(
            message: provider.error!,
            onRetry: () => provider.loadAll(),
          );
        }

        if (list.isEmpty) {
          return EmptyState(
            icon: mine ? Icons.assignment_outlined : Icons.water_drop_outlined,
            title: mine ? 'No requests yet' : 'No blood requests right now',
            subtitle: mine
                ? 'Requests you create will show up here.'
                : 'Check back soon or pull to refresh.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => mine ? provider.loadMine() : provider.loadAll(),
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _RequestCard(request: list[i]),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BloodRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(request.requiredTime);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BloodRequestDetailScreen(requestId: request.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BloodDrop(size: 46, label: request.bloodGroup),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text('${request.units} unit(s) • ${request.cause}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TypeBadge(type: request.requestType),
                      const SizedBox(height: 6),
                      StatusBadge(status: request.status),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(request.locationDetail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
