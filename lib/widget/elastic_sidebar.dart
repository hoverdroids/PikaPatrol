
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/widget/sidebar_item.dart';

//Credit to: https://www.youtube.com/watch?v=1KurAaGLwHc&t=1602s

class ElasticSidebar extends StatefulWidget {
  final double percentOfWidth;
  final int animationDuration;
  final double pixelsShownWhenClosed;
  final int archHeight;

  ElasticSidebar({ this.percentOfWidth, this.animationDuration, this.pixelsShownWhenClosed, this.archHeight});

  @override
  _ElasticSidebarState createState() => _ElasticSidebarState(
      percentOfWidth: percentOfWidth,
      animationDuration: animationDuration,
      pixelsShownWhenClosed: pixelsShownWhenClosed,
      archHeight: archHeight);
}

class _ElasticSidebarState extends State<ElasticSidebar> {

  final double percentOfWidth;
  final int animationDuration;
  final double pixelsShownWhenClosed;
  final int archHeight;

  _ElasticSidebarState({this.percentOfWidth, this.animationDuration, this.pixelsShownWhenClosed, this.archHeight});

  GlobalKey globalKey = GlobalKey();//TODO - does this need a more descriptive name?
  bool isMenuOpen = false;//TODO - this was static; should it remain static?
  Offset _offset = Offset(0,0);
  List<double> limits = [0,0,0,0,0,0];

  @override
  void initState() {
    limits= [0, 0, 0, 0, 0, 0];
    WidgetsBinding.instance.addPostFrameCallback(getPosition);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;
    double sidebarSize = mediaQuery.width * percentOfWidth;
    double menuContainerHeight = mediaQuery.height / 2;

    return AnimatedPositioned(
      duration: Duration(milliseconds: animationDuration),
      left: isMenuOpen ? 0 : -sidebarSize + pixelsShownWhenClosed,
      top: 0,
      curve: Curves.elasticOut,
      child: SizedBox(//TODO - change this to a scrollView
        width:sidebarSize,
        child: GestureDetector(
          onPanUpdate: (details) {
            if(details.localPosition.dx <= sidebarSize) {
              setState((){
                _offset = details.localPosition;
              });
            }

            if(details.localPosition.dx>sidebarSize - pixelsShownWhenClosed && details.delta.distanceSquared > 2){
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
                painter: DrawerPainter(offset: _offset, archHeight: archHeight),
              ),
              Container(
                height: mediaQuery.height,
                width: sidebarSize,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(
                      height: mediaQuery.height * 0.25,//TODO - pass a header widget
                      child: Center(
                        child: Column(
                          children: [
                            Image.asset("assets/img/frppLogo.png", width: sidebarSize / 2),
                            Text("FRPP Rocks", style: TextStyle(color: Colors.amber))
                          ],
                        ),
                      ),
                    ),
                    Divider(thickness: 1),//TODO - pass a divider widget?
                    Container(//TODO - pass N items
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
                            text: "Taining Materials222",
                            iconData: Icons.payment,
                            height: 20,
                          ),
                          SidebarItem(
                            text: "Front Range \nPika Project",
                            iconData: Icons.notifications,
                            height: 20,
                          ),
                          SidebarItem(
                            text: "Denver Zoo2",
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
                    AnimatedPositioned(//TODO - move the back arrow to top right corner
                      duration: Duration(milliseconds: animationDuration),
                      right: (isMenuOpen) ? 10 : sidebarSize,
                      child: IconButton(//TODO - pass in a back widget?
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
    );
  }

  getPosition(duration) {//TODO - determine position based on preference; ie "space evenly if possible" or not
    RenderBox renderBox = globalKey.currentContext.findRenderObject();
    final position = renderBox.localToGlobal(Offset.zero);
    double start = position.dy - pixelsShownWhenClosed;
    double contLimit = position.dy + renderBox.size.height - pixelsShownWhenClosed;
    double step = (contLimit-start) / 5;
    limits = [];
    for (double x = start; x <= contLimit; x = x + step) {
      limits.add(x);
    }
    setState(() {
      limits = limits;
    });
  }

  //Get text size based on whether the user is hovering over the text or not
  double getSize(int x) {//TODO - be smarter about making the font size larger; maybe just scale the text?
    double size  = (_offset.dy > limits[x] && _offset.dy < limits[x + 1]) ? 25 : 20;
    return size;
  }
}

class DrawerPainter extends CustomPainter {

  final int archHeight;
  final Offset offset;

  DrawerPainter({ this.offset, this.archHeight });

  double getControlPointX(double width) {
    if(offset.dx == 0) {
      return width;
    } else {
      return offset.dx > width ? offset.dx : width + archHeight;
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