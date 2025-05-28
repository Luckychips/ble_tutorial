int to16(int target) {
  return int.parse('0x${target.toRadixString(16).padLeft(2, '0')}');
}