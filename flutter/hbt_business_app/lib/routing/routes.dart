/// Route path constants for the HBT Business App.
///
/// Centralises all route strings used with `Navigator.pushNamed` or
/// GoRouter/etc. to avoid magic strings scattered across screens.
///
/// For now screens use direct `Navigator.push(MaterialPageRoute(...))`
/// calls. These constants allow a future migration to named routing.
abstract final class Routes {
  Routes._();

  // ── Auth ──────────────────────────────────────────────────────────
  static const String signIn = '/sign-in';

  // ── Shell / Navigation ────────────────────────────────────────────
  static const String home = '/';
  static const String ticketTab = '/ticket';
  static const String cargoTab = '/cargo';
  static const String syncTab = '/sync';

  // ── Ticket Sales ──────────────────────────────────────────────────
  static const String ticketSales = '/ticket-sales';
  static const String counterBooking = '/counter-booking';
  static const String paymentDecision = '/payment-decision';
  static const String ticketScanner = '/ticket-scanner';

  // ── Trip ──────────────────────────────────────────────────────────
  static const String tripList = '/trips';
  static const String tripDetail = '/trips/:id';

  // ── Route ─────────────────────────────────────────────────────────
  static const String routeList = '/routes';
  static const String routeDetail = '/routes/:id';

  // ── Cargo ─────────────────────────────────────────────────────────
  static const String cargoWorklist = '/cargo/worklist';
  static const String cargoAcceptance = '/cargo/accept';

  // ── Refund ────────────────────────────────────────────────────────
  static const String refundList = '/refunds';
  static const String refundCreate = '/refunds/create';
  static const String refundDetail = '/refunds/:id';

  // ── Expense ───────────────────────────────────────────────────────
  static const String expenseList = '/expenses';
  static const String expenseCreate = '/expenses/create';

  // ── Finance ──────────────────────────────────────────────────────
  static const String profitLoss = '/profit-loss';
}
