# CampusOS — Intelligent University Platform & Autonomous AI Agent

> **AUST CSE Carnival 8.0 — AI Build Hackathon Submission**

---

## 📌 Project Overview

**CampusOS** is an intelligent, full-stack university operating system built to eliminate fragmented campus data and empower students with an autonomous AI agent. The platform provides a responsive **Campus Data Manager** dashboard covering all five university operational systems: **Class Schedules**, **Rooms & Labs**, **Events**, **Announcements**, and **Assignments**. Every system supports real-time **Create, Read, Update, and Delete (CRUD)** operations with persistent storage that survives reloads and restarts. 

Sitting directly on top of this live data is the **CampusOS AI Agent**, powered by Google Gemini using **genuine Function Calling / Tool Calling**. The agent dynamically executes tools against the live backend to look up schedules, perform multi-source reasoning (e.g. matching free hours to events), autonomously take actions (such as booking rooms with conflict detection and registering for events), ask clarifying questions when user requests are ambiguous, and safely refuse unauthorized operations.

---

## 🛠️ Tech Stack

- **Platform & Framework:** Flutter (Dart 3.x) — Universal Web and Desktop support
- **AI / LLM Engine:** Google Gemini (via official `google_generative_ai` SDK) with **real-time Tool Calling / Function Calling**
- **Persistence & Backend Service:** `CampusDatabaseService` with persistent storage (`shared_preferences` / local storage) — loads seed data on initial startup and persists all mutations permanently
- **Architecture:** Reactive Model-View-Service architecture with `ChangeNotifier` ensuring zero-delay live synchronization between data mutations and AI queries
- **Design & UI/UX:** Modern Material 3 UI with adaptive NavigationRail for wide screens and bottom navigation for compact screens

---

## 🚀 Setup Instructions (Run Locally)

The project can be executed simply by following these steps:

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.13.0 or higher)
- Google Chrome browser (for Web) or Windows Desktop build tools
- A Google Gemini API Key (free from [Google AI Studio](https://aistudio.google.com/))

### 1. Clone the repository
```bash
git clone https://github.com/lamim6126/cse-carnival-8-aibuild-hackathon.git
cd cse-carnival-8-aibuild-hackathon
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Open `.env` and set your Gemini API key:
```env
GOOGLE_API_KEY=your_gemini_api_key_here
```
> 💡 *Note: You can also configure or update the API Key directly inside the app UI by clicking the Settings gear icon in the top right corner.*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
To run directly in Google Chrome:
```bash
flutter run -d chrome
```

*(Optional) To run as native Windows desktop app:*
```bash
flutter run -d windows
```

---

## 🔑 Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_API_KEY` | Yes | Your Google Gemini API Key for the AI Agent |
| `GEMINI_API_KEY` | Optional | Alternative environment variable alias for the API Key |

*No API keys are committed to this repository in compliance with hackathon regulations.*

---

## 📊 Core Features & The 5 Systems

| System | Fields Managed | Available Operations |
|---|---|---|
| **1. Schedules** | Course, title, day, start/end time, room, instructor, section | View, Add, Edit, Delete, Filter by day/search |
| **2. Rooms & Labs** | Room number, type, capacity, equipment, floor, status, bookings | View, Add, Edit, Delete, **Book Room** (with real-time conflict checking), **Cancel Booking** |
| **3. Events** | Name, description, date, time, venue, organizer, capacity, registered count | View, Add, Edit, Delete, **Register Student** (with capacity limit checking), **Cancel Registration** |
| **4. Announcements** | Title, body, priority (high/medium/low), posted by, date, expires | View, Add, Edit, Delete, Priority-based filtering |
| **5. Assignments** | Course, title, description, assigned date, deadline, status | View, Add, Edit, Delete, Status filtering |

All mutations persist immediately to the backend database service and trigger reactive updates across both the UI and AI Agent context without requiring manual page refresh.

---

## 🤖 How to Use the AI Agent

Click **"AI Agent"** in the sidebar or tap the floating **"Ask AI Agent"** button from any screen. 

The agent uses **real function calling** to fetch and modify data on the fly. Quick action chips for all official hackathon test queries are provided at the top of the chat:

### Sample Queries Supported:
- **Simple Lookups:**
  - *"When is my next class?"*
  - *"What classes do I have on Wednesday?"*
  - *"What assignments do I have due this week?"*
  - *"Show me all high priority announcements."*
- **Multi-Source Reasoning:**
  - *"I'm free until 2 PM — is there anything on campus I could drop into?"* (cross-references student schedule with campus events)
  - *"Which labs have a projector and can fit at least 30 people?"* (filters room type `lab`, equipment `projector`, capacity >= 30)
- **Autonomous Actions:**
  - *"Book Room 7A02 tomorrow from 3 PM to 5 PM."* (checks availability and records booking)
  - *"Register me for the Guest Lecture on Deep Learning."* (validates seat capacity and registers student)
  - *"I need a room for 5 people with a projector, tomorrow between 2 and 4."*
- **Handling Ambiguity & Safety:**
  - *"Just book me any room tomorrow afternoon."* → Agent intelligently refuses to blindly book, instead asking clarifying questions regarding time, capacity, and room requirements.
  - Rejecting unauthorized actions (e.g. requests to delete university records or modify student grades).

---

## 🧪 Testing & Verification

Automated tests are included to ensure app stability:
```bash
flutter test
```

---

## 👥 Team Details

- **Event:** AUST CSE Carnival 8.0 — AI Build Hackathon (Preliminary Round)
- **Team Repository:** [lamim6126/cse-carnival-8-aibuild-hackathon](https://github.com/lamim6126/cse-carnival-8-aibuild-hackathon)
