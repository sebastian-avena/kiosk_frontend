import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kiosk_flutter/l10n/generated/l10n.dart';
import 'package:kiosk_flutter/models/backend_models.dart';
import 'package:kiosk_flutter/providers/main_provider.dart';
import 'package:kiosk_flutter/screens/payment_screens/new_payu_screen.dart';
import 'package:provider/provider.dart';
import 'package:kiosk_flutter/screens/start_screen.dart';

import 'package:kiosk_flutter/widgets/lists/order_list_view.dart';
import 'package:kiosk_flutter/widgets/card/phone_popup_card.dart';
import 'package:kiosk_flutter/themes/color.dart';
import 'package:async/async.dart';

class SummaryCard extends StatefulWidget {
  final Function onInteraction;
  final Function onPopUpFinish;

  const SummaryCard({Key? key, required this.onInteraction, required this.onPopUpFinish}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SummaryCardState();
}

class SummaryCardState extends State<SummaryCard> {
  var _paymentState = 0; // 0 - Not Started, 1 - Processing, 2 - Not Accepted, 3 - Accepted

  RestartableTimer? timer;
  late MainProvider provider;

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  void _timerStart() {
    print("2 timer start");
    timer?.cancel();
    timer = RestartableTimer(const Duration(minutes: 1), () async {
      //print('sec timer');
      print("in summary card timer");
      await provider.orderCancel();
      provider.changeToPizza();
      provider.inPayment = false;
      setState(() {
        _paymentState = 0;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => const StartScreen()));
    });
  }

  void _timerStop() {
    print("2 timer stop");
    timer?.cancel();
  }

