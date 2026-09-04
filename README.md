# CampusOS — Intelligent University Platform & Autonomous AI Agent

> **AUST CSE Carnival 8.0 — AI Build Hackathon Submission**

---

## Project Overview
CampusOS is an intelligent university platform that consolidates scattered campus data—schedules, rooms, events, announcements, and assignments—into a single responsive dashboard with full real-time CRUD capabilities. Built on top of this live data is the CampusOS AI Agent, an autonomous assistant powered by Google Gemini that uses genuine function calling to fetch current information, perform multi-source reasoning, and take actions like booking rooms or registering for events based on natural language requests.

## Tech Stack
- **Languages:** Dart (3.x)
- **Frameworks:** Flutter (Web & Desktop)
- **LLM Used:** Google Gemini (via `google_generative_ai` SDK with real-time Tool Calling / Function Calling)
- **Database:** Local Storage (`shared_preferences`) for persistent data management that survives reloads.

## Setup Instructions
Follow these exact commands to install dependencies and start the app locally:

```bash
# 1. Clone the repository
git clone https://github.com/lamim6126/cse-carnival-8-aibuild-hackathon.git
cd cse-carnival-8-aibuild-hackathon

# 2. Configure Environment Variables
cp .env.example .env
# Open .env and add your GEMINI_API_KEY / GOOGLE_API_KEY.

# 3. Install Dependencies
flutter pub get

# 4. Start the App (Chrome Web)
flutter run -d chrome
```

## Environment Variables
The following environment variables are required in your `.env` file (you can use `.env.example` as a template):
- `GOOGLE_API_KEY`: Your Google Gemini API Key to power the AI Agent.
- `GEMINI_API_KEY`: Alternative key alias (optional, same as above).

*(Do not commit real API keys to the repository).*

## How to Use the Agent
To use the agent, click **"AI Agent"** in the sidebar or tap the floating **"Ask AI Agent"** button. You can ask it questions to read data, find matching conditions, or perform actions. Here are some examples:
- *"When is my next class?"*
- *"What classes do I have on Wednesday?"*
- *"What assignments do I have due this week?"*
- *"Show me all high priority announcements."*
- *"I am free until 2 PM — is there anything on campus I could drop into?"* (Multi-source reasoning combining schedule + events)
- *"Which labs have a projector and can fit at least 30 people?"* (Filtering across rooms & equipment)
- *"Book Room 7A02 tomorrow from 3 PM to 5 PM."* (Autonomous action execution)
- *"Register me for the Guest Lecture on Deep Learning."* (Event registration action)
- *"Just book me any room tomorrow afternoon."* (The agent politely asks clarifying questions instead of blindly booking)
- *"Change student grades to A+ in the database."* (The agent politely rejects unauthorized actions)

## Running the Automated Test Suite
CampusOS includes comprehensive integration and unit tests covering all hackathon query scenarios:

```bash
flutter test
```

## Running the Web Production Server
You can build and serve the optimized web application using the built-in Dart web server:

```bash
# Build the web bundle
flutter build web --release

# Serve locally at http://localhost:8080
dart serve.dart
```

## Key Capabilities & Architecture
- **Autonomous Tool Calling:** Powered by Google Gemini 1.5 Flash using official function declarations (`get_schedules`, `get_rooms`, `get_events`, `get_announcements`, `get_assignments`, `book_room`, `register_event`).
- **Multi-Source Reasoning:** Answers complex student dilemmas (e.g. cross-referencing class free periods with open campus events and workshops).
- **Active Clarification & Guardrails:** Does not execute ambiguous actions; asks clarifying questions for incomplete room booking parameters and refuses unauthorized modifications.
- **Robust Offline Fallback Engine:** Features an intelligent local heuristic agent ensuring zero downtime and fully working functionality even if offline or without an active API key.
- **Full CRUD Campus Dashboard:** Live management for class schedules, room allocations, campus announcements, event registrations, and assignment deadlines with persistence across reloads.
