import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Components/cart_button.dart';
import '../../../Utils/colors.dart';

class QuantityAdjustementRow extends StatefulWidget {
  final int itemCount;
  final Function(int) onQuantityChanged;
  const QuantityAdjustementRow({
    super.key,
    required this.itemCount,
    required this.onQuantityChanged,
  });

  @override
  State<QuantityAdjustementRow> createState() => _QuantityAdjustementRowState();
}

class _QuantityAdjustementRowState extends State<QuantityAdjustementRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      padding: const EdgeInsets.only(top: 8.0, bottom: 10),
      child: Column(
        children: [
          // const Gap(10),
          // Decrease Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 1 < 1) ? 1 : widget.itemCount - 1);
                    });
                  },
                  label: '-1',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 5 < 1) ? 1 : widget.itemCount - 5);
                    });
                  },
                  label: '-5',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 10 < 1) ? 1 : widget.itemCount - 10);
                    });
                  },
                  label: '-10',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 20 < 1) ? 1 : widget.itemCount - 20);
                    });
                  },
                  label: '-20',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 50 < 1) ? 1 : widget.itemCount - 50);
                    });
                  },
                  label: '-50',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged((widget.itemCount - 100 < 1) ? 1 : widget.itemCount - 100);
                    });
                  },
                  label: '-100',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
              ],
            ),
          ),
          const Gap(5),
          // Increase Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 1);
                    });
                  },
                  label: '+1',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 5);
                    });
                  },
                  label: '+5',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 10);
                    });
                  },
                  label: '+10',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 20);
                    });
                  },
                  label: '+20',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 50);
                    });
                  },
                  label: '+50',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      widget.onQuantityChanged(widget.itemCount + 100);
                    });
                  },
                  label: '+100',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
              ],
            ),
          ),
          // const Gap(10),
        ],
      ),
    );
  }
}