import 'package:flutter/material.dart';
import 'package:pika_joe/mock/data.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';

//We are extending and returning the container because that's what the pager requires. Otherwise it would b
//better to simpply return the ObservationsScrollView
class ObservationsPage extends Container {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: observationsPageBgGradient,
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          tileMode: TileMode.clamp,
        ),
      ),
      child: ObservationsScrollView(),
    );
  }
}

class ObservationsScrollView extends StatefulWidget {
  @override
  _ObservationsScrollViewState createState() => _ObservationsScrollViewState();

}

class _ObservationsScrollViewState extends State<ObservationsScrollView> {

  var currentPage = images.length - 1.0;

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: images.length - 1);
    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[

            ],
          ),
        ),
      ),
    );
  }
}