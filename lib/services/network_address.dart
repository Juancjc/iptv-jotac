import 'dart:io';

/// Best guess at this device's address on the local network (the one a phone
/// on the same Wi-Fi can reach), skipping virtual adapters when possible.
Future<String> findLocalIPv4() async {
  List<NetworkInterface> interfaces;
  try {
    interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
  } on SocketException {
    return '127.0.0.1';
  }

  InternetAddress? fallback;
  for (final iface in interfaces) {
    final name = iface.name.toLowerCase();
    final looksVirtual =
        name.contains('virtual') ||
        name.contains('vmware') ||
        name.contains('vethernet') ||
        name.contains('docker') ||
        name.contains('loopback');
    for (final addr in iface.addresses) {
      if (!_isPrivateLan(addr.address)) continue;
      fallback ??= addr;
      if (!looksVirtual) return addr.address;
    }
  }
  return fallback?.address ?? '127.0.0.1';
}

bool _isPrivateLan(String ip) {
  if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
  final match = RegExp(r'^172\.(\d{1,3})\.').firstMatch(ip);
  if (match != null) {
    final second = int.tryParse(match.group(1)!) ?? 0;
    return second >= 16 && second <= 31;
  }
  return false;
}
