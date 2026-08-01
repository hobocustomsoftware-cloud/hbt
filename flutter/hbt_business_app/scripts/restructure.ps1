# ── HBT Flutter App Restructure Script ─────────────────────────────────
# Moves files to production folder structure and updates ALL imports.
# Does NOT change business logic — only file locations and import paths.
# ────────────────────────────────────────────────────────────────────────

$root = "F:\hbt\flutter\hbt_business_app\lib"

# ── 1. FILE MOVE MAP: source → dest (both relative to $root) ──────────
$moves = @(
  @{from = "app/hbt_business_app.dart";          to = "app/app.dart"}
  @{from = "core/config/app_config.dart";        to = "app/app_config.dart"}
  @{from = "core/network/api_client.dart";       to = "shared/services/api_client.dart"}
  @{from = "core/database/app_database.dart";    to = "infrastructure/database/app_database.dart"}
  @{from = "core/models/hbt_models.dart";        to = "shared/models/hbt_models.dart"}
  @{from = "core/offline/device_registry.dart";  to = "infrastructure/offline/device_registry.dart"}
  @{from = "core/offline/sync_manager.dart";     to = "infrastructure/offline/sync_manager.dart"}
  @{from = "core/offline/sync_upload_queue.dart"; to = "infrastructure/offline/sync_upload_queue.dart"}
  @{from = "features/auth/application/session_controller.dart";      to = "features/auth/controllers/session_controller.dart"}
  @{from = "features/auth/presentation/sign_in_screen.dart";         to = "features/auth/screens/sign_in_screen.dart"}
  @{from = "features/business/presentation/business_home.dart";      to = "features/business/screens/business_home.dart"}
  @{from = "features/cargo/presentation/cargo_acceptance_page.dart"; to = "features/cargo/screens/cargo_acceptance_page.dart"}
  @{from = "features/cargo/presentation/cargo_worklist_page.dart";   to = "features/cargo/screens/cargo_worklist_page.dart"}
  @{from = "features/organization/domain/organization_context.dart"; to = "shared/models/organization_context.dart"}
  @{from = "features/refund/application/refund_service.dart";        to = "shared/services/refund_service.dart"}
  @{from = "features/refund/presentation/refund_create_page.dart";   to = "features/refund/screens/refund_create_page.dart"}
  @{from = "features/refund/presentation/refund_detail_page.dart";   to = "features/refund/screens/refund_detail_page.dart"}
  @{from = "features/refund/presentation/refund_list_page.dart";     to = "features/refund/screens/refund_list_page.dart"}
  @{from = "features/routes/presentation/route_detail_page.dart";    to = "features/routes/screens/route_detail_page.dart"}
  @{from = "features/routes/presentation/route_list_page.dart";      to = "features/routes/screens/route_list_page.dart"}
  @{from = "features/ticket_sales/presentation/counter_booking_page.dart";    to = "features/ticket_sales/screens/counter_booking_page.dart"}
  @{from = "features/ticket_sales/presentation/payment_decision_page.dart";  to = "features/ticket_sales/screens/payment_decision_page.dart"}
  @{from = "features/ticket_sales/presentation/ticket_sales_page.dart";      to = "features/ticket_sales/screens/ticket_sales_page.dart"}
  @{from = "features/ticket_sales/presentation/ticket_scanner_screen.dart";  to = "features/ticket_sales/screens/ticket_scanner_screen.dart"}
  @{from = "features/trip/presentation/trip_detail_page.dart";       to = "features/trip/screens/trip_detail_page.dart"}
  @{from = "features/trip/presentation/trip_list_page.dart";         to = "features/trip/screens/trip_list_page.dart"}
)

