# Store release design

The user approved implementation of the preceding code review and publication to the existing GitHub repository and Vercel. Keep Flutter, Firebase Auth, Firestore, Arabic/English and existing visual design. Work on codex/store-production in the existing checkout.

## Approach
Use a Vercel Node API alongside the Flutter web build. A trusted Firebase Admin service verifies ID tokens, reads authoritative Firestore products, and commits order creation, stock reservation and cart removal in one transaction. Retrying a checkout uses the same idempotency key. Client order writes and card storage are denied. Retain cash on delivery. Electronic payments and carrier tracking require the user's provider account and remain explicitly unavailable until configured; never simulate payment success.

## Requirements
Remove passwords/PAN/CVV from persisted models and logs. Supply a reviewed cleanup script for legacy data. Use one Firebase project with platform-specific app registrations. Make web startup independent of native notification plugins. Correct cache expiry, optional product sizes and bounded cart updates. Capture recipient, phone, street, building/unit, city, country and postal code. Add order details and cancellation/return requests, server-authorized status changes, administrator inventory/order screens, complete account deletion and token ownership. Provide accurate privacy/help screens, configuration guidance, tests and CI. Preserve existing users' accessible data where possible; legacy addresses require completion before checkout.

## External dependencies
Firebase Admin credentials, Firebase platform app registrations and authorized domains must be configured for the existing project. Obtain capabilities from connected accounts before asking for anything. Never copy credentials into Git. Do not invent a merchant, payment gateway, carrier, support address or successful live transaction.

## Acceptance
Flutter analysis, behavioral tests and web build pass. Backend tests exercise unauthenticated access, price manipulation, unavailable stock, duplicate requests and order transition restrictions. Firestore emulator tests exercise ownership and denial of financial/order writes. Publish source and verified build, check deployed routes, and disclose any external setup still blocking live commerce.
