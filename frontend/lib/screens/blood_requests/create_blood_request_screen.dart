import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/blood_request_provider.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _requestTypes = ['critical', 'urgent', 'normal'];

class CreateBloodRequestScreen extends StatefulWidget {
  const CreateBloodRequestScreen({super.key});

  @override
  State<CreateBloodRequestScreen> createState() =>
      _CreateBloodRequestScreenState();
}

class _CreateBloodRequestScreenState extends State<CreateBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientName = TextEditingController();
  final _contact = TextEditingController();
  final _units = TextEditingController(text: '1');
  final _cause = TextEditingController();
  final _location = TextEditingController();
  final _note = TextEditingController();

  String? _bloodGroup;
  String _requestType = 'urgent';
  DateTime? _requiredTime;
  bool _submitting = false;

  @override
  void dispose() {
    _patientName.dispose();
    _contact.dispose();
    _units.dispose();
    _cause.dispose();
    _location.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _requiredTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bloodGroup == null) {
      _showSnack('Please select a blood group');
      return;
    }
    if (_requiredTime == null) {
      _showSnack('Please select a required date & time');
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<BloodRequestProvider>().create(
            patientName: _patientName.text.trim(),
            contactNumber: _contact.text.trim(),
            bloodGroup: _bloodGroup!,
            units: int.tryParse(_units.text.trim()) ?? 1,
            requestType: _requestType,
            cause: _cause.text.trim(),
            locationDetail: _location.text.trim(),
            requiredTime: _requiredTime!,
            note: _note.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Failed to create request. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Blood Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _patientName,
                  decoration: const InputDecoration(labelText: 'Patient name', hintText: 'e.g. John Doe'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contact,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Contact number (optional)'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood group'),
                        items: _bloodGroups
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _units,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Units needed'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Urgency', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _requestTypes.map((t) {
                    final selected = t == _requestType;
                    final color = requestTypeColor(t);
                    return ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => setState(() => _requestType = t),
                      selectedColor: color.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: selected ? color : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cause,
                  decoration: const InputDecoration(
                      labelText: 'Cause', hintText: 'e.g. Surgery, Accident, Thalassemia'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                      labelText: 'Location', hintText: 'Hospital name, area, city'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Required by'),
                    child: Text(
                      _requiredTime == null
                          ? 'Select date & time'
                          : DateFormat('MMM d, yyyy • h:mm a').format(_requiredTime!),
                      style: TextStyle(
                        color: _requiredTime == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Additional note (optional)'),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Submit Request',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