# ── 2. IMPORT REWRITE RULES ──────────────────────────────────────────
# These are OLD import patterns found in files → NEW target paths.
# Handles both relative (`../`) and various depth levels.
$rewritePatterns = @(
  # config
  @{old = "'../core/config/app_config.dart'";       new = "'../app/app_config.dart'"}
  @{old = "'../../core/config/app_config.dart'";    new = "'../../app/app_config.dart'"}
  @{old = "'../../../core/config/app_config.dart'"; new = "'../../../app/app_config.dart'"}
  # network/api_client
  @{old = "'../core/network/api_client.dart'";       new = "'../shared/services/api_client.dart'"}
  @{old = "'../../core/network/api_client.dart'";    new = "'../../shared/services/api_client.dart'"}
  @{old = "'../../../core/network/api_client.dart'"; new = "'../../../shared/services/api_client.dart'"}
  # database
  @{old = "'../core/database/app_database.dart'";       new = "'../infrastructure/database/app_database.dart'"}
  @{old = "'../../core/database/app_database.dart'";    new = "'../../infrastructure/database/app_database.dart'"}
  @{old = "'../../../core/database/app_database.dart'"; new = "'../../../infrastructure/database/app_database.dart'"}
  # models/hbt_models
  @{old = "'../core/models/hbt_models.dart'";       new = "'../shared/models/hbt_models.dart'"}
  @{old = "'../../core/models/hbt_models.dart'";    new = "'../../shared/models/hbt_models.dart'"}
  @{old = "'../../../core/models/hbt_models.dart'"; new = "'../../../shared/models/hbt_models.dart'"}
  # offline/device_registry
  @{old = "'../core/offline/device_registry.dart'";       new = "'../infrastructure/offline/device_registry.dart'"}
  @{old = "'../../core/offline/device_registry.dart'";    new = "'../../infrastructure/offline/device_registry.dart'"}
  # offline/sync_manager
  @{old = "'../core/offline/sync_manager.dart'";       new = "'../infrastructure/offline/sync_manager.dart'"}
  @{old = "'../../core/offline/sync_manager.dart'";    new = "'../../infrastructure/offline/sync_manager.dart'"}
  # offline/sync_upload_queue
  @{old = "'../core/offline/sync_upload_queue.dart'";       new = "'../infrastructure/offline/sync_upload_queue.dart'"}
  @{old = "'../../core/offline/sync_upload_queue.dart'";    new = "'../../infrastructure/offline/sync_upload_queue.dart'"}
  # organization domain
  @{old = "'../organization/domain/organization_context.dart'";       new = "'../shared/models/organization_context.dart'"}
  @{old = "'../../organization/domain/organization_context.dart'";    new = "'../../shared/models/organization_context.dart'"}
  @{old = "'../../../organization/domain/organization_context.dart'"; new = "'../../../shared/models/organization_context.dart'"}
  # auth/application/session_controller
  @{old = "'../auth/application/session_controller.dart'";       new = "'../auth/controllers/session_controller.dart'"}
  @{old = "'../../auth/application/session_controller.dart'";    new = "'../../auth/controllers/session_controller.dart'"}
  @{old = "'../../../auth/application/session_controller.dart'"; new = "'../../../auth/controllers/session_controller.dart'"}
  # auth/presentation/sign_in_screen
  @{old = "'../auth/presentation/sign_in_screen.dart'";       new = "'../auth/screens/sign_in_screen.dart'"}
  @{old = "'../../auth/presentation/sign_in_screen.dart'";    new = "'../../auth/screens/sign_in_screen.dart'"}
  # auth/application (in same feature → controllers)
  @{old = "'application/session_controller.dart'"; new = "'controllers/session_controller.dart'"}
  # auth/presentation → screens
  @{old = "'presentation/sign_in_screen.dart'"; new = "'screens/sign_in_screen.dart'"}
  # business/presentation → screens
  @{old = "'business/presentation/business_home.dart'";    new = "'business/screens/business_home.dart'"}
  @{old = "'../business/presentation/business_home.dart'"; new = "'../business/screens/business_home.dart'"}
  # cargo/presentation → screens
  @{old = "'cargo/presentation/cargo_worklist_page.dart'";   new = "'cargo/screens/cargo_worklist_page.dart'"}
  @{old = "'../cargo/presentation/cargo_worklist_page.dart'"; new = "'../cargo/screens/cargo_worklist_page.dart'"}
  @{old = "'cargo/presentation/cargo_acceptance_page.dart'";   new = "'cargo/screens/cargo_acceptance_page.dart'"}
  @{old = "'../cargo/presentation/cargo_acceptance_page.dart'"; new = "'../cargo/screens/cargo_acceptance_page.dart'"}
  # ticket_sales/presentation → screens
  @{old = "'ticket_sales/presentation/counter_booking_page.dart'";      new = "'ticket_sales/screens/counter_booking_page.dart'"}
  @{old = "'../ticket_sales/presentation/counter_booking_page.dart'";   new = "'../ticket_sales/screens/counter_booking_page.dart'"}
  @{old = "'ticket_sales/presentation/ticket_sales_page.dart'";         new = "'ticket_sales/screens/ticket_sales_page.dart'"}
  @{old = "'../ticket_sales/presentation/ticket_sales_page.dart'";      new = "'../ticket_sales/screens/ticket_sales_page.dart'"}
  @{old = "'ticket_sales/presentation/payment_decision_page.dart'";     new = "'ticket_sales/screens/payment_decision_page.dart'"}
  @{old = "'../ticket_sales/presentation/payment_decision_page.dart'";  new = "'../ticket_sales/screens/payment_decision_page.dart'"}
  @{old = "'ticket_sales/presentation/ticket_scanner_screen.dart'";      new = "'ticket_sales/screens/ticket_scanner_screen.dart'"}
  @{old = "'../ticket_sales/presentation/ticket_scanner_screen.dart'";   new = "'../ticket_sales/screens/ticket_scanner_screen.dart'"}
  # trip/presentation → screens
  @{old = "'trip/presentation/trip_list_page.dart'";     new = "'trip/screens/trip_list_page.dart'"}
  @{old = "'../trip/presentation/trip_list_page.dart'";  new = "'../trip/screens/trip_list_page.dart'"}
  @{old = "'trip/presentation/trip_detail_page.dart'";   new = "'trip/screens/trip_detail_page.dart'"}
  @{old = "'../trip/presentation/trip_detail_page.dart'"; new = "'../trip/screens/trip_detail_page.dart'"}
  # routes/presentation → screens
  @{old = "'routes/presentation/route_list_page.dart'";    new = "'routes/screens/route_list_page.dart'"}
  @{old = "'../routes/presentation/route_list_page.dart'"; new = "'../routes/screens/route_list_page.dart'"}
  @{old = "'routes/presentation/route_detail_page.dart'";   new = "'routes/screens/route_detail_page.dart'"}
  @{old = "'../routes/presentation/route_detail_page.dart'"; new = "'../routes/screens/route_detail_page.dart'"}
  # refund/presentation → screens
  @{old = "'refund/presentation/refund_list_page.dart'";      new = "'refund/screens/refund_list_page.dart'"}
  @{old = "'../refund/presentation/refund_list_page.dart'";   new = "'../refund/screens/refund_list_page.dart'"}
  @{old = "'refund/presentation/refund_create_page.dart'";     new = "'refund/screens/refund_create_page.dart'"}
  @{old = "'../refund/presentation/refund_create_page.dart'";  new = "'../refund/screens/refund_create_page.dart'"}
  @{old = "'refund/presentation/refund_detail_page.dart'";     new = "'refund/screens/refund_detail_page.dart'"}
  @{old = "'../refund/presentation/refund_detail_page.dart'";  new = "'../refund/screens/refund_detail_page.dart'"}
  # refund/application → shared/services
  @{old = "'refund/application/refund_service.dart'";    new = "'../shared/services/refund_service.dart'"}
  @{old = "'../refund/application/refund_service.dart'"; new = "'../shared/services/refund_service.dart'"}
)

