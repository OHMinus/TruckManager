import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice_data.dart';

class LineService {
  static const String _channelAccessToken = String.fromEnvironment('LINE_CHANNEL_ACCESS_TOKEN', defaultValue: '');
  static const String _targetUserId = String.fromEnvironment('LINE_TARGET_USER_ID', defaultValue: '');

  Future<bool> sendInvoiceFlexMessage(InvoiceData invoiceData) async {
    if (_channelAccessToken.isEmpty || _targetUserId.isEmpty) {
      print("Error: LINE credentials are not set in the environment.");
      return false;
    }
    try {
      final body = {
        "to": _targetUserId,
        "messages": [
          {
            "type": "flex",
            "altText": "請求のお知らせ",
            "contents": {
              "type": "carousel",
              "contents": [
                {
                  "type": "bubble",
                  "size": "micro",
                  "header": {
                    "type": "box",
                    "layout": "vertical",
                    "contents": [
                      {
                        "type": "text",
                        "text": "請求申請",
                        "color": "#ffffff",
                        "align": "start",
                        "size": "md",
                        "gravity": "center"
                      },
                      {
                        "type": "text",
                        "text": "未処理",
                        "color": "#ffffff",
                        "align": "start",
                        "size": "xs",
                        "gravity": "center",
                        "margin": "lg"
                      },
                      {
                        "type": "box",
                        "layout": "vertical",
                        "contents": [
                          {
                            "type": "box",
                            "layout": "vertical",
                            "contents": [
                              {"type": "filler"}
                            ],
                            "width": "0%",
                            "backgroundColor": "#0D8186",
                            "height": "6px"
                          }
                        ],
                        "backgroundColor": "#9FD8E36E",
                        "height": "6px",
                        "margin": "sm"
                      }
                    ],
                    "backgroundColor": "#27ACB2",
                    "paddingTop": "19px",
                    "paddingAll": "12px",
                    "paddingBottom": "16px"
                  },
                  "body": {
                    "type": "box",
                    "layout": "vertical",
                    "contents": [
                      {
                        "type": "box",
                        "layout": "horizontal",
                        "contents": [
                          {"type": "text", "text": "日付"},
                          {"type": "text", "text": invoiceData.date}
                        ],
                        "flex": 1
                      },
                      {
                        "type": "box",
                        "layout": "horizontal",
                        "contents": [
                          {"type": "text", "text": "金額"},
                          {"type": "text", "text": "¥${invoiceData.price}"}
                        ]
                      },
                      {
                        "type": "box",
                        "layout": "horizontal",
                        "contents": [
                          {"type": "text", "text": "目的"},
                          {"type": "text", "text": invoiceData.purpose}
                        ]
                      },
                      {
                        "type": "box",
                        "layout": "horizontal",
                        "contents": [
                          {"type": "text", "text": "更新"},
                          {"type": "text", "text": "今日"}
                        ]
                      },
                      {"type": "separator"},
                      {
                        "type": "button",
                        "action": {
                          "type": "uri",
                          "label": "詳細を確認",
                          "uri": "http://linecorp.com/" // Dummy URI for now
                        }
                      }
                    ],
                    "spacing": "md",
                    "paddingAll": "12px"
                  },
                  "styles": {
                    "footer": {"separator": false}
                  }
                }
              ]
            }
          }
        ]
      };

      final response = await http.post(
        Uri.parse('https://api.line.me/v2/bot/message/push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_channelAccessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('LINE通知が正常に送信されました。');
        return true;
      } else {
        print('LINE送信エラー: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('LINEサービス内でエラーが発生しました: $e');
      return false;
    }
  }
}
