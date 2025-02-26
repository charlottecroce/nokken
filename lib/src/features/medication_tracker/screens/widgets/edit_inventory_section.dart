import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nokken/src/services/navigation_service.dart';
import '../../../../shared/theme/shared_widgets.dart';

class InventorySection extends StatelessWidget {
  final int currentQuantity;
  final int refillThreshold;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onThresholdChanged;

  const InventorySection({
    super.key,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.onQuantityChanged,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Inventory',
      children: [
        _buildCounterRow(
          context,
          label: 'Current Quantity',
          value: currentQuantity,
          onChanged: onQuantityChanged,
          minValue: 0,
          showAddButton: true,
        ),
        SharedWidgets.verticalSpace(),
        _buildCounterRow(
          context,
          label: 'Refill Alert at',
          value: refillThreshold,
          onChanged: onThresholdChanged,
          minValue: 0,
          showAddButton: false,
        ),
      ],
    );
  }

  Widget _buildCounterRow(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int minValue,
    required bool showAddButton,
    int? maxValue,
  }) {
    final controller = TextEditingController(text: value.toString());
    final addController = TextEditingController(text: '30');

    return Row(
      children: [
        Text('$label: '),
        Flexible(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (String val) {
              final newValue = int.tryParse(val) ?? value;
              if (newValue >= minValue &&
                  (maxValue == null || newValue <= maxValue)) {
                onChanged(newValue);
              } else {
                controller.text = value.toString();
              }
            },
          ),
        ),
        if (showAddButton)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add More'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add More'),
                  content: TextField(
                    controller: addController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Amount to add',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => NavigationService.goBack(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        final amount = int.tryParse(addController.text) ?? 0;
                        final newValue = value + amount;
                        if (maxValue == null || newValue <= maxValue) {
                          onChanged(newValue);
                          controller.text = newValue.toString();
                        }
                        NavigationService.goBack(context);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
