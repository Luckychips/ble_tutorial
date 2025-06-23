import 'package:hive/hive.dart';

part 'core_model.g.dart';

@HiveType(typeId: 0)
class CoreModel extends HiveObject {
  @HiveField(0)
  String? remoteId;

  CoreModel({ required this.remoteId });
}