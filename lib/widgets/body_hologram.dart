import 'dart:math' as math;
import 'package:flutter/material.dart';

class BodyHologram extends StatefulWidget {
  const BodyHologram({super.key, this.onSelectionChanged});

  final ValueChanged<List<String>>? onSelectionChanged;

  @override
  State<BodyHologram> createState() => _BodyHologramState();
}

enum _BodyView { front, back }

class _BodyRegion {
  const _BodyRegion({required this.id, required this.label, required this.area});
  final String id;
  final String label;
  final Rect area; // normalized (0-1) area relative to widget size
}

class _BodyHologramState extends State<BodyHologram> {
  static const List<_BodyRegion> _frontRegions = <_BodyRegion>[
    _BodyRegion(id: 'head', label: 'Head', area: Rect.fromLTWH(0.44, 0.02, 0.12, 0.10)),
    _BodyRegion(id: 'neck', label: 'Neck', area: Rect.fromLTWH(0.46, 0.12, 0.08, 0.04)),
    _BodyRegion(id: 'shoulderL', label: 'Left Shoulder', area: Rect.fromLTWH(0.30, 0.14, 0.12, 0.08)),
    _BodyRegion(id: 'shoulderR', label: 'Right Shoulder', area: Rect.fromLTWH(0.58, 0.14, 0.12, 0.08)),
    _BodyRegion(id: 'upperArmL', label: 'Left Upper Arm', area: Rect.fromLTWH(0.26, 0.22, 0.12, 0.12)),
    _BodyRegion(id: 'upperArmR', label: 'Right Upper Arm', area: Rect.fromLTWH(0.62, 0.22, 0.12, 0.12)),
    _BodyRegion(id: 'forearmL', label: 'Left Forearm', area: Rect.fromLTWH(0.22, 0.32, 0.12, 0.12)),
    _BodyRegion(id: 'forearmR', label: 'Right Forearm', area: Rect.fromLTWH(0.66, 0.32, 0.12, 0.12)),
    _BodyRegion(id: 'handL', label: 'Left Hand', area: Rect.fromLTWH(0.20, 0.44, 0.14, 0.08)),
    _BodyRegion(id: 'handR', label: 'Right Hand', area: Rect.fromLTWH(0.66, 0.44, 0.14, 0.08)),
    _BodyRegion(id: 'chest', label: 'Chest', area: Rect.fromLTWH(0.36, 0.18, 0.28, 0.15)),
    _BodyRegion(id: 'abdomen', label: 'Abdomen', area: Rect.fromLTWH(0.37, 0.33, 0.26, 0.11)),
    _BodyRegion(id: 'pelvis', label: 'Pelvis', area: Rect.fromLTWH(0.38, 0.44, 0.24, 0.08)),
    _BodyRegion(id: 'thighL', label: 'Left Thigh', area: Rect.fromLTWH(0.40, 0.54, 0.12, 0.16)),
    _BodyRegion(id: 'thighR', label: 'Right Thigh', area: Rect.fromLTWH(0.52, 0.54, 0.12, 0.16)),
    _BodyRegion(id: 'kneeL', label: 'Left Knee', area: Rect.fromLTWH(0.40, 0.70, 0.12, 0.05)),
    _BodyRegion(id: 'kneeR', label: 'Right Knee', area: Rect.fromLTWH(0.52, 0.70, 0.12, 0.05)),
    _BodyRegion(id: 'shinL', label: 'Left Shin / Calf', area: Rect.fromLTWH(0.40, 0.75, 0.12, 0.11)),
    _BodyRegion(id: 'shinR', label: 'Right Shin / Calf', area: Rect.fromLTWH(0.52, 0.75, 0.12, 0.11)),
    _BodyRegion(id: 'ankleL', label: 'Left Ankle', area: Rect.fromLTWH(0.40, 0.86, 0.12, 0.04)),
    _BodyRegion(id: 'ankleR', label: 'Right Ankle', area: Rect.fromLTWH(0.52, 0.86, 0.12, 0.04)),
    _BodyRegion(id: 'footL', label: 'Left Foot', area: Rect.fromLTWH(0.40, 0.90, 0.12, 0.08)),
    _BodyRegion(id: 'footR', label: 'Right Foot', area: Rect.fromLTWH(0.52, 0.90, 0.12, 0.08)),
  ];

