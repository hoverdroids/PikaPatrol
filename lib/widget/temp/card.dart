/*

ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      offset: Offset(3.0, 6.0),
                      blurRadius: 10.0)
                ]),
                child: AspectRatio(
                  aspectRatio: cardAspectRatio,
                  child: GestureDetector(
                    onTap: () => print('Damnit'),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image.asset(images[i], fit: BoxFit.cover),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Text(title[i],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25.0,
                                        fontFamily: "SF-Pro-Text-Regular")),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, bottom: 12.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 22.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(20.0)),
                                  child: RawGestureDetector(
                                    gestures: <Type, GestureRecognizerFactory>{
                                      CustomPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
                                          () => CustomPanGestureRecognizer(
                                              onPanDown: () => _onPanDown,
                                              onPanUpdate: () => _onPanUpdate,
                                              onPanEnd:  () => _onPanEnd
                                          ),
                                          (CustomPanGestureRecognizer instance) {},
                                      ),
                                    },
                                    /*onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MovieScreen(movie: movies[2]),
                                      ),
                                    ),*/
                                    child: Text("Read Later",
                                      style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )











*
* */