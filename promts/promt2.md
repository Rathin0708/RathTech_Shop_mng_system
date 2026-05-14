# PROMPT 2 — OWNER SUPER ADMIN PORTAL + SUBSCRIPTION ENGINE + FEATURE CONTROL SYSTEM

## Enterprise Multi-Tenant SaaS Control Center

# PRODUCT CONTEXT

This document defines the complete enterprise architecture and implementation instructions for the Owner Super Admin Portal of the multi-tenant Shop Management SaaS ecosystem.

The Owner Portal is the brain of the entire platform.

This portal controls:

* tenants
* subscriptions
* plans
* feature flags
* devices
* analytics
* payments
* support
* notifications
* app customization
* shop-type modules
* Firebase tenant onboarding
* AI configuration
* reports
* SaaS growth metrics
* revenue tracking

The system must feel comparable to:

* Stripe Dashboard
* Shopify Admin
* Zoho Admin Panels
* Firebase Console
* AWS Console

The owner portal must be:

* modern
* responsive
* ultra-fast
* highly secure
* scalable
* modular
* analytics-driven
* easy to manage

Use Flutter Web.

Use clean architecture.

---

# GLOBAL RULES

## Rule 1

All actions must be role-protected.

## Rule 2

All data changes must create audit logs.

## Rule 3

All feature changes must sync dynamically.

## Rule 4

Every table must support:

* pagination
* sorting
* searching
* filtering
* exporting

## Rule 5

All dangerous actions require confirmation.

## Rule 6

Every module must support future enterprise scaling.

## Rule 7

Never hardcode features.

## Rule 8

All plans must be configurable dynamically.

## Rule 9

Owner portal must support real-time monitoring.

## Rule 10

System must support future white-label SaaS.

---

# PHASE 1 — OWNER PORTAL FOUNDATION

## Objective

Build the core structure of the owner admin system.

---

## Main Layout

Create:

* responsive sidebar
* top navigation
* notifications panel
* analytics header
* dynamic content area
* profile menu

---

## Sidebar Features

Sidebar must support:

* collapsible mode
* mobile drawer
* role-based menus
* dynamic feature visibility
* icons
* active route highlighting

---

## Top Bar

Include:

* global search
* notifications
* profile avatar
* dark mode toggle
* language switch
* quick actions

---

## Dashboard Layout

Dashboard must contain:

* KPI cards
* charts
* recent activity
* revenue widgets
* subscription widgets
* alerts

---

## Dashboard Cards

Examples:

* total tenants
* active subscriptions
* monthly recurring revenue
* active devices
* daily transactions
* failed payments
* sync failures
* crashes

---

## Responsive Design

Support:

* desktop
* tablet
* mobile web

---

## Theme System

Support:

* light mode
* dark mode
* custom brand colors

---

# PHASE 2 — AUTHENTICATION + ACCESS CONTROL

## Objective

Create enterprise-grade authentication system.

---

## Authentication Methods

Support:

* email login
* Google login
* OTP verification
* MFA support later

---

## Access Roles

Create roles:

* Super Owner
* Admin
* Support Staff
* Finance Manager
* Sales Manager
* Technical Team
* Read-Only Analyst

---

## Permission System

Each role must have:

* module permissions
* screen permissions
* action permissions
* export permissions

---

## Session Security

Implement:

* secure sessions
* auto logout
* session expiry
* suspicious login detection
* IP/device tracking

---

## Login Logs

Track:

* login time
* IP
* device
* browser
* failed attempts

---

## Audit Logs

Every admin action must log:

* user
* action
* timestamp
* module
* changes

---

# PHASE 3 — TENANT MANAGEMENT SYSTEM

## Objective

Manage all business tenants.

---

## Tenant Creation

Admin can:

* create tenant
* assign plan
* assign modules
* assign shop type
* set device limits
* set branch limits
* activate trial

---

## Tenant Profile

Store:

* business name
* owner details
* GST number
* phone number
* email
* address
* logo
* shop category
* branch count

---

## Tenant Status

Possible statuses:

* active
* suspended
* expired
* trial
* blocked

---

## Tenant Search

Support:

* global search
* filter by plan
* filter by status
* filter by revenue
* filter by region

---

## Tenant Details Screen

Show:

* subscription info
* devices
* branches
* storage usage
* billing volume
* active users
* support history

---

## Tenant Actions

Support:

* suspend tenant
* renew plan
* reset devices
* disable features
* force logout users
* upgrade plan

---

## Tenant Analytics

Track:

* daily sales
* active sessions
* module usage
* sync health
* crash count

---

# PHASE 4 — SUBSCRIPTION ENGINE

## Objective

Build powerful SaaS monetization engine.

---

## Subscription Types

Support:

* free trial
* monthly
* yearly
* lifetime
* custom enterprise

---

## Plan Features

Each plan can control:

* features
* modules
* branches
* employees
* storage
* API access
* device count
* analytics level

---

## Dynamic Plan Builder

Admin can:

* create plans
* edit plans
* clone plans
* archive plans
* create promotional plans

---

## Trial System

Support:

* limited duration
* limited features
* auto-expiry
* upgrade prompts

---

## Upgrade System

Support:

* upgrade anytime
* downgrade anytime
* prorated calculation later

---

## Renewal Engine

Need:

