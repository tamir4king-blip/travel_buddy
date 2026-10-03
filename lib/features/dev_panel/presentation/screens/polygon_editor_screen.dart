import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/data/achievement_definitions_repository.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievement_definitions_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';

class PolygonEditorScreen extends ConsumerStatefulWidget {
  const PolygonEditorScreen({super.key});

  @override
  ConsumerState<PolygonEditorScreen> createState() =>
      _PolygonEditorScreenState();
}

class _PolygonEditorScreenState extends ConsumerState<PolygonEditorScreen> {
  MapboxMap? _mapboxMap;
  PolygonAnnotationManager? _polygonManager;
  PointAnnotationManager? _vertexManager;
  PointAnnotationManager? _pinManager;

  Achievement? _selected;
  final List<List<double>> _vertices = []; // [[lat, lng], ...]
  bool _saving = false;
  String _search = '';

  /// Maps a vertex PointAnnotation.id to its index in [_vertices], so drag
  /// callbacks (which receive the annotation, not the index) can update the
  /// right entry. Rebuilt on every [_renderVertices] call since annotations
  /// are recreated, not mutated.
  final Map<String, int> _vertexIdToIndex = {};

  /// Manually-chosen pin location [lat, lng]. Null means "auto: follow
  /// polygon centroid". Set when the user drags the pin or when an existing
  /// achievement is loaded with a saved lat/lng (so we show the saved pin
  /// position, not the recomputed centroid).
  List<double>? _pinOverride;
  bool _draggingPin = false;

