import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/commuter_cash_payment.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:get_it/get_it.dart';
import 'package:currency_formatter/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/utils/functions.dart';
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
   for (var pc in  passengerCounts) {
     passengersIn += pc.passengersIn!;;
   }
   var total = 0.0;
   for (var cp in  cashPayments) {
     total += cp.amount!;
   }
    return Card(
      elevation:  8,
      child:  Padding(padding: EdgeInsets.all(16), child: Column(
        children: [
          DataCup(title:  'Trips', count:  trips.length,),
          gapH8,
          DataCup(title:  'Commuter Payments', amount:  total,),
          gapH8,
          DataCup(title:  'Passengers', count:  passengersIn),
        ],
      ))
    );
  }
}

class DataCup extends StatelessWidget {
  const DataCup({super.key, required this.title, this.amount, this.count});
  final String title;
  final double? amount;
  final int? count;

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
        SizedBox(width: 160, child: Text(title, style: myTextStyle(weight: FontWeight.w900, color: Colors.grey),)),
        Text(display, style: myTextStyle(weight: FontWeight.w900, fontSize:  24),),
      ],
    );
  }
}
