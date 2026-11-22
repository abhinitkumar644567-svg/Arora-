import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS Liquid Glass शैली का रियूज़ेबल ग्लास कंटेनर।
/// इसमें फ्रॉस्टेड ब्लर, चमकदार रिम-लाइटिंग बॉर्डर, सॉफ्ट शैडो और वैकल्पिक टैप एनीमेशन शामिल है।
class LiquidGlassBox extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color tintColor;
  final double surfaceOpacity;
  final double borderWidth;
  final bool showShadow;
  final VoidCallback? onTap;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.borderRadius = 26,
    this.blur = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.tintColor = Colors.white,
    this.surfaceOpacity = 0.58,
    this.borderWidth = 1.35,
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<LiquidGlassBox> createState() => _LiquidGlassBoxState();
}

class _LiquidGlassBoxState extends State<LiquidGlassBox> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final topAlpha = widget.surfaceOpacity.clamp(0.1, 0.95);
    final bottomAlpha = (widget.surfaceOpacity * 0.42).clamp(0.05, 0.85);

    Widget glassBody = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: CustomPaint(
            foregroundPainter: _SpecularGlassBorderPainter(
              borderRadius: widget.borderRadius,
              strokeWidth: widget.borderWidth,
            ),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.48, 1.0],
                  colors: [
                    widget.tintColor.withValues(alpha: topAlpha),
                    widget.tintColor.withValues(alpha: (topAlpha + bottomAlpha) / 2),
                    widget.tintColor.withValues(alpha: bottomAlpha),
                  ],
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return glassBody;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: glassBody,
      ),
    );
  }
}

/// कांच के किनारों पर पड़ने वाली प्राकृतिक रोशनी (Specular Rim Light) बनाता है।
class _SpecularGlassBorderPainter extends CustomPainter {
  final double borderRadius;
  final double strokeWidth;

  const _SpecularGlassBorderPainter({
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.32, 0.68, 1.0],
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.80),
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularGlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// पूरे ऐप के लिए एकसमान, हल्का और आँखों को सुकून देने वाला लाइट मेश बैकग्राउंड।
/// इसके ऊपर LiquidGlassBox का ट्रांसपेरेंट इफ़ेक्ट बेहद उभरकर दिखता है।
class LiquidMeshBackground extends StatelessWidget {
  final Widget child;

  const LiquidMeshBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // बेस पर्ल-स्काई ग्रेडिएंट
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEAF3FF),
                Color(0xFFF7FAFF),
                Color(0xFFEBF7F3),
              ],
            ),
          ),
        ),

        // ऊपरी बाएँ कोने में सॉफ्ट स्काई ब्लू ऑर्ब
        Positioned(
          top: -90,
          left: -70,
          child: _SoftAmbientOrb(
            size: 300,
            color: const Color(0xFF60A5FA).withValues(alpha: 0.28),
          ),
        ),

        // मध्य दाएँ हिस्से में हल्का मिंट-सियान ऑर्ब
        Positioned(
          top: 220,
          right: -110,
          child: _SoftAmbientOrb(
            size: 280,
            color: const Color(0xFF34D399).withValues(alpha: 0.20),
          ),
        ),

        // निचले बाएँ हिस्से में हल्का इंडिगो-लैवेंडर ऑर्ब
        Positioned(
          bottom: -100,
          left: -50,
          child: _SoftAmbientOrb(
            size: 320,
            color: const Color(0xFFA5B4FC).withValues(alpha: 0.24),
          ),
        ),

        // मुख्य स्क्रीन कंटेंट
        child,
      ],
    );
  }
}

class _SoftAmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftAmbientOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}