# ── 3. COPY FILES WITH IMPORT REWRITES ──────────────────────────────
Write-Host "=== Copying files with import rewrites ===" -ForegroundColor Cyan

foreach ($m in $moves) {
  $src = Join-Path $root $m.from
  $dst = Join-Path $root $m.to

  if (-not (Test-Path $src)) {
    Write-Host "  SKIP (not found): $($m.from)" -ForegroundColor Yellow
    continue
  }

  $content = Get-Content $src -Raw -Encoding UTF8

  # Apply all rewrite patterns
  $changed = $false
  foreach ($r in $rewritePatterns) {
    if ($content -match [regex]::Escape($r.old)) {
      $content = $content -replace [regex]::Escape($r.old), $r.new
      $changed = $true
    }
  }

  $content | Set-Content $dst -Encoding UTF8 -NoNewline
  if ($changed) {
    Write-Host "  COPY + REWRITE: $($m.from) → $($m.to)" -ForegroundColor Green
  } else {
    Write-Host "  COPY (no changes): $($m.from) → $($m.to)" -ForegroundColor Gray
  }
}

# ── 4. UPDATE IMPORTS IN FILES THAT DIDN'T MOVE ─────────────────────
Write-Host "`n=== Updating imports in remaining files ===" -ForegroundColor Cyan