  static const List<_BodyRegion> _backRegions = <_BodyRegion>[
    _BodyRegion(id: 'headBack', label: 'Head (Back)', area: Rect.fromLTWH(0.44, 0.02, 0.12, 0.10)),
    _BodyRegion(id: 'neckBack', label: 'Neck (Back)', area: Rect.fromLTWH(0.46, 0.12, 0.08, 0.04)),
    _BodyRegion(id: 'shoulderBackL', label: 'Left Shoulder (Back)', area: Rect.fromLTWH(0.30, 0.14, 0.12, 0.08)),
    _BodyRegion(id: 'shoulderBackR', label: 'Right Shoulder (Back)', area: Rect.fromLTWH(0.58, 0.14, 0.12, 0.08)),
    _BodyRegion(id: 'upperBack', label: 'Upper Back', area: Rect.fromLTWH(0.36, 0.20, 0.28, 0.18)),
    _BodyRegion(id: 'midBack', label: 'Mid Back', area: Rect.fromLTWH(0.36, 0.38, 0.28, 0.10)),
    _BodyRegion(id: 'lowerBack', label: 'Lower Back', area: Rect.fromLTWH(0.36, 0.48, 0.28, 0.08)),
    _BodyRegion(id: 'glutes', label: 'Glutes', area: Rect.fromLTWH(0.38, 0.56, 0.24, 0.08)),
    _BodyRegion(id: 'upperArmBackL', label: 'Left Upper Arm (Back)', area: Rect.fromLTWH(0.26, 0.22, 0.12, 0.12)),
    _BodyRegion(id: 'upperArmBackR', label: 'Right Upper Arm (Back)', area: Rect.fromLTWH(0.62, 0.22, 0.12, 0.12)),
    _BodyRegion(id: 'forearmBackL', label: 'Left Forearm (Back)', area: Rect.fromLTWH(0.22, 0.32, 0.12, 0.12)),
    _BodyRegion(id: 'forearmBackR', label: 'Right Forearm (Back)', area: Rect.fromLTWH(0.66, 0.32, 0.12, 0.12)),
    _BodyRegion(id: 'handBackL', label: 'Left Hand (Back)', area: Rect.fromLTWH(0.20, 0.44, 0.14, 0.08)),
    _BodyRegion(id: 'handBackR', label: 'Right Hand (Back)', area: Rect.fromLTWH(0.66, 0.44, 0.14, 0.08)),
    _BodyRegion(id: 'thighBackL', label: 'Left Thigh (Back)', area: Rect.fromLTWH(0.40, 0.64, 0.12, 0.12)),
    _BodyRegion(id: 'thighBackR', label: 'Right Thigh (Back)', area: Rect.fromLTWH(0.52, 0.64, 0.12, 0.12)),
    _BodyRegion(id: 'kneeBackL', label: 'Left Knee (Back)', area: Rect.fromLTWH(0.40, 0.76, 0.12, 0.05)),
    _BodyRegion(id: 'kneeBackR', label: 'Right Knee (Back)', area: Rect.fromLTWH(0.52, 0.76, 0.12, 0.05)),
    _BodyRegion(id: 'calfL', label: 'Left Calf', area: Rect.fromLTWH(0.40, 0.81, 0.12, 0.10)),
    _BodyRegion(id: 'calfR', label: 'Right Calf', area: Rect.fromLTWH(0.52, 0.81, 0.12, 0.10)),
    _BodyRegion(id: 'heelL', label: 'Left Heel', area: Rect.fromLTWH(0.40, 0.91, 0.12, 0.05)),
    _BodyRegion(id: 'heelR', label: 'Right Heel', area: Rect.fromLTWH(0.52, 0.91, 0.12, 0.05)),
  ];

  final Set<String> _selected = <String>{};
  _BodyView _view = _BodyView.front;

  void _toggle(String regionId) {
    setState(() {
      if (_selected.contains(regionId)) {
        _selected.remove(regionId);
      } else {
        _selected.add(regionId);
      }
    });
    widget.onSelectionChanged?.call(_selectedLabels);
  }

  List<_BodyRegion> get _regions =>
      _view == _BodyView.front ? _frontRegions : _backRegions;

