int crc16(List<int> data) {
  int crc = 0xFFFF;
  for (int byte in data) {
    crc ^= (byte << 8);
    for (int i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = (crc << 1) ^ 0x1021;
      } else {
        crc <<= 1;
      }

      crc &= 0xFFFF;
    }
  }

  return crc;
}

bool isReadyCommand(List<int> bytes) {
  return bytes.length >= 4 && String.fromCharCode(bytes[0]) == 's' && String.fromCharCode(bytes[3]) == '?';
}

bool isNormalReceived(List<int> sendBytes, List<int> receivedBytes) {
  if (sendBytes.length >= 4 && receivedBytes.length >= 6) {
    List<int> body = receivedBytes.sublist(0, receivedBytes.length - 2);
    int receivedCrc = receivedBytes[receivedBytes.length - 2] + (receivedBytes[receivedBytes.length - 1] << 8);
    int calculatedCrc = crc16(body);

    return String.fromCharCode(receivedBytes[0]) == 'r' && String.fromCharCode(receivedBytes[3]) == ':' && receivedCrc == calculatedCrc;
  }

  return false;
}

List<int> convertToInt16BigEndian(List<int> bytes) {
  if (bytes.length % 2 != 0) {
    throw ArgumentError('Byte list must have an even number of elements');
  }

  List<int> result = [];
  for (int i = 0; i < bytes.length; i += 2) {
    int value = (bytes[i] << 8) | bytes[i + 1];
    if (value & 0x8000 != 0) {
      value -= 0x10000;
    }

    result.add(value);
  }

  return result;
}

bool isAsciiCharacter(int c) {
  return c >= 0 && c <= 127;
}

bool hasAscii(String command) {
  return ['ssv', 'srz'].any((word) => command.contains(word));
}