# Verve Store

Flutter storefront with Arabic/English, Firebase authentication and private data, and a Vercel Node API for trusted order processing.

[Open the web store](https://verve-store-delta.vercel.app/) · [Download the Android test APK](https://verve-store-delta.vercel.app/download/android)

## Store catalog

Verve Store serves fashion, groceries/market, home, beauty and electronics products from Firestore. Administrators can synchronize the full catalog (194 items across 24 clothing and market categories from DummyJSON) through **Settings → Store administration** or an authenticated POST to `/api/store?action=importCatalog`. Re-syncing preserves existing merchant edits and stock. Clothing and footwear items (`Mens Shirts`, `Tops`, `Womens Dresses`, `Mens Shoes`, `Womens Shoes`) require size selection (`S`/`M`/`L`/`XL`); market and general products do not. Orders use cash on delivery (`pending` → `confirmed` → `shipped` → `delivered`). Staff can add an HTTPS tracking URL when recording shipment.

## Run and verify

Use Flutter **3.50.0**, Node **24** and Java **21** (Firestore emulator).

```sh
flutter pub get
npm ci
flutter analyze
flutter test
npm test
npx firebase-tools@15.34.2 emulators:exec --config firebase.test.json --only firestore --project demo-verve-store 'npm test'
flutter build web --release --no-wasm-dry-run
```

`npm test` runs unit/API tests and skips emulator-only tests unless `FIRESTORE_EMULATOR_HOST` is set. The emulator command runs all backend tests, including ownership and concurrent checkout tests.

## Live configuration

Firebase project: `verve-store-gamal6507`. Public Web, Android and iOS registrations are in `lib/firebase_options.dart`; public client API keys are identifiers, not server credentials. The Android JSON and iOS plist belong to this project. Do not mix in the former project's settings or data.

Vercel project: `verve-store`. Required production environment variables:

- `FIREBASE_PROJECT_ID`: `verve-store-gamal6507`.
- `FIREBASE_SERVICE_ACCOUNT`: service account JSON stored as a Vercel secret. Never commit it, put it into a Dart define, or send it to a browser.
- `STORE_OWNER_EMAIL`: the owner's verified Google/Firebase email. The server grants the `admin` claim only when the signed-in token's verified email matches this server setting.

The server account needs `roles/datastore.user` and `roles/firebaseauth.admin`. Rotate its key if exposed. `.secrets/`, `.env*`, `node_modules/` and `.vercel/` are ignored by Git.

Email/password and Google sign-in are enabled. The production hostname must remain in Firebase Authentication's authorized domains. Facebook login is unavailable until the owner configures a Facebook application. Browser push is not requested; in-app notifications remain available. Native push requires platform credentials and permissions, and native social sign-in needs release SHA/callback configuration.

## Manage the store

Sign in with the verified owner account, then open **Settings → Store administration**. Add your actual products, EGP prices, inventory and HTTPS images, or sync the full clothing and market catalog directly from the administration panel. Hidden products are unavailable to customers. Use the administration orders screen to confirm, ship and deliver orders, and review cancellation/return requests.

The server computes prices from Firestore and reserves stock in the same transaction as order creation and cart removal. The client persists an idempotency key until the server acknowledges checkout. Cancelling an order restores reserved stock once. Changing the client price, total or status does not determine the accepted order.

Cash on delivery is the available payment method. Shipping currently costs **EGP 10** per nonempty order. Visa, Apple Pay, Vodafone Cash and InstaPay are **not activated**; the merchant must open provider accounts and complete their supported integration before electronic payments can be offered. No PAN, CVV or password is stored by application code. Status `pending` means received, not charged or shipped. Return requests do not imply an automatic refund. Carrier booking and tracking numbers require the owner's carrier service.

Customer support: [WhatsApp +20 1095930009](https://wa.me/201095930009).

## Deploy

```sh
firebase deploy --only auth,firestore --project verve-store-gamal6507
vercel --prod
```

Vercel builds Flutter with `scripts/build-web.sh`, serves `build/web`, and bundles `api/store.mjs` with the trusted backend. GitHub CI checks the client, server and rules. Native apps use the `API_BASE_URL` Dart define (default `https://verve-store-delta.vercel.app`). iOS release builds must be completed and tested on macOS/Xcode; this Windows workflow verifies the web release.

## Existing deployments

The former Firebase project is not migrated or modified. If its owner grants access later, `scripts/cleanup-legacy.mjs` provides a **dry run** for locating password fields and saved card records. With a correctly scoped `GOOGLE_APPLICATION_CREDENTIALS` and explicit `FIREBASE_PROJECT_ID`, run it without arguments first; `--apply` removes those fields/records. Export and review needed data before applying. Do not point the new store at legacy data without a separate schema migration.

Security Rules are a reviewed prototype with executable ownership, schema and financial-write denial tests; test them again when the data model changes. Server Admin SDK access bypasses Firestore rules, so server authorization and secret handling are also required.
