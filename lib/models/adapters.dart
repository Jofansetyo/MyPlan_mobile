import 'package:hive/hive.dart';
import 'transaction_model.dart';
import 'task_model.dart';

// ==========================================
// ADAPTER UNTUK TRANSACTION
// ==========================================
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      type: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      category: fields[3] as String,
      date: fields[4] as DateTime,
      note: fields[5] as String,
      walletType: fields[6] as String? ?? 'Cash',
      transferToWallet: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.walletType)
      ..writeByte(7)
      ..write(obj.transferToWallet);
  }
}

// ==========================================
// ADAPTER UNTUK TASK
// ==========================================
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      course: fields[2] as String?,
      assignedDate: fields[3] as DateTime,
      deadline: fields[4] as DateTime,
      priority: fields[5] as String,
      status: fields[6] as String,
      reminder: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.course)
      ..writeByte(3)
      ..write(obj.assignedDate)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.reminder);
  }
}
