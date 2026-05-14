# PROMPT 1 — FOUNDATION + CORE ARCHITECTURE + SAAS ENGINE

## Enterprise Multi-Tenant Shop Management SaaS Product

# PRODUCT OVERVIEW

You are building a world-class enterprise-grade multi-tenant Shop Management SaaS ecosystem using Flutter, Firebase, Isar local database, and scalable modular architecture.

The product must support:

* Multiple shop industries
* Offline-first architecture
* Dynamic feature activation
* Subscription-based feature control
* Cross-platform support
* White-label customization
* AI-ready modular architecture
* High scalability
* Clean enterprise-grade code
* Secure authentication
* Sync engine
* Owner super admin portal
* Dynamic dashboards
* Modular billing systems
* Local-first storage
* Cloud sync
* Analytics
* Device restriction system
* Razorpay payments
* Firebase-based backend
* Future enterprise migration capability

The product must look premium, modern, smooth, professional, ultra-fast, scalable, and production-ready.

The UI must feel comparable to:

* Shopify POS
* Notion
* Vyapar
* Zoho
* GoFrugal
* Petpooja
* Stripe Dashboard

The system must support:

* Android
* iOS
* Windows
* macOS
* Web

Use clean architecture everywhere.

---

# GLOBAL ENGINEERING RULES

## Rule 1

Never place business logic inside UI.

## Rule 2

Use modular architecture.

## Rule 3

Every feature must support future scalability.

## Rule 4

Every screen must support:

* loading state
* error state
* empty state
* retry state
* offline state

## Rule 5

Every API call must support:

* retry
* timeout
* logging
* exception handling

## Rule 6

Every module must be independently replaceable.

## Rule 7

The product must work smoothly even with poor internet.

## Rule 8

Offline-first architecture is mandatory.

## Rule 9

Avoid unnecessary Firebase reads.

## Rule 10

All feature access must be controlled dynamically from owner portal.

---

# PHASE 1 — PRODUCT FOUNDATION

## Objective

Create the core foundation for the entire SaaS ecosystem.

## Main Goals

Build:

* product vision
* architecture blueprint
* scalable project structure
* coding standards
* UI system
* naming conventions
* core dependency structure

---

## Product Identity

Product Type:
Enterprise Retail Operating System.

Core Product Philosophy:

"One Core Engine. Unlimited Shop Types."

Target Audience:

* Kirana stores
* Pharmacies
* Garments
* Electronics
* Jewellery
* Bakeries
* Salons
* Restaurants
* Wholesale shops
* Multi-branch retail businesses

---

## Core Product Pillars

### Pillar 1

Offline-first experience.

### Pillar 2

Ultra-fast billing.

### Pillar 3

Dynamic feature system.

### Pillar 4

Subscription-controlled modules.

### Pillar 5

Cross-platform consistency.

### Pillar 6

Shop-type intelligent workflows.

### Pillar 7

Simple UI for non-technical users.

### Pillar 8

Enterprise scalability.

---

## Product Layers

### Layer 1

Marketing Website

### Layer 2

Owner Super Admin Portal

### Layer 3

User Shop Application

### Layer 4

Sync Engine

### Layer 5

Analytics System

### Layer 6

Subscription Engine

### Layer 7

Notification System

### Layer 8

AI Engine

---

## Technology Stack

### Frontend

Flutter

### Backend

Firebase

### Local Database

Isar

### State Management

Riverpod

### Navigation

GoRouter

### Dependency Injection

Riverpod Providers

### Payments

Razorpay

### Notifications

Firebase Cloud Messaging

### Analytics

Firebase Analytics

### Crash Reporting

Firebase Crashlytics

### Cloud Functions

Firebase Functions

---

## Flutter Version Standards

Use latest stable Flutter version.

Requirements:

* sound null safety
* latest Dart stable
* Material 3
* adaptive layouts
* responsive UI

---

## Folder Structure

```txt
apps/
 ├── owner_portal/
 ├── user_app/
 ├── website/

packages/
 ├── core/
 ├── ui_kit/
 ├── auth/
 ├── billing/
 ├── inventory/
 ├── subscriptions/
 ├── sync_engine/
 ├── analytics/
 ├── notifications/
 ├── reporting/
 ├── printers/
 ├── offline_storage/
 ├── feature_flags/
 ├── shop_types/
 ├── shared_models/
```

---

## Core Coding Standards

### Naming

Classes:
PascalCase

Variables:
camelCase

Constants:
UPPER_SNAKE_CASE

Files:
snake_case

---

## UI Standards

### Design Goals

* modern
* premium
* minimal
* ultra-clean
* touch friendly
* keyboard friendly
* responsive

### Border Radius

Use consistent radius system.

### Typography

Use scalable typography.

### Colors

Support:

* light mode
* dark mode
* dynamic theme

### Animations

Use subtle animations.

