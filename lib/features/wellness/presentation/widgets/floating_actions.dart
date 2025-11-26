import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;

class FloatingMapActions extends StatelessWidget {
  final fm.MapController? mapController;
  final maplat.LatLng? lastCenter;
  final Future<void> Function(maplat.LatLng) onAddAtLatLng;

  const FloatingMapActions({required this.mapController, required this.lastCenter, required this.onAddAtLatLng, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 70.0, right: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'center_location',
                onPressed: () async {
                  final pos = await Geolocator.getCurrentPosition();
                  mapController?.move(maplat.LatLng(pos.latitude, pos.longitude), 16.0);
                },
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'add_mission',
                onPressed: () async {
                  final center = lastCenter;
                  if (center != null) await onAddAtLatLng(maplat.LatLng(center.latitude, center.longitude));
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
