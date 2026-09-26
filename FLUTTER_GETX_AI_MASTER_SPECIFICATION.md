# Flutter / GetX — AI Master Context & Architecture Specification

Act as an Expert Flutter & GetX Architect and Backend/Database Specialist. Strictly adhere to the following architecture, state management guidelines, layout engineering rules, and system specifications.

---

## 1. Strict Coding Rules

- **NEVER** use `setState()`. This is a strict GetX reactive project.
- **NEVER** put business logic, API calls, or conditional data formatting inside a View file.
- **NEVER** put `Get.put()` inside a View or a `build()` method. ALWAYS register dependencies in the module's `Binding` class using `Get.lazyPut()`.
- **NEVER** use standard Flutter `Navigator` — ALWAYS use GetX routing (`Get.toNamed`, `Get.offAllNamed`, `Get.back()`).
- **NEVER** let an exception fail silently. ALWAYS wrap async methods in `try/catch` and log via a central logger.
- **NEVER** hardcode strings, hex colors, or magic numbers (paddings/margins) in UI files. ALWAYS reference `AppColors` and `AppConstants` from `core/values`.
- **ALWAYS** follow the 3-tier flow: **View (UI) -> Controller (Logic) -> Dataset (Data Layer)**.
- **ALWAYS** use `.obs` for reactive variables and `Obx()` to listen in the View.
- **ALWAYS** extend `GetView<YourController>` for main module screens.
- **ALWAYS** display realistic **Shimmer / Skeleton loaders** mirroring the component geometry when loading content (`isLoading.value == true`). **NEVER** use bare spinners or blank screens for content loading.
- **ALWAYS** build screens, components, modals, and toolbars to be **100% dynamically responsive** across Desktop, Tablet, and Mobile with zero `RenderFlex` overflow risks.
- **ALWAYS** use standardized compact snackbars (Top-Right on Desktop/Tablet, Top-Center on Mobile, never full-width).
- **ALWAYS** display validation and submission errors **INSIDE** an active Dialog, Form, or BottomSheet (NEVER trigger a floating snackbar while a modal is open).
- **ALWAYS** implement server-side pagination when fetching collections. Decide between **Table Paginated** (for data tables, admin lists, audit registries) and **Infinite Scroll** (for card grids, media galleries, mobile views) based on screen feature and viewport. **NEVER** fetch unbounded datasets.

---

## 2. Architecture & Data Flow (MVC + Dataset)

Strictly adhere to the streamlined 3-tier architecture:

```
[ View (UI Layer) ]  <--->  [ Controller (Logic & State) ]  <--->  [ Dataset (Data Access Layer) ]  <--->  [ Backend / Supabase / Local DB ]
```

1. **View (UI Layer)**:
   - Extends `GetView<YourController>`.
   - Sole responsibility: rendering UI widgets, receiving user interaction events, and delegating them to the Controller.
   - Listens to Controller observables reactively using `Obx()`.
   - **Zero** business logic, **zero** API/database queries, and **zero** direct data manipulation.

2. **Controller (Logic & State Layer)**:
   - Extends `GetxController`.
   - Manages state variables, reactive observables (`.obs`), form validations, and user flow decisions.
   - Communicates directly with the **Dataset** to query or mutate data.
   - Handles async operations inside `try/catch`, triggers UI feedback (`Get.snackbar`, `Get.dialog`, `Get.bottomSheet`), and updates state.

3. **Dataset (Data Access Layer - Remote & Local Storage)**:
   - Encapsulates all external data communication: backend APIs, database client (e.g. Supabase queries, RPC functions, Auth, Storage), and local caching.
   - Replaces unnecessary intermediate repository/provider boilerplate with clean, purpose-built dataset classes.
   - Returns structured models or typed response payloads directly to the Controller.

---

## 3. UI Feedback, Compact Snackbars & Modal Error Rules

### A. Compact Floating Snackbar Standards
- **Desktop / Tablet (`>= 768px`)**:
  - Position: **Top-Right** (`SnackPosition.TOP`).
  - Sizing: **Compact / Small width** (max-width ~380px–420px). **NEVER full-width**.
  - Styling: Rounded corners, subtle drop shadow, floating margin from top and right screen edges.
- **Mobile Phone (`< 768px`)**:
  - Position: **Top-Center** (`SnackPosition.TOP`).
  - Sizing: Compact width with standard side margins (e.g. 16px).
- **Usage Scope**:
  - Reserved exclusively for general app notifications, background task updates, or success messages after a modal has already closed.

### B. In-Context Modal & Form Error Handling
- **Inline Modal Errors**:
  - When a **Dialog**, **Form**, or **BottomSheet** is currently open, any validation failure or submission error **MUST be rendered directly INSIDE the modal/dialog/bottomSheet** (e.g., reactive error banner, inline field validation helper text).
  - **NEVER** show a floating `Get.snackbar()` over or behind an open Dialog/BottomSheet for form errors.
  - Keep the dialog/bottomsheet open so the user can correct their input without losing state.
- **Success Handling**:
  - On successful form submission, close the Dialog/BottomSheet first (`Get.back()`), then trigger the top-corner success snackbar.

---

## 4. Loading States & Shimmer Loader Standards

To provide a smooth, modern user experience, **generic blocking loading spinners and blank screens are strictly prohibited for content loading**.

### A. Shimmer / Skeleton Placeholder Requirements
- **ALWAYS** display animated **Shimmer / Skeleton loaders** mirroring the actual component layout whenever data is loading (`isLoading.value == true`).
- **Layout Mirroring Rules**:
  - **Metric / Stats Cards**: Skeleton cards with shimmer placeholder icon box, title line, and numeric value bar.
  - **Cards & Grids**: Skeleton cards matching thumbnail aspect ratio, title bar, category chips, and action button placeholders.
  - **Data Tables & Lists**: Skeleton table rows with multi-column shimmer bars of varying realistic widths (e.g. 40%, 70%, 25%).
  - **Navigation & Sidebars**: Skeleton list tiles with leading icon and label placeholders.
  - **Detail & Preview Panes**: Skeleton banner, metadata chips, and multi-line paragraph bars.

