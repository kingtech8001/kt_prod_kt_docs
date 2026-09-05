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
- **ALWAYS** follow the **View -> Controller -> Dataset** flow.
- **ALWAYS** use `.obs` for reactive variables and `Obx()` to listen in the View.
- **ALWAYS** display realistic **Shimmer / Skeleton loaders** mirroring the screen/component geometry when loading content (`isLoading.value == true`). **NEVER** use bare spinners or blank screens for content loading.
- **ALWAYS** build all screens, components, modals, and toolbars to be **100% dynamically responsive** across PC (Desktop/Ultrawide), Tablet, and Mobile with zero hardcoded overflow risks.
- **ALWAYS** use `Get.snackbar()`, `Get.dialog()`, or `Get.bottomSheet()` triggered from the Controller.
- **ALWAYS** use the standardized compact snackbar (Top-Right on Desktop, Top-Center on Mobile, never full-width).
- **ALWAYS** display validation/submission errors **INSIDE** the active Dialog, Form, or BottomSheet (NEVER trigger a floating snackbar while a modal is open).
- **ALWAYS** extend `GetView<YourController>` for main module screens.
- **ALWAYS** reference `AppColors` and `AppConstants` from `core/values`.
- **ALWAYS** register feature dependencies in the module's Binding class using `Get.lazyPut()`.
- **ALWAYS** implement server-side pagination when fetching collections. Decide between **Table Paginated** (for data tables, admin lists, audit logs) and **Infinite Scroll** (for card grids, media galleries, mobile views) based on screen feature and device viewport. **NEVER** fetch unbounded datasets.


---

## 2. Architecture & Data Flow (MVC + Dataset)

Strictly adhere to the streamlined 3-tier architecture:

```
[ View (UI) ]  <--->  [ Controller (Logic) ]  <--->  [ Dataset (Server/Local Data) ]  <--->  [ Supabase / Local DB ]
```

1. **View (UI Layer)**:
   - Extends `GetView<YourController>`.
   - Sole responsibility: rendering UI widgets, receiving user interaction events, and delegating them to the Controller.
   - Listens to Controller observables reactively using `Obx()`.
   - **Zero** business logic, **zero** API/database queries, and **zero** direct data manipulation.

2. **Controller (Logic & State Layer)**:
   - Extends `GetxController`.
   - Manages state variables, reactive observables (`.obs`), form validations, and user flow decisions.
   - Communicates directly with the **Dataset** to request data or execute operations.
   - Handles async operations inside `try/catch`, triggers UI feedback (`Get.snackbar`, `Get.dialog`, `Get.bottomSheet`), and updates state.

3. **Dataset (Data Access Layer - Server Query & Local DB)**:
   - Encapsulates all external data communication: **Supabase** (RPC functions, table queries, Auth, Storage) and/or **Local Database / Cache**.
   - Replaces unnecessary intermediate repository/provider boilerplate with clean, purpose-built dataset classes.
   - Returns structured models or typed response payloads directly to the Controller.

---

## 3. UI Feedback, Snackbar & Modal Error Rules

### A. Compact Snackbar Standards
- **Desktop / Tablet (`>= 768px`)**:
  - Position: **Top-Right** (`SnackPosition.TOP`).
  - Sizing: **Compact / Small width** (max-width ~380px–420px). **NEVER full-width**.
  - Styling: Rounded corners, subtle drop shadow, floating margin from top and right edges.
- **Mobile Phone (`< 768px`)**:
  - Position: **Top-Center** (`SnackPosition.TOP`).
  - Sizing: Compact width with standard side margins (e.g. 16px).
- **Usage**:
  - Reserved exclusively for general application notifications, async background results, or success messages after a modal has already closed.

### B. In-Context Modal & Form Error Handling (Dialogs & BottomSheets)
- **Inline Modal Errors**:
  - When a **Dialog**, **Form**, or **BottomSheet** is currently open, any validation failure or submission error **MUST be rendered directly INSIDE the modal/dialog/bottomSheet** (e.g., reactive error banner, inline field validation error).
  - **NEVER** show a floating `Get.snackbar()` over or behind an open Dialog/BottomSheet for form errors.
  - Keep the dialog/bottomsheet open so the user can fix the input without losing state.
- **Success Handling**:
  - On successful form submission, close the Dialog/BottomSheet first (`Get.back()`), then trigger the top-corner success snackbar.

---

## 4. Dynamic Responsiveness & Multi-Device Adaptive Rules (PC, Tablet, Mobile)

