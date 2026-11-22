import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// लॉगिन के प्रकार को ट्रैक करने के लिए Enum
enum AuthMethod { none, google, phone }

/// चैट मैसेज की डिलीवरी स्थिति
enum MessageStatus { sending, sent, delivered, read }

/// यूज़र की व्यक्तिगत जानकारी और प्रोफ़ाइल पिक्चर का मॉडल
@immutable
class UserProfile {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final AuthMethod authMethod;
  final Uint8List? avatarBytes;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.address,
    this.phone = '',
    this.email = '',
    this.authMethod = AuthMethod.none,
    this.avatarBytes,
    required this.updatedAt,
  });

  /// यदि प्रोफ़ाइल पिक्चर नहीं है, तो नाम के शुरुआती अक्षर (Initials) दिखाने के लिए
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  bool get isProfileComplete =>
      name.trim().isNotEmpty && address.trim().isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    AuthMethod? authMethod,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      authMethod: authMethod ?? this.authMethod,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firebase Firestore या SharedPreferences में सेव करने के लिए Map कन्वर्ज़न
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'authMethod': authMethod.name,
      'avatarBase64': avatarBytes != null ? base64Encode(avatarBytes!) : null,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawAvatar = map['avatarBase64'] as String?;
    return UserProfile(
      id: (map['id'] as String?) ?? 'local_user',
      name: (map['name'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      authMethod: AuthMethod.values.firstWhere(
        (m) => m.name == map['authMethod'],
        orElse: () => AuthMethod.none,
      ),
      avatarBytes:
          (rawAvatar != null && rawAvatar.isNotEmpty) ? base64Decode(rawAvatar) : null,
      updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// चैट स्क्रीन के प्रत्येक मैसेज का मॉडल
@immutable
class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;
  final Uint8List? attachmentBytes;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.status = MessageStatus.read,
    this.attachmentBytes,
  });

  bool get hasAttachment => attachmentBytes != null;

  /// बिना किसी बाहरी पैकेज के 12-घंटे का समय फॉर्मेट (जैसे: 10:45 AM)
  String get formattedTime {
    final hour12 = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    DateTime? timestamp,
    MessageStatus? status,
    Uint8List? attachmentBytes,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'attachmentBase64':
          attachmentBytes != null ? base64Encode(attachmentBytes!) : null,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final rawAttachment = map['attachmentBase64'] as String?;
    return ChatMessage(
      id: (map['id'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      isMe: (map['isMe'] as bool?) ?? true,
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      attachmentBytes: (rawAttachment != null && rawAttachment.isNotEmpty)
          ? base64Decode(rawAttachment)
          : null,
    );
  }
}

/// इमेज फॉर्मेट में सेव किए गए नोट्स का मॉडल
@immutable
class ImageNote {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime createdAt;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final int accentColorValue;
  final bool isPinned;

  const ImageNote({
    required this.id,
    required this.title,
    required this.subject,
    this.description = '',
    required this.createdAt,
    this.imageBytes,
    this.imageUrl,
    this.accentColorValue = 0xFF007AFF,
    this.isPinned = false,
  });

  Color get accentColor => Color(accentColorValue);

  bool get hasLocalImage => imageBytes != null;

  bool get hasNetworkImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  /// तारीख का साफ़ फॉर्मेट (जैसे: 22 Nov)
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }

  ImageNote copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    DateTime? createdAt,
    Uint8List? imageBytes,
    String? imageUrl,
    int? accentColorValue,
    bool? isPinned,
  }) {
    return ImageNote(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'imageBase64': imageBytes != null ? base64Encode(imageBytes!) : null,
      'imageUrl': imageUrl,
      'accentColorValue': accentColorValue,
      'isPinned': isPinned,
    };
  }

  factory ImageNote.fromMap(Map<String, dynamic> map) {
    final rawImage = map['imageBase64'] as String?;
    return ImageNote(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'बिना शीर्षक नोट',
      subject: (map['subject'] as String?) ?? 'सामान्य',
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      imageBytes:
          (rawImage != null && rawImage.isNotEmpty) ? base64Decode(rawImage) : null,
      imageUrl: map['imageUrl'] as String?,
      accentColorValue: (map['accentColorValue'] as int?) ?? 0xFF007AFF,
      isPinned: (map['isPinned'] as bool?) ?? false,
    );
  }
}

