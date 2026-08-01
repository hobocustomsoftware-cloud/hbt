import 'package:flutter/material.dart';

import '../../../shared/services/api_client.dart';
import '../../auth/controllers/session_controller.dart';

/// Create or edit a route.
class RouteDetailPage extends StatefulWidget {
  const RouteDetailPage({
    super.key,
    required this.session,
    required this.organizationId,
    this.route,
  });

  final SessionController session;
  final String organizationId;

  /// Null means creating a new route.
  final Map<String, dynamic>? route;

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _regionController;
  late final TextEditingController _distController;
  late final TextEditingController _durController;

  String _status = 'draft';
  bool _saving = false;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _codeController = TextEditingController(text: r?['code'] ?? '');
    _nameController = TextEditingController(text: r?['name'] ?? '');
    _regionController = TextEditingController(
      text: r?['operating_region'] ?? '',
    );
    _distController = TextEditingController(
      text: r?['estimated_distance_km']?.toString() ?? '',
    );
    _durController = TextEditingController(
      text: r?['estimated_duration_minutes']?.toString() ?? '',
    );
    _status = r?['status'] ?? 'draft';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _regionController.dispose();
    _distController.dispose();
    _durController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'operating_region': _regionController.text.trim(),
      'status': _status,
    };

    final dist = double.tryParse(_distController.text);
    final dur = int.tryParse(_durController.text);
    if (dist != null) body['estimated_distance_km'] = dist;
    if (dur != null) body['estimated_duration_minutes'] = dur;

    try {
      Map<String, dynamic> result;
      if (_isEditing) {
        result = await widget.session.api.patch(
          '/organizations/${widget.organizationId}/routes/${widget.route!['id']}/',
          body,
        );
      } else {
        result = await widget.session.api.post(
          '/organizations/${widget.organizationId}/routes/',
          body,
        );
      }
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_isEditing ? 'Edit Route' : 'Create Route'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Route Code',
              hintText: 'e.g. RTE-001',
            ),
            enabled: !_isEditing,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Route Name',
              hintText: 'e.g. Yangon — Mandalay',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regionController,
            decoration: const InputDecoration(
              labelText: 'Operating Region',
              hintText: 'e.g. Yangon Region',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _distController,
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _durController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
        ],
      ),
    ),
  );
}
