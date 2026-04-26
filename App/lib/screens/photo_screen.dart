import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import '../models/avatar_model.dart';
import '../main.dart';

class PhotoScreen extends StatefulWidget {
  final AvatarModel avatar;

  const PhotoScreen({super.key, required this.avatar});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSaving = false;
  bool _showSaved = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _captureAndSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Flash animation
      _flashController.forward().then((_) {
        _flashController.reverse();
      });

      // Small delay to let flash show
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the widget as image
      RenderRepaintBoundary boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Request permission
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }

        // Save using Gal.putImageBytes
        await Gal.putImageBytes(pngBytes, album: 'Habitu');

        setState(() {
          _showSaved = true;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Photo saved to gallery!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Hide saved indicator after a bit
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showSaved = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photo: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.avatar;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // === CAPTURE AREA (everything inside RepaintBoundary will be saved) ===
                RepaintBoundary(
                  key: _captureKey,
                  child: SizedBox(
                    width: screenSize.width,
                    height: screenSize.height,
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/photo/photo_bg.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.none,
                          ),
                        ),

                        // Pet in the middle
                        Center(
                          child: avatar.equippedHat.isNotEmpty
                              ? Image.asset(
                                  'assets/pet_with_hat/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}/${avatar.equippedHat}.png',
                                  width: screenSize.width * 0.75,
                                  height: screenSize.width * 0.75,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (c, e, s) => Image.asset(
                                    'assets/pets/${avatar.species.toLowerCase()}/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}.png',
                                    width: screenSize.width * 0.75,
                                    height: screenSize.width * 0.75,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    errorBuilder: (c2, e2, s2) => Image.asset(
                                      'assets/images/CAT.png',
                                      width: screenSize.width * 0.75,
                                      height: screenSize.width * 0.75,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/pets/${avatar.species.toLowerCase()}/${avatar.species.toLowerCase()}_stage${avatar.selectedStage < 1 ? 1 : avatar.selectedStage}.png',
                                  width: screenSize.width * 0.75,
                                  height: screenSize.width * 0.75,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (c, e, s) => Image.asset(
                                    'assets/images/CAT.png',
                                    width: screenSize.width * 0.75,
                                    height: screenSize.width * 0.75,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),

                        // Status level and pet name at top right
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  avatar.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lv.${avatar.level}',
                                  style: TextStyle(
                                    color: Colors.greenAccent.shade200,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _buildMiniStat(
                                  'STR',
                                  avatar.strength,
                                  Colors.redAccent.shade200,
                                ),
                                _buildMiniStat(
                                  'INT',
                                  avatar.intelligence,
                                  Colors.blueAccent.shade200,
                                ),
                                _buildMiniStat(
                                  'MND',
                                  avatar.mind,
                                  Colors.indigoAccent.shade200,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // === CAMERA BOX OVERLAY (on top, NOT captured in screenshot) ===
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/photo/photo_box.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),

                // Capture button (the white button at bottom of photo_box)
                Positioned(
                  bottom: screenSize.height * 0.03,
                  child: GestureDetector(
                    onTap: () {
                      playClickSound();
                      _captureAndSave();
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isSaving
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                                strokeWidth: 3,
                              ),
                            )
                          : _showSaved
                              ? Icon(
                                  Icons.check,
                                  color: Colors.grey.shade700,
                                  size: 30,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/photo/camera.png',
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Flash effect
          AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              return _flashAnimation.value > 0
                  ? Container(
                      color: Colors.white.withOpacity(
                        _flashAnimation.value * 0.7,
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () {
                playClickSound();
                Navigator.pop(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Lv.$value',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
