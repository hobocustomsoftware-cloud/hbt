import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/services/ticket_validation_service.dart';
import '../../../shared/models/ticket_validation_result.dart';
import '../../auth/controllers/session_controller.dart';

/// Screen for scanning ticket and cargo QR codes.
///
/// Parses QR codes (strips HBT:TICKET: and HBT:CARGO:V1: prefixes),
/// validates via the API, and displays the result with proper status
/// handling for: valid, used, expired, cancelled, invalid, and error.
class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _torchOn = false;
  bool _processing = false;
  TicketValidationResult? _result;

  late final TicketValidationService _validator;

  String get _organizationId =>
      widget.session.activeOrganization!.organization.id;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _validator = TicketValidationService(
      api: widget.session.api,
      organizationId: _organizationId,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller?.start();
    } else if (state == AppLifecycleState.paused) {
      _controller?.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _processing = true;
      _result = null;
    });
    _controller?.stop();

    final code = barcode.rawValue!;
    final result = await _validator.validate(code);

    if (!mounted) return;
    setState(() {
      _result = result;
      _processing = false;
    });
  }

  void _scanAgain() {
    setState(() {
      _result = null;
      _processing = false;
    });
    _controller?.start();
  }

  /// Record that the scanned ticket was validated at the gate.
  ///
  /// Marks the ticket as `validated` server-side (idempotent) so there is
  /// an audit trail for check-in and a used ticket cannot be re-used.
  Future<void> _markValidated() async {
    final ticketId = _result?.ticketData?['id']?.toString();
    if (ticketId == null) return;
    setState(() => _processing = true);
    try {
      final updated = await widget.session.api.post(
        '/organizations/$_organizationId/tickets/$ticketId/validate/',
        {},
      );
      if (!mounted) return;
      setState(() {
        _result = TicketValidationResult.valid(updated);
        _processing = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Ticket marked as validated.')),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('QR Scanner'),
      actions: [
        IconButton(
          icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          onPressed: _toggleTorch,
          tooltip: 'Torch',
        ),
      ],
    ),
    body: Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),

        // Scan window overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Bottom hint
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Scan the ticket QR code',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),

        // Result overlay
        if (_result != null)
          _ResultOverlay(
            result: _result!,
            canValidate: _result!.status == TicketValidationStatus.valid &&
                widget.session.hasPermission('ticket.validate'),
            onValidate: _markValidated,
            onScanAgain: _scanAgain,
          ),

        // Processing indicator
        if (_processing)
          const Center(child: CircularProgressIndicator()),
      ],
    ),
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.result,
    required this.onScanAgain,
    this.canValidate = false,
    this.onValidate,
  });

  final TicketValidationResult result;
  final VoidCallback onScanAgain;
  final bool canValidate;
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context) {
    final icon = result.isValid
        ? Icons.check_circle
        : result.status.isWarning
            ? Icons.warning_amber_rounded
            : Icons.cancel;

    final color = result.isValid
        ? Colors.green
        : result.status.isWarning
            ? Colors.orange
            : Colors.red;

    final displayText = result.ticketData != null
        ? TicketValidationService.formatResult(result)
        : (result.errorMessage ?? 'Unknown error.');

    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayText,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (canValidate && onValidate != null) ...[
                FilledButton.icon(
                  onPressed: onValidate,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Mark as Validated'),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: onScanAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
