import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../services/word_comparator.dart';

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('الكتابة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RichText(
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 28,
                        height: 1.8,
                      ),
                      children: _buildTextSpans(provider, theme),
                    ),
                  ),
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 28,
                      height: 1.8,
                      color: Colors.transparent, 
                    ),
                    cursorColor: theme.primaryColor,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                    onChanged: (text) => provider.onTextChanged(text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(TestProvider provider, ThemeData theme) {
    List<TextSpan> spans = [];
    final originalWords = provider.originalWords;
    final typedWords = provider.typedWords;

    for (int i = 0; i < originalWords.length; i++) {
      String originalWord = originalWords[i];
      
      if (i < typedWords.length) {
        String typedWord = typedWords[i];
        
        if (i == typedWords.length - 1 && !_controller.text.endsWith(' ')) {
          if (WordComparator.isPartiallyCorrect(originalWord, typedWord)) {
            spans.add(TextSpan(text: typedWord + ' ', style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
          } else {
            spans.add(TextSpan(text: typedWord + ' ', style: TextStyle(color: Colors.redAccent)));
          }
        } 
        else {
          if (WordComparator.isWordCorrect(originalWord, typedWord)) {
            spans.add(TextSpan(text: originalWord + ' ', style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
          } else {
            spans.add(TextSpan(text: typedWord + ' ', style: TextStyle(color: Colors.red, decoration: TextDecoration.underline)));
          }
        }
      } else {
        spans.add(TextSpan(
          text: originalWord + ' ',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.28)),
        ));
      }
    }
    return spans;
  }
}
