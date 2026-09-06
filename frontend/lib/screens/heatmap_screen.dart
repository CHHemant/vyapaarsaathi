// frontend/lib/screens/heatmap_screen.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/heatmap_data.dart';
import '../providers/core_providers.dart';
import '../services/api_service.dart';
import '../services/office_kit_service.dart';
import '../theme/kirana_colors.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../widgets/entrance_animation.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final GlobalKey _exportBoundaryKey = GlobalKey();

  int _selectedDays = 30;
  HeatmapData? _data;
  bool _isLoading = true;
  bool _isFromCache = false;
  DateTime? _cachedAt;
  bool _isMirroring = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetch(_selectedDays);
  }

  Future<void> _fetch(int days) async {
    setState(() {
      _isLoading = true;
      _isFromCache = false;
    });

    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);

    try {
      final data = await api.getHeatmap(days: days);
      if (!mounted) return;
      if (days == 30) await cache.saveHeatmap(data);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      final cached = cache.getCachedHeatmap();
      if (!mounted) return;
      setState(() {
        _data = cached?.data;
        _isFromCache = true;
        _cachedAt = cached?.cachedAt;
        _isLoading = false;
      });
    }
  }

  void _onRangeChanged(int days) {
    setState(() => _selectedDays = days);
    _fetch(days);
  }

  Future<void> _mirrorToLaptop() async {
    final officeKit = ref.read(officeKitServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (_isMirroring) {
      await officeKit.stopMirroring();
      setState(() => _isMirroring = false);
      return;
    }

    final result = await officeKit.mirrorToLaptop();
    switch (result) {
      case OfficeKitSuccess():
        setState(() => _isMirroring = true);
      case OfficeKitFailure(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  Future<void> _exportAsPng() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final officeKit = ref.read(officeKitServiceProvider);

    try {
      final boundary = _exportBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/cashflow_heatmap_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      final result = await officeKit.transferFile(path);
      switch (result) {
        case OfficeKitSuccess():
          messenger.showSnackBar(const SnackBar(
            content: Text('Heatmap exported and sent to laptop!'),
            backgroundColor: KiranaColors.success,
          ));
        case OfficeKitFailure(:final reason):
          messenger.showSnackBar(SnackBar(content: Text('Saved locally, but transfer failed: $reason')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Cash Flow Insights')),
      body: RefreshIndicator(
        onRefresh: () => _fetch(_selectedDays),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            EntranceAnimation(
              delay: const Duration(milliseconds: 100),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7d')),
                  ButtonSegment(value: 30, label: Text('30d')),
                  ButtonSegment(value: 90, label: Text('90d')),
                ],
                selected: {_selectedDays},
                onSelectionChanged: (selection) => _onRangeChanged(selection.first),
              ),
            ),
            const SizedBox(height: 24),
            if (_isFromCache) _CachedBadge(cachedAt: _cachedAt),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else
              EntranceAnimation(
                delay: const Duration(milliseconds: 200),
                child: RepaintBoundary(
                  key: _exportBoundaryKey,
                  child: KiranaCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income Activity',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        HeatmapCalendar(days: _data?.days ?? const []),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_data != null && _data!.days.isNotEmpty) 
              EntranceAnimation(
                delay: const Duration(milliseconds: 300),
                child: _InsightsRow(data: _data!),
              ),
            const SizedBox(height: 32),
            EntranceAnimation(
              delay: const Duration(milliseconds: 400),
              child: Column(
                children: [
                  RupeeButton(
                    label: _isMirroring ? 'Stop Mirroring' : 'Mirror Screen to Laptop',
                    icon: _isMirroring ? Icons.stop_screen_share_rounded : Icons.cast_connected_rounded,
                    showRupeePrefix: false,
                    fullWidth: true,
                    onPressed: _mirrorToLaptop,
                    color: _isMirroring ? KiranaColors.error : KiranaColors.primary,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportAsPng,
                    icon: _isExporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.file_download_rounded),
                    label: const Text('Export for Loan App'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InsightsRow extends StatelessWidget {
  final HeatmapData data;
  const _InsightsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final best = data.bestDay;
    final worst = data.worstDay;
    final trend = data.weekOverWeekTrend;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KiranaCard(
                padding: const EdgeInsets.all(16),
                child: _InsightContent(
                  title: 'Best Day',
                  value: best == null ? '-' : best.weekday,
                  subtitle: best == null ? '' : '₹${best.avgIncome.toStringAsFixed(0)} avg',
                  icon: Icons.star_rounded,
                  iconColor: KiranaColors.tertiary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KiranaCard(
                padding: const EdgeInsets.all(16),
                child: _InsightContent(
                  title: 'Trend',
                  value: trend == null ? '-' : '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%',
                  subtitle: 'Week over Week',
                  icon: Icons.insights_rounded,
                  iconColor: trend != null && trend >= 0 ? KiranaColors.secondary : KiranaColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightContent extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _InsightContent({
    required this.title, 
    required this.value, 
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _CachedBadge extends StatelessWidget {
  final DateTime? cachedAt;
  const _CachedBadge({this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KiranaColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt_rounded, size: 16, color: KiranaColors.warning),
          const SizedBox(width: 8),
          Text(
            'Showing offline data',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: KiranaColors.warning.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
