import csv
import os
import shutil
import ssl
from datetime import datetime, timedelta, timezone as dt_timezone
from io import StringIO
from pathlib import Path

from django.db.models import Count, Sum
from django.db import connection
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from apps.audit.services import record_audit_event
from apps.core.serializers import EmptySerializer

from apps.bookings.models import Booking
from apps.boarding.models import BoardingRecord
from apps.cargo.models import CargoShipment
from apps.notifications.models import Notification, PendingWorkItem
from apps.offline.models import Device, SyncOperation
from apps.payments.models import PaymentIntent, PaymentRecord, PaymentWebhookEvent, RefundRequest
from apps.scheduling.models import Trip
from apps.subscriptions.models import SubscriptionInvoice
from apps.scheduling.views import OrganizationSchedulingMixin, require_trip_scope
from apps.ticketing.models import Ticket

from .models import CashSettlement, PrintAttempt, PrintDocument, PrinterProfile, PrintTemplate
from .dashboard import build_owner_dashboard
from .serializers import (
    CashSettlementSerializer, PrintDocumentSerializer, PrintAttemptSerializer,
    PrinterProfileSerializer, PrintTemplateSerializer, SettlementActionSerializer,
    SettlementCreateSerializer, TripCloseRequestSerializer, TripClosingSerializer,
    OwnerDashboardSerializer, MonitoringAlertListSerializer, MonitoringDashboardSerializer,
    SyncBootstrapSerializer, ReportExportQuerySerializer,
)
from .services import acknowledge_print


class PrintDocumentListCreateView(OrganizationSchedulingMixin, generics.ListCreateAPIView):
    serializer_class = PrintDocumentSerializer
    view_permission = "print.view"
    manage_permission = "print.create"
    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PrintDocument.objects.filter(organization=organization)


class PrinterProfileListCreateView(OrganizationSchedulingMixin, generics.ListCreateAPIView):
    serializer_class = PrinterProfileSerializer
    view_permission = "print.view"
    manage_permission = "print.create"
    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PrinterProfile.objects.filter(organization=organization)
    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        serializer.save(organization=organization)


class PrintTemplateListCreateView(OrganizationSchedulingMixin, generics.ListCreateAPIView):
    serializer_class = PrintTemplateSerializer
    view_permission = "print.view"
    manage_permission = "print.create"
    def get_queryset(self):
        organization, _ = self.organization_and_membership()
        return PrintTemplate.objects.filter(organization=organization)
    def perform_create(self, serializer):
        organization, _ = self.organization_and_membership()
        serializer.save(organization=organization, created_by=self.request.user)


class PrintAcknowledgeView(OrganizationSchedulingMixin, APIView):
    manage_permission = "print.create"
    @extend_schema(request=PrintAttemptSerializer, responses=PrintAttemptSerializer, operation_id="print_document_acknowledge")
    def post(self, request, organization_id, document_id, version=None):
        organization, _ = self.organization_and_membership()
        document = get_object_or_404(PrintDocument, pk=document_id, organization=organization)
        serializer = PrintAttemptSerializer(data=request.data, context={"organization": organization, "request": request})
        serializer.is_valid(raise_exception=True)
        attempt = acknowledge_print(document=document, actor=request.user, **serializer.validated_data)
        return Response(PrintAttemptSerializer(attempt).data)


class TripCloseView(OrganizationSchedulingMixin, APIView):
    manage_permission = "trip.close"
    @extend_schema(request=TripCloseRequestSerializer, responses=TripClosingSerializer, operation_id="trip_close")
    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, pk=trip_id, organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        serializer = TripCloseRequestSerializer(data=request.data, context={"trip": trip, "request": request})
        serializer.is_valid(raise_exception=True)
        return Response(TripClosingSerializer(serializer.save()).data)


class SettlementCreateView(OrganizationSchedulingMixin, APIView):
    manage_permission = "settlement.create"
    @extend_schema(request=SettlementCreateSerializer, responses=CashSettlementSerializer, operation_id="cash_settlement_create")
    def post(self, request, organization_id, trip_id, version=None):
        organization, membership = self.organization_and_membership()
        trip = get_object_or_404(Trip, pk=trip_id, organization=organization)
        require_trip_scope(membership, trip, self.manage_permission)
        serializer = SettlementCreateSerializer(data=request.data, context={"trip": trip, "request": request})
        serializer.is_valid(raise_exception=True)
        return Response(CashSettlementSerializer(serializer.save()).data)