  void makePayment() {
    if (provider.sum != 0) {
      showDialog(
          context: context,
          builder: (context) {
            return PhonePopupCard(onInteraction: () {
              //print('dumpc 2');
              widget.onInteraction();
            }, onPress: (isPromotionChecked) {
              widget.onPopUpFinish();
              print("pop");
              if (isPromotionChecked) {
                print(provider.order?.clientPhoneNumber);
                provider.updateOrderClientPhoneNumber(provider.order?.clientPhoneNumber);
              } else {
                provider.updateOrderClientPhoneNumber(provider.order?.clientPhoneNumber);
              }
              //provider.changeOrderStatus(1);
              print("done");
              if (MediaQuery.of(context).size.height > 1000) {
                setState(() {
                  _paymentState = 1;
                });
                provider.inPayment = true;
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewPayUScreen(),
                  ),
                );
              }
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context, listen: true);
    final size = MediaQuery.of(context).size;

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: AppColors.green,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 6,
      surfaceTintColor: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: size.height > 1000 ? size.width * 0.4 : size.width * 0.6,
              height: size.height * 0.05,
              child: FittedBox(
                child: Text(
                  AppText.of(context).orderSummaryText,
                  style: const TextStyle(
                    fontFamily: 'GloryExtraBold',
                    fontSize: 30,
                    color: AppColors.mediumBlue,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: size.width * 0.9,
            height: size.height * 0.4,
            child: OrderList(storageOrders: provider.storageOrders),
          ),
          _paymentState == 0
              ? Container(
                  alignment: AlignmentDirectional.center,
                  padding: EdgeInsets.fromLTRB(0, size.height * 0.05, size.width * 0, 0),
                  child: InkWell(
                    onTapDown: (_) {
                      makePayment();
                    },
                    child: SizedBox(
                      width: size.height > 1000 ? size.width * 0.86 : size.width * 0.8,
                      height: size.height > 1000 ? size.height * 0.05 : size.height * 0.075,
                      child: ElevatedButton(
                        onPressed: () {
                          makePayment();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.black),
                        child: SizedBox(
                          width: size.height > 1000 ? size.width * 0.4 : size.width * 0.5,
                          child: FittedBox(
                            child: Text(
                              AppText.of(context).makePaymentButtonLabel,
                              style: const TextStyle(
                                fontFamily: 'GloryBold',
                                fontSize: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ))
              : size.height > 1000
                  ? FutureBuilder(
                      future: provider.payment.startTransaction(provider.sum),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          _timerStop();
                          return Column(
                            children: [
                              SizedBox(
                                height: size.width > 1000 ? size.height * 0.1 : size.height * 0.17,
                                width: size.width * 0.86,
                                child: Card(
                                  color: AppColors.green,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      SizedBox(
                                        height: size.width > 1000 ? size.width * 0.04 : size.width * 0.08,
                                        child: FittedBox(
                                          child: Text(
                                            AppText.of(context).paymentStartedText.toUpperCase(),
                                            style: const TextStyle(
                                              fontFamily: 'GloryExtraBold',
                                              fontSize: 25,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: size.width > 1000 ? size.width * 0.03 : size.width * 0.06,
                                        width: size.width * 0.8,
                                        child: FittedBox(
                                          child: Text(
                                            AppText.of(context).paymentInfoText,
                                            style: const TextStyle(
                                              fontFamily: 'GloryMedium',
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const CircularProgressIndicator(color: AppColors.darkGreen),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return const Text('Error');
                          } else if (snapshot.hasData) {
                            //print("Its done: ${snapshot.data.toString()}");
                            print("snapshot data");
                            print(snapshot.data);
                            if (snapshot.data.toString() == "7") {
                              // change flag to test 7, for normal 0
                              //print("Its done: ${snapshot.data.toString()}");
                              //provider.changeOrderStatus(2);
                              _timerStop();
                              return Column(children: [
                                SizedBox(
                                  height: size.height * 0.1,
                                  width: size.width * 0.86,
                                  child: Card(
                                    color: AppColors.green,
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(AppText.of(context).paymentAcceptedText.toUpperCase(), style: const TextStyle(fontFamily: 'GloryExtraBold', fontSize: 25)),
                                          FutureBuilder(
                                              future: provider.getOrderNumber(),
                                              builder: (context2, snapshot2) {
                                                print("from summary");
                                                if (snapshot2.connectionState == ConnectionState.waiting) {
                                                  return const CircularProgressIndicator(color: AppColors.darkGreen);
                                                } else if (snapshot2.connectionState == ConnectionState.done) {
                                                  if (snapshot2.hasError) {
                                                    return Text('Error ${snapshot2.error}');
                                                  } else if (snapshot2.hasData) {
                                                    //_timerStart();
                                                    return Text('Twoje zamówienie ma nr ${snapshot2.data}');
                                                  } else {
                                                    return const Text('Empty data');
                                                  }
                                                } else {
                                                  return Text(snapshot2.connectionState.toString());
                                                }
                                              })
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(0, size.height * 0.01, 0, 0),
                                  child: SizedBox(
                                    height: size.width > 1000 ? size.height * 0.03 : size.height * 0.05,
                                    width: size.width > 1000 ? size.width * 0.2 : size.width * 0.4,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await provider.orderFinish();
                                        provider.changeToPizza();
                                        provider.inPayment = false;
                                        setState(() {
                                          _paymentState = 0;
                                        });
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const StartScreen()));
                                      },
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red, width: 1)),
                                      child: AutoSizeText(
                                        AppText.of(context).returnButtonLabel,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontFamily: 'GloryMedium',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ]);
                            } else {
                              _timerStart();
                              print("in sumarry card");
                              provider.updateOrderStatus(OrderStatus.canceled);
                              return Column(
                                children: [
                                  SizedBox(
                                    height: size.height * 0.1,
                                    width: size.width * 0.86,
                                    child: Card(
                                      color: AppColors.red,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          FittedBox(
                                            child: Text(
                                              AppText.of(context).paymentCancelledText.toUpperCase(),
                                              style: const TextStyle(
                                                fontFamily: 'GloryExtraBold',
                                                fontSize: 25,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.fromLTRB(0, size.height * 0.01, 0, 0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.fromLTRB(size.width * 0.02, 0, 0, 0),
                                          child: SizedBox(
                                            height: size.height > 1000 ? size.width * 0.05 : size.width * 0.1,
                                            width: size.height > 1000 ? size.width * 0.2 : size.width * 0.4,
                                            child: InkWell(
                                              onTapDown: (_) async {
                                                _timerStop();
                                                await provider.orderCancel();
                                                provider.changeToPizza();
                                                provider.inPayment = false;
                                                setState(() {
                                                  _paymentState = 0;
                                                });
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const StartScreen()));
                                              },
                                              child: OutlinedButton(
                                                onPressed: () async {
                                                  _timerStop();
                                                  await provider.orderCancel();
                                                  provider.changeToPizza();
                                                  provider.inPayment = false;
                                                  setState(() {
                                                    _paymentState = 0;
                                                  });
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StartScreen()));
                                                },
                                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red, width: 1)),
                                                child: FittedBox(
                                                  child: Text(
                                                    AppText.of(context).returnButtonLabel,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontFamily: 'GloryMedium',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.fromLTRB(size.height > 1000 ? size.width * 0.45 : size.width * 0.05, 0, 0, 0),
                                          child: SizedBox(
                                            height: size.height > 1000 ? size.width * 0.05 : size.width * 0.1,
                                            width: size.height > 1000 ? size.width * 0.2 : size.width * 0.4,
                                            child: InkWell(
                                              onTapDown: (_) {
                                                _timerStop();
                                                provider.updateOrderStatus(OrderStatus.paymentInProgress);
                                                setState(() {
                                                  _paymentState = 1;
                                                });
                                              },
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  _timerStop();
                                                  provider.updateOrderStatus(OrderStatus.paymentInProgress);
                                                  setState(() {
                                                    _paymentState = 1;
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.black),
                                                child: FittedBox(
                                                  child: Text(
                                                    AppText.of(context).tryAgainButtonLabel,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontFamily: 'GloryMedium',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          } else {
                            //print(snapshot.data);
                            return const Text('Empty data');
                          }
                        } else {
                          return const Text('snapshot.connectionState');
                        }
                      })
                  : SizedBox(
                      height: size.height * 0.18,
                      width: size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NewPayUScreen()));
                        },
                        child: const Text("go"),
                      ),
                    ),
        ],
      ),
    );
  }
}
