# Codebase Overview

## Summary
This repository is a **Flutter + Firebase rental-management app** (`lozido_app`) with two roles:
- **Landlord**: manage houses, rooms, contracts, invoices, deposits, services, assets, vehicles, chat, notifications.
- **Tenant**: view room/contract/invoices, chat, profile.

It also includes **Firebase Cloud Functions** for:
- Zalo invoice notifications.
- AI chatbot auto-replies (Gemini + Firestore RAG).

## Tech Stack
- Flutter (Dart)
- Firebase Auth, Cloud Firestore, Firebase Storage
- Firebase Cloud Functions (Node.js + Python)
- Gemini API (`google_generative_ai` in app; `google.generativeai` in Python functions)

## App Bootstrap and Routing
- Entry point initializes Firebase and Vietnamese locale formatting, then launches `AuthWrapper`.
- `AuthWrapper` listens to auth state, resolves role from Firestore, and routes to:
  - `MainPage` (Landlord)
  - `TenantMainPage` (Tenant)

Key files:
- `lib/main.dart`
- `lib/presentation/pages/auth/auth_wrapper.dart`

## Architecture Reality vs README
`README.md` describes Clean Architecture, but current implementation is mostly:
- Feature-page-driven UI.
- Direct Firestore reads/writes inside pages.
- Service layer used for cross-cutting concerns (chat, notifications, Gemini).

Core services:
- `lib/services/chat_service.dart`
- `lib/services/notification_service.dart`
- `lib/services/gemini_service.dart`

## Main UI Structure
- Landlord shell and bottom navigation:
  - `lib/presentation/pages/main_screen/main_page.dart`
- Main landlord dashboard and management hub:
  - `lib/presentation/pages/home/home_page.dart`
- Tenant shell and tab structure:
  - `lib/presentation/pages/tenant/tenant_main_page.dart`

## Messaging and Notifications
### Chat
- Firestore path: `chatRooms/{roomId}/messages/{messageId}`
- `ChatService` handles:
  - room creation
  - message send/listen
  - unread counts
  - active users in room
  - notify non-active participants

### Notifications
- Firestore collection: `notifications`
- `NotificationService` handles:
  - create notifications
  - stream by user
  - mark read / mark all read

Mail UI:
- `lib/presentation/pages/home/mail_page.dart`

## AI Features in App
`GeminiService` provides:
- Parse invoice adjustments from natural language into structured JSON.
- Parse contract/ID documents into structured fields.

Configuration:
- Gemini API key loaded from Firestore document: `config/gemini`.

File:
- `lib/services/gemini_service.dart`

## Cloud Functions (`functions/`)
### Node.js Functions
File: `functions/index.js`
- Firestore trigger on invoice creation:
  - `houses/{houseid}/invoices/{invoiceId}`
  - builds invoice message and sends to Zalo Bot API.
- HTTPS webhook:
  - receives Zalo messages.
  - processes `ketnoi + phone` flow to link `zaloUid` to active contracts/rooms.
- Setup endpoint:
  - registers webhook URL with Zalo platform.

### Python Functions
Files:
- `functions/chatbot/main.py`
- `functions/chatbot/chatbot_reply.py`
- `functions/chatbot/database_tools.py`

Behavior:
- Trigger on new message in `chatRooms/{roomId}/messages/{messageId}`.
- Only auto-reply in room named `Lozido CSKH`.
- Uses Gemini embedding + Firestore vector search (`chunks`) for context.
- Applies role-aware behavior:
  - Landlord can access tool functions (`get_houses_list`, `get_rooms_status`, `get_unpaid_invoices`).
  - Tenant gets restricted/general responses.

## Firestore Data Model (High-Level)
Top-level collections:
- `users`
- `tenants`
- `houses`
- `chatRooms`
- `notifications`
- `config`

Typical subcollections under each house:
- `rooms`
- `contracts`
- `invoices`
- `deposits`
- `transactions`
- `services`
- `assets`
- `vehicles`

## Important Notes
- Role resolution checks `users` first, then `tenants`.
- Some naming is inconsistent (`houseName` / `propertyName` / `name`) and handled defensively in UI/functions.
- Several screens are very large and tightly coupled to Firestore operations; refactoring opportunities exist if stricter layering is needed.

## Suggested Next Documentation
If needed, add a second doc with:
- Collection-by-collection schema (required/optional fields).
- Page-to-collection write matrix (who writes what).
- Index requirements for Firestore queries.