class SettlementActionView(OrganizationSchedulingMixin, APIView):
    manage_permission = "settlement.approve"
    @extend_schema(request=SettlementActionSerializer, responses=CashSettlementSerializer, operation_id="cash_settlement_action")
    def post(self, request, organization_id, settlement_id, version=None):
        organization, membership = self.organization_and_membership()
        settlement = get_object_or_404(CashSettlement, pk=settlement_id, organization=organization)
        require_trip_scope(membership, settlement.trip, self.manage_permission)
        serializer = SettlementActionSerializer(data=request.data, context={"settlement": settlement, "request": request})
        serializer.is_valid(raise_exception=True)
        return Response(CashSettlementSerializer(serializer.save()).data)


class OwnerDashboardView(OrganizationSchedulingMixin, APIView):
    view_permission = "report.owner"
    @extend_schema(parameters=[OpenApiParameter("period", OpenApiTypes.STR, enum=["day", "week", "month", "year"], description="Aggregation window for the dashboard snapshot (default: day).")], responses=OwnerDashboardSerializer, operation_id="owner_dashboard")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        period = request.query_params.get("period", "day")
        if period not in ("day", "week", "month", "year"):
            return Response({"detail": "period must be one of day, week, month, year."}, status=400)
        try:
            snapshot = build_owner_dashboard(organization=organization, period=period)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(snapshot)


def _csv_safe(value):
    text = "" if value is None else str(value)
    if text.startswith(("=", "+", "-", "@", "\t", "\r")):
        return "'" + text
    return text