* auto reminders
* expiry alerts
* grace periods
* failed payment retry

---

## Coupons & Offers

Support:

* percentage discounts
* flat discounts
* referral offers
* festive campaigns

---

## Revenue Tracking

Track:

* monthly recurring revenue
* annual recurring revenue
* lifetime revenue
* churn rate
* active subscribers

---

# PHASE 5 — FEATURE FLAG ENGINE

## Objective

Create dynamic feature control system.

---

## Feature Flag Philosophy

Every feature must be dynamically controllable.

Nothing hardcoded.

---

## Feature Categories

Examples:

* billing
* inventory
* CRM
* reports
* analytics
* AI
* multi branch
* printer support
* loyalty system
* employee system

---

## Feature Rules

Each feature contains:

* name
* description
* dependencies
* enabled state
* plan eligibility

---

## Dynamic UI Rendering

If feature disabled:

* hide menu
* disable routes
* block APIs
* disable actions

---

## Runtime Updates

Feature changes should apply instantly.

No app update required.

---

## Remote Config Integration

Use Firebase Remote Config for:

* app banners
* maintenance mode
* announcements
* feature experiments

---

## Beta Features

Support:

* beta rollout
* selective rollout
* A/B testing later

---

# PHASE 6 — DEVICE CONTROL SYSTEM

## Objective

Control subscription-based device access.

---

## Device Registration

Store:

* device ID
* model
* OS
* app version
* login time

---

## Device Limits

Each subscription defines:

* max devices
* simultaneous sessions

---

## Device Actions

Admin can:

* revoke device
* force logout
* reset all devices
* block suspicious device

---

## Security Checks

Detect:

* multiple suspicious logins
* rapid device switching
* token abuse

---

## Device Analytics

Track:

* active devices
* inactive devices
* device usage trends

---

# PHASE 7 — ANALYTICS + BUSINESS INTELLIGENCE

## Objective

Create enterprise SaaS analytics engine.

---

## Global Analytics Dashboard

Show:

* revenue trends
* user growth
* plan growth
* churn rate
* top regions
* top shop categories

---

## SaaS Metrics

Track:

* MRR
* ARR
* CAC later
* retention rate
* DAU
* MAU
* subscription conversion

---

## Feature Analytics

Track:

* most used features
* least used features
* module popularity
* feature retention

---

## Crash Analytics

Integrate:

* Firebase Crashlytics

Track:

* crash frequency
* affected tenants
* crash sources

---

## Sync Analytics

Track:

* sync failures
* pending queues
* upload latency

---

## Billing Analytics

Track:

* daily bill count
* average bill value
* transaction trends

---

## Charts

Support:

* line charts
* bar charts
* pie charts
* heatmaps later

---

# PHASE 8 — PAYMENT + RAZORPAY SYSTEM

## Objective

Build secure payment infrastructure.

---

## Payment Gateway

Use:

* Razorpay

---

## Payment Flows

Support:

* subscription purchase
* renewal
* upgrade
* add-on purchases

---

## Webhook Verification

Use Firebase Functions.

Verify:

* successful payment
* failed payment
* refunds
* subscription renewal

---

## Invoice System

Generate:

* GST invoices
* PDF receipts
* payment history

---

## Failed Payment Recovery

Support:

* retry
* reminders
* grace period

---

## Transaction Logs

Track:

* payment ID
* tenant ID
* amount
* method
* status

---

## Financial Reports

Generate:

* revenue reports
* tax reports
* payout reports

---

# PHASE 9 — SUPPORT + CRM + NOTIFICATION SYSTEM

## Objective

Build SaaS customer support ecosystem.

---

## Support Ticket System

Support:

* create ticket
* assign priority
* assign staff
* resolve ticket
* attachments

---

## Ticket Categories

Examples:

* billing issue
* sync issue
* payment issue
* bug report
* feature request

---

## CRM Features

Track:

* lead status
* onboarding progress
* renewal reminders
* customer communication

---

## Notification System

Send:

* push notifications
* email notifications later
* renewal alerts
* maintenance alerts
* announcements

---

## Notification Templates

Create reusable templates.

---

## Campaign System

Support future:

* marketing campaigns
* festive offers
* referral campaigns

---

# PHASE 10 — WHITE-LABEL + FUTURE SCALING

## Objective

Prepare platform for enterprise expansion.

---

## White-Label Support

Allow:

* custom logo
* custom colors
* custom app name
* custom domain later

---

## Dynamic Branding

Use Remote Config.

---

## Dedicated Backend Support

Future support:

* client Firebase projects
* custom backend connections
* enterprise APIs

---

## Marketplace Preparation

Future plugin system:

* WhatsApp integrations
* accounting integrations
* AI plugins
* ERP plugins

---

## API Readiness

Prepare:

* REST APIs
* webhooks
* external integrations

---

## Scalability Rules

System must support:

* thousands of tenants
* millions of transactions
* high concurrency

---

## Final Owner Portal Goals

The owner portal must become:

* the brain of the SaaS
* a fully scalable admin ecosystem
* highly secure
* analytics-driven
* subscription-powered
* modular
* enterprise-ready

The final experience must feel:

* premium
* smooth
* fast
* modern
* reliable
* scalable

The system should be capable of supporting a future multi-crore SaaS comp
