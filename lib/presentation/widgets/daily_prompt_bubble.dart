import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_provider.dart';

class DailyPromptBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUserId;
  final String chatId;
  final User otherUser;

  const DailyPromptBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<DailyPromptBubble> createState() => _DailyPromptBubbleState();
}

class _DailyPromptBubbleState extends State<DailyPromptBubble> {
  final TextEditingController _answerController = TextEditingController();

  void _submitAnswer(BuildContext context) {
    if (_answerController.text.trim().isEmpty) return;
    
    context.read<ChatProvider>().answerDailyPrompt(
      widget.message.id,
      _answerController.text.trim(),
    );
    Navigator.pop(context);
    _answerController.clear();
  }

  void _showAnswerDialog(BuildContext context) {
    final question = widget.message.gameData?['question'] as String? ?? 'Daily Prompt';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Answer Prompt',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your match won\'t see this until they answer too!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitAnswer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE3C72),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameData = widget.message.gameData ?? {};
    final question = gameData['question'] as String? ?? 'Deep Question?';
    final answers = Map<String, dynamic>.from(gameData['answers'] as Map? ?? {});

    final myAnswer = answers[widget.currentUserId] as String?;
    final otherAnswer = answers[widget.otherUser.id] as String?;

    final bothAnswered = myAnswer != null && otherAnswer != null;
    final onlyIAnswered = myAnswer != null && otherAnswer == null;
    final onlyTheyAnswered = myAnswer == null && otherAnswer != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFE3C72).withValues(alpha: 0.1),
            const Color(0xFFFF655B).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFE3C72).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFFFE3C72)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Deep Question',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Question
          Text(
            question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // State 1: Both Answered (Reveal!)
          if (bothAnswered) ...[
            const Divider(),
            const SizedBox(height: 8),
            _buildAnswerRow('You', myAnswer, isDark),
            const SizedBox(height: 8),
            _buildAnswerRow(widget.otherUser.firstName, otherAnswer, isDark),
          ] 
          // State 2: I haven't answered yet
          else if (myAnswer == null) ...[
            if (onlyTheyAnswered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${widget.otherUser.firstName} answered. Answer to reveal!',
                  style: const TextStyle(
                    color: Color(0xFFFE3C72),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: () => _showAnswerDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE3C72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Tap to Answer'),
            ),
          ]
          // State 3: Only I answered
          else if (onlyIAnswered) ...[
            const Divider(),
            const SizedBox(height: 8),
            _buildAnswerRow('You', myAnswer, isDark),
            const SizedBox(height: 8),
            Text(
              'Waiting for ${widget.otherUser.firstName} to answer...',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String name, String? answer, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          answer ?? '',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
