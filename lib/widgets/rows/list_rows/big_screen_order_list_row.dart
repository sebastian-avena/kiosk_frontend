import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kiosk_flutter/models/menus/munchie_product.dart';
import 'package:kiosk_flutter/themes/color.dart';

class BigScreenOrderListRow extends StatelessWidget {
  const BigScreenOrderListRow({super.key, required this.product});

  final MunchieProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).size.width * 0.001),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.01, 0, 0, 0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.05,
              height: MediaQuery.of(context).size.width * 0.06,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.mediumBlue),
              child: Center(
                child: FittedBox(
                  child: Text(
                    '${product.number}x',
                    style: const TextStyle(
                      fontFamily: 'GloryLight',
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.02, 0, MediaQuery.of(context).size.width * 0.05, 0),
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.03,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'GloryBold',
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.025,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.ingredientNamesAsString,
                      style: const TextStyle(
                        fontFamily: 'GloryLightItalic',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.05,
            child: FittedBox(
              child: Text(
                '${product.price.toStringAsFixed(2)} zł',
                style: const TextStyle(
                  fontFamily: 'GloryLightItalic',
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.01, 0, MediaQuery.of(context).size.width * 0.01, 0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.02,
              height: MediaQuery.of(context).size.width * 0.02,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mediumBlue,
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    '${product.number}x',
                    style: const TextStyle(
                      fontFamily: 'GloryLight',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.1,
            child: AutoSizeText(
              '${(product.number * product.price).toStringAsFixed(2)} zł',
              textAlign: TextAlign.end,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'GloryBold',
                fontSize: 20,
              ),
            ),
          )
        ],
      ),
    );
  }
}
