import 'package:flutter/material.dart';
import 'package:kiosk_flutter/models/country_model.dart';
import 'package:kiosk_flutter/themes/color.dart';
import 'package:kiosk_flutter/widgets/buttons/num_pad.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kiosk_flutter/providers/main_provider.dart';
import 'package:provider/provider.dart';

class PhonePopupCard extends StatefulWidget{
  final Function onPress;
  final Function onInteraction;

  const PhonePopupCard({
    Key? key,
    required this.onPress,
    required this.onInteraction
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => _PhonePopupCardState();
}

class _PhonePopupCardState extends State<PhonePopupCard> {
  bool isCheckedMain = false;
  bool isCheckedA = false;
  bool isCheckedB = false;
  bool isCheckedC = false;
  final TextEditingController _myController = TextEditingController();

  CountryModel _dropdownValue = CountryModel(
      countryCode: "",
      dialCode: "",
      minNumber: 0,
      maxNumber: 0,
      format: "");

  late MainProvider provider;

  void onPointerDown(PointerEvent){
    print("dumpc");
    widget.onInteraction();
  }

  @override
  initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context, listen: true);

    if(provider.countryList.isEmpty){
      provider.getCountryCodes();
      return const Text("");
    }else{
      if(_dropdownValue.dialCode.isEmpty){
        _dropdownValue = provider.countryList.first;
      }

      return Listener(
        onPointerDown: onPointerDown,
        child: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height * 0.01, 0, 0),
                    child: Text(AppLocalizations.of(context)!.enterPhoneNumberText.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontFamily: "GloryMedium"))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.06, 0, 0, 0),
                        child: DropdownButton(
                          value: _dropdownValue,
                          items: provider.countryList.map<DropdownMenuItem<CountryModel>>((CountryModel value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Container(
                                  padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.01, 0, 0, 22),
                                  child: Text("${value.countryCode.toUpperCase()
                                  .replaceAllMapped(RegExp(r'[A-Z]'),
                                      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397))} ${value.dialCode}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'GloryBold'))));
                          }).toList(),
                          onChanged: (CountryModel? value) {
                            setState(() {
                              _dropdownValue = value!;
                            });
                        })),
                      Container(
                        padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width* 0.04, 0, 0, 8),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextField(
                            controller: _myController,
                            showCursor: false,
                            keyboardType: TextInputType.none,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontFamily: 'GloryBold'))))]),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height * 0.01, 0, MediaQuery.of(context).size.height * 0.02),
                    child: NumPad(controller: _myController, maxDigit: _dropdownValue.maxNumber)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.05, 0, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                        activeColor: AppColors.green,
                                        checkColor: Colors.transparent,
                                        side: MaterialStateBorderSide.resolveWith((states) =>
                                          const BorderSide(
                                              width: 1.5,
                                              color: AppColors.green)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5)),
                                        value: isCheckedMain,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            isCheckedMain = value!;
                                            if (value == true) {
                                              isCheckedA = true;
                                              isCheckedB = true;
                                              isCheckedC = true;
                                            } else {
                                              isCheckedA = false;
                                              isCheckedB = false;
                                              isCheckedC = false;
                                            }
                                          });
                                        })),
                                Text(AppLocalizations.of(context)!.selectAllCheckText,
                                    style: const TextStyle(
                                        fontFamily: "GloryMedium",
                                        fontSize: 16))
                              ]),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                      scale: 1.5,
                                      child: Checkbox(
                                          activeColor: AppColors.green,
                                          checkColor: Colors.transparent,
                                          side: MaterialStateBorderSide.resolveWith((states) =>
                                            const BorderSide(
                                                width: 1.5,
                                                color: AppColors.green)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          value: isCheckedA,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isCheckedA = value!;
                                              if (isCheckedA == true && isCheckedB == true && isCheckedC == true) {
                                                isCheckedMain = true;
                                              } else {
                                                isCheckedMain = false;
                                              }
                                            });
                                          })),
                                  Text(AppLocalizations.of(context)!.requiredCheckText,
                                      style: const TextStyle(
                                          fontFamily: "GloryMedium",
                                          fontSize: 16))
                                ]),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                      scale: 1.5,
                                      child: Checkbox(
                                          activeColor: AppColors.green,
                                          checkColor: Colors.transparent,
                                          side: MaterialStateBorderSide.resolveWith((states) =>
                                            const BorderSide(
                                                width: 1.5,
                                                color: AppColors.green)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          value: isCheckedB,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isCheckedB = value!;

                                              if (isCheckedA == true && isCheckedB == true && isCheckedC == true) {
                                                isCheckedMain = true;
                                              } else {
                                                isCheckedMain = false;
                                              }
                                            });
                                          })),
                                  Text(AppLocalizations.of(context)!.promotionCheckText,
                                      style: const TextStyle(
                                          fontFamily: "GloryMedium",
                                          fontSize: 16))
                                ]),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                      scale: 1.5,
                                      child: Checkbox(
                                          activeColor: AppColors.green,
                                          checkColor: Colors.transparent,
                                          side: MaterialStateBorderSide.resolveWith((states) =>
                                          const BorderSide(
                                              width: 1.5,
                                              color: AppColors.green)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          value: isCheckedC,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isCheckedC = value!;

                                              if (isCheckedA == true && isCheckedB == true && isCheckedC == true) {
                                                isCheckedMain = true;
                                              } else {
                                                isCheckedMain = false;
                                              }
                                            });
                                          })),
                                  Text(AppLocalizations.of(context)!.optionalCheckText,
                                      style: const TextStyle(
                                          fontFamily: "GloryMedium",
                                          fontSize: 16))
                                ])
                          ])),
                      Container(
                          padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height * 0.035, MediaQuery.of(context).size.width * 0.05, 0),
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: ElevatedButton(
                                  onPressed: () {
                                    if (isCheckedA == true && _myController.text.length >= _dropdownValue.minNumber) {
                                      Navigator.of(context).pop();
                                      provider.order.client_name = _dropdownValue.dialCode + _myController.text.substring(0, 3) + _myController.text.substring(4, 7) + _myController.text.substring(8);
                                      widget.onPress(isCheckedB);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                      foregroundColor: Colors.black),
                                  child: Text(
                                      AppLocalizations.of(context)!.confirmButtonLabel,
                                      style: const TextStyle(
                                          fontFamily: 'GloryBold',
                                          fontSize: 30)))))])])))));
    }
  }
}