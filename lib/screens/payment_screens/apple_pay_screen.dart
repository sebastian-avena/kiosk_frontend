import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_flutter/providers/main_provider.dart';
import 'package:kiosk_flutter/screens/payment_screens/payment_status_screen.dart';
import 'package:kiosk_flutter/screens/start_screen.dart';
import 'package:kiosk_flutter/themes/color.dart';
import 'package:kiosk_flutter/utils/api/api_service.dart';
import 'package:kiosk_flutter/widgets/bars/payu_top_bar.dart';
import 'package:kiosk_flutter/widgets/mobile_payment.dart';
import 'package:payu/payu.dart' as PayU;
import 'package:provider/provider.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' as SVG;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:pay/pay.dart';
import 'dart:io';

import 'display_frame_screen.dart';

class ApplePayScreen extends StatefulWidget {
  final double amount;
  final int id;

  const ApplePayScreen({Key? key, required this.amount, required this.id})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ApplePayScreenState();
}

class ApplePayScreenState extends State<ApplePayScreen> {
  late MainProvider provider;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context, listen: true);
    print("heh?");
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: null,
        body: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                    image: SVG.Svg('assets/images/background.svg'),
                    fit: BoxFit.cover)),
            child: Column(children: [
              PayUTopBar(onPress: () {}, amount: provider.sum),
              Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ApplePayButton(
                    paymentConfiguration:
                        PaymentConfiguration.fromJsonString(defaultApplePay),
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.3),
                    onPaymentResult: (result) {},
                    style: ApplePayButtonStyle.black,
                    type: ApplePayButtonType.buy,
                    paymentItems: [
                      PaymentItem(
                          label: "total",
                          amount: provider.sum.toString(),
                          status: PaymentItemStatus.final_price)
                    ],
                    loadingIndicator: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )),
              Text('new')
            ])));
  }

  static const String defaultApplePay = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.sams.fish",
    "displayName": "Sam's Fish",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
    "countryCode": "US",
    "currencyCode": "USD",
    "requiredBillingContactFields": ["emailAddress", "name", "phoneNumber", "postalAddress"],
    "requiredShippingContactFields": [],
    "shippingMethods": [
      {
        "amount": "0.00",
        "detail": "Available within an hour",
        "identifier": "in_store_pickup",
        "label": "In-Store Pickup"
      },
      {
        "amount": "4.99",
        "detail": "5-8 Business Days",
        "identifier": "flat_rate_shipping_id_2",
        "label": "UPS Ground"
      },
      {
        "amount": "29.99",
        "detail": "1-3 Business Days",
        "identifier": "flat_rate_shipping_id_1",
        "label": "FedEx Priority Mail"
      }
    ]
  }
}''';
}