import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/observations_page.dart';
import 'package:pika_joe/screens/splash/page2.dart';
import 'package:pika_joe/screens/splash/page3.dart';
import 'package:pika_joe/widget/sidebar_item.dart';
import 'package:pika_joe/widget/standard_app_bar.dart';


class LiquidSwipeWrapper extends StatefulWidget {
  @override
  _LiquidSwipeWrapperState createState() => _LiquidSwipeWrapperState();
}

class _LiquidSwipeWrapperState extends State<LiquidSwipeWrapper> {

  //TODO - https://github.com/iamSahdeep/liquid_swipe_flutter/blob/master/example/lib/main.dart
  LiquidController liquidController = LiquidController();

  //TODO - make the drawer its own widget
  //Credit to: https://www.youtube.com/watch?v=1KurAaGLwHc&t=1602s
  Offset _offset = Offset(0,0);
  GlobalKey globalKey = GlobalKey();
  List<double> limits = [0,0,0,0,0,0];

  bool isMenuOpen = false;

  @override
  void initState() {
    limits= [0, 0, 0, 0, 0, 0];
    WidgetsBinding.instance.addPostFrameCallback(getPosition);
    super.initState();
  }

  getPosition(duration) {
    RenderBox renderBox = globalKey.currentContext.findRenderObject();
    final position = renderBox.localToGlobal(Offset.zero);
    double start = position.dy - 20;
    double contLimit = position.dy + renderBox.size.height - 20;
    double step = (contLimit-start)/5;
    limits = [];
    for (double x = start; x <= contLimit; x = x + step) {
      limits.add(x);
    }
    setState(() {
      limits = limits;
    });
  }

  /*double getSize(int x) {
    double size  = (_offset.dy > limits[x] && _offset.dy < limits[x + 1]) ? 25 : 20;
    return size;
  }*/

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;
    double sidebarSize = mediaQuery.width * 0.65;
    double menuContainerHeight = mediaQuery.height/2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: mainAppBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:[
              Color.fromRGBO(255, 65, 108, 1.0),
              Color.fromRGBO(255, 75, 73, 1.0)
            ],
          ),
        ),
        width: mediaQuery.width,
        child: Stack(
          children: <Widget>[
            LiquidSwipe(
              pages: <Container>[
                ObservationsPage(),
                Page2(),
                Page3(),
              ],
              enableLoop: true,
              fullTransitionValue: 300,
              enableSlideIcon: true,
              waveType: WaveType.liquidReveal,
              positionSlideIcon: 0.5,
              liquidController: liquidController,
              ignoreUserGestureWhileAnimating: true,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 1500),
              left: isMenuOpen?0: -sidebarSize+20,
              top: 0,
              curve: Curves.elasticOut,
              child: SizedBox(
                width:sidebarSize,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if(details.localPosition.dx <= sidebarSize) {
                      setState((){
                        _offset = details.localPosition;
                      });
                    }

                    if(details.localPosition.dx>sidebarSize-20 && details.delta.distanceSquared>2){
                      setState(() {
                        isMenuOpen = true;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _offset = Offset(0,0);
                    });
                  },
                  child: Stack(
                    children: <Widget>[
                      CustomPaint(
                        size: Size(sidebarSize, mediaQuery.height),
                        painter: DrawerPainter(offset: _offset),
                      ),
                      Container(
                        height: mediaQuery.height,
                        width: sidebarSize,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              height: mediaQuery.height * 0.25,
                              child: Center(
                                child: Column(
                                  children: [
                                    Image.asset("assets/img/frppLogo.png", width: sidebarSize/2),
                                    Text("FRPP Rocks", style: TextStyle(color: Colors.amber))
                                  ],
                                ),
                              ),
                            ),
                            Divider(thickness: 1,),
                            Container(
                              key: globalKey,
                              width: double.infinity,
                              height: menuContainerHeight,
                              child: Column(
                                children: <Widget>[
                                  SidebarItem(
                                    text: "Profile",
                                    iconData: Icons.person,
                                    height: 20,
                                  ),
                                  SidebarItem(
                                      text: "Taining Materials",
                                      iconData: Icons.payment,
                                      height: 20,
                                  ),
                                  SidebarItem(
                                    text: "Front Range \nPika Project",
                                    iconData: Icons.notifications,
                                    height: 20,
                                  ),
                                  SidebarItem(
                                    text: "Denver Zoo",
                                    iconData: Icons.settings,
                                    height: 20,
                                  ),
                                  SidebarItem(
                                    text: "Rocky Mountain \nWild",
                                    iconData: Icons.attach_file,
                                    height: 20
                                  ),
                                ],
                              ),
                            ),
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 400),
                              right: (isMenuOpen)?10:sidebarSize,
                              child: IconButton(
                                enableFeedback: true,
                                icon: Icon(Icons.keyboard_backspace,color: Colors.black45,size: 30,),
                                onPressed: (){
                                  this.setState(() {
                                    isMenuOpen = false;
                                  });
                                },),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        color: Colors.amber,
        backgroundColor: Colors.white,
        buttonBackgroundColor: Colors.blueAccent,
        height: 50,
        items: <Widget>[
          Icon(Icons.add, size: 30),
          Icon(Icons.list, size: 30),
          Icon(Icons.compare_arrows, size: 30),
        ],
        onTap: (index) {
          //TODO - liquidController.animateToPage(page: 2);//liquidController.currentPage + 1, duration: 500);
        },
        animationDuration: Duration(
          milliseconds: 200
        ),
        animationCurve: Curves.bounceInOut,
        index: 1,
      ),
    );
  }
}

//TODO - move!
class DrawerPainter extends CustomPainter {

  final Offset offset;

  DrawerPainter({ this.offset });

  double getControlPointX(double width) {
    if(offset.dx == 0) {
      return width;
    } else {
      return offset.dx > width ? offset.dx : width + 75;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    Path path = Path();
    path.moveTo(-size.width, 0);
    path.lineTo(size.width, 0);
    path.quadraticBezierTo(getControlPointX(size.width), offset.dy, size.width, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(-size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

//TODO - make own widget