KT Vault is a modern enterprise web application accessed across desktop monitors, laptops, tablets, and smartphones. **Every single view, component, modal, toolbar, and layout MUST be 100% dynamically responsive** without any UI breakage, clipping, or `RenderFlex` overflow errors.

### A. Viewport Breakpoints & Layout Matrix
- **PC / Desktop (`> 1024px`)**:
  - **Navigation**: Fixed permanent left navigation sidebar (`WebSidebar`, ~260px width).
  - **Metrics & Grids**: 3 to 4 column responsive grid layouts (`crossAxisCount: 3` or `4`).
  - **Forms & Details**: Side-by-side multi-column form sections and split detail/preview panes.
  - **Data Tables**: Wide tables showing all metadata columns with sortable headers.
  - **Notifications**: Top-Right compact floating snackbars.
- **Tablet (`768px – 1024px`)**:
  - **Navigation**: Collapsible sidebar folded into a drawer, accessible via header menu icon.
  - **Metrics & Grids**: 2-column adaptive grid layouts (`crossAxisCount: 2`).
  - **Forms & Details**: Semi-stacked fluid form layouts with responsive controls.
  - **Data Tables**: Horizontally scrollable data tables (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) with sticky/pinned action columns.
  - **Notifications**: Top-Right compact floating snackbars.
- **Mobile Phone (`< 768px`)**:
  - **Navigation**: Fully collapsed navigation drawer (`Drawer`), compact mobile header with touch-friendly actions.
  - **Metrics & Grids**: Single-column stacked cards (`crossAxisCount: 1`), full-width fluid layouts.
  - **Forms & Details**: Strictly vertical stacked forms with full-width primary action buttons.
  - **Modals & Dialogs**: Adapt into full-width modal dialogs or swipeable bottom sheets (`Get.bottomSheet`).
  - **Filter Toolbars**: MUST use `Wrap(spacing: 8, runSpacing: 8)` instead of single-line `Row` to prevent horizontal overflow.
  - **Notifications**: Top-Center compact floating snackbars with standard 16px screen margins.

### B. Overflow Prevention & Layout Engineering Rules
- **NEVER** use fixed rigid pixel widths on content containers (e.g. `SizedBox(width: 800)`). Use fluid constraints (`constraints: BoxConstraints(maxWidth: ...)`), `Expanded`, or `Flexible`.
- **ALWAYS** use `LayoutBuilder` to compute dynamic column counts, spacing, and aspect ratios based on available width constraints.
- **ALWAYS** wrap flexible horizontal text with `overflow: TextOverflow.ellipsis` inside `Row` / `Flex` widgets to prevent line overflow.
- **ALWAYS** wrap screen contents in `SingleChildScrollView` to support vertical scrolling on small screens and rotated viewports.

---

## 5. Loading States & Shimmer Loader Architecture

To provide a smooth, premium web experience, **generic blocking loading spinners and blank screens are strictly prohibited for content loading**.

### A. Shimmer / Skeleton Placeholder Requirements
- **ALWAYS** display animated **Shimmer / Skeleton loaders** mirroring the actual component layout whenever data is loading (`isLoading.value == true`).
- **Layout Mirroring**:
  - **Metric Cards**: Skeleton cards with shimmer placeholder icon box, title line, and numeric value bar.
  - **Document & Appliance Cards**: Skeleton cards matching thumbnail aspect ratio, title bar, category chip, and action button placeholders.
  - **Data Tables & Lists**: Skeleton table rows with multi-column shimmer bars of varying realistic widths (e.g. 40%, 70%, 25%).
  - **Folder Trees & Sidebars**: Skeleton list tiles with leading icon and label placeholders.
  - **Detail & Preview Panes**: Skeleton banner, metadata chips, and multi-line paragraph bars.
- **Micro / Button Spinners**:
  - `CircularProgressIndicator` is **ONLY** allowed as a tiny inline spinner (`width: 16-18px`) inside action buttons during submission (`isSubmitting.value == true`).
  - **NEVER** show a raw full-screen or full-card `CircularProgressIndicator` when content is being fetched.

### B. Shimmer Color & Visual Standards
- Shimmer base color: `AppColors.cardBorder` / subtle surface neutral.
- Shimmer highlight color: `AppColors.cardBackground` / bright surface accent.
- Animation: Smooth continuous linear gradient sweep from left to right.
- Transition: Smooth immediate switch from shimmer skeleton to rendered data when `isLoading.value` becomes `false`.