Avoid heavy animations.

---

## Performance Rules

Never:

* rebuild unnecessary widgets
* stream huge collections
* load large datasets directly
* block UI thread

Always:

* paginate
* lazy load
* cache
* use isolates where needed

---

# PHASE 2 — MULTI-TENANT SAAS ARCHITECTURE

## Objective

Build scalable SaaS tenant architecture.

---

## Tenant Definition

A tenant represents one business/shop.

Each tenant has:

* subscription
* settings
* modules
* users
* branches
* permissions
* branding
* analytics

---

## Tenant Isolation Strategy

Use tenant-based data separation.

Example:

```txt
/tenants/{tenantId}
```

Every collection must contain:

```txt
tenantId
```

---

## Tenant Collections

### Collections

```txt
users
shops
subscriptions
plans
feature_flags
branches
products
bills
inventory
customers
vendors
reports
analytics
notifications
```

---

## Tenant Security

All Firestore rules must validate:

* authenticated user
* tenant ownership
* permissions
* subscription validity

---

## Tenant Feature Activation

Each tenant has:

```json
{
  "billing": true,
  "inventory": true,
  "crm": false,
  "multiBranch": false
}
```

Feature flags must dynamically control:

* UI visibility
* routes
* APIs
* modules
* permissions

---

## Subscription-Aware Rendering

When user logs in:

System must:

1. Fetch tenant config
2. Fetch subscription
3. Fetch feature flags
4. Cache locally
5. Build dynamic UI

---

## Dynamic Sidebar

Sidebar menu generated dynamically.

Example:

If inventory disabled:
Do not show inventory menu.

---

## Device Control System

Each tenant has:

* max devices
* active sessions
* hardware identifiers
* login restrictions

---

## Session Management

Support:

* remote logout
* session expiry
* suspicious login detection
* forced re-authentication

---

# PHASE 3 — FIREBASE BACKEND ARCHITECTURE

## Objective

Design scalable Firebase architecture.

---

## Firebase Services

Use:

### Firebase Auth

Authentication.

### Firestore

Cloud database.

### Firebase Storage

Files/images.

### Cloud Functions

Backend logic.

### Firebase Analytics

Usage analytics.

### Firebase Crashlytics

Crash tracking.

### Firebase Messaging

Notifications.

### Remote Config

Dynamic app config.

---

## Firebase Authentication

Support:

* email login
* mobile OTP
* Google login
* role-based login

---

## Firestore Rules

Rules must:

* validate tenant
* validate role
* validate subscription
* prevent unauthorized access

---

## Firestore Optimization Rules

Avoid:

* huge nested collections
* realtime everywhere
* large unindexed queries

Always:

* index queries
* paginate
* cache locally

---

## Firebase Cloud Functions

Use functions for:

* subscription verification
* Razorpay verification
* feature activation
* analytics processing
* scheduled tasks
* notifications
* cleanup jobs

---

## Firebase Remote Config

Use for:

* maintenance mode
* app colors
* feature toggles
* banners
* announcements
* UI changes

---

## Firebase Storage

Store:

* logos
* invoices
* reports
* backups
* product images

---

## Firebase Analytics Events

Track:

* app_open
* bill_created
* sync_completed
* subscription_renewed
* crash_detected
* feature_used

---

# PHASE 4 — FLUTTER APPLICATION ARCHITECTURE

## Objective

Build scalable Flutter codebase.

---

## Architecture Style

Use:
Clean Architecture.

Layers:

```txt
presentation/
domain/
data/
```

---

## Presentation Layer

Contains:

* screens
* widgets
* providers
* controllers

---

## Domain Layer

Contains:

* entities
* use cases
* repositories

---

## Data Layer

Contains:

* models
* services
* local database
* remote APIs
* repository implementations

---

## State Management

Use Riverpod.

Avoid:

* global mutable state
* direct Firebase calls in UI

---

## Routing

Use GoRouter.

Support:

* role-based routes
* auth guards
* subscription guards
* feature guards

---

## Error Handling

Create unified error model.

Every error must contain:

* code
* message
* stack trace
* source

---

## Logging System

Create centralized logger.

Support:

* info logs
* warning logs
* error logs
* sync logs

---

## Reusable UI System

Build reusable:

* buttons
* cards
* dialogs
* inputs
* loaders
* snackbars
* tables
* charts

---

## Theme Engine

Support:

* dark mode
* light mode
* dynamic brand colors

---

# PHASE 5 — OFFLINE-FIRST ENGINE

## Objective

Ensure app works without internet.

---

## Local Database

Use Isar.

---

## Local Data Storage

Store locally:

* products
* bills
* inventory
* customers
* settings
* reports
* cached analytics

---

## Offline Billing Flow

When internet unavailable:

1. Save bill locally
2. Update local stock
3. Queue sync job
4. Mark pending sync
5. Sync later automatically

