import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/invoice_data.dart';

class AiService {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<InvoiceData?> extractInvoiceData(File imageFile) async {
    if (_geminiApiKey.isEmpty) {
      print("Error: GEMINI_API_KEY is not set in the environment.");
      return null;
    }
    try {
      final imageBytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // We use gemini-1.5-flash as it supports image inputs well
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "このレシートまたはスクリーンショットから、日付(date)、金額(price)、および目的(purpose)を抽出してください。金額はカンマなしの数値文字列にしてください。目的は、何に対する支払いか（例：タクシー代、食事代、備品購入など）を推測または抽出してください。結果を以下のJSON形式で返してください。JSON以外のテキストは含めないでください。\n\n```json\n{\n  \"date\": \"YYYY-MM-DD\",\n  \"price\": \"金額\",\n  \"purpose\": \"目的\"\n}\n```"
              },
              {
                "inline_data": {
                  // Assuming JPEG or PNG. Gemini API expects correct mime type, but image/jpeg is usually a safe default if unknown, or you can extract it from the file extension.
                  "mime_type": _getMimeType(imageFile.path),
                  "data": imageBase64
                }
              }
            ]
          }
        ],
         "generationConfig": {
            "responseMimeType": "application/json",
         }
      };

      final response = await http.post(
        url,
        headers: {
          "x-goog-api-key": _geminiApiKey,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final extractedText =
            responseBody['candidates'][0]['content']['parts'][0]['text'];

        // Clean up the text in case Gemini wraps it in markdown despite responseMimeType
        String jsonText = extractedText;
        final regex = RegExp(r'\{[\s\S]*\}');
        final match = regex.firstMatch(jsonText);
        if (match != null) {
          jsonText = match.group(0)!;
        }

        final Map<String, dynamic> jsonMap = jsonDecode(jsonText);
        return InvoiceData.fromJson(jsonMap);
      } else {
        print("Gemini API error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error calling Gemini API: $e");
      return null;
    }
  }

  String _getMimeType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    } else if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    } else if (lowerPath.endsWith('.heic')) {
       return 'image/heic';
    } else if (lowerPath.endsWith('.heif')) {
       return 'image/heif';
    } else {
      return 'image/jpeg'; // Default assumption
    }
  }
}
