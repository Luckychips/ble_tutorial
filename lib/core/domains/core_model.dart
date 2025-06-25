//lib
import 'package:hive/hive.dart';
//generated
part 'core_model.g.dart';

@HiveType(typeId: 0)
class CoreModel extends HiveObject {
  @HiveField(0)
  String? remoteId;

  @HiveField(1)
  int? deviceVersion;

  CoreModel({ required this.remoteId, required this.deviceVersion });
}