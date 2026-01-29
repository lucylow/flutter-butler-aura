class Device {
  final String id;
  final String tuyaDeviceId;
  final String name;
  final String type;
  final String room;
  final Map<String, dynamic> dpIds;
  final bool isOnline;
  final Map<String, dynamic> currentState;

  Device({
    required this.id,
    required this.tuyaDeviceId,
    required this.name,
    required this.type,
    required this.room,
    required this.dpIds,
    required this.isOnline,
    required this.currentState,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      tuyaDeviceId: json['tuya_device_id'] as String? ?? '',
      name: json['device_name'] as String? ?? 'Unknown Device',
      type: json['device_type'] as String? ?? 'unknown',
      room: json['room'] as String? ?? 'Unassigned',
      dpIds: json['dp_ids'] as Map<String, dynamic>? ?? {},
      isOnline: json['is_online'] as bool? ?? false,
      currentState: json['current_state'] as Map<String, dynamic>? ?? {},
    );
  }

  bool get isOn {
    if (currentState.isEmpty) return false;
    // Check common Tuya DP codes for switches
    for (var key in ['switch_1', 'switch_led', '1', '20', 'power', 'state']) {
      if (currentState.containsKey(key)) {
        final val = currentState[key];
        if (val is bool) return val;
        if (val is String) return val.toLowerCase() == 'true';
        if (val is int) return val == 1;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tuya_device_id': tuyaDeviceId,
      'device_name': name,
      'device_type': type,
      'room': room,
      'dp_ids': dpIds,
      'is_online': isOnline,
      'current_state': currentState,
    };
  }
}
