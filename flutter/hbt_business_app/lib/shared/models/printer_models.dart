/// Paper width for thermal printers.
enum PaperWidth {
  mm58,
  mm80;

  int get widthChars {
    switch (this) {
      case PaperWidth.mm58:
        return 32; // 58mm ≈ 32 characters
      case PaperWidth.mm80:
        return 48; // 80mm ≈ 48 characters
    }
  }

  String get label {
    switch (this) {
      case PaperWidth.mm58:
        return '58 mm';
      case PaperWidth.mm80:
        return '80 mm';
    }
  }
}

/// Connection type for a thermal printer.
enum PrinterConnection {
  bluetooth,
  network,
  usb;

  String get label {
    switch (this) {
      case PrinterConnection.bluetooth:
        return 'Bluetooth';
      case PrinterConnection.network:
        return 'Network';
      case PrinterConnection.usb:
        return 'USB';
    }
  }
}

/// Status of a thermal printer.
enum PrinterStatus {
  connected,
  disconnected,
  outOfPaper,
  paperJam,
  overheating,
  busy,
  error;

  String get label {
    switch (this) {
      case PrinterStatus.connected:
        return 'Connected';
      case PrinterStatus.disconnected:
        return 'Disconnected';
      case PrinterStatus.outOfPaper:
        return 'Out of Paper';
      case PrinterStatus.paperJam:
        return 'Paper Jam';
      case PrinterStatus.overheating:
        return 'Overheating';
      case PrinterStatus.busy:
        return 'Busy';
      case PrinterStatus.error:
        return 'Error';
    }
  }

  bool get isError =>
      this == outOfPaper ||
      this == paperJam ||
      this == overheating ||
      this == error;
}

/// A detected or connected thermal printer device.
class PrinterDevice {
  final String id;
  final String name;
  final String? address;
  final PrinterConnection connectionType;
  final PaperWidth? paperWidth;
  final PrinterStatus status;

  const PrinterDevice({
    required this.id,
    required this.name,
    this.address,
    this.connectionType = PrinterConnection.bluetooth,
    this.paperWidth,
    this.status = PrinterStatus.disconnected,
  });

  factory PrinterDevice.fromJson(Map<String, dynamic> json) => PrinterDevice(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString(),
        connectionType: PrinterConnection.values.firstWhere(
          (c) => c.name == json['connection_type'],
          orElse: () => PrinterConnection.bluetooth,
        ),
        paperWidth: json['paper_width'] != null
            ? PaperWidth.values.firstWhere(
                (p) => p.name == json['paper_width'],
                orElse: () => PaperWidth.mm80,
              )
            : null,
        status: PrinterStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PrinterStatus.disconnected,
        ),
      );
}

/// A print job submitted to the printer.
class PrintJob {
  final String id;
  final PrintDocumentType documentType;
  final Map<String, dynamic> data;
  final PaperWidth paperWidth;
  final int copies;
  final DateTime submittedAt;
  PrintJobStatus status;
  String? errorMessage;

  PrintJob({
    required this.id,
    required this.documentType,
    required this.data,
    this.paperWidth = PaperWidth.mm80,
    this.copies = 1,
    DateTime? submittedAt,
    this.status = PrintJobStatus.pending,
    this.errorMessage,
  }) : submittedAt = submittedAt ?? DateTime.now();
}

/// Status of a print job.
enum PrintJobStatus {
  pending,
  printing,
  completed,
  failed,
  cancelled;

  String get label {
    switch (this) {
      case PrintJobStatus.pending:
        return 'Pending';
      case PrintJobStatus.printing:
        return 'Printing…';
      case PrintJobStatus.completed:
        return 'Completed';
      case PrintJobStatus.failed:
        return 'Failed';
      case PrintJobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Type of document to print.
enum PrintDocumentType {
  ticket,
  cargoReceipt,
  refundReceipt,
  shiftSummary;

  String get label {
    switch (this) {
      case PrintDocumentType.ticket:
        return 'Ticket';
      case PrintDocumentType.cargoReceipt:
        return 'Cargo Receipt';
      case PrintDocumentType.refundReceipt:
        return 'Refund Receipt';
      case PrintDocumentType.shiftSummary:
        return 'Shift Summary';
    }
  }
}
