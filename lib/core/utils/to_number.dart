String to16With0x(int target) {
  return '0x${target.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}

int to16(int target) {
  return int.parse(to16With0x(target));
}

String toCharacter(int target) {
  return String.fromCharCode(int.parse(target.toRadixString(10)));
}