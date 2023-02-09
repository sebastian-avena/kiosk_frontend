import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_flutter/models/card_token_model.dart';
import 'package:kiosk_flutter/providers/main_provider.dart';
import 'package:kiosk_flutter/screens/payment_screens/payment_status_screen.dart';
import 'package:kiosk_flutter/screens/start_screen.dart';
import 'package:kiosk_flutter/themes/color.dart';
import 'package:kiosk_flutter/utils/api/api_service.dart';
import 'package:kiosk_flutter/widgets/bars/payu_top_bar.dart';
import 'package:kiosk_flutter/widgets/mobile_payment.dart';
import 'package:payu/payu.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' as SVG;
import 'package:webview_flutter/webview_flutter.dart';

import 'display_frame_screen.dart';

class TokenPaymentScreen extends StatefulWidget{
  final CardPaymentToken cardToken;
  final int id;
  final double amount;
  final bool save;

  const TokenPaymentScreen({
    Key? key,
    required this.cardToken,
    required this.id,
    required this.amount,
    required this.save,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => TokenPaymentScreenState();
}

class TokenPaymentScreenState extends State<TokenPaymentScreen> {
  late MainProvider provider;
  bool warning = false;
  String url = "";
  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          color:  Colors.white,
        image: DecorationImage(
            image: SVG.Svg('assets/images/background.svg'),
            fit: BoxFit.cover)),
        child: Column(
          children: [
            PayUTopBar(
                onPress: () {

                },
                amount: provider.sum),
            ElevatedButton(
                onPressed: () {
                  print("click");
                  print(widget.cardToken.value);
                  if(warning){
                    _didTapHandleWarningContinue3DS(context, url, widget.id);
                  }else{
                    _payment();
                  }

                },
                child: Text("use card ${widget.cardToken.cardNumberMasked}"))
          ])));
  }

  void _payment() async {
    final result = await ApiService(token: provider.loginToken).paymentCardTokenOrder(widget.id, widget.amount, widget.cardToken.value);

    print(result.toString());
    String statusCode = jsonDecode(result!)["status"]["statusCode"];

    try{
      if(widget.save == true){
        print(jsonDecode(result)["payMethods"]);
        print(jsonDecode(result)["payMethods"]["payMethod"]["value"]);
        widget.cardToken.value = jsonDecode(result)["payMethods"]["payMethod"]["value"];
        provider.cardTokens.add(widget.cardToken);
        provider.saveCardTokens();
      }
    }catch(e){
      print("nope");
      print(e);
    }

    if(statusCode == "WARNING_CONTINUE_REDIRECT"){
      print(1);
    } else if(statusCode == "WARNING_CONTINUE_3DS"){
      print(2);
      url = jsonDecode(result)["redirectUri"];
      warning = true;
      _didTapHandleWarningContinue3DS(context, jsonDecode(result)["redirectUri"], widget.id);

    } else if(statusCode == "SUCCESS"){
      print(3);
    } else if(statusCode == "WARNING_CONTINUE_CVV"){
      print(4);
    }
  }

  void _didTapHandleWarningContinue3DS(context, String uri, int id) async {
    final SoftAcceptMessage result = await showDialog(
        context: context,
        builder: (context) => SoftAcceptAlertDialog(
            request: SoftAcceptRequest(
                redirectUri: uri)));

    final result2 = SoftAcceptRequest(redirectUri: uri);

    print(result2.toString());
    print("first");
    print(result.value);
    print("seccond");

    if(result.value == "AUTHENTICATION_SUCCESSFUL"){
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PaymentStatusScreen(id: id)));
    }else if(result.value == "AUTHENTICATION_CANCELED"){
      print("Authentication failed");
    }else if(result.value == "DISPLAY_FRAME"){
      print(uri);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayFrameScreen(url: uri, id: id)
          ));
    }
  }
}