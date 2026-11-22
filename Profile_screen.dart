import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../widgets/liquid_glass_box.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  Uint8List? _draftAvatarBytes;
  bool _avatarRemoved = false;
  bool _isEditing = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final profile = appStore.profile;
    _nameController = TextEditingController(text: profile.name);
    _addressController = TextEditingController(text: profile.address);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _draftAvatarBytes = profile.avatarBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _resetDraftFromStore() {
    final profile = appStore.profile;
    _nameController.text = profile.name;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _draftAvatarBytes = profile.avatarBytes;
    _avatarRemoved = false;
  }

  void _toggleEditMode() {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      if (_isEditing) {
        _resetDraftFromStore();
        _isEditing = false;
      } else {
        _isEditing = true;
      }
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      setState(() {
        _draftAvatarBytes = bytes;
        _avatarRemoved = false;
        _isEditing = true;
      });
    } catch (_) {
      if (!mounted) return;
      _showToast('प्रोफ़ाइल फोटो चुनने में समस्या आई।', isError: true);
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _openAvatarOptionsSheet() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    final hasPhoto = _draftAvatarBytes != null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: LiquidGlassBox(
              borderRadius: 28,
              blur: 28,
              surfaceOpacity: 0.80,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'प्रोफ़ाइल पिक्चर अपडेट करें',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoActionTile(
                          icon: Icons.photo_library_rounded,
                          label: 'गैलरी से चुनें',
                          color: const Color(0xFF007AFF),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _pickAvatar(ImageSource.gallery);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PhotoActionTile(
                          icon: Icons.camera_alt_rounded,
                          label: 'कैमरा खोलें',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _pickAvatar(ImageSource.camera);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          HapticFeedback.selectionClick();
                          setState(() {
                            _draftAvatarBytes = null;
                            _avatarRemoved = true;
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 19,
                        ),
                        label: const Text(
                          'मौजूदा फोटो हटाएँ',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                              const Color(0xFFDC2626).withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAvatarPreview() {
    if (_draftAvatarBytes == null) {
      _openAvatarOptionsSheet();
      return;
    }
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      _draftAvatarBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LiquidGlassBox(
                      borderRadius: 50,
                      blur: 20,
                      surfaceOpacity: 0.30,
                      padding: const EdgeInsets.all(10),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    appStore.updateProfile(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      avatarBytes: _avatarRemoved ? null : _draftAvatarBytes,
      clearAvatar: _avatarRemoved,
    );

    setState(() {
      _isEditing = false;
      _avatarRemoved = false;
    });

    _showToast('आपकी प्रोफ़ाइल सफलतापूर्वक सेव हो गई!');
  }

  Future<void> _confirmLogout() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'अकाउंट से लॉगआउट करें?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'लॉगआउट करने पर आप लॉगिन पेज पर वापस पहुँच जाएँगे। क्या आप जारी रखना चाहते हैं?',
          style: TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'लॉगआउट करें',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    appStore.logout();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  String _authBadgeText(AuthMethod method) {
    switch (method) {
      case AuthMethod.google:
        return 'Google अकाउंट से कनेक्टेड';
      case AuthMethod.phone:
        return 'Phone OTP से वेरिफ़ाइड';
      case AuthMethod.none:
        return 'लोकल प्रोफ़ाइल';
    }
  }

  String _formatUpdatedAt(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour12:$minute $period';
  }

  String _previewInitials(String fallback) {
    final text = _nameController.text.trim();
    if (text.isEmpty) return fallback;
    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: LiquidMeshBackground(
          child: SafeArea(
            child: ListenableBuilder(
              listenable: appStore,
              builder: (context, _) {
                final profile = appStore.profile;

                return Column(
                  children: [
                    // 1. टॉप Liquid Glass नेविगेशन बार
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: Row(
                        children: [
                          LiquidGlassBox(
                            borderRadius: 18,
                            blur: 20,
                            surfaceOpacity: 0.70,
                            padding: const EdgeInsets.all(10),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 19,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'मेरी प्रोफ़ाइल',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          LiquidGlassBox(
                            borderRadius: 18,
                            blur: 20,
                            surfaceOpacity: 0.74,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            onTap: _toggleEditMode,
                            child: Text(
                              _isEditing ? 'रद्द करें' : 'एडिट',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _isEditing
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. स्क्रॉल होने वाला मुख्य प्रोफ़ाइल कंटेंट
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // हीरो प्रोफ़ाइल पिक्चर और पहचान कार्ड
                              _buildAvatarIdentityCard(profile),
                              const SizedBox(height: 18),

                              // व्यक्तिगत जानकारी फॉर्म कार्ड
                              LiquidGlassBox(
                                borderRadius: 28,
                                blur: 24,
                                surfaceOpacity: 0.66,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'व्यक्तिगत विवरण',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (_isEditing
                                                    ? const Color(0xFF007AFF)
                                                    : const Color(0xFF10B981))
                                                .withValues(alpha: 0.13),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            _isEditing
                                                ? 'एडिट मोड चालू'
                                                : 'सेव है',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: _isEditing
                                                  ? const Color(0xFF007AFF)
                                                  : const Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    _buildProfileField(
                                      label: 'पूरा नाम',
                                      hint: 'अपना पूरा नाम लिखें',
                                      controller: _nameController,
                                      icon: Icons.badge_rounded,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.name,
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'कृपया अपना नाम दर्ज करें';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 15),

                                    _buildProfileField(
                                      label: 'पूरा पता (Address)',
                                      hint: 'गाँव/शहर, जिला और पिनकोड लिखें',
                                      controller: _addressController,
                                      icon: Icons.location_on_rounded,
                                      enabled: _isEditing,
                                      maxLines: 3,
                                      keyboardType: TextInputType.streetAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'कृपया अपना पता दर्ज करें';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 15),

                                    _buildProfileField(
                                      label: 'मोबाइल नंबर',
                                      hint: '+91 9876543210',
                                      controller: _phoneController,
                                      icon: Icons.phone_iphone_rounded,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 15),

                                    _buildProfileField(
                                      label: 'ईमेल पता',
                                      hint: 'example@gmail.com',
                                      controller: _emailController,
                                      icon: Icons.alternate_email_rounded,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.emailAddress,
                                    ),

                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                      child: _isEditing
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 22,
                                              ),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 54,
                                                child: ElevatedButton.icon(
                                                  onPressed: _saveProfile,
                                                  icon: const Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 20,
                                                  ),
                                                  label: const Text(
                                                    'बदलाव सेव करें',
                                                    style: TextStyle(
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF007AFF),
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // अंतिम अपडेट समय
                              Center(
                                child: Text(
                                  'अंतिम अपडेट: ${_formatUpdatedAt(profile.updatedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // लॉगआउट Liquid Glass कार्ड
                              LiquidGlassBox(
                                borderRadius: 22,
                                blur: 20,
                                surfaceOpacity: 0.66,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                onTap: _confirmLogout,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'अकाउंट से लॉगआउट करें',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarIdentityCard(UserProfile profile) {
    final displayName = _nameController.text.trim().isEmpty
        ? 'आपका नाम'
        : _nameController.text.trim();

    return LiquidGlassBox(
      borderRadius: 30,
      blur: 24,
      surfaceOpacity: 0.66,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        children: [
          // प्रोफ़ाइल पिक्चर + कैमरा बैज
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _isEditing
                    ? _openAvatarOptionsSheet
                    : _openAvatarPreview,
                child: LiquidGlassBox(
                  borderRadius: 80,
                  blur: 18,
                  surfaceOpacity: 0.78,
                  padding: const EdgeInsets.all(6),
                  child: Hero(
                    tag: 'user_profile_avatar',
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF007AFF),
                      backgroundImage: _draftAvatarBytes != null
                          ? MemoryImage(_draftAvatarBytes!)
                          : null,
                      child: _draftAvatarBytes == null
                          ? Text(
                              _previewInitials(profile.initials),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openAvatarOptionsSheet,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A84FF), Color(0xFF0066E5)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isPickingPhoto
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 13.5,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(width: 6),
                Text(
                  _authBadgeText(profile.authMethod),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // मिनी एक्टिविटी समरी स्ट्रिप
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                _ProfileStatItem(
                  value: '${appStore.totalNotesCount}',
                  label: 'इमेज नोट्स',
                ),
                _statDivider(),
                _ProfileStatItem(
                  value: '${appStore.pinnedNotesCount}',
                  label: 'पिन नोट्स',
                ),
                _statDivider(),
                _ProfileStatItem(
                  value: '${appStore.totalMessagesCount}',
                  label: 'चैट मैसेज',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF007AFF).withValues(alpha: 0.48)
                  : Colors.white.withValues(alpha: 0.90),
              width: enabled ? 1.4 : 1.1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                icon,
                color: enabled
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF64748B),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}