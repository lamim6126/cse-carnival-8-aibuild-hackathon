import 'package:flutter/material.dart';
import '../services/campus_database_service.dart';
import '../services/gemini_agent_service.dart';

class SettingsDialog {
  static void show(BuildContext context) {
    final agent = GeminiAgentService();
    final db = CampusDatabaseService();
    final keyCtrl = TextEditingController(text: agent.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.indigo),
            SizedBox(width: 8),
            Text("CampusOS Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Gemini API Key:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Google Gemini API Key",
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 8),
              const Text("Note: Automatically loaded from .env if present. You can change it anytime here.",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 24),
              const Text("Data Management:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.restore, color: Colors.red),
                label: const Text("Reset All Data to Original Seed Files", style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await db.resetToSeedData();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All 5 systems reset to original seed data."), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (keyCtrl.text.isNotEmpty) {
                await agent.setApiKey(keyCtrl.text.trim());
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save API Key"),
          ),
        ],
      ),
    );
  }
}
