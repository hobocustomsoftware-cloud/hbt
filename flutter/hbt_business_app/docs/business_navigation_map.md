# Business App — Navigation Map

**Format:** Mermaid flow diagrams

---

## 1. Top-Level Navigation

```mermaid
flowchart TB
    START([App Launch]) --> MAIN(main.dart)
    MAIN --> APP(HbtBusinessApp)
    
    APP --> LOAD{Session restore}
    LOAD -->|loading| SPLASH[LoadingScreen<br/>CircularProgressIndicator]
    LOAD -->|authenticated| HOME(BusinessHome)
    LOAD -->|not authenticated| SIGNIN(SignInScreen)
    
    SIGNIN -->|login success| HOME
    SIGNIN -->|sign out| SIGNIN
    
    HOME -->|org switch| HOME
    HOME -->|sign out| SIGNIN

    subgraph Shell [BusinessHome Shell]
        HOME --> TAB{Tab NavigationBar}
        TAB -->|Tab 0| DASH[DashboardPage]
        TAB -->|Tab 1| TS[TicketSalesPage]
        TAB -->|Tab 2| CG[CargoWorklistPage]
        TAB -->|Tab 3| SYNC[Sync Page<br/>Placeholder]
    end
```

---

## 2. Ticket Sales Workflow

```mermaid
flowchart LR
    subgraph Entry [Entry Points]
        DASH["DashboardPage<br/>'New Booking'"]
        TICKET["TicketSalesPage<br/>'Counter ticket sale'"]
        TRIPDTL["TripDetailPage<br/>'New Booking for this Trip'"]
    end

    Entry --> CB[CounterBookingPage]
    
    CB -->|select passenger| CB
    CB -->|select trip| CB
    CB -->|select stops| CB
    CB -->|select seat| CB
    CB -->|tap Book| CB_API{API calls}
    
    CB_API -->|create booking| CB_API
    CB_API -->|create fare quote| CB_API
    CB_API -->|lock quote| CB_RESULT{Success?}
    
    CB_RESULT -->|success| PENDING[PaymentDecisionPage]
    CB_RESULT -->|fail| CB_ERROR[ErrorCard in CB]
    CB_ERROR --> CB

    PENDING -->|upload evidence| PENDING
    PENDING -->|record payment| PENDING
    PENDING -->|approve + issue| TICKETS["Issued tickets list<br/>in PaymentDecisionPage"]

    subgraph Scanner [QR Scanner]
        SCANNER[TicketScannerScreen]
    end

    subgraph Lists [List Views]
        TSPAGE[TicketSalesPage]
        TSPAGE -->|booking list| TSPAGE
        TSPAGE -->|ticket list| TSPAGE
    end
```

---

## 3. Trip Management Workflow

```mermaid
flowchart LR
    subgraph Entries
        APPBAR["AppBar IconButton"]
        DASH_Q["DashboardPage<br/>Quick Action"]
    end

    Entries --> TRIPL[TripListPage]
    
    TRIPL -->|tap trip| TRIPD[TripDetailPage]
    TRIPD -->|status action| TRIPD_API{API call}
    TRIPD_API -->|ready/boarding/depart/arrive| TRIPD
    TRIPD -->|New Booking| CB[CounterBookingPage<br/>with preselected trip]
    TRIPD -->|pull to refresh| TRIPD
    
    TRIPL -->|filter by status| TRIPL
    TRIPL -->|pull to refresh| TRIPL
```

---

## 4. Route Management Workflow

```mermaid
flowchart LR
    subgraph Entries
        APPBAR["AppBar IconButton"]
        DASH_Q["DashboardPage<br/>Quick Action"]
    end

    Entries --> RL[RouteListPage]
    
    RL -->|tap route| RD[RouteDetailPage<br/>Edit mode]
    RL -->|tap +| RD_NEW[RouteDetailPage<br/>Create mode]
    RL -->|pull to refresh| RL
    
    RD -->|save| RD_API{API call}
    RD_API -->|PATCH (edit)| RL
    RD_API -->|POST (create)| RL
```

---

## 5. Cargo Workflow

```mermaid
flowchart LR
    subgraph Entry
        TAB["Tab 2: Cargo"]
    end

    TAB --> CWP[CargoWorklistPage]
    
    CWP -->|'Cargo လက်ခံရန်'| CAP[CargoAcceptancePage]
    
    CAP -->|fill form| CAP
    CAP -->|accept| CAP_API{API call}
    CAP_API -->|success| CWP
    CAP_API -->|fail| CAP_ERROR[ErrorCard in CAP]
    
    CWP -->|shipment list| CWP
    CWP -->|'Trip သတ်မှတ်'| TRIP_PICKER[Diaog: Trip picker]
    TRIP_PICKER -->|select trip| CWP
    CWP -->|transition button| CWP_API{API call}
    CWP -->|'အပ်နှံ'| HANDOVER[Diaog: Recipient info]
    HANDOVER -->|confirm| CWP
```

