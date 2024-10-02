import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiosk_flutter/common/widgets/background.dart';
import 'package:kiosk_flutter/features/order/bloc/order_bloc.dart';
import 'package:kiosk_flutter/models/backend_models.dart';
import 'package:kiosk_flutter/screens/start_screen_kiosk.dart';
import 'package:kiosk_flutter/themes/color.dart';
import 'package:kiosk_flutter/utils/api/api_service.dart';

class BlikPayScreen extends StatefulWidget {
  final double amount;
  final int id;

  const BlikPayScreen({Key? key, required this.amount, required this.id}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BlikPayScreenState();
}

class BlikPayScreenState extends State<BlikPayScreen> {
  TextEditingController controller = TextEditingController();

  int status = 0;
  int orderNumber = 1;
  bool blikFlag = false;
  bool smsFlag = false;

  bool paymentDone = false;

  @override
  Widget build(context) {
    print("status: $status");
    if (status == 1) {
      if (!blikFlag) {
        blikFlag = true;
        ApiService(token: provider.loginToken).checkPaymentStatus(widget.id).then((value) => {
              setState(() {
                if (value == "COMPLETED") {
                  status = 2;
                  context.read<OrderBloc>().add(const OrderEvent.updateOrderStatus(OrderStatus.paid));
                }
              })
            });
      }
    } else if (status == 2) {
      if (!smsFlag) {
        smsFlag = true;
        provider.testRoute().then((value) => {
              setState(() {
                orderNumber = value;
                status = 3;
              })
            });
      }
    } else if (status == 3) {}

    return Background(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.lime)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: GestureDetector(
                    onTap: () {
                      if (status == 0) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "<",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.lime,
                        fontSize: 60,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Image.asset(
                    'assets/images/payULogos/payULogoLime.png',
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Text(
                    "${provider.sum.toStringAsFixed(2)} zł",
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          status == 0
              ? Column(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "Wprowadź kod blik",
                        ),
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.length == 6) {
                        ApiService(token: provider.loginToken).paymentBlikOrder(widget.id, widget.amount, controller.text);
                        setState(() {
                          status = 1;
                        });
                      }
                    },
                    child: const Text("zapłać"),
                  )
                ])
              : status == 1
                  ? Column(
                      children: [
                        Container(padding: const EdgeInsets.all(20), child: const Text("Płatność rozpoczęta")),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.5, height: MediaQuery.of(context).size.width * 0.5, child: const CircularProgressIndicator())
                      ],
                    )
                  : status == 2
                      ? Column(
                          children: [
                            Container(padding: const EdgeInsets.all(10), child: const Text("Płatność zakończona powodzeniem", style: TextStyle(fontSize: 20))),
                            const CircularProgressIndicator()
                          ],
                        )
                      : status == 3
                          ? Column(
                              children: [
                                Container(padding: const EdgeInsets.all(10), child: const Text("Płatność zakończona powodzeniem", style: TextStyle(fontSize: 20))),
                                Container(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'Twoje zamówienie ma nr $orderNumber',
                                      style: const TextStyle(fontSize: 15),
                                    )),
                                ElevatedButton(
                                  onPressed: () async {
                                    await provider.orderFinish();
                                    provider.changeToPizza();
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StartScreenKiosk()));
                                  },
                                  child: const Text("Zakończ transakcje"),
                                )
                              ],
                            )
                          : const Text("")
        ],
      ),
    );
  }
}