  /// Returns the arithmetic centroid of [_vertices] as [lat, lng], or null if
  /// fewer than 1 vertex. Simple mean is accurate enough for pin placement
  /// on claim-area polygons (we're not computing mass moments).
  List<double>? _centroid() {
    if (_vertices.isEmpty) return null;
    var sumLat = 0.0;
    var sumLng = 0.0;
    for (final v in _vertices) {
      sumLat += v[0];
      sumLng += v[1];
    }
    return [sumLat / _vertices.length, sumLng / _vertices.length];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final geoAchievements = achievements.allAchievements
        .where((a) => a.latitude != null && a.longitude != null)
        .where((a) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.title.toLowerCase().contains(q) ||
          a.id.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  _selected?.longitude ?? 34.85,
                  _selected?.latitude ?? 32.33,
                ),
              ),
              zoom: _selected != null ? 14.0 : 10.0,
            ),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          ),

          // Top bar: back + achievement selector
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Column(
              children: [
                Row(
                  children: [
                    _circleButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAchievementSelector(geoAchievements),
                    ),
                  ],
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoBar(),
                ],
              ],
            ),
          ),

          // Bottom action bar
          if (_selected != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _buildActionBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementSelector(List<Achievement> achievements) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<Achievement>(
        offset: const Offset(0, 48),
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 340),
        itemBuilder: (context) {
          return [
            PopupMenuItem<Achievement>(
              enabled: false,
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.search, size: 16),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            ...achievements.map((a) => PopupMenuItem<Achievement>(
                  value: a,
                  child: Text(
                    '${a.title} ${a.hasPolygon ? "(polygon)" : a.claimRadius != null ? "(${a.claimRadius!.toInt()}m)" : ""}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ];
        },
        onSelected: _selectAchievement,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selected?.title ?? 'Select achievement...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selected != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(LucideIcons.chevronDown,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    final vertexCount = _vertices.length;
    final source = _selected!.hasPolygon ? 'Polygon' : 'Radius';

    final String message;
    if (_vertices.isEmpty) {
      message = 'Current: $source. Tap map to add polygon vertices.';
    } else if (vertexCount < 3) {
      message = '$vertexCount vertices. Need ${3 - vertexCount} more.';
    } else {
      final pinNote = _pinOverride != null ? ' • manual pin' : '';
      message =
          '$vertexCount vertices$pinNote • Long-press a vertex or the pin to drag.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _vertices.isNotEmpty ? LucideIcons.hexagon : LucideIcons.circle,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          if (_pinOverride != null && vertexCount >= 3)
            GestureDetector(
              onTap: _resetPinToCentroid,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: const [
                    Icon(LucideIcons.locateFixed,
                        size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text('Reset pin',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _actionButton(
            icon: LucideIcons.undo2,
            label: 'Undo',
            onTap: _vertices.isNotEmpty ? _undoVertex : null,
          ),
          const SizedBox(width: 8),
          _actionButton(
            icon: LucideIcons.trash2,
            label: 'Clear',
            onTap: _vertices.isNotEmpty ? _clearVertices : null,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _vertices.length >= 3 && !_saving ? _savePolygon : null,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 14),
              label: Text(_saving ? 'Saving...' : 'Save Polygon',
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.bgCardLight,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.95),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.textPrimary),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color ?? AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Map callbacks ──

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _polygonManager =
        await mapboxMap.annotations.createPolygonAnnotationManager();
    _vertexManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    // Separate manager so the pin preview doesn't get wiped by vertex redraws
    _pinManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Long-press a vertex to start dragging it; polygon fill updates live.
    _vertexManager!.dragEvents(
      onChanged: _onVertexDragChanged,
      onEnd: _onVertexDragEnd,
    );

    // Long-press the pin to drag it to a custom location; this overrides
    // the auto-centroid and is what gets saved as the achievement lat/lng.
    _pinManager!.dragEvents(
      onBegin: (_) => _draggingPin = true,
      onChanged: _onPinDragChanged,
      onEnd: _onPinDragEnd,
    );

    // If selected achievement already has polygon, load it
    if (_selected != null && _selected!.hasPolygon) {
      _vertices.clear();
      _vertices.addAll(_selected!.claimPolygon!);
      _seedPinOverrideFromAchievement(_selected!);
      _renderPolygon();
      _renderVertices();
      _renderPinPreview();
    }
  }

  void _onVertexDragChanged(PointAnnotation a) {
    final idx = _vertexIdToIndex[a.id];
    if (idx == null || idx >= _vertices.length) return;
    final coords = a.geometry.coordinates;
    _vertices[idx] = [coords.lat.toDouble(), coords.lng.toDouble()];
    // Live polygon fill update. Skip vertex re-render — that would delete
    // the annotation currently being dragged and break the gesture.
    _renderPolygon();
    // If pin is auto-following centroid, follow the new shape live.
    if (_pinOverride == null && !_draggingPin) _renderPinPreview();
  }

  void _onVertexDragEnd(PointAnnotation a) {
    if (mounted) setState(() {});
  }

  void _onPinDragChanged(PointAnnotation a) {
    final coords = a.geometry.coordinates;
    _pinOverride = [coords.lat.toDouble(), coords.lng.toDouble()];
  }

  void _onPinDragEnd(PointAnnotation a) {
    _draggingPin = false;
    if (mounted) setState(() {});
  }

  /// When loading an existing achievement with a polygon, prefer its saved
  /// latitude/longitude as the pin position rather than recomputing the
  /// centroid — the user may have manually placed the pin before.
  void _seedPinOverrideFromAchievement(Achievement a) {
    if (a.hasPolygon && a.latitude != null && a.longitude != null) {
      _pinOverride = [a.latitude!, a.longitude!];
    } else {
      _pinOverride = null;
    }
  }

  void _onMapTap(MapContentGestureContext context) {
    if (_selected == null) return;

    final coords = context.point.coordinates;
    final lat = coords.lat.toDouble();
    final lng = coords.lng.toDouble();

    setState(() {
      _vertices.add([lat, lng]);
    });
    _renderPolygon();
    _renderVertices();
    _renderPinPreview();
  }

  void _selectAchievement(Achievement achievement) {
    setState(() {
      _selected = achievement;
      _vertices.clear();
      _search = '';
      if (achievement.hasPolygon) {
        _vertices.addAll(
          achievement.claimPolygon!.map((p) => List<double>.from(p)),
        );
      }
      _seedPinOverrideFromAchievement(achievement);
    });

    // Fly to achievement location
    if (_mapboxMap != null &&
        achievement.latitude != null &&
        achievement.longitude != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates:
                Position(achievement.longitude!, achievement.latitude!),
          ),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }

    _renderPolygon();
    _renderVertices();
    _renderPinPreview();
  }

  void _undoVertex() {
    if (_vertices.isEmpty) return;
    setState(() => _vertices.removeLast());
    _renderPolygon();
    _renderVertices();
    _renderPinPreview();
  }

  void _clearVertices() {
    setState(() {
      _vertices.clear();
      _pinOverride = null;
    });
    _renderPolygon();
    _renderVertices();
    _renderPinPreview();
  }

  void _resetPinToCentroid() {
    setState(() => _pinOverride = null);
    _renderPinPreview();
  }

  // ── Rendering ──

  Future<void> _renderPolygon() async {
    if (_polygonManager == null) return;
    await _polygonManager!.deleteAll();

    if (_vertices.length < 3) return;

    final positions =
        _vertices.map((v) => Position(v[1], v[0])).toList();
    // Close the ring
    positions.add(positions.first);

    await _polygonManager!.create(PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [positions]),
      fillColor: _colorToArgb(AppColors.accent.withValues(alpha: 0.25)),
      fillOutlineColor: _colorToArgb(AppColors.accent),
      fillOpacity: 1.0,
    ));
  }

  Future<void> _renderVertices() async {
    if (_vertexManager == null) return;
    await _vertexManager!.deleteAll();
    _vertexIdToIndex.clear();

    for (var i = 0; i < _vertices.length; i++) {
      final v = _vertices[i];
      final ann = await _vertexManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(v[1], v[0])),
        iconSize: 0.4,
        iconColor: _colorToArgb(AppColors.accent),
        isDraggable: true,
      ));
      _vertexIdToIndex[ann.id] = i;
    }
  }

  /// Draws a draggable preview pin showing where the achievement marker
  /// will land after saving. Uses [_pinOverride] if set, otherwise the
  /// polygon centroid. Skipped while the user is mid-drag on the pin to
  /// avoid deleting the annotation under their finger.
  Future<void> _renderPinPreview() async {
    if (_pinManager == null) return;
    if (_draggingPin) return;
    await _pinManager!.deleteAll();

    if (_vertices.length < 3) return;
    final pos = _pinOverride ?? _centroid();
    if (pos == null) return;

    await _pinManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(pos[1], pos[0])),
      iconSize: 1.2,
      iconColor: _colorToArgb(AppColors.primary),
      isDraggable: true,
    ));
  }

  int _colorToArgb(Color c) {
    return (c.a * 255).round() << 24 |
        (c.r * 255).round() << 16 |
        (c.g * 255).round() << 8 |
        (c.b * 255).round();
  }

  // ── Save ──

  Future<void> _savePolygon() async {
    if (_selected == null || _vertices.length < 3) return;

    setState(() => _saving = true);

    try {
      final pinPos = _pinOverride ?? _centroid();
      if (SupabaseConfig.isConfigured) {
        final client = ref.read(supabaseClientProvider);
        final repo = AchievementDefinitionsRepository(client);
        await repo.savePolygon(
          _selected!.id,
          _vertices,
          centerLat: pinPos?[0],
          centerLng: pinPos?[1],
        );
      }

      // Refresh definitions from Supabase
      await ref.read(achievementDefinitionsProvider.notifier).refresh();

      if (mounted) {
        final pinNote = _pinOverride != null ? 'manual pin' : 'pin at centroid';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved "${_selected!.title}" — ${_vertices.length} vertices, $pinNote'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