---

## 6. Refund Workflow

```mermaid
flowchart LR
    subgraph Entries
        APPBAR["AppBar IconButton<br/>(refund.view)"]
        DASH_Q["DashboardPage<br/>Quick Action<br/>(refund.view)"]
    end

    Entries --> RFL[RefundListPage]
    
    RFL -->|tap +| RCF[RefundCreatePage]
    RCF -->|select payment| RCF
    RCF -->|enter amount + reason| RCF
    RCF -->|submit| RCF_API{API call}
    RCF_API -->|success| RCF_DONE["Success view in RCF"]
    RCF_DONE -->|Back to List| RFL
    
    RFL -->|tap refund| RFD[RefundDetailPage]
    RFD -->|pull to refresh| RFD
    
    RFD -->|status = requested| RFD_ACTIONS{refund.approve?}
    RFD_ACTIONS -->|Approve| RFD_A["Dialog: approved amount"]
    RFD_ACTIONS -->|Reject| RFD_R["Dialog: rejection reason"]
    RFD_A -->|confirm| RFD
    RFD_R -->|confirm| RFD
    
    RFD -->|status = approved| RFD_PAID{refund.pay?}
    RFD_PAID -->|Mark Paid| RFD_P["Dialog: payout ref"]
    RFD_P -->|confirm| RFD
    
    RFD -->|status = paid| RFD_DONE{refund.complete?}
    RFD_DONE -->|Complete| RFD_C["Confirm dialog"]
    RFD_C -->|yes| RFD
```

---

## 7. Full Navigation Tree

```mermaid
flowchart TB
    APP[HbtBusinessApp]
    APP -->|loading| LOAD[LoadingScreen]
    APP -->|authenticated| BH[BusinessHome]
    APP -->|not auth| SI[SignInScreen]

    BH -->|AppBar| TABS{Tabs}
    TABS -->|0| DASH[DashboardPage]
    TABS -->|1| TS[TicketSalesPage]
    TABS -->|2| CW[CargoWorklistPage]
    TABS -->|3| SYNC[Sync Placeholder]

    DASH --> TR[Trips]
    DASH --> RT[Routes]
    DASH --> SC[Scanner]
    DASH --> NB[New Booking]
    DASH --> RF[Refunds]
    DASH --> PP[Pending Payments → Tab 1]

    BH -->|AppBar icon| TRL[TripListPage]
    BH -->|AppBar icon| RTL[RouteListPage]
    BH -->|AppBar icon| SCAN[TicketScannerScreen]
    BH -->|AppBar icon| RE[RefundListPage]

    TRL --> TD[TripDetailPage]
    TD --> NB
    RTL --> RD[RouteDetailPage]

    TS --> CB[CounterBookingPage]
    CB --> PD[PaymentDecisionPage]

    CW --> CA[CargoAcceptancePage]

    RE --> RC[RefundCreatePage]
    RE --> RFD[RefundDetailPage]

    BH -->|sign out| SI
```

---

## 8. Navigation Issues

| Issue | Type | Detail |
|-------|------|--------|
| **No splash screen** | Missing | Loading is an inline widget (not a route). On cold start, the session restore shows `CircularProgressIndicator` — no branding. |
| **No named routes** | Architecture | All navigation uses `Navigator.push(MaterialPageRoute(...))`. `routing/routes.dart` exists but is unused. |
| **Placeholder sync tab** | Dead end | Tab 3 shows "Sync and Pending Work is being connected to the API flow." — no navigation targets. |
| **Trip list from AppBar + Dashboard** | Duplicate entry | Trips and Routes are accessible from both the AppBar AND Dashboard quick actions. Same screen, two paths. |
| **Scanner from AppBar + Dashboard** | Duplicate entry | Same pattern. |
| **Refund from AppBar + Dashboard** | Duplicate entry | Same pattern. |
| **PaymentDecisionPage dead end** | UX gap | After tickets are issued, the user sees a ticket list but no "Back to Home" or "Print" action. Must use hardware back. |
| **No booking detail screen** | Missing | After creating a booking + fare quote in CounterBookingPage, the user sees a card tappable to PaymentDecision. But there's no independent booking detail screen showing full booking info. |
| **No ticket detail screen** | Missing | Tickets are shown as `AppListTileCard` with title + subtitle. No detail view with full info. |
| **No cargo detail screen** | Missing | Cargo shipments are shown as list items with status actions. No independent detail page. |
| **No offline entry point** | Missing | The sync tab is a placeholder. No way to view pending operations, retry failed syncs, or see conflicts. |
