# UI/UX Roadmap — MISK EWT ERP (2025-08-22)

Focus: polish Dashboard and core lists, then kick off the Public App.

Dashboard (Phase A)
- Live KPIs: users, initiatives, campaigns, open tasks, donations (confirmed/reconciled)
- Unified Recent Activities: events, announcements, donations, tasks (links to detail)
- My Tasks: quick status filters, “View all” link
- Permission gating: show/hide KPI tiles and sections by role/permissions
- Skeleton loaders + empty/error states across sections

Lists & Forms (Phase B)
- Shared components: CommonCard, FilterBar, MiskBadge (already rolling out)
- Consistent spacing/radii/shadows via theme tokens
- SearchInput everywhere, responsive filter bars
- Re-auth guardrails on sensitive actions

Public App (Phase C)
- Payment Settings-driven Donate flows: Bank/UPI/Razorpay
- Receipt submission (Bank/UPI) with reference + optional upload (backend adapter)
- Razorpay checkout (order → payment → callback update)
- Transparency: Confirmed vs Reconciled totals

Security & Stability (Phase D)
- Typed errors, friendly messages
- Firestore rules enforcing permissions
- Audit logging for sensitive changes

Success criteria
- No analyzer errors in modified areas
- No overflow in dashboard/list screens on narrow widths
- Dashboard reflects live data and navigates to detail pages
- Public App minimal donate journey works end-to-end

