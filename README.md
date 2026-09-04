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
- *"What have I got due this week?"*
- *"I am free until 2 — is there anything on campus I could drop into?"*
- *"Book Room 302 tomorrow, 3 to 5 PM."*
- *"I need a room for 5 people with a projector, tomorrow between 2 and 4."*
- *"Just book me any room tomorrow afternoon."* (The agent will ask clarifying questions instead of blindly acting)
