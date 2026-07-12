class ChatMessageModel {
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;

  const ChatMessageModel({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp,
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '?',
        text: map['text'] ?? '',
        timestamp: map['timestamp'] ?? 0,
      );
}