/// पूरे ऐप के लिए सेंट्रलाइज्ड रिएक्टिव स्टोर (Singleton Pattern)
class AppStore extends ChangeNotifier {
  AppStore._internal() {
    _seedInitialData();
  }

  static final AppStore instance = AppStore._internal();

  bool _isLoggedIn = false;
  bool _isPartnerTyping = false;

  late UserProfile _profile;
  final List<ChatMessage> _messages = [];
  final List<ImageNote> _notes = [];

  // --- Getters ---
  bool get isLoggedIn => _isLoggedIn;
  bool get isPartnerTyping => _isPartnerTyping;
  UserProfile get profile => _profile;

  UnmodifiableListView<ChatMessage> get messages =>
      UnmodifiableListView(_messages);

  UnmodifiableListView<ImageNote> get notes => UnmodifiableListView(_notes);

  int get totalNotesCount => _notes.length;
  int get pinnedNotesCount => _notes.where((n) => n.isPinned).length;
  int get totalMessagesCount => _messages.length;

  /// इमेज नोट्स के लिए उपलब्ध सभी कैटेगरी (फ़िल्टर चिप्स के लिए)
  List<String> get noteSubjects {
    final set = <String>{'सभी', 'भौतिकी', 'रसायन', 'गणित', 'सामान्य'};
    for (final note in _notes) {
      if (note.subject.trim().isNotEmpty) {
        set.add(note.subject.trim());
      }
    }
    return set.toList(growable: false);
  }