  List<String> get _selectedLabels => _regions
      .where((_) => _selected.contains(_.id))
      .map((_) => _.label)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF4F8FF), Color(0xFFE8F2FB)],
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = math.min(constraints.maxWidth, 320);
            final double height = math.min(constraints.maxHeight, 500);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _viewToggle(),
                const SizedBox(height: 8),
                SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: <Widget>[
                      CustomPaint(
                        size: Size(width, height),
                        painter: _SilhouettePainter(view: _view),
                      ),
                      ..._buildRegions(width, height),
                      if (_selected.isNotEmpty)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: _SelectedChips(labels: _selectedLabels),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBD1EA)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _viewChip(label: 'Front', view: _BodyView.front),
          _viewChip(label: 'Back', view: _BodyView.back),
        ],
      ),
    );
  }

  Widget _viewChip({required String label, required _BodyView view}) {
    final bool active = _view == view;
    return InkWell(
      onTap: () => setState(() {
        _view = view;
        _selected.clear();
      }),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5AA7D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF5AA7D4),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRegions(double width, double height) {
    return _regions.map((_) {
      final Rect normalized = _.area;
      final double left = normalized.left * width;
      final double top = normalized.top * height;
      final double regionWidth = normalized.width * width;
      final double regionHeight = normalized.height * height;
      final bool isSelected = _selected.contains(_.id);
      return Positioned(
        left: left,
        top: top,
        width: regionWidth,
        height: regionHeight,
        child: GestureDetector(
          onTap: () => _toggle(_.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? const Color(0xFF5AA7D4).withOpacity(0.18)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2C82B6)
                    : const Color(0xFF5AA7D4).withOpacity(0.35),
                width: isSelected ? 2 : 0.8,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF2C82B6).withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.view});
  final _BodyView view;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint fill = Paint()
      ..color = const Color(0xFFE6F3FF)
      ..style = PaintingStyle.fill;
    final Paint outline = Paint()
      ..color = const Color(0xFF5AA7D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final Path body = Path();
    // Simplified outline approximating the provided vector for both views.
    body.moveTo(w * 0.5, h * 0.02);
    body.quadraticBezierTo(w * 0.46, h * 0.06, w * 0.44, h * 0.12);
    body.quadraticBezierTo(w * 0.40, h * 0.16, w * 0.36, h * 0.22);
    body.quadraticBezierTo(w * 0.28, h * 0.26, w * 0.26, h * 0.34);
    body.quadraticBezierTo(w * 0.24, h * 0.42, w * 0.22, h * 0.46);
    body.quadraticBezierTo(w * 0.22, h * 0.56, w * 0.28, h * 0.60);
    body.quadraticBezierTo(w * 0.32, h * 0.64, w * 0.34, h * 0.74);
    body.quadraticBezierTo(w * 0.36, h * 0.90, w * 0.34, h * 0.98);
    body.lineTo(w * 0.42, h * 0.98);
    body.quadraticBezierTo(w * 0.44, h * 0.86, w * 0.46, h * 0.74);
    body.lineTo(w * 0.54, h * 0.74);
    body.quadraticBezierTo(w * 0.56, h * 0.86, w * 0.58, h * 0.98);
    body.lineTo(w * 0.66, h * 0.98);
    body.quadraticBezierTo(w * 0.64, h * 0.90, w * 0.66, h * 0.74);
    body.quadraticBezierTo(w * 0.68, h * 0.64, w * 0.72, h * 0.60);
    body.quadraticBezierTo(w * 0.78, h * 0.56, w * 0.78, h * 0.46);
    body.quadraticBezierTo(w * 0.76, h * 0.40, w * 0.74, h * 0.34);
    body.quadraticBezierTo(w * 0.72, h * 0.26, w * 0.64, h * 0.22);
    body.quadraticBezierTo(w * 0.60, h * 0.16, w * 0.56, h * 0.12);
    body.quadraticBezierTo(w * 0.54, h * 0.06, w * 0.50, h * 0.02);
    body.close();

    canvas.drawPath(body, fill);
    canvas.drawPath(body, outline);

    _paintDetails(canvas, size, outline);
  }

  void _paintDetails(Canvas canvas, Size size, Paint outline) {
    final double w = size.width;
    final double h = size.height;
    final Path details = Path();

    if (view == _BodyView.front) {
      details.moveTo(w * 0.46, h * 0.14);
      details.lineTo(w * 0.54, h * 0.14); // collar bone
      details.moveTo(w * 0.38, h * 0.26);
      details.quadraticBezierTo(w * 0.50, h * 0.30, w * 0.62, h * 0.26); // chest top
      details.moveTo(w * 0.42, h * 0.34);
      details.quadraticBezierTo(w * 0.50, h * 0.32, w * 0.58, h * 0.34); // ribs line
      details.moveTo(w * 0.48, h * 0.38);
      details.lineTo(w * 0.52, h * 0.38); // center ribs
      details.moveTo(w * 0.46, h * 0.46);
      details.quadraticBezierTo(w * 0.50, h * 0.44, w * 0.54, h * 0.46); // waist line
      details.moveTo(w * 0.44, h * 0.54);
      details.quadraticBezierTo(w * 0.50, h * 0.52, w * 0.56, h * 0.54); // pelvis arc
      details.moveTo(w * 0.46, h * 0.64);
      details.quadraticBezierTo(w * 0.50, h * 0.62, w * 0.54, h * 0.64); // thigh top
      details.moveTo(w * 0.42, h * 0.72);
      details.lineTo(w * 0.46, h * 0.72);
      details.moveTo(w * 0.54, h * 0.72);
      details.lineTo(w * 0.58, h * 0.72); // knee caps
    } else {
      details.moveTo(w * 0.44, h * 0.22);
      details.quadraticBezierTo(w * 0.50, h * 0.24, w * 0.56, h * 0.22); // traps line
      details.moveTo(w * 0.46, h * 0.32);
      details.lineTo(w * 0.54, h * 0.48); // spine
      details.moveTo(w * 0.40, h * 0.30);
      details.quadraticBezierTo(w * 0.50, h * 0.34, w * 0.60, h * 0.30); // scapula
      details.moveTo(w * 0.44, h * 0.50);
      details.quadraticBezierTo(w * 0.50, h * 0.48, w * 0.56, h * 0.50); // lower back
      details.moveTo(w * 0.44, h * 0.58);
      details.quadraticBezierTo(w * 0.50, h * 0.56, w * 0.56, h * 0.58); // glute top
    }

    canvas.drawPath(details, outline..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) =>
      oldDelegate.view != view;
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: labels
          .map(
            (String label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBD1EA)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2C4A73),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
