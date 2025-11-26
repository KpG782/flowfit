import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as maplat;
import '../../domain/geofence_mission.dart';

class AddMissionDialog extends StatefulWidget {
  final maplat.LatLng latLng;
  const AddMissionDialog({required this.latLng, super.key});

  @override
  State<AddMissionDialog> createState() => _AddMissionDialogState();
}

class _AddMissionDialogState extends State<AddMissionDialog> {
  String _title = '';
  String? _description;
  MissionType _type = MissionType.sanctuary;
  double _radius = 50.0;
  double? _targetDistance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(
              children: [
                const Text('Radius (m)'),
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 1000,
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text(_radius.toStringAsFixed(0)),
              ],
            ),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(labelText: 'Target distance (m)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final mission = GeofenceMission(
                id: id,
                title: _title.isEmpty ? 'Mission $id' : _title,
                description: _description,
                center: LatLngSimple(widget.latLng.latitude, widget.latLng.longitude),
                radiusMeters: _radius,
                type: _type,
                targetDistanceMeters: _targetDistance,
              );
              Navigator.of(context).pop(mission);
            },
            child: const Text('Add')),
      ],
    );
  }
}
