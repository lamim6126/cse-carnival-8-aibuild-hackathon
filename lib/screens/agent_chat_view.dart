import 'package:flutter/material.dart';
import '../services/gemini_agent_service.dart';

class AgentChatView extends StatefulWidget {
  const AgentChatView({super.key});

  @override
  State<AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends State<AgentChatView> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _agent = GeminiAgentService();

  final List<String> _sampleQueries = [
    "When is my next class?",
    "What classes do I have on Wednesday?",
    "What assignments do I have due this week?",
    "Show me all high priority announcements.",
    "I'm free until 2 PM — is there anything on campus I could drop into?",
    "Which labs have a projector and can fit at least 30 people?",
    "Book Room 7A02 tomorrow from 3 PM to 5 PM.",
    "Register me for the Guest Lecture on Deep Learning.",
    "I need a room for 5 people with a projector, tomorrow between 2 and 4.",
    "Just book me any room tomorrow afternoon.",
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? query]) {
    final text = query ?? _textCtrl.text;
    if (text.trim().isEmpty) return;
    if (query == null) _textCtrl.clear();
    _agent.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _agent,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade600,
                    radius: 20,
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CampusOS AI Agent", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("Powered by Google Gemini with Real-time Function Calling", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Live Backend Connected", style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cleaning_services, size: 20),
                    tooltip: "Clear Conversation",
                    onPressed: () => _agent.clearChat(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sample queries test bar
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleQueries.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final q = _sampleQueries[i];
                    return ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.indigo.shade50,
                      side: BorderSide(color: Colors.indigo.shade100),
                      onPressed: () => _send(q),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: _agent.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 48, color: Colors.indigo.shade300),
                            const SizedBox(height: 12),
                            const Text("How can I assist you today?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text("Ask about schedules, rooms, events, notices, or click any prompt above.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        itemCount: _agent.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _agent.messages[i];
                          final isUser = msg.sender == 'user';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  CircleAvatar(backgroundColor: Colors.indigo.shade100, radius: 14, child: const Icon(Icons.smart_toy, size: 16, color: Colors.indigo)),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (msg.toolCallsMade.isNotEmpty) ...[
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: msg.toolCallsMade.map((tool) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade300),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.bolt, size: 13, color: Colors.amber),
                                                  const SizedBox(width: 3),
                                                  Text("Function Call: $tool", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isUser ? Colors.indigo : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          msg.text,
                                          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 14, child: const Icon(Icons.person, size: 16, color: Colors.black54)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (_agent.isThinking) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text("CampusOS Agent is reasoning & executing tools...", style: TextStyle(fontSize: 12, color: Colors.indigo.shade700, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: "Ask CampusOS anything or give an action command...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.indigo),
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _send(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