$allDartFiles = Get-ChildItem $root -Recurse -Include "*.dart" | Where-Object { -not $_.FullName.Contains("\node_modules\") }

foreach ($file in $allDartFiles) {
  $relPath = [System.IO.Path]::GetRelativePath($root, $file.FullName)

  # Skip files that were moved (they already have updated imports from step 3)
  $wasMoved = $false
  foreach ($m in $moves) {
    if ($relPath -eq $m.to) { $wasMoved = $true; break }
  }
  if ($wasMoved) { continue }

  # Also skip files still in old paths that will be deleted
  $isOldPath = $false
  foreach ($m in $moves) {
    if ($relPath -eq $m.from) { $isOldPath = $true; break }
  }
  if ($isOldPath) { continue }

  $content = Get-Content $file.FullName -Raw -Encoding UTF8
  $before = $content
  foreach ($r in $rewritePatterns) {
    $content = $content -replace [regex]::Escape($r.old), $r.new
  }

  if ($content -ne $before) {
    $content | Set-Content $file.FullName -Encoding UTF8 -NoNewline
    Write-Host "  UPDATED: $relPath" -ForegroundColor Green
  }
}

# ── 5. DELETE OLD EMPTY DIRECTORIES ─────────────────────────────────
Write-Host "`n=== Cleaning up old directories ===" -ForegroundColor Cyan

# Delete old files that were moved
foreach ($m in $moves) {
  $oldFile = Join-Path $root $m.from
  if (Test-Path $oldFile) {
    Remove-Item $oldFile -Force
    Write-Host "  DELETED: $($m.from)" -ForegroundColor Yellow
  }
}

# Delete old empty directories
$oldDirs = @(
  "core/config",
  "core/network",
  "core/database",
  "core/models",
  "core/offline",
  "features/auth/application",
  "features/auth/presentation",
  "features/business/presentation",
  "features/cargo/presentation",
  "features/organization/domain",
  "features/organization",
  "features/refund/application",
  "features/refund/presentation",
  "features/routes/presentation",
  "features/ticket_sales/presentation",
  "features/trip/presentation"
)

foreach ($d in $oldDirs) {
  $dirPath = Join-Path $root $d
  if (Test-Path $dirPath) {
    # Remove empty dirs (only delete if empty)
    $remaining = Get-ChildItem $dirPath -Recurse
    if ($remaining.Count -eq 0) {
      Remove-Item $dirPath -Recurse -Force
      Write-Host "  REMOVED DIR: $d" -ForegroundColor Gray
    } else {
      Write-Host "  NOT EMPTY: $d ($($remaining.Count) items)" -ForegroundColor Red
    }
  }
}

# ── 6. VERIFICATION ──────────────────────────────────────────────────
Write-Host "`n=== Final structure ===" -ForegroundColor Cyan
Write-Host ""
Get-ChildItem $root -Recurse -Include "*.dart" | ForEach-Object {
  $rel = [System.IO.Path]::GetRelativePath($root, $_.FullName)
  Write-Host "  $rel"
}

Write-Host "`n✅ Restructure complete! Run 'flutter analyze lib/' to verify." -ForegroundColor Green
