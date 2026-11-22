import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../widgets/liquid_glass_box.dart';
import '../main_shell.dart';

class ImageNotesScreen extends StatefulWidget {
  const ImageNotesScreen({super.key});

  @override
  State<ImageNotesScreen> createState() => _ImageNotesScreenState();
}

class _ImageNotesScreenState extends State<ImageNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubject = 'सभी';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddNoteSheet() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddImageNoteSheet(
        initialSubject: _selectedSubject == 'सभी' ? 'भौतिकी' : _selectedSubject,
      ),
    );

    if (created == true && mounted) {
      _showToast('नया इमेज नोट सफलतापूर्वक सेव हो गया!');
    }
  }

  void _openNoteViewer(ImageNote note) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => _FullScreenNoteViewer(noteId: note.id),
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
    );
  }

  Future<void> _confirmDeleteNote(ImageNote note) async {
    HapticFeedback.mediumImpact();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'इमेज नोट डिलीट करें?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          '"${note.title}" को स्थायी रूप से हटा दिया जाएगा।',
          style: const TextStyle(color: Color(0xFF475569)),
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
            child: const Text('डिलीट करें'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      appStore.deleteImageNote(note.id);
      if (mounted) _showToast('नोट हटा दिया गया।');
    }
  }

  void _resetFilters() {
    HapticFeedback.selectionClick();
    _searchController.clear();
    setState(() {
      _selectedSubject = 'सभी';
      _searchQuery = '';
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 112),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= 640 ? 3 : 2;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListenableBuilder(
        listenable: appStore,
        builder: (context, _) {
          final subjects = appStore.noteSubjects;
          if (!subjects.contains(_selectedSubject)) {
            _selectedSubject = 'सभी';
          }

          final notes = appStore.filteredNotes(
            subject: _selectedSubject,
            query: _searchQuery,
          );

          return Stack(
            children: [
              Column(
                children: [
                  // 1. ग्लास सर्च बार
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: _buildGlassSearchBar(),
                  ),

                  // 2. विषय फ़िल्टर चिप्स
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        final isSelected = subject == _selectedSubject;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSubject = subject);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: isSelected
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF007AFF),
                                        Color(0xFF2563EB),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.62),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.92),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF007AFF)
                                            .withValues(alpha: 0.24),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. काउंट और क्विक जानकारी स्ट्रिप
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Text(
                          '${notes.length} इमेज फाइल्स उपलब्ध',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedSubject != 'सभी' ||
                            _searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: _resetFilters,
                            child: const Text(
                              'फ़िल्टर हटाएँ',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. इमेज नोट्स ग्रिड या एम्प्टी स्टेट
                  Expanded(
                    child: notes.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              2,
                              20,
                              MainShell.bottomDockClearance + 78,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.77,
                            ),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return _ImageNoteGridCard(
                                note: note,
                                onTap: () => _openNoteViewer(note),
                                onTogglePin: () {
                                  HapticFeedback.selectionClick();
                                  appStore.toggleNotePin(note.id);
                                },
                                onLongPress: () => _confirmDeleteNote(note),
                              );
                            },
                          ),
                  ),
                ],
              ),

              // 5. फ्लोटिंग Liquid Glass "नोट जोड़ें" बटन
              Positioned(
                right: 20,
                bottom: MainShell.bottomDockClearance + 10,
                child: IgnorePointer(
                  ignoring: isKeyboardOpen,
                  child: AnimatedOpacity(
                    opacity: isKeyboardOpen ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedScale(
                      scale: isKeyboardOpen ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: _openAddNoteSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0A84FF), Color(0xFF0066E5)],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF)
                                    .withValues(alpha: 0.34),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'नोट जोड़ें',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return LiquidGlassBox(
      borderRadius: 22,
      blur: 22,
      surfaceOpacity: 0.66,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 21,
            color: Color(0xFF007AFF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'इमेज नोट्स या विषय खोजें...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltering = _selectedSubject != 'सभी' || _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          28,
          0,
          28,
          MainShell.bottomDockClearance,
        ),
        child: LiquidGlassBox(
          borderRadius: 28,
          blur: 22,
          surfaceOpacity: 0.65,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isFiltering
                      ? Icons.search_off_rounded
                      : Icons.photo_library_outlined,
                  size: 30,
                  color: const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFiltering
                    ? 'कोई मिलता-जुलता नोट नहीं मिला'
                    : 'अभी कोई इमेज नोट सेव नहीं है',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFiltering
                    ? 'दूसरा शब्द खोजें या सभी विषय देखने के लिए फ़िल्टर रीसेट करें।'
                    : 'नीचे "नोट जोड़ें" बटन दबाकर अपनी पहली इमेज नोट फाइल सेव करें।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isFiltering ? _resetFilters : _openAddNoteSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isFiltering ? 'फ़िल्टर रीसेट करें' : 'पहला नोट जोड़ें',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// गैलरी का प्रत्येक इमेज नोट कार्ड
class _ImageNoteGridCard extends StatelessWidget {
  final ImageNote note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onLongPress;

  const _ImageNoteGridCard({
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: LiquidGlassBox(
        borderRadius: 24,
        blur: 20,
        surfaceOpacity: 0.66,
        padding: const EdgeInsets.all(9),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // इमेज प्रीव्यू एरिया
            Expanded(
              child: Hero(
                tag: 'note_hero_${note.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NoteMediaSurface(note: note, compact: true),

                      // विषय बैज
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            note.subject,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: note.accentColor,
                            ),
                          ),
                        ),
                      ),

                      // पिन टॉगल बटन
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onTogglePin,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: note.isPinned
                                  ? const Color(0xFF007AFF)
                                  : Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              note.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              size: 13,
                              color: note.isPinned
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // शीर्षक और तारीख
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        note.hasLocalImage || note.hasNetworkImage
                            ? Icons.image_rounded
                            : Icons.description_outlined,
                        size: 13,
                        color: note.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// इमेज या डेमो नोट शीट को साफ-सुथरे ढंग से रेंडर करने वाला कॉमन विजेट
class _NoteMediaSurface extends StatelessWidget {
  final ImageNote note;
  final bool compact;

  const _NoteMediaSurface({
    required this.note,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (note.hasLocalImage) {
      return Image.memory(
        note.imageBytes!,
        fit: compact ? BoxFit.cover : BoxFit.contain,
      );
    }

    if (note.hasNetworkImage) {
      return Image.network(
        note.imageUrl!,
        fit: compact ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildStyledNoteSheet(),
      );
    }

    return _buildStyledNoteSheet();
  }

  /// यदि शुरुआती नोट में अभी इमेज अपलोड नहीं है, तो साफ नोट-शीट जैसा विज़ुअल कवर दिखाता है
  Widget _buildStyledNoteSheet() {
    return Container(
      width: compact ? null : 320,
      height: compact ? null : 420,
      padding: EdgeInsets.all(compact ? 14 : 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            note.accentColor.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.92),
            note.accentColor.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(compact ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: note.accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: compact ? 28 : 48,
              color: note.accentColor,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 20),
            Text(
              note.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            if (note.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                note.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: note.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${note.subject} • ${note.formattedDate}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: note.accentColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// फुल-स्क्रीन पिंच-टू-ज़ूम और डबल-टैप ज़ूम व्यूअर
class _FullScreenNoteViewer extends StatefulWidget {
  final String noteId;

  const _FullScreenNoteViewer({required this.noteId});

  @override
  State<_FullScreenNoteViewer> createState() => _FullScreenNoteViewerState();
}

class _FullScreenNoteViewerState extends State<_FullScreenNoteViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late final AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;

  bool _showOverlay = true;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final Matrix4 targetMatrix;

    if (currentScale > 1.2) {
      targetMatrix = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const double scale = 2.5;
      targetMatrix = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  Future<void> _deleteAndClose(ImageNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'नोट डिलीट करें?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('"${note.title}" को स्थायी रूप से हटाएँ?'),
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
            child: const Text('डिलीट करें'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      appStore.deleteImageNote(note.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final matchIndex = appStore.notes.indexWhere((n) => n.id == widget.noteId);
        if (matchIndex == -1) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final note = appStore.notes[matchIndex];

        return Scaffold(
          body: LiquidMeshBackground(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // पिंच-टू-ज़ूम और डबल-टैप व्यूइंग एरिया
                GestureDetector(
                  onTap: () => setState(() => _showOverlay = !_showOverlay),
                  onDoubleTapDown: (details) => _doubleTapDetails = details,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.85,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(60),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Hero(
                          tag: 'note_hero_${note.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _NoteMediaSurface(note: note, compact: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // टॉप फ्लोटिंग ग्लास टूलबार
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            children: [
                              LiquidGlassBox(
                                borderRadius: 18,
                                blur: 22,
                                surfaceOpacity: 0.72,
                                padding: const EdgeInsets.all(10),
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              LiquidGlassBox(
                                borderRadius: 18,
                                blur: 22,
                                surfaceOpacity: 0.72,
                                padding: const EdgeInsets.all(10),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  appStore.toggleNotePin(note.id);
                                },
                                child: Icon(
                                  note.isPinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 20,
                                  color: note.isPinned
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 10),
                              LiquidGlassBox(
                                borderRadius: 18,
                                blur: 22,
                                surfaceOpacity: 0.72,
                                padding: const EdgeInsets.all(10),
                                onTap: () => _deleteAndClose(note),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // निचला ग्लास विवरण कार्ड
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: LiquidGlassBox(
                            borderRadius: 26,
                            blur: 26,
                            surfaceOpacity: 0.76,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: note.accentColor
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        note.subject,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: note.accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      note.formattedDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'ज़ूम के लिए डबल टैप करें',
                                      style: TextStyle(
                                     fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (note.description.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    note.description,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// नया इमेज नोट जोड़ने के लिए मॉडर्न Liquid Glass बॉटम शीट
class _AddImageNoteSheet extends StatefulWidget {
  final String initialSubject;

  const _AddImageNoteSheet({required this.initialSubject});

  @override
  State<_AddImageNoteSheet> createState() => _AddImageNoteSheetState();
}

class _AddImageNoteSheetState extends State<_AddImageNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  static const List<String> _presetSubjects = [
    'भौतिकी',
    'रसायन',
    'गणित',
    'अंग्रेज़ी',
    'हिंदी',
    'सामान्य',
  ];

  late String _selectedSubject;
  Uint8List? _pickedImageBytes;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = _presetSubjects.contains(widget.initialSubject)
        ? widget.initialSubject
        : _presetSubjects.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() => _pickedImageBytes = bytes);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    appStore.addImageNote(
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      description: _descriptionController.text.trim(),
      imageBytes: _pickedImageBytes,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 14,
      ),
      child: SafeArea(
        top: false,
        child: LiquidGlassBox(
          borderRadius: 30,
          blur: 28,
          surfaceOpacity: 0.80,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: 16),
                  const Text(
                    'नया इमेज नोट जोड़ें',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // इमेज अपलोड प्रीव्यू बॉक्स
                  if (_pickedImageBytes != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            _pickedImageBytes!,
                            height: 165,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _pickedImageBytes = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _imageSourceButton(
                            icon: Icons.photo_library_rounded,
                            label: 'गैलरी से फोटो चुनें',
                            color: const Color(0xFF007AFF),
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _imageSourceButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'कैमरे से खींचें',
                            color: const Color(0xFF10B981),
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // शीर्षक फ़ील्ड
                  _sheetField(
                    controller: _titleController,
                    hint: 'नोट का शीर्षक (जैसे: अध्याय 2 फॉर्मूले)',
                    icon: Icons.title_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'कृपया नोट का शीर्षक दर्ज करें';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // विषय चिप चयन
                  const Text(
                    'विषय चुनें',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetSubjects.map((subject) {
                      final selected = subject == _selectedSubject;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSubject = subject);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF007AFF)
                                : Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF007AFF)
                                  : Colors.white,
                            ),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // संक्षिप्त विवरण फ़ील्ड
                  _sheetField(
                    controller: _descriptionController,
                    hint: 'संक्षिप्त विवरण (वैकल्पिक)',
                    icon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),

                  // सेव बटन
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isPicking ? null : _saveNote,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'इमेज नोट सेव करें',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}