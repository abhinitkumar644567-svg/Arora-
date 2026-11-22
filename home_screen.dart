import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../widgets/liquid_glass_box.dart';
import '../main_shell.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  String _formattedToday() {
    final now = DateTime.now();
    const weekdays = [
      'सोमवार',
      'मंगलवार',
      'बुधवार',
      'गुरुवार',
      'शुक्रवार',
      'शनिवार',
      'रविवार',
    ];
    const months = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर',
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} $month';
  }

  String _authLabel(AuthMethod method) {
    switch (method) {
      case AuthMethod.google:
        return 'Google वेरिफ़ाइड';
      case AuthMethod.phone:
        return 'Phone OTP वेरिफ़ाइड';
      case AuthMethod.none:
        return 'लोकल सेशन';
    }
  }

  void _openProfile(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final profile = appStore.profile;
        final recentNotes = appStore.filteredNotes().take(6).toList();
        final latestMessage =
            appStore.messages.isNotEmpty ? appStore.messages.last : null;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            6,
            20,
            MainShell.bottomDockClearance + 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. हीरो ग्लास ओवरव्यू कार्ड
              _buildHeroSummaryCard(context, profile),
              const SizedBox(height: 18),

              // 2. प्रोफ़ाइल पूरी करने का स्मार्ट कार्ड (यदि पता/नाम अधूरा हो)
              if (!profile.isProfileComplete ||
                  profile.address == 'अपना पता यहाँ अपडेट करें') ...[
                _buildProfileCompletionBanner(context),
                const SizedBox(height: 18),
              ],

              // 3. क्विक एक्सेस बेंटो ग्रिड (चैट और इमेज नोट्स)
              const _SectionHeader(
                title: 'त्वरित एक्सेस',
                subtitle: 'एक टैप में मुख्य सेक्शन खोलें',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BentoActionTile(
                      title: 'चैट रूम',
                      subtitle: '${appStore.totalMessagesCount} मैसेज',
                      badgeText: 'लाइव',
                      icon: Icons.chat_bubble_rounded,
                      accentColor: const Color(0xFF007AFF),
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _BentoActionTile(
                      title: 'इमेज नोट्स',
                      subtitle: '${appStore.totalNotesCount} फाइल्स सेव',
                      badgeText: '${appStore.pinnedNotesCount} पिन',
                      icon: Icons.photo_library_rounded,
                      accentColor: const Color(0xFF10B981),
                      onTap: () => onNavigateTab(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. हाल की चैट का प्रीव्यू कार्ड
              _SectionHeader(
                title: 'हाल की बातचीत',
                actionLabel: 'चैट खोलें',
                onActionTap: () => onNavigateTab(1),
              ),
              const SizedBox(height: 10),
              _buildLatestChatCard(latestMessage),
              const SizedBox(height: 22),

              // 5. पिन किए गए और हाल के इमेज नोट्स (स्वाइप कैरोसेल)
              _SectionHeader(
                title: 'पिन व हाल के इमेज नोट्स',
                actionLabel: 'सभी देखें',
                onActionTap: () => onNavigateTab(2),
              ),
              const SizedBox(height: 12),
              if (recentNotes.isEmpty)
                _buildEmptyNotesCard()
              else
                SizedBox(
                  height: 184,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: recentNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return _NotePreviewCard(
                        note: recentNotes[index],
                        onTap: () => onNavigateTab(2),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSummaryCard(BuildContext context, UserProfile profile) {
    return LiquidGlassBox(
      borderRadius: 30,
      blur: 26,
      surfaceOpacity: 0.66,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formattedToday(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _authLabel(profile.authMethod),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'आपका स्मार्ट स्टडी व चैट स्पेस',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'सारे इमेज नोट्स, लाइव चैट और व्यक्तिगत प्रोफ़ाइल एक ही स्मूद ग्लास इंटरफ़ेस में तैयार हैं।',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),

          // 3 मिनी स्टैट्स पिल
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                _HeroMetricItem(
                  value: '${appStore.totalNotesCount}',
                  label: 'कुल नोट्स',
                  color: const Color(0xFF007AFF),
                ),
                _metricDivider(),
                _HeroMetricItem(
                  value: '${appStore.pinnedNotesCount}',
                  label: 'पिन नोट्स',
                  color: const Color(0xFF10B981),
                ),
                _metricDivider(),
                _HeroMetricItem(
                  value: '${appStore.totalMessagesCount}',
                  label: 'मैसेज',
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildProfileCompletionBanner(BuildContext context) {
    return LiquidGlassBox(
      borderRadius: 24,
      blur: 20,
      surfaceOpacity: 0.62,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _openProfile(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'अपनी प्रोफ़ाइल पूरी करें',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'नाम, पता और प्रोफ़ाइल पिक्चर सेव करने के लिए टैप करें',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestChatCard(ChatMessage? latestMessage) {
    final previewText = latestMessage == null
        ? 'अभी कोई बातचीत नहीं हुई है। पहला मैसेज भेजने के लिए टैप करें।'
        : (latestMessage.text.isNotEmpty
            ? latestMessage.text
            : 'इमेज अटैचमेंट भेजा गया');

    return LiquidGlassBox(
      borderRadius: 24,
      blur: 22,
      surfaceOpacity: 0.64,
      padding: const EdgeInsets.all(16),
      onTap: () => onNavigateTab(1),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF007AFF), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      latestMessage == null
                          ? 'नई चैट शुरू करें'
                          : (latestMessage.isMe ? 'आपने भेजा' : 'ताज़ा उत्तर'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    if (latestMessage != null)
                      Text(
                        latestMessage.formattedTime,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotesCard() {
    return LiquidGlassBox(
      borderRadius: 24,
      blur: 20,
      surfaceOpacity: 0.60,
      padding: const EdgeInsets.all(20),
      onTap: () => onNavigateTab(2),
      child: const Row(
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 32,
            color: Color(0xFF007AFF),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'कोई इमेज नोट सेव नहीं है',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'अपना पहला इमेज नोट जोड़ने के लिए यहाँ टैप करें।',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeroMetricItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BentoActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _BentoActionTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBox(
      borderRadius: 26,
      blur: 22,
      surfaceOpacity: 0.64,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePreviewCard extends StatelessWidget {
  final ImageNote note;
  final VoidCallback onTap;

  const _NotePreviewCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: LiquidGlassBox(
        borderRadius: 24,
        blur: 20,
        surfaceOpacity: 0.66,
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // इमेज या ग्रेडिएंट प्रीव्यू बॉक्स
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (note.hasLocalImage)
                      Image.memory(
                        note.imageBytes!,
                        fit: BoxFit.cover,
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              note.accentColor.withValues(alpha: 0.24),
                              note.accentColor.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: note.accentColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          note.subject,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: note.accentColor,
                          ),
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note.formattedDate,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}