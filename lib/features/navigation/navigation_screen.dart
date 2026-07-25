import 'package:flutter/material.dart';

import '../../models/navigation_data.dart';
import '../../services/navigation_pipeline_processor.dart';
import '../../services/obstacle_priority_analyzer.dart';
import '../detection/detection_result.dart';
import '../voice/voice_service.dart';

/// Full-featured Navigation Screen demonstrating the 7-stage processing pipeline:
/// Camera → AI Detection → Bounding Boxes → Position Analyzer → Distance Estimator → Obstacle Priority → Navigation Data
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationPipelineProcessor _processor =
      NavigationPipelineProcessor.instance;
  late NavigationData _currentNavData;

  // Sample simulated detections to demonstrate real-time pipeline processing
  final List<DetectionResult> _sampleDetections = const [
    DetectionResult(
      label: 'Chair',
      confidence: 0.89,
      rect: Rect.fromLTWH(0.40, 0.45, 0.25, 0.35),
    ),
    DetectionResult(
      label: 'Person',
      confidence: 0.94,
      rect: Rect.fromLTWH(0.10, 0.20, 0.20, 0.60),
    ),
    DetectionResult(
      label: 'Stairs',
      confidence: 0.78,
      rect: Rect.fromLTWH(0.42, 0.70, 0.30, 0.25),
    ),
  ];

  @override
  void initState() {
    super.initState();
    VoiceService.instance.initialize();
    _currentNavData = _processor.process(_sampleDetections);
  }

  void _refreshPipeline() {
    setState(() {
      _currentNavData = _processor.process(_sampleDetections);
    });
    VoiceService.instance.speak(_currentNavData.voiceGuidanceText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Guidance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Announce Guidance',
            onPressed: () {
              VoiceService.instance.speak(_currentNavData.voiceGuidanceText);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run Pipeline',
            onPressed: _refreshPipeline,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pipeline Architecture Flow Diagram ──────────────────────────
            _buildPipelineFlowCard(theme),
            const SizedBox(height: 20),

            // ── Current Navigation Path Status ──────────────────────────────
            _buildPathStatusCard(theme),
            const SizedBox(height: 20),

            // ── Primary Obstacle Highlight ─────────────────────────────────
            if (_currentNavData.primaryObstacle != null) ...[
              _buildPrimaryObstacleCard(
                theme,
                _currentNavData.primaryObstacle!,
              ),
              const SizedBox(height: 20),
            ],

            // ── Prioritized Obstacle Telemetry List ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detected Obstacles (${_currentNavData.obstacleCount})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.sort_rounded, size: 16),
                  label: const Text('By Priority'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._currentNavData.obstacles.map((obstacle) {
              return _buildObstacleTile(theme, obstacle);
            }),

            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/camera');
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Open Live Camera Guidance'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineFlowCard(ThemeData theme) {
    const pipelineStages = [
      'Camera',
      'AI Detection',
      'Bounding Boxes',
      'Position Analyzer',
      'Distance Estimator',
      'Obstacle Priority',
      'Navigation Data',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'VisionMate AI Pipeline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.start,
              children: List.generate(pipelineStages.length, (index) {
                final isLast = index == pipelineStages.length - 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLast
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pipelineStages[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isLast
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isLast
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathStatusCard(ThemeData theme) {
    final PathState state = _currentNavData.pathState;
    final Color statusColor;
    final String statusTitle;
    final IconData statusIcon;

    switch (state) {
      case PathState.blocked:
        statusColor = const Color(0xFFFF3B30);
        statusTitle = 'Path Blocked — Stop!';
        statusIcon = Icons.dangerous_rounded;
        break;
      case PathState.caution:
        statusColor = const Color(0xFFFF9500);
        statusTitle = 'Caution — Obstacles Ahead';
        statusIcon = Icons.warning_rounded;
        break;
      case PathState.clear:
        statusColor = const Color(0xFF34C759);
        statusTitle = 'Path Clear';
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentNavData.voiceGuidanceText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryObstacleCard(
    ThemeData theme,
    ProcessedObstacle obstacle,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: obstacle.tierColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: obstacle.tierColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: obstacle.tierColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Priority Threat',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: obstacle.tierColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        obstacle.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: obstacle.tierColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    obstacle.priorityTier.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  'Distance',
                  obstacle.distance.formattedDistance,
                  Icons.straighten_rounded,
                ),
                _buildMetricColumn(
                  'Position',
                  obstacle.position.readableDirection,
                  Icons.explore_rounded,
                ),
                _buildMetricColumn(
                  'Clock',
                  "${obstacle.position.clockDirection} o'clock",
                  Icons.access_time_rounded,
                ),
                _buildMetricColumn(
                  'Score',
                  obstacle.priorityScore.toStringAsFixed(0),
                  Icons.speed_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildObstacleTile(ThemeData theme, ProcessedObstacle obstacle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: obstacle.tierColor.withValues(alpha: 0.15),
          child: Icon(
            Icons.remove_red_eye_rounded,
            color: obstacle.tierColor,
            size: 20,
          ),
        ),
        title: Text(
          obstacle.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${obstacle.distance.formattedDistance} • ${obstacle.position.readableDirection} (${obstacle.position.clockDirection} o\'clock)',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: obstacle.tierColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: obstacle.tierColor, width: 1),
          ),
          child: Text(
            '${obstacle.priorityScore.toStringAsFixed(0)} pts',
            style: TextStyle(
              color: obstacle.tierColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
