import 'package:flutter/material.dart';

class AssociationRegistration extends StatefulWidget {
  const AssociationRegistration({super.key});

  @override
  AssociationRegistrationState createState() =>
      AssociationRegistrationState();
}

class AssociationRegistrationState extends State<AssociationRegistration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      child: Text('Kasie Registration'),
    );
  }
}