---

## 6. Pagination & Data Loading Architecture (Table Paginated vs Infinite Scroll)

Fetching unbounded datasets into memory in a single query is strictly prohibited. Every screen, module, or dataset handling lists or collections of data **MUST** implement server-side pagination (`limit` & `offset` / `.range(from, to)` via Supabase) through the Controller and Dataset.

The pagination pattern MUST be chosen based on the screen feature and viewport:

### A. Pattern Selection Matrix
| Screen / Feature Type | Pagination Pattern | UI Controls & Behavior |
| :--- | :--- | :--- |
| **Data Tables & Admin Registries** (User lists, bill registries, audit logs, tabular views) | **Table Paginated** | Dedicated bottom pagination toolbar with total items count, page size selector (`10`, `25`, `50`, `100`), Previous/Next and direct page number navigation. Shimmer rows on page change. |
| **Card Grids & Media Galleries** (Document vault grid, appliance cards, thumbnail views) | **Infinite Scroll** | `ScrollController` listener fetching next batch when user scrolls near the bottom (~200px threshold). Append shimmer skeleton cards at the bottom while fetching. |
| **Mobile Form Factors (`< 768px`)** | **Infinite Scroll / Load More** | Smooth continuous scrolling with bottom loader or an explicit "Load More" button to avoid cramped table pagination controls on small screens. |
| **Search Queries & Filter Changes** | **Immediate Reset** | Any change in search input, tab filter, category, or sorting **MUST immediately reset pagination to page 1** (or clear the list and fetch the first batch). |

### B. Table Pagination Standards
- **UI Elements**:
  - Item range and total count display (e.g., `Showing 1–25 of 148 entries`).
  - Rows per page dropdown (`10`, `25`, `50`, `100`).
  - First, Previous, Page Numbers (`[1] [2] [3] ... [10]`), Next, and Last buttons.
  - Disable Previous/First buttons on page 1, and Next/Last buttons on the final page.
- **Controller State**:
  - `final currentPage = 1.obs;`
  - `final pageSize = 25.obs;`
  - `final totalCount = 0.obs;`
  - `final isTableLoading = false.obs;`
- **Behavior**: Changing page or page size triggers skeleton shimmer rows, replaces current page records, and scrolls the table smoothly back to the top.

### C. Infinite Scroll & Lazy Loading Standards
- **Scroll Detection**: Attach a listener to the view's `ScrollController`:
  ```dart
  scrollController.addListener(() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      controller.loadNextPage();
    }
  });
  ```
- **Fetch Guards**:
  - ALWAYS prevent concurrent or duplicate requests:
    `if (isLoadingMore.value || !hasMore.value) return;`
- **Controller State**:
  - `final currentPage = 1.obs;`
  - `final hasMore = true.obs;`
  - `final isLoadingMore = false.obs;`
  - `final items = <ItemModel>[].obs;`
- **UI Feedback**:
  - Initial fetch: Display full shimmer skeleton cards mirroring geometry (`isLoading.value == true`).
  - Subsequent batches: Keep existing rendered items visible and append a compact shimmer card or indicator at the bottom (`isLoadingMore.value == true`).

---

## 7. Role Permissions & User Management

Public registration is disabled. All staff accounts are provisioned and managed directly by administrators.

- **`admin`**: System management access. Can provision/create new staff accounts (`admin`, `editor`, `viewer`, `user`), toggle staff status, edit all configurations, upload/manage documents, and perform soft/permanent deletions.
- **`editor`**: Document management access. Can upload documents, edit metadata, view files, and organize folders. Cannot delete records or manage staff.
- **`viewer`**: Read-only access. Can view documents, preview PDFs/images, and search logs. Cannot upload, edit, or delete anything.
- **`user`**: Standard access. Can view personal and assigned documents.

---

## 8. Business Domain & Specializations

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

## 9. Supabase RPC Endpoints

- `rpc('get_dashboard_metrics') -> JSONB`
- `rpc('soft_delete_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('restore_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('permanent_delete_document', { p_document_id: UUID, p_user_id: UUID }) -> VOID`
- `rpc('admin_create_staff_user', { p_email: TEXT, p_password: TEXT, p_full_name: TEXT, p_role: TEXT, p_department: TEXT }) -> JSONB`
- `rpc('admin_get_all_users') -> SETOF profiles`
- `rpc('admin_update_user_role', { p_target_user_id: UUID, p_role: TEXT, p_is_active: BOOLEAN }) -> VOID`