### B. Micro / Button Spinners
- `CircularProgressIndicator` is **ONLY** allowed as a tiny inline spinner (`width: 16-18px`, `strokeWidth: 2`) inside action buttons during submission (`isSubmitting.value == true`).
- **NEVER** show a raw full-screen or full-card `CircularProgressIndicator` when content is being fetched.

### C. Shimmer Visual Standards
- Shimmer base color: `AppColors.cardBorder` or subtle surface neutral.
- Shimmer highlight color: `AppColors.cardBackground` or bright surface accent.
- Smooth continuous linear sweep from left to right.
- Transition: Instant smooth switch from skeleton placeholders to rendered data once `isLoading.value` becomes `false`.

---

## 5. Dynamic Responsiveness & Multi-Device Adaptive Rules

Every screen, component, modal, toolbar, and layout MUST be 100% dynamically responsive without any UI breakage, clipping, or `RenderFlex` overflow errors.

### A. Viewport Breakpoints & Layout Matrix
- **Desktop (`> 1024px`)**:
  - Permanent fixed navigation sidebar.
  - 3 to 4 column responsive grid layouts (`crossAxisCount: 3` or `4`).
  - Side-by-side multi-column form sections and split detail/preview panes.
  - Wide data tables showing all metadata columns with sortable headers.
  - Top-Right compact floating snackbars.
- **Tablet (`768px – 1024px`)**:
  - Collapsible sidebar folded into a drawer, accessible via header menu icon.
  - 2-column adaptive grid layouts (`crossAxisCount: 2`).
  - Semi-stacked fluid form layouts with responsive controls.
  - Horizontally scrollable data tables (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) with pinned action columns.
  - Top-Right compact floating snackbars.
- **Mobile Phone (`< 768px`)**:
  - Fully collapsed navigation drawer (`Drawer`), compact mobile header with touch-friendly actions.
  - Single-column stacked cards (`crossAxisCount: 1`), full-width fluid layouts.
  - Strictly vertical stacked forms with full-width primary action buttons.
  - Modals adapt into full-width dialogs or swipeable bottom sheets (`Get.bottomSheet`).
  - Filter toolbars **MUST** use `Wrap(spacing: 8, runSpacing: 8)` instead of single-line `Row` to prevent horizontal overflow.
  - Top-Center compact floating snackbars with standard 16px screen margins.

### B. Overflow Prevention & Layout Engineering Rules
- **NEVER** use fixed rigid pixel widths on content containers (e.g. `SizedBox(width: 800)`). Use fluid constraints (`constraints: BoxConstraints(maxWidth: ...)`), `Expanded`, or `Flexible`.
- **ALWAYS** use `LayoutBuilder` to compute dynamic column counts, spacing, and aspect ratios based on available width constraints.
- **ALWAYS** wrap flexible horizontal text with `overflow: TextOverflow.ellipsis` inside `Row` / `Flex` widgets.
- **ALWAYS** wrap screen contents in `SingleChildScrollView` to support vertical scrolling on small screens and rotated viewports.

---

## 6. Pagination & Data Loading Architecture (Table Paginated vs Infinite Scroll)

Fetching unbounded datasets into memory in a single query is strictly prohibited. Every screen, module, or dataset handling collections of data **MUST** implement server-side pagination through the Controller and Dataset.

### A. Pattern Selection Matrix
| Screen / Feature Type | Pagination Pattern | UI Controls & Behavior |
| :--- | :--- | :--- |
| **Data Tables & Admin Registries** (User lists, logs, tabular records) | **Table Paginated** | Dedicated bottom pagination toolbar with total items count, page size selector (`10`, `25`, `50`, `100`), Previous/Next and direct page number navigation. Shimmer rows on page change. |
| **Card Grids & Media Galleries** (Product grids, media cards, item cards) | **Infinite Scroll** | `ScrollController` listener fetching next batch when user scrolls near the bottom (~200px threshold). Append shimmer skeleton cards at the bottom while fetching. |
| **Mobile Form Factors (`< 768px`)** | **Infinite Scroll / Load More** | Smooth continuous scrolling with bottom loader or an explicit "Load More" button to avoid cramped table pagination controls. |
| **Search Queries & Filter Changes** | **Immediate Reset** | Any change in search input, tab filter, category, or sorting **MUST immediately reset pagination to page 1** (or clear the list and fetch the first batch). |

### B. Table Pagination Standards
- **UI Elements**:
  - Item range and total count display (e.g., `Showing 1–25 of 148 entries`).
  - Rows per page dropdown (`10`, `25`, `50`, `100`).
  - First, Previous, Page Numbers (`[1] [2] [3] ... [10]`), Next, and Last buttons.
  - Disable Previous/First buttons on page 1, and Next/Last buttons on the final page.
- **Controller State**:
  ```dart
  final currentPage = 1.obs;
  final pageSize = 25.obs;
  final totalCount = 0.obs;
  final isTableLoading = false.obs;
  ```
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
    ```dart
    if (isLoadingMore.value || !hasMore.value) return;
    ```
- **Controller State**:
  ```dart
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;
  final items = <ItemModel>[].obs;
  ```
- **UI Feedback**:
  - Initial fetch: Display full shimmer skeleton cards mirroring geometry (`isLoading.value == true`).
  - Subsequent batches: Keep existing rendered items visible and append a compact shimmer card or indicator at the bottom (`isLoadingMore.value == true`).
