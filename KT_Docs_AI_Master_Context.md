# KT Vault — AI Master Context & Architecture Specification

Act as an Expert Flutter Web / GetX Architect and PostgreSQL Database Specialist. Strictly adhere to the following architecture, design guidelines, and system specifications for **KT Vault**.

---

## 1. Strict Coding Rules

- **NEVER** use `setState()`. This is a strict GetX project.
- **NEVER** put business logic, API calls, or conditional data formatting inside a View file.
- **NEVER** put `Get.put()` inside a View or a `build()` method. Use module `Bindings` with `Get.lazyPut()`.
- **NEVER** use standard `Navigator` — ALWAYS use GetX routing (`Get.toNamed`, `Get.offAllNamed`).
- **NEVER** let an exception fail silently. ALWAYS wrap async methods in `try/catch` and log via `AppLogger`.
- **NEVER** hardcode strings, hex colors, or magic numbers (padding/margins) in UI files.
- **ALWAYS** use `.obs` for reactive variables and `Obx()` to listen in the View.
- **ALWAYS** use `Get.snackbar()`, `Get.dialog()`, or `Get.bottomSheet()` triggered from the Controller.
- **ALWAYS** extend `GetView<YourController>` for main module screens.
- **ALWAYS** reference `AppColors` and `AppConstants` from `core/values`.
- **ALWAYS** register feature dependencies in the module's Binding class using `Get.lazyPut()`.

---

## 2. Responsiveness & Adaptive Web Rules

- **Breakpoints**:
  - **Mobile**: `< 768px` (Single column cards, drawer navigation, stacked form sections).
  - **Tablet**: `768px – 1024px` (2-column grids, collapsible drawer navigation).
  - **Desktop**: `> 1024px` (Permanent fixed sidebar, 4-column metric grids, side-by-side forms).
- **Navigation**:
  - On screens `< 1024px`, the sidebar folds into a `Drawer`, triggered by the hamburger menu in `WebHeader`.
  - On screens `>= 1024px`, the `WebSidebar` is fixed on the left.
- **Grids & Lists**:
  - All card grids must use `LayoutBuilder` with adaptive `crossAxisCount` (1 on mobile, 2 on tablet, 3-4 on desktop).
  - Filter toolbars must use `Wrap` with `spacing` and `runSpacing` to prevent `RenderFlex` overflows on mobile.
- **Forms**:
  - Upload and settings forms stack vertically on compact screens and display side-by-side on wide screens.

---

## 3. Role Permissions & User Management

Public registration is disabled. All staff accounts are provisioned and managed directly by administrators.

- **`admin`**: System management access. Can provision/create new staff accounts (`admin`, `editor`, `viewer`, `user`), toggle staff status, edit all configurations, upload/manage documents, and perform soft/permanent deletions.
- **`editor`**: Document management access. Can upload documents, edit metadata, view files, and organize folders. Cannot delete records or manage staff.
- **`viewer`**: Read-only access. Can view documents, preview PDFs/images, and search logs. Cannot upload, edit, or delete anything.
- **`user`**: Standard access. Can view personal and assigned documents.

---

## 4. Business Domain & Specializations

- **Utility Bills Management**:
  - Piped Gas (Gujarat Gas / Adani Gas / MNGL / MGL), Electricity/Light (UGVCL, Torrent Power, Adani Electricity, BESCOM, Tata Power), Water (Municipal Corporation), Internet/Broadband (Airtel, Jio, ACT, Tata Play), Property Tax.
  - Multi-city indexing (*Ahmedabad, Surat, Vadodara, Rajkot, Gandhinagar, Mumbai, Pune, Delhi NCR, Bangalore, Hyderabad*).
  - Consumer numbers, meter numbers, bill dates, due dates, amounts, and payment status (*Paid / Pending / Overdue*).
- **Appliance & Asset Invoices / Warranty Vault**:
  - Ceiling Fans, Washing Machines, Geysers/Heaters, Air Conditioners, Refrigerators, Laptops/Computers.
  - Brand catalogs (*Samsung, LG, Voltas, Havells, Crompton, Daikin, Philips, Blue Star, Sony, Apple, Dell, HP*).
  - Serial numbers, purchase dates, warranty validity dates, and auto-computed expiration status (*Active / Expiring in 30 Days / Expired*).
- **Multi-Format Previews & Actions**:
  - Interactive PDF viewer dialog.
  - Zoomable/rotatable image lightbox dialog.
  - Time-limited expiring share links.
  - Soft delete trash bin with one-click restore or permanent purge.
- **Activity Audit Trail**:
  - Automatic event logging for uploads, views, downloads, shares, deletions, and restorations.

---

## 5. Supabase RPC Endpoints

- `rpc('get_dashboard_metrics') -> JSONB`
- `rpc('soft_delete_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('restore_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('permanent_delete_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('admin_create_staff_user', { p_email: TEXT, p_password: TEXT, p_full_name: TEXT, p_role: TEXT, p_department: TEXT }) -> JSONB`
- `rpc('admin_get_all_users') -> SETOF profiles`
- `rpc('admin_update_user_role', { p_target_user_id: UUID, p_role: TEXT, p_is_active: BOOLEAN }) -> VOID`
