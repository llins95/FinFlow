import 'package:hive/hive.dart';

import 'purchase.dart';

class PurchaseAdapter extends TypeAdapter<Purchase> {
  @override
  final int typeId = 0;

  @override
  Purchase read(BinaryReader reader) {
    final fieldCount = reader.readByte();

    final fields = <int, dynamic>{
      for (int index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };

    return Purchase(
      id: fields[0] as String,
      description: fields[1] as String,
      amount: fields[2] as double,
      cardId: fields[3] as String,
      installments: fields[4] as int,
      purchaseDate: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Purchase purchase) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(purchase.id)
      ..writeByte(1)
      ..write(purchase.description)
      ..writeByte(2)
      ..write(purchase.amount)
      ..writeByte(3)
      ..write(purchase.cardId)
      ..writeByte(4)
      ..write(purchase.installments)
      ..writeByte(5)
      ..write(purchase.purchaseDate);
  }
}