class ReportExportView(OrganizationSchedulingMixin, APIView):
    view_permission = "report.owner"
    @extend_schema(parameters=[OpenApiParameter("report", str, required=True), OpenApiParameter("date", OpenApiTypes.DATE), OpenApiParameter("date_from", OpenApiTypes.DATE), OpenApiParameter("date_to", OpenApiTypes.DATE)], responses={(200, "text/csv"): OpenApiTypes.BINARY}, operation_id="organization_report_export_csv")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        query = ReportExportQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        data = query.validated_data
        report = data["report"]
        start, end = data["date_from"], data["date_to"]
        rows = self._rows(organization, report, start, end)
        output = StringIO()
        writer = csv.writer(output, lineterminator="\n")
        for row in rows:
            writer.writerow([_csv_safe(value) for value in row])
        response = HttpResponse("\ufeff" + output.getvalue(), content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = f'attachment; filename="hbt-{report}-{start}-{end}.csv"'
        response["X-Content-Type-Options"] = "nosniff"
        record_audit_event(actor=request.user, tenant_id=organization.tenant_id, organization_id=organization.id, action="report.exported", resource_type="report", resource_id="", metadata={"report": report, "date_from": start, "date_to": end, "format": "csv"})
        return response
    @staticmethod
    def _rows(organization, report, start, end):
        if report == "trips":
            yield ("trip_number", "service_date", "status", "departure", "arrival")
            for trip in Trip.objects.filter(organization=organization, service_date__range=(start, end)).order_by("service_date", "planned_departure_at"):
                yield (trip.trip_number, trip.service_date, trip.status, trip.planned_departure_at, trip.planned_arrival_at)
            return
        if report == "payments":
            yield ("payment_number", "confirmed_at", "method", "amount", "currency", "booking_id", "cargo_shipment_id")
            for payment in PaymentRecord.objects.filter(organization=organization, status=PaymentRecord.Status.CONFIRMED, confirmed_at__date__range=(start, end)).order_by("confirmed_at"):
                yield (payment.payment_number, payment.confirmed_at, payment.method, payment.amount, payment.currency, payment.booking_id, payment.cargo_shipment_id)
            return
        if report == "cargo":
            yield ("shipment_number", "created_at", "status", "pieces", "weight_kg", "total_charge", "currency")
            for shipment in CargoShipment.objects.filter(organization=organization, created_at__date__range=(start, end)).order_by("created_at"):
                yield (shipment.shipment_number, shipment.created_at, shipment.status, shipment.piece_count, shipment.weight_kg, shipment.total_charge, shipment.currency)
            return
        trips = Trip.objects.filter(organization=organization, service_date__range=(start, end))
        tickets = Ticket.objects.filter(organization=organization, trip__service_date__range=(start, end)).exclude(status=Ticket.Status.CANCELLED)
        cargo = CargoShipment.objects.filter(organization=organization, created_at__date__range=(start, end))
        payments = PaymentRecord.objects.filter(organization=organization, status=PaymentRecord.Status.CONFIRMED, confirmed_at__date__range=(start, end))
        yield ("metric", "value")
        yield ("date_from", start); yield ("date_to", end)
        yield ("trip_count", trips.count()); yield ("closed_trip_count", trips.filter(status=Trip.Status.CLOSED).count()); yield ("ticket_count", tickets.count()); yield ("cargo_count", cargo.count()); yield ("confirmed_payment_total", payments.aggregate(total=Sum("amount"))["total"] or 0)


class SyncBootstrapView(OrganizationSchedulingMixin, APIView):
    view_permission = "offline.sync"
    @extend_schema(responses=SyncBootstrapSerializer, operation_id="offline_sync_bootstrap")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership()
        since = request.query_params.get("since")
        cargo = CargoShipment.objects.filter(organization=organization)
        trips = Trip.objects.filter(organization=organization)
        if since:
            cargo = cargo.filter(updated_at__gt=since); trips = trips.filter(updated_at__gt=since)
        return Response({"server_time": timezone.now(), "cargo_shipments": list(cargo.values("id", "shipment_number", "tracking_code", "status", "assigned_trip_id", "updated_at")[:1000]), "trips": list(trips.values("id", "trip_number", "status", "service_date", "updated_at")[:500])})


def _oldest_age_seconds(queryset, field_name, now):
    value = queryset.order_by(field_name).values_list(field_name, flat=True).first()
    if not value: return 0
    return max(0, int((now - value).total_seconds()))

def _backup_age_seconds():
    latest = os.getenv("HBT_BACKUP_LATEST_FILE", "").strip()
    if not latest: return None
    path = Path(latest)
    if not path.exists(): return None
    modified_at = timezone.datetime.fromtimestamp(path.stat().st_mtime, tz=dt_timezone.utc)
    return max(0, int((timezone.now() - modified_at).total_seconds()))

def _certificate_expiry_days():
    certificate_path = os.getenv("HBT_TLS_CERTIFICATE_PATH", "").strip()
    if not certificate_path: return None
    path = Path(certificate_path)
    if not path.exists(): return None
    try:
        decoded = ssl._ssl._test_decode_cert(str(path)); not_after = decoded.get("notAfter")
        if not not_after: return None
        expires_at = timezone.datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=dt_timezone.utc)
    except Exception: return None
    return max(0, int((expires_at - timezone.now()).total_seconds() // 86400))

def _database_status():
    try:
        with connection.cursor() as cursor: cursor.execute("SELECT 1"); cursor.fetchone()
    except Exception: return "unavailable"
    return "ok"


class MonitoringDashboardView(OrganizationSchedulingMixin, APIView):
    view_permission = "report.owner"
    @extend_schema(responses=MonitoringDashboardSerializer, operation_id="organization_monitoring_dashboard")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership(); now = timezone.now(); today = timezone.localdate(); last_24h = now - timedelta(hours=24)
        push_backlog = Notification.objects.filter(organization=organization, channel=Notification.Channel.PUSH, status__in=[Notification.Status.CREATED, Notification.Status.QUEUED, Notification.Status.PROCESSING], available_at__lte=now)
        sync_backlog = SyncOperation.objects.filter(organization=organization, status=SyncOperation.Status.RECEIVED)
        webhook_backlog = PaymentWebhookEvent.objects.filter(connector__organization=organization, status=PaymentWebhookEvent.Status.RECEIVED)
        disk_free_bytes = shutil.disk_usage(Path(__file__).resolve().anchor).free
        return Response({"service_overview": {"generated_at": now, "active_devices_24h": Device.objects.filter(user__organization_memberships__organization=organization, user__organization_memberships__status="active", status=Device.Status.ACTIVE, last_seen_at__gte=last_24h).distinct().count(), "pending_push_notifications": push_backlog.count(), "push_queue_oldest_seconds": _oldest_age_seconds(push_backlog, "available_at", now), "sync_backlog_count": sync_backlog.count(), "sync_backlog_oldest_seconds": _oldest_age_seconds(sync_backlog, "created_at", now), "payment_reconciliation_backlog": PaymentIntent.objects.filter(organization=organization, status=PaymentIntent.Status.REQUIRES_RECONCILIATION).count(), "webhook_backlog_count": webhook_backlog.count(), "webhook_backlog_oldest_seconds": _oldest_age_seconds(webhook_backlog, "created_at", now)}, "business_reliability": {"bookings_today": Booking.objects.filter(organization=organization, created_at__date=today).count(), "expired_bookings_today": Booking.objects.filter(organization=organization, status=Booking.Status.EXPIRED, updated_at__date=today).count(), "active_trips": Trip.objects.filter(organization=organization, status__in=[Trip.Status.BOARDING, Trip.Status.DEPARTED, Trip.Status.IN_PROGRESS, Trip.Status.DELAYED]).count(), "rejected_boardings_24h": BoardingRecord.objects.filter(organization=organization, status=BoardingRecord.Status.REJECTED, created_at__gte=last_24h).count(), "cargo_exceptions_24h": CargoShipment.objects.filter(organization=organization, updated_at__gte=last_24h, status__in=[CargoShipment.Status.DAMAGED, CargoShipment.Status.LOST, CargoShipment.Status.RETURNED]).count(), "refunds_in_progress": RefundRequest.objects.filter(organization=organization, status__in=[RefundRequest.Status.REQUESTED, RefundRequest.Status.APPROVED, RefundRequest.Status.PAID]).count(), "subscription_past_due": SubscriptionInvoice.objects.filter(subscription__tenant=organization.tenant, status__in=[SubscriptionInvoice.Status.ISSUED, SubscriptionInvoice.Status.PAYMENT_SUBMITTED, SubscriptionInvoice.Status.OVERDUE], due_at__lt=now).count()}, "infrastructure": {"database": _database_status(), "disk_free_bytes": disk_free_bytes, "backup_age_seconds": _backup_age_seconds(), "certificate_expires_in_days": _certificate_expiry_days()}})


class MonitoringAlertsView(OrganizationSchedulingMixin, APIView):
    view_permission = "report.owner"
    @extend_schema(responses=MonitoringAlertListSerializer, operation_id="organization_monitoring_alerts")
    def get(self, request, organization_id, version=None):
        organization, _ = self.organization_and_membership(); now = timezone.now()
        push_backlog = Notification.objects.filter(organization=organization, channel=Notification.Channel.PUSH, status__in=[Notification.Status.CREATED, Notification.Status.QUEUED, Notification.Status.PROCESSING], available_at__lte=now)
        webhook_backlog = PaymentWebhookEvent.objects.filter(connector__organization=organization, status=PaymentWebhookEvent.Status.RECEIVED)
        sync_backlog = SyncOperation.objects.filter(organization=organization, status=SyncOperation.Status.RECEIVED)
        database_status = _database_status(); backup_age = _backup_age_seconds(); certificate_days = _certificate_expiry_days()
        alerts = [
            {"code":"api_readiness","severity":"critical","status":"ok" if database_status=="ok" else "triggered","threshold":"database must be reachable","value":database_status,"message":"Database-backed readiness is healthy." if database_status=="ok" else "Database-backed readiness failed."},
            {"code":"payment_webhook_backlog","severity":"critical","status":"triggered" if _oldest_age_seconds(webhook_backlog,"created_at",now)>300 else "ok","threshold":"oldest received webhook <= 300 seconds","value":str(_oldest_age_seconds(webhook_backlog,"created_at",now)),"message":"Payment webhook backlog age within threshold."},
            {"code":"offline_sync_backlog","severity":"warning","status":"triggered" if _oldest_age_seconds(sync_backlog,"created_at",now)>1800 else "ok","threshold":"oldest received offline sync <= 1800 seconds","value":str(_oldest_age_seconds(sync_backlog,"created_at",now)),"message":"Offline sync backlog age within threshold."},
            {"code":"backup_age","severity":"critical","status":"unavailable" if backup_age is None else "triggered" if backup_age>86400 else "ok","threshold":"latest backup age <= 86400 seconds","value":"unknown" if backup_age is None else str(backup_age),"message":"Backup age evidence is unavailable." if backup_age is None else "Latest backup age is within threshold."},
            {"code":"certificate_expiry","severity":"warning","status":"unavailable" if certificate_days is None else "triggered" if certificate_days<14 else "ok","threshold":"certificate expiry >= 14 days","value":"unknown" if certificate_days is None else str(certificate_days),"message":"Certificate expiry evidence is unavailable." if certificate_days is None else "Certificate expiry is within threshold."},
            {"code":"push_queue_backlog","severity":"warning","status":"triggered" if _oldest_age_seconds(push_backlog,"available_at",now)>300 else "ok","threshold":"oldest push queue item <= 300 seconds","value":str(_oldest_age_seconds(push_backlog,"available_at",now)),"message":"Push queue age is within threshold."},
        ]
        for alert in alerts:
            if alert["status"] == "triggered":
                if alert["code"] == "payment_webhook_backlog": alert["message"] = "Payment webhook backlog exceeded 5 minutes."
                elif alert["code"] == "offline_sync_backlog": alert["message"] = "Offline sync backlog exceeded 30 minutes."
                elif alert["code"] == "backup_age": alert["message"] = "Latest backup evidence is older than 24 hours."
                elif alert["code"] == "certificate_expiry": alert["message"] = "TLS certificate expires in fewer than 14 days."
                elif alert["code"] == "push_queue_backlog": alert["message"] = "Push queue backlog exceeded 5 minutes."
        return Response({"generated_at": now, "alerts": alerts})