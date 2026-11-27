import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hhmmobile/app/router/app_routes.dart';
import 'package:hhmmobile/app/theme/app_dimens.dart';

Future<void> showPaperOrder(
  BuildContext context, {
  required String symbol,
  required String price,
  required bool isBuy,
}) async {
  final quantityController = TextEditingController();
  final parsedPrice = double.tryParse(
    price.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
  );
  if (parsedPrice == null || parsedPrice <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Giá coin không hợp lệ')),
    );
    quantityController.dispose();
    return;
  }
  await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String? error;
        return StatefulBuilder(builder: (context, setSheetState) {
          final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
          final total = quantity * parsedPrice;
          return Padding(
              padding: EdgeInsetsGeometry.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${isBuy ? 'Mua' : 'Bán'} $symbol · Paper trading',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Số lượng $symbol',
                      errorText: error,
                    ),
                    onChanged: (_) => setSheetState(() => error = null),
                  ),
                  const SizedBox(height: 12),
                  Text('Giá tham khảo: ${parsedPrice.toStringAsFixed(4)}'),
                  Text('Giá trị mô phỏng: ${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (quantity <= 0) {
                        setSheetState(() => error = 'Nhập số lượng lớn hơn 0');
                        return;
                      }

                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã mô phỏng ${isBuy ? 'mua' : 'bán'} '
                            '${quantity.toString()} $symbol '
                            '(${total.toStringAsFixed(2)} theo giá tham khảo). '
                            'Không có lệnh thật được gửi.',
                          ),
                        ),
                      );
                    },
                    child: Text('Mô phỏng ${isBuy ? 'Mua' : 'Bán'}'),
                  ),
                ],
              ));
        });
      });
  quantityController.dispose();
}
