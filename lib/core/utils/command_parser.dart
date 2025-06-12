import 'package:ble_tutorial/config/engine.dart';

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

List<int> convertToBigEndianInt16(int number) {
  if (number < 0 || number > 0xFFFF) {
    throw ArgumentError('Value must be between 0 and 65535 (2 bytes).');
  }

  int highByte = (number >> 8) & 0xFF;
  int lowByte = number & 0xFF;
  // String highHex = highByte.toRadixString(16).padLeft(2, '0').toUpperCase();
  // String lowHex = lowByte.toRadixString(16).padLeft(2, '0').toUpperCase();
  return [highByte, lowByte];
}

bool isAsciiCharacter(int c) {
  return c >= 0 && c <= 127;
}

bool hasAscii(String command) {
  return getAsciiResponseCommandList().any((word) => command.contains(word));
}

bool isRequireCrc(String command) {
  return getIncludedCrcCommandList().any((word) => command.contains(word));
}

bool hasParameter(String command) {
  return getIncludedParamCommandList().any((word) => command.contains(word));
}

bool hasTransferValue(String command) {
  return getIncludedValueCommandList().any((word) => command.contains(word));
}