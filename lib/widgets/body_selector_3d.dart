import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// 3D body selector using model_viewer_plus.
/// - Place your model at assets/models/human.glb (or adjust [modelAssetPath]).
/// - Provides auto-rotate, camera controls, pinch zoom, and tap picking (mocked).
class BodySelector3D extends StatefulWidget {
  const BodySelector3D({
    super.key,
    required this.onRegionSelected,
    this.modelAssetPath = 'assets/models/human.glb',
    this.autoRotate = true,
  });

  final ValueChanged<String> onRegionSelected;
  final String modelAssetPath;
  final bool autoRotate;

  @override
  State<BodySelector3D> createState() => _BodySelector3DState();
}

class _BodySelector3DState extends State<BodySelector3D> {
  String? _selectedRegion;
  Offset? _tapPosition;

  // Mock picking: map Y position to a rough region. Replace with real raycast once available.
  String _mockPickRegion(Offset localPos, Size size) {
    final double y = localPos.dy / size.height;
    if (y < 0.2) return 'Head';
    if (y < 0.45) return 'Chest';
    if (y < 0.65) return 'Arm';
    if (y < 0.85) return 'Leg';
    return 'Foot';
  }

  void _handleTap(TapDownDetails details, Size size) {
    final String region = _mockPickRegion(details.localPosition, size);
    setState(() {
      _selectedRegion = region;
      _tapPosition = details.localPosition;
    });
    widget.onRegionSelected(region);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final String resolvedSrc = kIsWeb
            ? 'assets/assets/models/human.glb' // Flutter web serves assets with a leading assets/ prefix
            : widget.modelAssetPath;
        return Stack(
          children: <Widget>[
            ModelViewer(
              src: resolvedSrc,
              alt: '3D human body',
              autoRotate: widget.autoRotate,
              cameraControls: true,
              disableZoom: false,
              ar: false,
              backgroundColor: Colors.white,
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (TapDownDetails d) => _handleTap(d, size),
              ),
            ),
            if (_tapPosition != null && _selectedRegion != null)
              Positioned(
                left: _tapPosition!.dx - 36,
                top: _tapPosition!.dy - 36,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.16),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Colors.blueAccent,
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedRegion!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
