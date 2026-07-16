// explorer_screen.dart
// Interactive placeholder compass tool representing device compass/GPS capabilities.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ExplorerScreen extends StatefulWidget {
  final bool isEmbedded;

  const ExplorerScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  double _heading = 0.0; // Simulated degrees (0 to 360)
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  bool _sensorAvailable = true;
  Timer? _sensorTimeoutTimer;
  bool _hasReceivedEvent = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    _sensorTimeoutTimer = Timer(const Duration(seconds: 2), () {
      if (!_hasReceivedEvent && mounted) {
        setState(() {
          _sensorAvailable = false;
        });
      }
    });

    try {
      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          // Calculate heading in degrees (0 to 360, where 0/360 is North)
          double heading = atan2(event.y, event.x) * (180 / pi);
          
          // Normalize negative values
          if (heading < 0) {
            heading += 360;
          }

          // Throttle using a 1-degree tolerance check
          final double diff = (heading - _heading).abs();
          final double normalizedDiff = diff > 180 ? 360 - diff : diff;

          if (normalizedDiff > 1.0 || !_hasReceivedEvent) {
            if (mounted) {
              setState(() {
                _heading = heading;
                _hasReceivedEvent = true;
                _sensorAvailable = true;
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Compass Sensor: Magnetometer stream error: $error');
          if (mounted) {
            setState(() {
              _sensorAvailable = false;
            });
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Compass Sensor: Exception subscribing to magnetometer: $e');
      _sensorAvailable = false;
    }
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _sensorTimeoutTimer?.cancel();
    super.dispose();
  }

  String _getDirectionLetter(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    final bodyContent = SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? mediaQuery.size.width * 0.15 : 24.0,
          vertical: 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Screen Header
            const Text(
              'Explorer Tool',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orient yourself in new destinations',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Interactive Compass Widget
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glowing Ring
                Container(
                  width: isTablet ? 280 : 220,
                  height: isTablet ? 280 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                ),
                // Inner Compass Dial
                Container(
                  width: isTablet ? 240 : 190,
                  height: isTablet ? 240 : 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E2F),
                    border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.5), width: 2),
                  ),
                  child: CustomPaint(
                    painter: CompassDialPainter(),
                  ),
                ),

                // Rotating Needle
                Transform.rotate(
                  angle: -_heading * (pi / 180), // Counter-rotate to mimic actual compass pointing north
                  child: Icon(
                    Icons.explore_rounded,
                    size: isTablet ? 120 : 96,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Heading Readings
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _getDirectionLetter(_heading),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF818CF8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_heading.toStringAsFixed(0)}°',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _sensorAvailable
                  ? 'Compass Active (using Magnetometer sensor)'
                  : 'Compass not available on this device',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _sensorAvailable ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 32),

            // Simulation Slider Card
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(
                    Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6,
                  ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.black12,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    Text(
                      'Simulate Device Heading Rotation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Slider(
                      value: _heading,
                      min: 0.0,
                      max: 360.0,
                      divisions: 360,
                      activeColor: const Color(0xFF6366F1),
                      inactiveColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.black12,
                      label: '${_heading.toStringAsFixed(0)}°',
                      onChanged: (value) {
                        setState(() {
                          _heading = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer Tool'),
        centerTitle: true,
      ),
      body: SafeArea(child: bodyContent),
    );
  }
}

// Paints cardinal markings (N, E, S, W) on the compass face
class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.5),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final cardinals = {
      'N': const Offset(0, -1),
      'S': const Offset(0, 1),
      'E': const Offset(1, 0),
      'W': const Offset(-1, 0),
    };

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    cardinals.forEach((label, offset) {
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();

      final x = center.dx + radius * offset.dx - (textPainter.width / 2);
      final y = center.dy + radius * offset.dy - (textPainter.height / 2);

      textPainter.paint(canvas, Offset(x, y));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
