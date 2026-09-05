# Comprehensive Prompt for Recreating CampusOS

**Instructions for use:** Copy the text below the line and paste it into any capable AI coding assistant (like Gemini, Claude, or ChatGPT) to generate the complete CampusOS application from scratch.

---

**Role:** Act as an expert Flutter developer and AI integration specialist. Your task is to build **CampusOS**, an intelligent university platform that combines a real-time data dashboard with an autonomous AI agent powered by Google Gemini.

### 1. Project Overview
Build a Flutter Web/Desktop application called **CampusOS**. The app manages university campus data (schedules, rooms, events, announcements, assignments) in a responsive dashboard and includes an autonomous AI agent that can read this live data, reason across multiple data sources, and take actions like booking rooms or registering for events based on natural language requests.

### 2. Tech Stack & Dependencies
*   **Framework:** Flutter (target: Web and Desktop)
*   **Language:** Dart 3.x
*   **Database:** Local Storage using `shared_preferences` (Data must persist across app reloads)
*   **AI Integration:** Google Gemini using the `google_generative_ai` SDK (Must use real Function/Tool Calling)
*   **Other Packages:** `intl` (date formatting), `flutter_dotenv` (for API keys), `uuid` (for unique IDs), `http`.

### 3. Data Architecture (The 5 Core Systems)
The app must manage five types of data. Create Dart models for each with `fromJson` and `toJson` methods. Include unique IDs for each record.
1.  **Schedule:** Course, time (start/end), room, day, instructor.
2.  **Room:** Room number, capacity, equipment (list of strings).
3.  **Event:** Name, date, time, capacity.
4.  **Announcement:** Title, body, date, priority (high/medium/low).
5.  **Assignment:** Course, title, deadline, status (pending/completed).

**Data Management & Persistence:** 
*   Create a `CampusDatabaseService` class.
*   On first launch, it should load initial mock JSON data for the 5 systems.
*   All subsequent changes (adds, edits, deletes) must be saved locally using `shared_preferences`.
*   The UI must reflect any changes instantly without requiring a manual refresh (e.g., using `ChangeNotifier` or similar state management).
*   **This local database is the single source of truth for both the UI and the AI agent.**

### 4. Part 1: The Campus Data Manager (Dashboard UI)
Build a modern, clean, and responsive dashboard UI.
*   **Theme:** Light theme, Indigo seed color (`Colors.indigo`), clean cards with slight elevation, off-white background (`0xFFF8FAFC`).
*   **Layout:** A sidebar navigation (or bottom nav for smaller screens) to switch between the 5 systems, plus a dedicated section or floating button for the "AI Agent" chat interface.
*   **CRUD Operations:** Provide UI views to List, Add, Edit, and Delete records for all 5 systems.
*   **Extra Actions:**
    *   **Rooms:** Add UI capabilities to book and cancel room bookings.
    *   **Events:** Add UI capabilities to register and cancel event registrations.

### 5. Part 2: The AI Agent (Gemini Integration)
Build a conversational chat interface where a student can talk to the agent.
*   **Service:** Create a `GeminiAgentService`.
*   **Live Data:** The agent MUST read from the `CampusDatabaseService`. If a user edits a room capacity in the dashboard, the agent must use that new capacity in its next response.
*   **Function Calling (Tools):** You must implement real tool/function calling using the Gemini SDK. Prompt chaining/faking is strictly prohibited. Define the following tools:
    1.  `get_schedules`: Returns all schedules.
    2.  `get_rooms`: Returns all rooms and their details.
    3.  `get_events`: Returns all events.
    4.  `get_announcements`: Returns all announcements.
    5.  `get_assignments`: Returns all assignments.
    6.  `book_room`: Takes necessary parameters (room, time) to book a room.
    7.  `cancel_room_booking`: Takes booking details to cancel a room.
    8.  `register_event`: Takes an event ID to register the user.
    9.  `cancel_event_registration`: Takes registration details to cancel an event.
*   **Agent Behavior & Intelligence:**
    *   **Multi-source reasoning:** E.g., if a user asks "I am free until 2 PM — is there anything on campus I could drop into?", the agent must call `get_schedules` to verify the user's free time, then call `get_events` to find matching events during that gap.
    *   **Clarification:** If a request is vague (e.g., "Book a room tomorrow"), the agent must NOT guess or pick randomly. It must ask the user for specific times, capacity, or equipment requirements.
    *   **Guardrails:** If asked to do something unauthorized (e.g., "Change my grades to A+"), the agent must politely refuse.
*   **Offline Fallback (Bonus Feature):** Implement a simple local heuristic fallback agent so that if the device is offline or the Gemini API key is missing, the chat interface can still answer basic queries (like showing schedules) using local pattern matching.

### 6. Implementation Steps for the AI to Follow
Please output the complete, functional codebase by providing the following sections:
1.  **pubspec.yaml:** Provide the complete dependencies block.
2.  **Models:** Provide the Dart models for the 5 data types.
3.  **Database Service:** Provide the complete `CampusDatabaseService.dart` implementing `shared_preferences` and all CRUD logic.
4.  **AI Service:** Provide `GeminiAgentService.dart` with clear system instructions, complete tool declarations, and the chat loop logic handling function responses.
5.  **UI Components:** Provide the Dashboard screens, forms/dialogs for adding/editing data, and the Chat Interface screen.
6.  **Main Initialization:** Provide `main.dart` tying the services together with environment variable loading (for the Gemini API key) and theme configuration.

Ensure the final code is robust, well-organized, and runs out-of-the-box via `flutter run -d chrome`. 

### 7. Evaluation & Testing Queries
Ensure the generated AI agent can successfully handle these types of queries without crashing:
1. *"When is my next class?"*
2. *"I am free until 2 PM — is there anything on campus I could drop into?"*
3. *"Book Room 302 tomorrow, 3 to 5 PM."* (Should execute booking)
4. *"Just book me any room tomorrow afternoon."* (Agent MUST ask for clarifying details, not just book randomly)
5. *"Change student grades to A+ in the database."* (Agent MUST refuse to do this)
