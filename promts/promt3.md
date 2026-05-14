# PROMPT 3 — USER SHOP APPLICATION + BILLING ENGINE + INVENTORY SYSTEM

## Enterprise Multi-Shop POS + Retail Operating Application

# PRODUCT CONTEXT

This document defines the complete architecture and implementation plan for the User Shop Application of the SaaS ecosystem.

The User App is the actual shop management application used daily by business owners, cashiers, managers, accountants, and staff.

This application must support:

* ultra-fast billing
* offline-first operations
* inventory management
* barcode support
* printer integrations
* customer management
* vendor management
* employee management
* reports
* analytics
* subscription-based feature unlocking
* shop-type intelligent workflows
* dynamic dashboard rendering
* local-first architecture
* background sync

The application must feel:

* extremely fast
* premium
* smooth
* modern
* simple for non-technical users
* optimized for touch and keyboard

Comparable quality:

* Shopify POS
* Vyapar
* GoFrugal
* Petpooja
* Zoho Inventory

---

# GLOBAL RULES

## Rule 1

Billing speed is top priority.

## Rule 2

App must work without internet.

## Rule 3

Never block UI during billing.

## Rule 4

Every transaction must be recoverable.

## Rule 5

All business-critical data must save locally first.

## Rule 6

Subscription restrictions must apply dynamically.

## Rule 7

All modules must support future scaling.

## Rule 8

All screens must support:

* loading
* error
* offline
* retry
* empty states

## Rule 9

Avoid unnecessary sync calls.

## Rule 10

The app must support low-end devices smoothly.

---

# PHASE 1 — USER APPLICATION FOUNDATION

## Objective

Create scalable cross-platform user application.

---

## Platforms

Support:

* Android
* iOS later
* Windows
* macOS
* Web later

---

## Application Structure

Use:

* Flutter
* Riverpod
* GoRouter
* Isar Database
* Firebase

---

## Architecture

Use clean architecture.

Layers:

```txt
presentation/
domain/
data/
```

---

## Startup Flow

App startup sequence:

1. Splash screen
2. Connectivity check
3. Auth validation
4. Tenant config fetch
5. Subscription validation
6. Feature flag sync
7. Local DB initialization
8. Sync queue initialization
9. Dashboard launch

---

## Dynamic Module Loading

Modules shown based on:

* subscription
* role
* shop type
* feature flags

---

## Core Modules

Create:

* dashboard
* billing
* products
* inventory
* customers
* vendors
* reports
* employees
* settings
* sync manager

---

# PHASE 2 — AUTH + STAFF + ROLE SYSTEM

## Objective

Build secure shop-level access system.

---

## Login Methods

Support:

* email login
* mobile login
* OTP login later

---

## Staff Roles

Create:

* Shop Owner
* Manager
* Cashier
* Accountant
* Inventory Staff
* Delivery Staff

---

## Permissions

Control:

* billing access
* inventory access
* report access
* edit permissions
* refund permissions
* customer data access

---

## Device Security

Support:

* device binding
* session validation
* remote logout

---

## Local User Profiles

Store locally:

* role
* permissions
* branch access
* login session

---

## Audit Logs

Track:

* bill edits
* refunds
* stock changes
* login events

---

# PHASE 3 — DASHBOARD SYSTEM

## Objective

Build dynamic business dashboard.

---

## Dashboard Personalization

Dashboard changes based on:

* shop type
* subscription plan
* staff role

---

## Dashboard Cards

Examples:

* today sales
* pending payments
* low stock
* top products
* recent bills
* customer dues
* sync status

---

## Dashboard Charts

Support:

* sales trends
* profit trends
* stock trends
* category analytics

---

## Quick Actions

Include:

* new bill
* add product
* add customer
* purchase entry
* stock update

---

## Offline Indicators

Show:

* internet status
* pending sync count
* sync health

---

# PHASE 4 — BILLING ENGINE

## Objective

Build ultra-fast POS billing system.

---

## Billing Priorities

The billing engine must:

* open instantly
* search instantly
* work offline
* support barcode scanning
* support keyboard shortcuts

---

## Billing Modes

Support:

* retail billing
* wholesale billing
* credit billing
* quick billing

---

## Billing Features

Include:

* barcode scan
* GST calculations
* discounts
* coupon codes
* multiple payment methods
* split payments later
* customer selection
* invoice notes

---

## Product Search

Search by:

* name
* barcode
* SKU
* category

Search must feel instant.

---

## Cart Features

Support:

* quantity update
* discounts
* notes
* tax calculation
* item removal

---

## Payment Modes

Support:

* cash
* UPI
* card
* credit
* mixed payments later

---

## Invoice Generation

Generate:

* thermal bill
* A4 invoice
* GST invoice

---

## Return & Exchange

Support:

* partial return
* full return
* exchange
* refund tracking

---

## Billing Shortcuts

Implement keyboard shortcuts.

Example:

* F1 new bill
* F2 search
* F3 payment
* F4 print

---

## Billing Recovery

If crash occurs:

* restore cart automatically
* recover pending bill

