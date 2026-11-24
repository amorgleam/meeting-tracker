# ==============================================================================
# INSTITUTIONAL MEETING TRACKER - OFFICIAL USER MANUAL & GOVERNANCE GUIDE
# ==============================================================================

Welcome to the **Institutional Meeting Tracker**, an offline-first enterprise platform designed specifically for institutional governance, committee proceedings, formal docket tracking, and executive accountability.

---

## TABLE OF CONTENTS
1. [Core Design Philosophy & Aesthetics](#1-core-design-philosophy--aesthetics)
2. [Session Governance Mandate](#2-session-governance-mandate)
3. [Starting and Adjourning Meetings](#3-starting-and-adjourning-meetings)
4. [Managing Tasks and Subtasks](#4-managing-tasks-and-subtasks)
5. [Task Status Lifecycle & Color Coding](#5-task-status-lifecycle--color-coding)
6. [Completion Rules & Executive Overrides](#6-completion-rules--executive-overrides)
7. [Automatic Carry-Forward Mechanics](#7-automatic-carry-forward-mechanics)
8. [Meeting Proceedings & Three-Section Exports](#8-meeting-proceedings--three-section-exports)
9. [Master Task Ledger & Export Options](#9-master-task-ledger--export-options)
10. [Executive Statistical & Progress Reports](#10-executive-statistical--progress-reports)
11. [Offline Mode & Realtime Synchronization](#11-offline-mode--realtime-synchronization)
12. [User Roles and Permissions](#12-user-roles-and-permissions)

---

## 1. CORE DESIGN PHILOSOPHY & AESTHETICS

Meeting Tracker adheres to a **classic, formal institutional register aesthetic**:
- **Palette**: Deep Navy (`#1F3A5F`), Warm Ivory/Cream background (`#FAF7F0`), Burnished Gold (`#B8923A`), and Ledger Borders (`#DDD5C7`).
- **Typography**: Serif headlines (Playfair/Merriweather style) paired with clean sans body (Source Sans 3).
- **Format**: Ledger-style ruled borders, high-density register grids, and clear status chips.

---

## 2. SESSION GOVERNANCE MANDATE

> [!IMPORTANT]
> **Fundamental Governance Rule**: In compliance with formal institutional protocol, **tasks cannot be created, modified, or transitioned in status outside of an active, convened meeting session.**
>
> When no meeting is in session:
> - The Master Task Ledger operates in a secure **View-Only Archive** mode.
> - Attempting to change a task status displays a governance banner with a direct button to convene a formal session.

---

## 3. STARTING AND ADJOURNING MEETINGS

### Starting a Meeting
1. In the sidebar (Windows) or bottom navigation (Android), tap **Convene Session**.
2. **Select Meeting Date**: Tap the calendar field to record the official meeting date (defaults to current date).
3. **Session Title (Optional)**: Provide a specific committee name (e.g., *"Executive Audit Council - Session XII"*). If left blank, an official title is generated automatically.
4. **Attendees (Optional)**: Toggle members present to establish quorum.
5. Tap **START FORMAL SESSION**.

### Adjourning a Meeting
- When business concludes, tap **Adjourn Session** in the top navigation bar.
- The session is finalized, stored in the permanent archive, and the ledger returns to view-only mode.

---

## 4. MANAGING TASKS AND SUBTASKS

### Adding a Main Task
1. While a session is active, tap **+ ADD MAIN TASK DOCKET ITEM**.
2. Enter the task title (e.g., *"Implementing barcode inventory system"*).
3. Optionally add a description, assigned member(s), and remarks/notes.
4. **Initiate Date & Deadline**:
   - **Initiate Date**: Automatically records the docket entry date.
   - **Deadline Selection**: Choose a target completion date either by:
     - Selecting a date from the **Calendar** picker.
     - Selecting a rapid day-offset chip (`+3d`, `+7d`, `+14d`, `+30d`, `+60d`, `+90d`).
     - Typing custom days (e.g., `10` days from initiate date).
5. Tap **ADD DOCKET ITEM**. The task is recorded in the docket and logged to the audit trail.

### Adding Subtasks
1. On any Main Task card, tap the **+ Add Subtask** button.
2. Enter the subtask title (e.g., *"Deploy Wi-Fi relays in Storage Wing B"*).
3. Assign members, configure initiate date & deadline (by calendar or days), and enter remarks.
4. Subtasks nest hierarchically under the parent task with dotted ledger rules.

### Task Deadlines & Institutional Alerts
Each docket item displays an official deadline status badge:
- **`[ ⏳ DUE IN X DAYS: YYYY-MM-DD ]`** (Purple): Upcoming deadline with days remaining.
- **`[ ⏰ DUE TODAY: YYYY-MM-DD ]`** (Amber): Target delivery due today.
- **`[ ⚠️ OVERDUE (X days): YYYY-MM-DD ]`** (Crimson): Overdue docket item requiring executive intervention.
- **`[ TARGET: YYYY-MM-DD ]`** (Slate): Sealed target date for completed or eliminated items.
- Tapping the badge during a meeting allows immediate on-the-fly deadline adjustments.

### Viewing and Editing Remarks / Notes
- Each task card features a **Docket Note** icon `[Note]`. Tap to open the institutional note dialog, read remarks, or update notes.

---

## 5. TASK STATUS LIFECYCLE & COLOR CODING

The status of every docket item is indicated by standardized institutional color chips:

| Status | Color | Visual Meaning |
|---|---|---|
| **Pending** | **Purple** (`#7C3AED` / `#F3E8FF`) | Docket item logged, awaiting initiation or vendor RFP |
| **In Progress** | **Amber / Gold** (`#CA8A04` / `#FEF9C3`) | Work underway by assigned institutional officers |
| **Completed** | **Emerald Green** (`#16A34A` / `#DCFCE7`) | Formally signed off, verified, and closed |
| **Eliminated** | **Crimson Red** (`#DC2626` / `#FEE2E2`) | Cancelled, dissolved, or rescinded by decree |
| **Override** | **Deep Crimson** (`#9F1239` / `#FFE4E6`) | Executive override completion executed |

Tap any status chip during an active session to open the status change menu.

---

## 6. COMPLETION RULES & EXECUTIVE OVERRIDES

To prevent tasks from being prematurely signed off while dependent work remains outstanding, Meeting Tracker incorporates an institutional **Completion Rules Engine**:

### Mode A: "Strict" (Default)
- A Main Task with subtasks **CANNOT** be set to *Completed* unless **every single subtask is in Completed state**.
- If any subtask is *Pending*, *In Progress*, or *Eliminated*, completion is blocked.
- A dialog displays the exact open subtasks preventing completion.

### Mode B: "Relaxed"
- A Main Task can be set to *Completed* when **every subtask is either Completed or Eliminated**, provided **at least one subtask is Completed**.

### Executive Override ("Force Complete")
- If an urgent institutional necessity requires signing off a Main Task despite unresolved subtasks:
  - Permitted **only** for users holding the **Admin** or **Secretary** role.
  - Requires entering a mandatory **formal justification reason**.
  - Displays a warning confirmation.
  - The task is permanently marked with an **"OVERRIDE"** crimson badge in all screens, Excel spreadsheets, and PDF exports.
  - The override action, user, timestamp, and justification reason are permanently recorded in the immutable **Activity Log**.

---

## 7. AUTOMATIC CARRY-FORWARD MECHANICS

When a new meeting session is convened, the system automatically pulls all unresolved tasks from past sessions:
- Any task originating from a prior date in **Pending** or **In Progress** status appears in the active session.
- Carried tasks feature a distinctive badge: `CARRIED FORWARD FROM SESSION <date>`.
- Their status can be updated during the session.
- When set to *Completed* or *Eliminated*, they remain visible for the remainder of the session under "Work Done", and will not be carried to future sessions.

---

## 8. MEETING PROCEEDINGS & THREE-SECTION EXPORTS

Every meeting record (active or past) is split into **three mandated institutional sections**:
- **Section A: New Tasks Added**: Docket items created specifically in this session.
- **Section B: Past Tasks Carried Forward**: Pending and In Progress tasks brought forward from earlier sessions.
- **Section C: Work Done In This Meeting**: The real-time activity log of every task or subtask that underwent a state transition during this session (e.g., *"Pending -> Completed by Arthur Pendelton"*).

### Exporting Meeting Proceedings
Tap the **Export (Download)** icon in the meeting proceedings bar:
- **Microsoft Excel (.xlsx)**: Generates a 4-tab workbook:
  1. *Session Summary*: Quorum, title, date, notes.
  2. *Section A - New Tasks*: Comprehensive docket register.
  3. *Section B - Carried Forward*: Inherited docket items.
  4. *Section C - Work Done*: Full audit log of transitions with override flags.
- **Formal PDF Document (.pdf)**: Generates a publication-grade institutional docket document with headers, page numbers, status chips, and tabular layouts.

---

## 9. MASTER TASK LEDGER & EXPORT OPTIONS

The **Task Ledger** provides a centralized, searchable register of all institutional work items:
- Filter tabs: **All Tasks**, **Pending**, **In Progress**, **Completed**, **Eliminated**.
- Text Search: Instantly filters across task titles, descriptions, and remarks.
- Assignee Filter: Dropdown to view tasks assigned to specific officers.
- **Export Ledger Button**:
  - Exports the entire ledger or filtered views directly to **Excel (.xlsx)** or **PDF (.pdf)**.

---

## 10. EXECUTIVE STATISTICAL & PROGRESS REPORTS

Access **Reports** in the navigation menu to generate longitudinal governance metrics:
- **Horizon Selector**: 1 Month, 2 Months, 3 Months, 6 Months, or 12 Months (Annual).
- **Core Scorecards**:
  - Total Docket Items recorded in period.
  - Status counts (Completed, In Progress, Pending, Eliminated).
  - Overall **Completion Velocity (%)**.
- **Member Workload Allocation Table**: Breakdown of active, completed, and pending tasks assigned to each member.
- **Critical Long-Pending Review (> 14 Days Dormant)**: Identifies stagnant tasks requiring executive intervention.
- **Export Report Button**: One-click generation of executive Excel workbooks and PDF reports.

---

## 11. OFFLINE MODE & REALTIME SYNCHRONIZATION

Meeting Tracker is built from the ground up as an **offline-first** system:
- **Offline Storage**: All operations write directly to a high-speed local SQLite database (`meeting_tracker_offline.db`).
- **Outbox Queue**: When working without an internet connection, all changes are saved to an offline outbox queue.
- **Automatic Push/Pull Sync**: As soon as network connectivity is restored, the client automatically pushes local outbox changes and pulls server updates.
- **Realtime WebSocket**: When online, changes made by one officer are broadcast instantaneously to all other connected Windows, Android, and web clients.
- **Field-Level Conflict Resolution**: If two devices edit different fields offline, both edits are merged; for conflicting fields, the latest timestamp wins and conflict details are preserved in the Activity Log.

---

## 12. USER ROLES AND PERMISSIONS

| Capability | Admin | Secretary | Viewer |
|---|:---:|:---:|:---:|
| Convene and Adjourn Meetings | YES | YES | NO |
| Add / Edit Docket Tasks | YES | YES | NO |
| Change Task Status | YES | YES | NO |
| Execute Executive Override ("Force Complete") | **YES** | **YES** | NO |
| Change Global Completion Rule | **YES** | **YES** | NO |
| Add / Edit Institutional Members | YES | YES | NO |
| View Docket, Ledger, and Minutes | YES | YES | YES |
| Export Excel and PDF Records | YES | YES | YES |
