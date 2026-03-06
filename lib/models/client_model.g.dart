// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Client(
      id: fields[0] as String,
      fullName: fields[1] as String,
      phone: fields[2] as String,
      nationalId: fields[3] as String,
      bankCardNumber: fields[4] as String,
      purchaseDate: fields[5] as DateTime,
      note: fields[6] as String?,
      purchasePrice: fields[7] as double,
      deposit: fields[8] as double,
      dollarAmount: fields[9] as double,
      currency: fields[10] as String,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime?,
      bankName: fields.containsKey(13) ? fields[13] as String? : null,
      exchangeRate: fields.containsKey(14) ? fields[14] as double? : null,
      profitLyd: fields.containsKey(15) ? fields[15] as double? : null,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.nationalId)
      ..writeByte(4)
      ..write(obj.bankCardNumber)
      ..writeByte(5)
      ..write(obj.purchaseDate)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.purchasePrice)
      ..writeByte(8)
      ..write(obj.deposit)
      ..writeByte(9)
      ..write(obj.dollarAmount)
      ..writeByte(10)
      ..write(obj.currency)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.bankName)
      ..writeByte(14)
      ..write(obj.exchangeRate)
      ..writeByte(15)
      ..write(obj.profitLyd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
