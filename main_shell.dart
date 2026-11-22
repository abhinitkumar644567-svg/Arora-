import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../widgets/liquid_glass_box.dart';
import 'chat/chat_screen.dart';
import 'home/home_screen.dart';
import 'notes/image_notes_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// बाकी स्क्रीनें (Home, Chat, Notes) इस ऊँचाई का उपयोग करके
  /// फ्लोटिंग ग्लास बॉटम बार के ऊपर सही स्पेसिंग रख सकती हैं।
  static const double bottomDockClearance = 104.0;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  late final List<Widget> _pages;

  static const List<_NavTabConfig> _tabs = [
    _NavTabConfig(
      label: 'होम',
      subtitle: 'डैशबोर्ड और त्वरित एक्सेस',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavTabConfig(
      label: 'चैट',
      subtitle: 'मॉडर्न ग्लास मैसेजिंग',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavTabConfig(
      label: 'नोट्स',
      subtitle: 'सेव किए गए इमेज नोट्स',
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onNavigateTab: _selectTab),
      const ChatScreen(),
      const ImageNotesScreen(),
    ];
  }

  void _selectTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    if (_currentIndex == index) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _openProfileScreen() {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleHardwareBack() {
    // यदि कीबोर्ड खुला है, तो पहले उसे बंद करें
    if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    // यदि यूज़र Chat या Notes टैब पर है, तो पहले Home पर वापस लाएँ
    if (_currentIndex != 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = 0);
      return;
    }

    // Home टैब पर दो बार बैक दबाने पर सुरक्षित एग्ज़िट
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'ऐप से बाहर निकलने के लिए एक बार फिर बैक दबाएँ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 108),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'सुप्रभात';
    if (hour < 17) return 'नमस्कार';
    return 'शुभ संध्या';
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;
    final activeTab = _tabs[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleHardwareBack();
      },
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: true,
        body: LiquidMeshBackground(
          child: Stack(
            children: [
              // मुख्य लेआउट: टॉप ग्लास हेडर + एक्टिव पेज
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildTopHeader(activeTab),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),

              // नीचे फ्लोटिंग iOS Liquid Glass बॉटम नेविगेशन डॉक
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: isKeyboardOpen,
                  child: AnimatedSlide(
                    offset: isKeyboardOpen
                        ? const Offset(0, 1.35)
                        : Offset.zero,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isKeyboardOpen ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: _buildFloatingGlassDock(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ऊपरी हेडर: बाईं तरफ डायनामिक शीर्षक और दाएँ कोने में लाइव प्रोफ़ाइल बटन
  Widget _buildTopHeader(_NavTabConfig activeTab) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final profile = appStore.profile;
        final firstName = profile.name.trim().isEmpty
            ? 'दोस्त'
            : profile.name.trim().split(RegExp(r'\s+')).first;

        final headerTitle =
            _currentIndex == 0 ? '${_timeBasedGreeting()}, $firstName' : activeTab.label;
        final headerSubtitle = _currentIndex == 0
            ? (profile.address.trim().isNotEmpty
                ? profile.address.trim()
                : activeTab.subtitle)
            : activeTab.subtitle;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Text(
                        headerTitle,
                        key: ValueKey(headerTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headerSubtitle,
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
              ),
              const SizedBox(width: 12),

              // ऊपरी दाएँ कोने में प्रोफ़ाइल सेक्शन बटन (सेव की गई फोटो + Hero एनीमेशन)
              Tooltip(
                message: 'प्रोफ़ाइल देखें',
                child: LiquidGlassBox(
                  borderRadius: 50,
                  blur: 20,
                  surfaceOpacity: 0.72,
                  padding: const EdgeInsets.all(4),
                  onTap: _openProfileScreen,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'user_profile_avatar',
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF007AFF),
                          backgroundImage: profile.avatarBytes != null
                              ? MemoryImage(profile.avatarBytes!)
                              : null,
                          child: profile.avatarBytes == null
                              ? Text(
                                  profile.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // ऑनलाइन / प्रोफ़ाइल स्टेटस डॉट
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: profile.isProfileComplete
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// नीचे फ्लोटिंग iOS 26/27 Liquid Glass पिल नेविगेशन डॉक
  Widget _buildFloatingGlassDock() {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: LiquidGlassBox(
                  borderRadius: 36,
                  blur: 28,
                  surfaceOpacity: 0.68,
                  borderWidth: 1.45,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final isSelected = _currentIndex == index;
                      final badgeCount = index == 2
                          ? appStore.totalNotesCount
                          : 0;

                      return Expanded(
                        flex: isSelected ? 4 : 3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectTab(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.94),
                                        Colors.white.withValues(alpha: 0.72),
                                      ],
                                    )
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      width: 1.1,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF007AFF)
                                            .withValues(alpha: 0.14),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      isSelected ? tab.activeIcon : tab.icon,
                                      size: 22,
                                      color: isSelected
                                          ? const Color(0xFF007AFF)
                                          : const Color(0xFF475569),
                                    ),
                                    if (!isSelected && badgeCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -7,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF007AFF),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            badgeCount > 9
                                                ? '9+'
                                                : '$badgeCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  child: isSelected
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 7),
                                          child: Text(
                                            tab.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF007AFF),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavTabConfig {
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const _NavTabConfig({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}
