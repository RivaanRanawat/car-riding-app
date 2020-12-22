import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:car_rider_app/dataprovider/appData.dart';
import 'package:car_rider_app/helpers/helperRepository.dart';
import 'package:car_rider_app/models/directionDetails.dart';
import 'package:car_rider_app/screens/search_screen.dart';
import 'package:car_rider_app/styles.dart';
import 'package:car_rider_app/universal_variables.dart';
import 'package:car_rider_app/widgets/progress_dialog.dart';
import 'package:car_rider_app/widgets/reusable_button.dart';
import 'package:car_rider_app/widgets/reusable_divider.dart';
import "package:flutter/material.dart";
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String id = "home";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double searchSheetHeight = 270;
  double rideSheetHeight = 0;
  double requestSheetHeight = 0;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double mapPadding = 0.0;
  var geoLocator = Geolocator();
  Position currentPos;
  List<LatLng> polyLineCordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  DirectionDetails tripDirectionDetails;

  bool drawerCanOpen = true;

  void setPositionLocator() async {
    Position position = await geoLocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPos = position;

    LatLng pos = LatLng(position.latitude, position.longitude);
    String address =
        await HelperRepository.findCordinatesAddress(position, context);
    print("Address " + address);
    CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));
    print(position);
  }

  void showRideDetailScreen() async {
    await getDirection();
    setState(() {
      searchSheetHeight = 0;
      rideSheetHeight = 270;
      mapPadding = 240;
      drawerCanOpen = false;
    });
  }

  void showRequestSheet() {
    setState(() {
      rideSheetHeight = 0;
      requestSheetHeight = 195;
      mapPadding = 200;
      drawerCanOpen = true;
    });
  }

  @override
  void initState() {
    super.initState();
    HelperRepository.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: [
              Container(
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 60,
                        width: 60,
                      ),
                      SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Rivaan Ranawat",
                            style: TextStyle(
                                fontSize: 20, fontFamily: "Bolt-Bold"),
                          ),
                          SizedBox(height: 5),
                          Text("View Profile"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ReusableDivider(),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(OMIcons.cardGiftcard),
                title: Text(
                  "Free Rides",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(OMIcons.creditCard),
                title: Text(
                  "Payments",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(OMIcons.history),
                title: Text(
                  "Trip History",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(OMIcons.contactSupport),
                title: Text(
                  "Support",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(OMIcons.info),
                title: Text(
                  "About",
                  style: kDrawerItemStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            initialCameraPosition: UniversalVariables.googlePlex,
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;

              setState(() {
                mapPadding = 270;
              });

              setPositionLocator();
            },
          ),
          // Drawer Button
          Positioned(
            top: 44,
            left: 22,
            child: GestureDetector(
              onTap: () {
                if (drawerCanOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7)),
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon((drawerCanOpen) ? Icons.menu : Icons.arrow_back,
                      color: Colors.black),
                ),
              ),
            ),
          ),

          // SEARCH PANEL
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                height: searchSheetHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text("Glad to see you!",
                          style: TextStyle(
                            fontSize: 10,
                          )),
                      Text(
                        "Where do you wanna go?",
                        style: TextStyle(
                            fontSize: 18, fontFamily: "Bolt-Semibold"),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (ctx) => SearchScreen()));
                          if (res == "getDirection") {
                            showRideDetailScreen();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 0.5,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                )
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.blueAccent),
                                SizedBox(width: 10),
                                Text("Search Destination"),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 22),
                      // HOME ADDRESS
                      Row(
                        children: [
                          Icon(OMIcons.home,
                              color: UniversalVariables.colorDimText),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                    "Home",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontFamily: "Bolt-Regular"),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                    (Provider.of<AppData>(context)
                                                .pickUpAddress !=
                                            null)
                                        ? Provider.of<AppData>(context)
                                            .pickUpAddress
                                            .placeName
                                        : "Add Home",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: "Bolt-Regular",
                                        fontSize: 11,
                                        color: UniversalVariables.colorDimText))
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ReusableDivider(),
                      SizedBox(height: 16),
                      //WORK ADDRESS
                      Row(
                        children: [
                          Icon(OMIcons.workOutline,
                              color: UniversalVariables.colorDimText),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Work",
                                style: TextStyle(fontFamily: "Bolt-Regular"),
                              ),
                              SizedBox(height: 3),
                              Text("Your Work Address",
                                  style: TextStyle(
                                      fontFamily: "Bolt-Regular",
                                      fontSize: 11,
                                      color: UniversalVariables.colorDimText))
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // RIDE DETAILS SCREEN
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(milliseconds: 150),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                height: rideSheetHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: UniversalVariables.colorAccent1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset("assets/images/taxi.png",
                                  height: 70, width: 70),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Taxi",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: "Bolt-Semibold"),
                                  ),
                                  Text(
                                    (tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : "",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: "Bolt-Regular",
                                        color:
                                            UniversalVariables.colorTextLight),
                                  )
                                ],
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Text(
                                (tripDirectionDetails != null)
                                    ? "₹${HelperRepository.estimateFares(tripDirectionDetails)}"
                                    : "",
                                style: TextStyle(
                                    fontSize: 18, fontFamily: "Bolt-Semibold"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.moneyBillAlt,
                              size: 18,
                              color: UniversalVariables.colorTextLight,
                            ),
                            SizedBox(width: 16),
                            Text("Cash"),
                            SizedBox(width: 5),
                            Icon(Icons.keyboard_arrow_down,
                                color: UniversalVariables.colorTextLight,
                                size: 16),
                          ],
                        ),
                      ),
                      SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ReusableButton(
                          text: "REQUEST CAB",
                          color: UniversalVariables.colorGreen,
                          onPressed: () {
                            showRequestSheet();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: new Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                height: requestSheetHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextLiquidFill(
                          text: 'Requesting a Ride..',
                          waveColor: UniversalVariables.colorTextSemiLight,
                          boxBackgroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 22.0,
                            fontFamily: "Bolt-Semibold",
                          ),
                          boxHeight: 40.0,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              width: 1.0,
                              color: UniversalVariables.colorLightGrayFair),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 25,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancel ride",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickUpAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    print(destination.lng);
    print(pickup.lng);
    var pickLatLng = LatLng(pickup.lat, pickup.lng);
    var destinationLatLng = LatLng(destination.lat, destination.lng);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            ProgressDialog(status: "Please wait.."));

    var details = await HelperRepository.getDirectionDetails(
        pickLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetails = details;
    });
    Navigator.of(context).pop();
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(details.encodedPoints);

    polyLineCordinates.clear();
    if (results.isNotEmpty) {
      results.forEach((element) {
        polyLineCordinates.add(LatLng(element.latitude, element.longitude));
      });
    }

    _polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId("polyid"),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polyLineCordinates,
        width: 4,
        startCap: Cap.roundCap,
        geodesic: true,
      );

      _polylines.add(polyline);
    });

    LatLngBounds bounds;
    // fitting the polyline in map
    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
          northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude));
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
        markerId: MarkerId("pickup"),
        position: pickLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: pickup.placeName, snippet: "Your Location"));

    Marker destinationMarker = Marker(
      markerId: MarkerId("destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: "Your Destination"),
    );

    setState(() {
      _markers.add(pickupMarker);
      _markers.add(destinationMarker);
    });

    Circle pickUpCircle = Circle(
      circleId: CircleId("pickup"),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickLatLng,
      fillColor: UniversalVariables.colorGreen,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId("destination"),
      strokeColor: UniversalVariables.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: UniversalVariables.colorAccentPurple,
    );

    setState(() {
      _circles.add(pickUpCircle);
      _circles.add(destinationCircle);
    });
  }

  resetApp() {
    setState(() {
      polyLineCordinates.clear();
      _polylines.clear();
      _markers.clear();
      _circles.clear();
      rideSheetHeight = 0;
      searchSheetHeight = 270;
      mapPadding = 280;
      drawerCanOpen = true;
      setPositionLocator();
    });
  }
}
