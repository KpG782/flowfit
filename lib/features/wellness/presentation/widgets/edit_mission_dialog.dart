import 'package:flutter/material.dart';
import '../../domain/geofence_mission.dart';

class EditMissionDialog extends StatefulWidget {
  final GeofenceMission mission;
  const EditMissionDialog({required this.mission, super.key});

  @override
  State<EditMissionDialog> createState() => _EditMissionDialogState();
}

class _EditMissionDialogState extends State<EditMissionDialog> {
  late String _title;
  String? _description;
  late MissionType _type;
  late double _radius;
  double? _targetDistance;

  @override
  void initState() {
    super.initState();
    _title = widget.mission.title;
    _description = widget.mission.description;
    _type = widget.mission.type;
    _radius = widget.mission.radiusMeters;
    _targetDistance = widget.mission.targetDistanceMeters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: _title),
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              controller: TextEditingController(text: _description),
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(
              children: [
                const Text('Radius (m)'),
                Expanded(
                  child: Slider(min: 10, max: 2000, value: _radius, onChanged: (v) => setState(() => _radius = v)),
                ),
                Text(_radius.toStringAsFixed(0)),
              ],
            ),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(labelText: 'Target distance (m)'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _targetDistance?.toString()),
                onChanged: (v) => setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final updated = widget.mission.copyWith(
                title: _title,
                description: _description,
                radiusMeters: _radius,
                type: _type,
                targetDistanceMeters: _targetDistance,
              );
              Navigator.of(context).pop(updated);
            },
            child: const Text('Save')),
      ],
    );
  }
}
