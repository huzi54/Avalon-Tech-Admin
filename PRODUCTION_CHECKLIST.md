# Production Readiness Checklist

This checklist tracks the migration of the payroll desktop app to a
multi-tenant, bilingual, Provider-based production application.

## 1. Baseline Audit

- [x] Run `flutter analyze`.
- [x] Run the existing payroll and PDF tests.
- [x] Inventory `setState` usage.
- [x] Review Firebase Auth and Firestore access.
- [x] Identify subscription self-upgrade security risk.
- [x] Identify global, non-tenant Firestore collections.
- [x] Identify hard-coded English and light-theme colours.

## 2. State Management

- [x] Add persistent app settings Provider.
- [x] Move login registration mode to Provider.
- [x] Move owner dashboard navigation to Provider.
- [ ] Move salary calculator form state to a dedicated Provider.
- [ ] Move employee creation form state to a dedicated Provider.
- [ ] Move employee list/detail filters and editing state to Provider.
- [ ] Move payroll list filters and selection state to Provider.
- [ ] Move remittance filters, selection, notes, and table state to Provider.
- [ ] Remove remaining active `setState` calls.
- [ ] Add provider unit tests for every migrated feature.

## 3. Multi-Tenant Firebase

- [ ] Add `OrganizationModel`.
- [ ] Add organization membership and role models.
- [ ] Store `organizationId` on user profiles.
- [ ] Scope employees, payrolls, remittances, attendance, reports, and settings
      below `organizations/{organizationId}`.
- [ ] Add a backwards-compatible migration for existing records.
- [ ] Add Firestore indexes.
- [ ] Add least-privilege Firestore Security Rules.
- [ ] Add audit logs for sensitive owner/admin actions.

## 4. Authentication And Roles

- [ ] Keep Firebase UID as the user identity.
- [ ] Add platform admin, organization owner, and employee authorization.
- [ ] Remove hard-coded owner PIN from the desktop client.
- [ ] Store owner authentication securely.
- [ ] Prevent employees from reading owner-only payroll and remittance data.
- [ ] Add password reset and account recovery.
- [ ] Add disabled-account and revoked-membership handling.

## 5. Subscription

- [ ] Add seven-day trial.
- [ ] Add monthly and yearly plan types.
- [ ] Add active, trialing, expired, cancelled, and suspended statuses.
- [ ] Use server timestamps for subscription dates.
- [ ] Remove subscription activation from the customer client.
- [ ] Allow upgrades only through Admin SDK or a protected Cloud Function.
- [ ] Add subscription access guards.
- [ ] Add expiry and grace-period tests.

## 6. Localization

- [x] Add English Canada locale.
- [x] Add French Canada locale.
- [x] Persist the selected locale.
- [x] Localize the settings and main sidebar foundation.
- [ ] Replace all remaining hard-coded screen strings.
- [ ] Localize validation and Firebase error messages.
- [ ] Localize dates, currency, PDFs, and printable reports.
- [ ] Add localization widget tests.

## 7. Theme And Settings

- [x] Add light, dark, and system theme modes.
- [x] Persist theme preference.
- [x] Add language selection.
- [x] Add support email display.
- [x] Keep logout available from settings and dashboard.
- [ ] Replace hard-coded light colours in legacy screens.
- [ ] Add organization branding settings for name, address, and logo.
- [ ] Load branding from the active organization.

## 8. Sensitive Data And Documents

- [ ] Stop storing production documents as Base64 inside Firestore documents.
- [ ] Use private Cloud Storage paths scoped by organization and employee.
- [ ] Add upload size, type, malware, and download authorization checks.
- [ ] Encrypt highly sensitive fields through a trusted backend and Cloud KMS.
- [ ] Mask SIN and identity values in normal UI.
- [ ] Add retention and deletion policies.
- [ ] Ensure logs never contain credentials, SIN, or document data.

## 9. Reliability

- [ ] Add a shared typed failure model.
- [ ] Add retry and offline states for Firestore operations.
- [ ] Add idempotent payroll/remittance writes.
- [ ] Use Firestore transactions or batches for linked records.
- [ ] Add loading, empty, permission, expired-plan, and network-error UI states.
- [ ] Add crash reporting and non-sensitive diagnostics.

## 10. Testing And Release

- [x] Preserve payroll calculation tests.
- [x] Preserve PDF generation tests.
- [x] Add app settings and navigation Provider tests.
- [ ] Add Firebase emulator tests for Security Rules.
- [ ] Add auth and subscription tests.
- [ ] Add employee, attendance, payroll, and remittance widget tests.
- [ ] Add Windows and macOS smoke tests.
- [ ] Verify all important layouts at multiple desktop window sizes.
- [ ] Configure separate Firebase projects for development and production.
- [ ] Document signing, packaging, backup, monitoring, and rollback.

## Admin Panel Decision

Use one production Firebase project for the customer app and admin panel, plus
a separate Firebase project for development. Build the platform admin panel as
a separate Flutter Web application, preferably in the same repository as a
separate app or package. Only the admin backend may create organizations,
confirm manual payments, change subscription status, or assign platform roles.
