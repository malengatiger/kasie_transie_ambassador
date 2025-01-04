import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/commuter_cash_payment.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:get_it/get_it.dart';
import 'package:currency_formatter/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/widgets/payment/cash_check_in_widget.dart';

class DashElements extends StatefulWidget {
  const DashElements({super.key, required this.isGrid});

  final bool isGrid;

  @override
  DashElementsState createState() => DashElementsState();
}

class DashElementsState extends State<DashElements>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late StreamSubscription<lib.Trip> tripSub;
  late StreamSubscription<CommuterCashPayment> cashSub;
  late StreamSubscription<lib.AmbassadorPassengerCount> passengerSub;

  List<lib.Trip> trips = [];
  List<CommuterCashPayment> cashPayments = [];
  List<lib.AmbassadorPassengerCount> passengerCounts = [];

  DataApiDog dataApiDog = GetIt.instance<DataApiDog>();

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
  }

  void _listen() {
    tripSub = dataApiDog.tripStream.listen((onData) {
      trips.insert(0, onData);
      if (mounted) {
        setState(() {});
      }
    });
    cashSub = dataApiDog.commuterCashPaymentStream.listen((onData) {
      cashPayments.insert(0, onData);
      if (mounted) {
        setState(() {});
      }
    });
    passengerSub = dataApiDog.passengerCountStream.listen((onData) {
      passengerCounts.insert(0, onData);
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var passengersIn = 0;
    for (var pc in passengerCounts) {
      passengersIn += pc.passengersIn!;
      ;
    }
    var total = 0.0;
    for (var cp in cashPayments) {
      total += cp.amount!;
    }

    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            trips.isEmpty? gapW32:DataCup(title: 'Trips', count: trips.length, color: Colors.red),
            gapH8,
            trips.isEmpty? gapW32:DataCup(
                title: 'Commuter Payments',
                amount: total,
                color: Colors.green.shade700),
            gapH8,
            trips.isEmpty? gapW32:DataCup(
                title: 'Passengers',
                count: passengersIn,
                color: Colors.blue.shade600),
            gapH32,
            gapH32,
           SizedBox(
              width: 300,
              child: ElevatedButton(
                style: ButtonStyle(
                  elevation: WidgetStatePropertyAll(8),
                  backgroundColor: WidgetStatePropertyAll(Colors.green),
                ),
                onPressed: () {
                  _navigateToCashCheckIn();
                },
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Cash Check In',
                    style: myTextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        weight: FontWeight.normal),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _navigateToCashCheckIn() async {
    var passengersIn = 0;
    for (var pc in passengerCounts) {
      passengersIn += pc.passengersIn!;
      ;
    }
    var total = 0.0;
    for (var cp in cashPayments) {
      total += cp.amount!;
    }
   var ok = await  NavigationUtils.navigateTo(
        context: context,
        widget: CashCheckInWidget(
          onError: (err) {},
          isCommuterCash: true,
          isRankFeeCash: false,
          amount: total,
          passengers: passengersIn,
        ));
    if (ok) {
      cashPayments.clear();
      passengerCounts.clear();
      trips.clear();
      setState(() {

      });
    }
  }
}

class DataCup extends StatelessWidget {
  const DataCup(
      {super.key,
      required this.title,
      this.amount,
      this.count,
      required this.color});

  final String title;
  final double? amount;
  final int? count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    var display = '';
    if (amount != null) {
      display = CurrencyFormatter.format(amount, CurrencyFormat(symbol: 'R'));
    }
    if (count != null) {
      var f = NumberFormat('###,###,###');
      display = f.format(count);
    }
    return Row(
      children: [
        SizedBox(
            width: 160,
            child: Text(
              title,
              style: myTextStyle(weight: FontWeight.w900, color: Colors.grey),
            )),
        Text(
          display,
          style:
              myTextStyle(weight: FontWeight.w900, fontSize: 24, color: color),
        ),
      ],
    );
  }
}