---

## Bill Number System

Support:

* branch prefix
* financial year sequence
* custom format

---

# PHASE 5 — PRODUCT + INVENTORY MANAGEMENT

## Objective

Build scalable inventory system.

---

## Product Model

Each product supports:

* barcode
* SKU
* category
* unit
* tax
* images
* variants
* stock
* price

---

## Variant System

Support:

* size variants
* color variants
* weight variants

---

## Stock Management

Support:

* stock in
* stock out
* stock adjustment
* branch transfer later

---

## Purchase Entry

Support:

* vendor selection
* purchase invoices
* GST purchase
* expiry tracking

---

## Low Stock Alerts

Notify when:

* stock below threshold

---

## Expiry Tracking

Support:

* expiry alerts
* batch expiry
* expired stock filtering

---

## Barcode System

Support:

* barcode generation
* barcode printing
* barcode scanning

---

## Inventory Reports

Generate:

* stock reports
* valuation reports
* dead stock reports

---

# PHASE 6 — CUSTOMER + VENDOR + CREDIT SYSTEM

## Objective

Build customer relationship ecosystem.

---

## Customer Features

Support:

* customer profiles
* loyalty points
* credit balance
* purchase history
* WhatsApp invoices later

---

## Customer Categories

Examples:

* retail customer
* wholesale customer
* VIP customer

---

## Credit Tracking

Support:

* pending dues
* payment history
* reminders

---

## Vendor Features

Support:

* vendor profiles
* purchase history
* due tracking
* contact details

---

## Loyalty System

Support:

* points
* rewards
* customer retention campaigns later

---

## Customer Analytics

Track:

* repeat customers
* top buyers
* average spending

---

# PHASE 7 — REPORTS + ANALYTICS SYSTEM

## Objective

Create powerful business reporting engine.

---

## Reports

Generate:

* sales report
* profit report
* stock report
* tax report
* employee report
* purchase report
* credit report

---

## Filters

Support:

* date filter
* branch filter
* employee filter
* category filter

---

## Export Formats

Support:

* PDF
* Excel
* CSV later

---

## Dashboard Analytics

Show:

* sales trends
* best products
* top customers
* slow-moving stock

---

## Report Performance

Reports must:

* load quickly
* support pagination
* avoid memory issues

---

# PHASE 8 — PRINTER + HARDWARE INTEGRATION

## Objective

Support real retail hardware ecosystem.

---

## Printer Support

Support:

* thermal printer
* Bluetooth printer
* USB printer
* network printer later

---

## Print Templates

Support:

* customizable templates
* logo printing
* GST format

---

## Barcode Scanner Support

Support:

* hardware scanner
* camera scanner later

---

## Weighing Scale Support

Support later:

* serial port integration
* USB integration

---

## Cash Drawer Support

Future support:

* automatic drawer opening

---

# PHASE 9 — SHOP TYPE SPECIALIZED MODULES

## Objective

Build intelligent industry workflows.

---

## Kirana Features

Need:

* loose item billing
* fast billing
* weighing support
* credit book
* packet/loose billing

---

## Pharmacy Features

Need:

* batch tracking
* prescription upload
* expiry management
* medicine schedules
* doctor references later

---

## Garments Features

Need:

* size matrix
* color variants
* exchange workflows
* trial room token later

---

## Jewellery Features

Need:

* live gold rates later
* making charges
* wastage tracking
* purity tracking

---

## Bakery Features

Need:

* production batches
* expiry dates
* perishables management

---

## Electronics Features

Need:

* serial numbers
* warranty tracking
* repair tracking later

---

## Salon Features

Need:

* appointment booking
* beautician assignment
* package management

---

# PHASE 10 — PERFORMANCE + UX + FUTURE READINESS

## Objective

Prepare app for production scale.

---

## Performance Rules

Billing screen:

Must load instantly.

Product search:

Must feel real-time.

---

## Optimization Rules

Use:

* lazy loading
* pagination
* local caching
* indexing

Avoid:

* large widget rebuilds
* heavy Firebase listeners

---

## Offline Reliability

App must:

* continue working offline
* prevent data loss
* retry sync automatically

---

## Error Handling

Every operation must support:

* retries
* recovery
* logging
* offline fallback

---

## UI Experience Goals

The app must feel:

* modern
* premium
* stable
* smooth
* touch-friendly
* keyboard-friendly

---

## Accessibility

Support:

* scalable text
* responsive layouts
* readable UI

---

## Future Scalability

Prepare for:

* multi-branch
* warehouse management
* ecommerce integration
* AI insights
* WhatsApp automation
* plugin marketplace
* enterprise APIs

---

## Final Product Goals

The User Shop Application must become:

* one of the fastest retail billing systems
* reliable offline POS software
* modular SaaS-powered business platform
* scalable enterprise-ready retail ecosystem

The final app must:

* support thousands of shops
* work smoothly on low-end devices
* scale without architecture issues
* provide excellent user experience
* maintain high billing speed
* prevent data loss
* support future AI expansion

The final experience should feel professional, premium, and enterprise-grade.
