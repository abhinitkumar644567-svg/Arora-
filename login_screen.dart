import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../widgets/liquid_glass_box.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isOtpStep = false;
  bool _isLoading = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onOtpFocusChanged);
  }

  void _onOtpFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpFocusNode.removeListener(_onOtpFocusChanged);
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      HapticFeedback.heavyImpact();
      _showToast('कृपया सही 10 अंकों का मोबाइल नंबर दर्ज करें।', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Firebase Phone Auth हुक: यहाँ FirebaseAuth.instance.verifyPhoneNumber जोड़ें
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isOtpStep = true;
    });
    _startResendTimer();
    _showToast('+91 $phone पर 6 अंकों का OTP भेजा गया है।');

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      HapticFeedback.heavyImpact();
      _showToast('कृपया पूरा 6 अंकों का OTP दर्ज करें।', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Firebase OTP वेरिफिकेशन हुक: यहाँ PhoneAuthProvider.credential सत्यापित करें
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    appStore.loginWithPhone(_phoneController.text.trim());
    setState(() => _isLoading = false);
    _navigateToMainShell();
  }

  Future<void> _openGoogleLoginSheet() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    final nameController = TextEditingController(
      text: appStore.profile.name == 'अतिथि यूज़र' ? '' : appStore.profile.name,
    );
    final emailController = TextEditingController(
      text: appStore.profile.email.isNotEmpty
          ? appStore.profile.email
          : 'student@gmail.com',
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: LiquidGlassBox(
            borderRadius: 30,
            blur: 28,
            surfaceOpacity: 0.76,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    _GoogleGlyphBadge(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google से जारी रखें',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'अकाउंट चुनें या अपनी जानकारी कन्फ़र्म करें',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildInputBox(
                  controller: nameController,
                  hint: 'आपका पूरा नाम',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                _buildInputBox(
                  controller: emailController,
                  hint: 'Google ईमेल पता',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'लॉगिन कन्फ़र्म करें',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      nameController.dispose();
      emailController.dispose();
      return;
    }

    final enteredName = nameController.text.trim();
    final enteredEmail = emailController.text.trim();
    nameController.dispose();
    emailController.dispose();

    setState(() => _isLoading = true);
    // Firebase Google Sign-In हुक: यहाँ GoogleSignIn().signIn() जोड़ें
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    appStore.loginWithGoogle(
      name: enteredName.isEmpty ? 'Google यूज़र' : enteredName,
      email: enteredEmail.isEmpty ? 'user@gmail.com' : enteredEmail,
    );

    setState(() => _isLoading = false);
    _navigateToMainShell();
  }

  void _navigateToMainShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // टॉप ऐप आइकन + ब्रांडिंग
                      LiquidGlassBox(
                        width: 78,
                        height: 78,
                        borderRadius: 26,
                        padding: EdgeInsets.zero,
                        surfaceOpacity: 0.72,
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 36,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Liquid Glass Space',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isOtpStep
                            ? '+91 ${_phoneController.text.trim()} पर भेजा गया 6-अंकों का कोड डालें'
                            : 'चैट, इमेज नोट्स और प्रोफ़ाइल के लिए सुरक्षित साइन-इन',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // मुख्य Liquid Glass लॉगिन कार्ड
                      LiquidGlassBox(
                        borderRadius: 32,
                        blur: 26,
                        surfaceOpacity: 0.62,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // लॉगिन स्टेटस चिप
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isOtpStep ? 'OTP सत्यापन' : 'मोबाइल लॉगिन',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007AFF)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _isOtpStep ? 'स्टेप 2/2' : 'स्टेप 1/2',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Phone Input <-> 6-Box OTP Input स्विचर
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _isOtpStep
                                  ? _buildOtpStep()
                                  : _buildPhoneStep(),
                            ),

                            const SizedBox(height: 22),

                            // विभाजक रेखा
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.black.withValues(alpha: 0.10),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'या फिर',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.black.withValues(alpha: 0.10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google साइन-इन ग्लास बटन
                            LiquidGlassBox(
                              borderRadius: 20,
                              blur: 14,
                              surfaceOpacity: 0.78,
                              showShadow: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              onTap: _isLoading ? null : _openGoogleLoginSheet,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleGlyphBadge(size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Google से लॉगिन करें',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'आपकी जानकारी सुरक्षित रूप से एन्क्रिप्टेड रहती है',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputBox(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          hint: '10 अंकों का मोबाइल नंबर',
          prefixText: '+91  ',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          digitsOnly: true,
          maxLength: 10,
        ),
        const SizedBox(height: 16),
        _buildPrimaryActionButton(
          label: 'OTP प्राप्त करें',
          icon: Icons.arrow_forward_rounded,
          onPressed: _isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final code = _otpController.text;
    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6-अंकों का iOS स्टाइल ग्लास OTP बॉक्स ग्रिड
        GestureDetector(
          onTap: () => _otpFocusNode.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasDigit = index < code.length;
                  final isCurrent = _otpFocusNode.hasFocus &&
                      (index == code.length ||
                          (code.length == 6 && index == 5));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasDigit
                          ? Colors.white.withValues(alpha: 0.90)
                          : Colors.white.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF007AFF)
                            : Colors.white.withValues(alpha: 0.92),
                        width: isCurrent ? 2.0 : 1.2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF007AFF)
                                    .withValues(alpha: 0.18),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      hasDigit ? code[index] : '',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enableInteractiveSelection: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.length == 6 && !_isLoading) {
                        _verifyOtp();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPrimaryActionButton(
          label: 'सत्यापित करें और आगे बढ़ें',
          icon: Icons.verified_user_rounded,
          onPressed: _isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _resendTimer?.cancel();
                      _otpController.clear();
                      setState(() {
                        _isOtpStep = false;
                        _resendSeconds = 0;
                      });
                    },
              child: const Text(
                'नंबर बदलें',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: (_resendSeconds > 0 || _isLoading)
                  ? null
                  : () {
                      _startResendTimer();
                      _showToast('नया OTP फिर से भेज दिया गया है।');
                    },
              child: Text(
                _resendSeconds > 0
                    ? 'पुनः भेजें (${_resendSeconds}s)'
                    : 'OTP पुनः भेजें',
                style: TextStyle(
                  color: _resendSeconds > 0
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    String? prefixText,
    bool digitsOnly = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: [
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 21),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 19),
                ],
              ),
      ),
    );
  }
}

/// बिना किसी बाहरी इमेज एसेट के साफ़ Google बैज आइकन
class _GoogleGlyphBadge extends StatelessWidget {
  final double size;

  const _GoogleGlyphBadge({this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.18),
            blurRadius: 8,
          ),
        ],
      ),
      child: Container(
        width: size - 4.5,
        height: size - 4.5,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size * 0.56,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}