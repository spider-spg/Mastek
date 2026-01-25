import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key, required this.onGetStarted}) : super(key: key);

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return Center(
              child: Container(
                width: double.infinity,
                height: viewport.maxHeight,
                constraints: const BoxConstraints(maxWidth: 393),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(offset: Offset(0, 20), blurRadius: 40, color: Color.fromRGBO(0, 0, 0, 0.1))],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      final available = constraints.maxHeight;
                      final scale = (available / 760).clamp(0.72, 1.0);

                      final titleSize = 28.0 * scale;
                      final subtitleSize = 14.0 * scale;
                      final sliderHeight = (72.0 * scale).clamp(56.0, 72.0);
                      final topGap = 12.0 * scale;
                      final sectionGap = 12.0 * scale;

                      return Column(
                        children: [
                          SizedBox(height: topGap),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCdrH6YXe5ORWGWPHpTGMXUi_leYQmJVAi9vK7X6ffhJYd6b83OuEXOAj76TidjhTNhm9owQfjZrIKb1ZlgKZ06pduTBsloZKczq1k_EjfcQnZYZrDBckIeLjkNuWlC4N8nOutMqMn04DNZwJ3vZ-kh4g5wliOuEIQYANEfIHYfTgX92CZhb2d8lUK5L7Edo-3VbMTo1ppPNL-L-9HtGahGWJk0E1eXRTR_pOyEo9ePUDskGhsGjlU7ioEML_kDjhtw_eXfOyr8u85U',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),

                          // Bottom card area
                          Expanded(
                            flex: 5,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              ),
                              padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 16 * scale),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48 * scale,
                                    height: 6 * scale,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: 'Your Virtual\nHealthcare ', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800)),
                                            TextSpan(text: 'Chatbot', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800, color: const Color(0xFF4F75D0))),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: sectionGap),
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 300),
                                      child: Text(
                                        'Your Virtual Healthcare Assistant: Partner in wellness, just a message away.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey, fontSize: subtitleSize),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: sliderHeight,
                                    width: double.infinity,
                                    child: _SlideToContinue(
                                      onCompleted: onGetStarted,
                                      scale: scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Dark mode toggle (kept visually overlayed)
                    Positioned(
                      right: 24,
                      top: 20,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toggle theme from app settings')));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                          ),
                          child: Icon(isDark ? Icons.dark_mode : Icons.dark_mode, color: isDark ? Colors.yellow.shade600 : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideToContinue extends StatefulWidget {
  const _SlideToContinue({required this.onCompleted, required this.scale});

  final VoidCallback onCompleted;
  final double scale;

  @override
  State<_SlideToContinue> createState() => _SlideToContinueState();
}

class _SlideToContinueState extends State<_SlideToContinue> with SingleTickerProviderStateMixin {
  static const double _completionThreshold = 0.88;

  late final AnimationController _controller;
  Animation<double>? _animation;
  double _dragDx = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _controller.addListener(() {
      final animation = _animation;
      if (animation == null) return;
      setState(() => _dragDx = animation.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.stop();
    final from = _dragDx;
    _animation = Tween<double>(begin: from, end: target).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = widget.scale;
    final trackPadding = (6.0 * scale).clamp(6.0, 10.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackRadius = constraints.maxHeight / 2;
        final handleSize = (constraints.maxHeight - (trackPadding * 2)).clamp(40.0, 62.0);
        final maxDx = (constraints.maxWidth - (trackPadding * 2) - handleSize).clamp(0.0, double.infinity);
        final progress = maxDx == 0 ? 0.0 : (_dragDx / maxDx).clamp(0.0, 1.0);

        final trackColor = isDark ? const Color(0xFF4F75D0).withOpacity(0.22) : const Color(0xFF4F75D0).withOpacity(0.16);
        final fillColor = const Color(0xFF4F75D0);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(trackRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(trackRadius),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: fillColor.withOpacity(0.9)),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Slide to continue',
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: trackPadding + _dragDx,
              child: GestureDetector(
                onPanStart: (_) => _controller.stop(),
                onPanUpdate: (details) {
                  if (_completed) return;
                  setState(() {
                    _dragDx = (_dragDx + details.delta.dx).clamp(0.0, maxDx);
                  });
                },
                onPanEnd: (_) {
                  if (_completed) return;
                  final shouldComplete = maxDx > 0 && (_dragDx / maxDx) >= _completionThreshold;
                  if (shouldComplete) {
                    _completed = true;
                    HapticFeedback.lightImpact();
                    _animateTo(maxDx);
                    widget.onCompleted();
                  } else {
                    _animateTo(0);
                  }
                },
                child: Container(
                  width: handleSize,
                  height: handleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(handleSize / 2),
                    boxShadow: const [BoxShadow(offset: Offset(0, 8), blurRadius: 16, color: Color.fromRGBO(0, 0, 0, 0.18))],
                  ),
                  child: Icon(Icons.chevron_right, color: const Color(0xFF4F75D0), size: 28 * scale),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
