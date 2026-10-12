import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/blood_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/blood_request_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_thread_screen.dart';

class BloodRequestDetailScreen extends StatefulWidget {
  final int requestId;
  const BloodRequestDetailScreen({super.key, required this.requestId});

  @override
  State<BloodRequestDetailScreen> createState() =>
      _BloodRequestDetailScreenState();
}

class _BloodRequestDetailScreenState extends State<BloodRequestDetailScreen> {
  final _service = BloodRequestService();
  BloodRequest? _request;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = await _service.getById(widget.requestId);
      setState(() => _request = req);
    } catch (_) {
      setState(() => _error = 'Failed to load this request.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _busy = true);
    try {
      await context
          .read<BloodRequestProvider>()
          .updateStatus(widget.requestId, status);
      await _load();
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to update status.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await context.read<BloodRequestProvider>().delete(widget.requestId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete request.')));
      setState(() => _busy = false);
    }
  }

  Future<void> _messageRequester() async {
    final req = _request!;
    setState(() => _busy = true);
    try {
      final convId =
          await context.read<ChatProvider>().openConversationWith(req.userId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: convId,
            otherUserName: req.requesterName,
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not start conversation.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().currentUser?.id;
    final isOwner = _request != null && myId == _request!.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          if (isOwner && _request != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.critical),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : _buildBody(isOwner),
    );
  }

  Widget _buildBody(bool isOwner) {
    final req = _request!;
    String dateStr;
    try {
      dateStr = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(req.requiredTime));
    } catch (_) {
      dateStr = req.requiredTime;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BloodDrop(size: 64, label: req.bloodGroup),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.patientName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(children: [
                      TypeBadge(type: req.requestType),
                      const SizedBox(width: 8),
                      StatusBadge(status: req.status),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.bloodtype_rounded, label: 'Units needed', value: '${req.units}'),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.info_outline_rounded, label: 'Cause', value: req.cause),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: req.locationDetail),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.schedule_rounded, label: 'Required by', value: dateStr),
                  if (req.contactNumber != null && req.contactNumber!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.call_outlined, label: 'Contact', value: req.contactNumber!),
                  ],
                  if (req.note != null && req.note!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.notes_rounded, label: 'Note', value: req.note!),
                  ],
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.person_outline_rounded, label: 'Requested by', value: req.requesterName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isOwner)
            PrimaryButton(
              label: 'Message Requester',
              icon: Icons.chat_bubble_outline_rounded,
              isLoading: _busy,
              onPressed: _messageRequester,
            ),
          if (isOwner) ...[
            const Text('Update status', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['pending', 'accepted', 'fulfilled', 'cancelled'].map((s) {
                final selected = s == req.status;
                final color = statusColor(s);
                return ChoiceChip(
                  label: Text(s[0].toUpperCase() + s.substring(1)),
                  selected: selected,
                  onSelected: _busy ? null : (_) => _updateStatus(s),
                  selectedColor: color.withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