  /// शुरुआती डेमो डेटा ताकि ऐप खोलते ही इंटरफ़ेस भरा-पूरा और प्रीमियम दिखे
  void _seedInitialData() {
    final now = DateTime.now();

    _profile = UserProfile(
      id: 'usr_001',
      name: 'अतिथि यूज़र',
      address: 'अपना पता यहाँ अपडेट करें',
      phone: '',
      email: '',
      authMethod: AuthMethod.none,
      updatedAt: now,
    );

    _messages.addAll([
      ChatMessage(
        id: 'msg_1',
        text: 'नमस्ते! आपके Liquid Glass ऐप में स्वागत है। यहाँ आप सीधे चैट और स्टडी डिस्कशन कर सकते हैं।',
        isMe: false,
        timestamp: now.subtract(const Duration(minutes: 14)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_2',
        text: 'बहुत बढ़िया! क्या हम यहाँ इमेज नोट्स भी शेयर कर सकते हैं?',
        isMe: true,
        timestamp: now.subtract(const Duration(minutes: 10)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_3',
        text: 'जी हाँ, नीचे दिए गए गैलरी आइकन से तुरंत कोई भी फोटो या नोट्स भेज सकते हैं।',
        isMe: false,
        timestamp: now.subtract(const Duration(minutes: 8)),
        status: MessageStatus.read,
      ),
    ]);

    _notes.addAll([
      ImageNote(
        id: 'note_1',
        title: 'विद्युत आवेश तथा क्षेत्र - फॉर्मूला शीट',
        subject: 'भौतिकी',
        description: 'अध्याय 1 के सभी महत्वपूर्ण सूत्र, गॉस प्रमेय और SI मात्रक।',
        createdAt: now.subtract(const Duration(days: 1)),
        accentColorValue: 0xFF007AFF,
        isPinned: true,
      ),
      ImageNote(
        id: 'note_2',
        title: 'कार्बनिक अभिक्रियाएँ (Name Reactions)',
        subject: 'रसायन',
        description: 'बोर्ड परीक्षा के लिए प्रमुख रासायनिक समीकरणों का शॉर्ट चार्ट।',
        createdAt: now.subtract(const Duration(days: 2)),
        accentColorValue: 0xFF10B981,
        isPinned: true,
      ),
      ImageNote(
        id: 'note_3',
        title: 'समाकलन (Integration) के मुख्य सूत्र',
        subject: 'गणित',
        description: 'सभी मानक समाकलन फॉर्मूले और त्वरित रिवीज़न नोट्स।',
        createdAt: now.subtract(const Duration(days: 3)),
        accentColorValue: 0xFF6366F1,
      ),
      ImageNote(
        id: 'note_4',
        title: 'साप्ताहिक रिवीज़न टाइमटेबल',
        subject: 'सामान्य',
        description: 'दैनिक अध्ययन और मॉक टेस्ट का संतुलित शेड्यूल।',
        createdAt: now.subtract(const Duration(days: 5)),
        accentColorValue: 0xFFF59E0B,
      ),
    ]);
  }

  // --- Auth Actions ---

  void loginWithPhone(String phoneNumber) {
    final cleaned = phoneNumber.trim();
    _isLoggedIn = true;
    _profile = _profile.copyWith(
      phone: '+91 $cleaned',
      authMethod: AuthMethod.phone,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void loginWithGoogle({required String name, required String email}) {
    _isLoggedIn = true;
    _profile = _profile.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : _profile.name,
      email: email.trim(),
      authMethod: AuthMethod.google,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // --- Profile Actions ---

  void updateProfile({
    String? name,
    String? address,
    String? phone,
    String? email,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
  }) {
    _profile = _profile.copyWith(
      name: name?.trim(),
      address: address?.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      avatarBytes: avatarBytes,
      clearAvatar: clearAvatar,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // --- Chat Actions ---

  Future<void> sendMessage(String text, {Uint8List? attachmentBytes}) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty && attachmentBytes == null) return;

    final id = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    final outgoing = ChatMessage(
      id: id,
      text: cleaned,
      isMe: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachmentBytes: attachmentBytes,
    );

    _messages.add(outgoing);
    notifyListeners();

    // हल्का रियल-टाइम अनुभव देने के लिए डिलीवरी व ऑटो-रिप्लाई सिमुलेशन
    await Future.delayed(const Duration(milliseconds: 450));
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(status: MessageStatus.read);
      _isPartnerTyping = true;
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 900));
    _isPartnerTyping = false;
    _messages.add(
      ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        text: attachmentBytes != null
            ? 'आपकी इमेज मिल गई है! बहुत साफ़ क्वालिटी है।'
            : 'संदेश प्राप्त हुआ: "$cleaned" — आगे क्या मदद चाहिए?',
        isMe: false,
        timestamp: DateTime.now(),
        status: MessageStatus.read,
      ),
    );
    notifyListeners();
  }

  void deleteMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  // --- Image Notes Actions ---

  void addImageNote({
    required String title,
    required String subject,
    String description = '',
    Uint8List? imageBytes,
    String? imageUrl,
    int? accentColorValue,
  }) {
    final palette = [
      0xFF007AFF,
      0xFF10B981,
      0xFF6366F1,
      0xFFF59E0B,
      0xFFEC4899,
      0xFF0EA5E9,
    ];
    final chosenColor =
        accentColorValue ?? palette[_notes.length % palette.length];

    final newNote = ImageNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      subject: subject.trim().isEmpty ? 'सामान्य' : subject.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
      imageBytes: imageBytes,
      imageUrl: imageUrl,
      accentColorValue: chosenColor,
    );

    _notes.insert(0, newNote);
    notifyListeners();
  }

  void toggleNotePin(String id) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notes[idx] = _notes[idx].copyWith(isPinned: !_notes[idx].isPinned);
    notifyListeners();
  }

  void deleteImageNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// विषय (Subject) और खोज शब्द (Search Query) के अनुसार नोट्स फ़िल्टर करता है
  /// पिन किए गए नोट्स हमेशा ऊपर दिखते हैं।
  List<ImageNote> filteredNotes({
    String subject = 'सभी',
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final result = _notes.where((note) {
      final matchesSubject = subject == 'सभी' || note.subject == subject;
      if (!matchesSubject) return false;
      if (normalizedQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(normalizedQuery) ||
          note.subject.toLowerCase().contains(normalizedQuery) ||
          note.description.toLowerCase().contains(normalizedQuery);
    }).toList();

    result.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }
}

/// पूरे ऐप में आसान उपयोग के लिए शॉर्टकट रेफ़रेंस
final AppStore appStore = AppStore.instance;