---

## Sync Queue System

Need:

* upload queue
* retry queue
* conflict queue
* failure queue

---

## Conflict Resolution

Rules:

* latest timestamp wins
* prevent duplicate bills
* maintain stock integrity

---

## Background Sync

When internet restored:

* detect connectivity
* process queue
* upload data
* update sync status

---

## Offline UI Indicators

Show:

* offline banner
* sync progress
* pending upload count

---

## Local Backup System

Support:

* export backup
* encrypted backup
* restore backup

---

# PHASE 6 — OWNER SUPER ADMIN PORTAL

## Objective

Create SaaS control center.

---

## Dashboard Features

Show:

* active tenants
* active users
* monthly revenue
* daily sales
* subscription stats
* crash reports
* sync failures

---

## Tenant Management

Support:

* create tenant
* edit tenant
* suspend tenant
* delete tenant
* activate modules
* manage devices

---

## Plan Management

Create:

* trial plans
* monthly plans
* yearly plans
* lifetime plans

Each plan controls:

* features
* devices
* branches
* storage
* employees

---

## Feature Flag Management

Enable/disable features dynamically.

---

## Notification Management

Send:

* updates
* maintenance alerts
* renewal reminders
* offers

---

## Support Dashboard

Manage:

* tickets
* customer issues
* crash logs
* sync issues

---

## Analytics Dashboard

Track:

* most used modules
* highest revenue shops
* feature popularity
* user retention

---

# PHASE 7 — USER SHOP APPLICATION

## Objective

Create powerful shop management app.

---

## Core Modules

### Billing

### Inventory

### Customers

### Vendors

### Reports

### Employees

### Settings

---

## Billing Engine Requirements

Must support:

* barcode scan
* GST
* thermal printing
* discount
* credit billing
* returns
* exchange

---

## Inventory Requirements

Support:

* stock in
* stock out
* low stock alerts
* expiry tracking
* supplier management

---

## Customer System

Support:

* loyalty points
* credit tracking
* WhatsApp invoices
* purchase history

---

## Reports

Generate:

* sales reports
* stock reports
* tax reports
* employee reports
* branch reports

---

## Printer Support

Support:

* bluetooth printer
* USB printer
* thermal printer

---

# PHASE 8 — SHOP TYPE MODULE SYSTEM

## Objective

Build industry-specific modules.

---

## Kirana Features

Need:

* loose item billing
* weighing support
* fast billing
* UPI QR

---

## Pharmacy Features

Need:

* batch tracking
* expiry tracking
* prescription upload
* medicine schedule tracking

---

## Garments Features

Need:

* size matrix
* color variants
* exchange management

---

## Jewellery Features

Need:

* gold rate
* purity tracking
* making charges
* wastage tracking

---

## Bakery Features

Need:

* batch production
* expiry dates
* morning/evening rates

---

## Salon Features

Need:

* appointment booking
* beautician assignment
* package management

---

# PHASE 9 — SECURITY + TESTING + QUALITY

## Objective

Ensure enterprise-grade stability.

---

## Security Rules

Must implement:

* encrypted storage
* secure auth
* JWT validation
* device binding
* role permissions
* audit logs

---

## Testing Types

### Unit Testing

### Widget Testing

### Integration Testing

### Sync Testing

### Offline Testing

### Load Testing

### Payment Testing

---

## Error Monitoring

Use:
Firebase Crashlytics.

Track:

* crashes
* sync failures
* API failures
* UI errors

---

## QA Checklist

Every screen must test:

* loading
* errors
* offline
* retries
* responsiveness

---

## Performance Benchmarks

Billing screen open:
< 1 second.

Product search:
instant.

Sync:
background optimized.

---

# PHASE 10 — DEPLOYMENT + SCALING + FUTURE ROADMAP

## Objective

Prepare product for production launch.

---

## CI/CD

Use:
GitHub Actions.

Automate:

* testing
* builds
* deployments

---

## Firebase Environments

Create:

* development
* staging
* production

---

## Release Workflow

Steps:

1. development
2. QA testing
3. staging deploy
4. production deploy

---

## Backup Strategy

Need:

* daily backup
* encrypted backup
* restore testing

---

## Monitoring System

Track:

* app crashes
* sync failures
* API latency
* Firebase usage

---

## Future Scalability

Future support:

* AI assistant
* plugin marketplace
* multi-language
* enterprise APIs
* warehouse management
* ERP integrations
* accounting integrations
* ecommerce integrations

---

# FINAL PRODUCT RULES

The final product must:

* feel premium
* work offline
* sync reliably
* scale smoothly
* support thousands of shops
* maintain clean architecture
* support modular upgrades
* support dynamic feature activation
* support future enterprise expansion

Never compromise:

* performance
* stability
* maintainability
* security
* billing speed
* offline support

The product should become one of the best retail SaaS systems in India.
