import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:floating_frosted_bottom_bar/app/frosted_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:souma/Env.dart';
import 'package:souma/models/PostData_All_Result.dart';
import 'package:souma/models/PostData_Market.dart';
import 'package:souma/utils/TabsIcon.dart';
import 'package:turn_page_transition/turn_page_transition.dart';
import 'listmarket.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
    path: 'assets/langs',
    supportedLocales: MyApp.list,
    saveLocale: true,
    useOnlyLangCode: true,
    child: const MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const list = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: "Souma",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{

  String? deviceId = 'UNKNOWN';
  String _Platform = 'UNKNOWN';
  late Timer t;
  late PostDataAllResult _response;
  late Socket? clientSocket;
  String current_market_name = tr('global_market');
  String code_market = "00000000";
  String code_product = "";
  bool isshowResult = false;
  final List<Widget> fancyCards = [];

  TextEditingController codebarreController = TextEditingController();
  PanelController? _panelController = PanelController();
  ScrollController _scrollcontroller = ScrollController();
  int currentIndex = 0;
  DateFormat format = DateFormat("dd/MM/yyyy");
  bool _isfloatingVisible = false;
  late int currentPage;
  late TabController tabController;
  final List<Color> colors = [
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Colors.blue,
    Colors.blue
  ];

  @override
  void initState() {
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
    tabController.animation!.addListener(
          () {
        final value = tabController.animation!.value.round();
        if (value != currentPage && mounted) {
          changePage(value);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _response = new PostDataAllResult();
    _scrollcontroller.addListener(_onScrollEvent);
    super.initState();
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  void dispose() {
    _scrollcontroller.removeListener(_onScrollEvent);
    super.dispose();
  }

  void _onScrollEvent() {
    final extentAfter = _scrollcontroller.position.extentAfter;
    if(extentAfter < 80){
      _panelController!.hide();
      setState(() {
        _isfloatingVisible = true;
      });
    }else{
      _panelController!.show();
      setState(() {
        _isfloatingVisible = false;
      });
    }
    t.cancel();
    t = Timer(Duration(seconds: 15), () {
      setState(() {
        isshowResult = false;
        _isfloatingVisible = false;
        _panelController!.show();
        _response = new PostDataAllResult();
      });
    });

  }


  @override
  Future<void> didChangeDependencies() async {
    deviceId  = await PlatformDeviceId.getDeviceId;
    if(Platform.isAndroid){
      _Platform = "ANDROID";
    }else{
      _Platform = "IOS";
    }
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/images/souma_logo2.png',
              fit: BoxFit.contain,
              height: 50,
            ),
          ],

        ),
        //centerTitle: true,
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.list,
              color: Colors.white,
            ),
            onPressed: () {
              _navigateToListMarketScreen(context);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.qr_code,
              color: Colors.white,
            ),
            onPressed: () {
              _navigateToScanMarketScreen(context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if(value == "1"){
                reOrderByPrice();
              }
              if(value == "2"){
                reOrderByRegion();
              }
              if(value == "3"){
                reOrderByDate();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: '1',
                child: Text('By price'),
              ),
              PopupMenuItem(
                value: '2',
                child: Text('By region'),
              ),
              PopupMenuItem(
                value: '3',
                child: Text('By date'),
              ),
            ],
          )
        ],
      ),
        body: SlidingUpPanel(
          controller: _panelController,
          renderPanelSheet: false,
          panelBuilder: showInsertCode,
          collapsed: _floatingCollapsed(),
          body: isshowResult ? showResult() : ScanWidget(),
        ),
      floatingActionButton: new Visibility(
        visible: _isfloatingVisible,
        child: new FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: _goToTop,
          child: new Icon(Icons.upgrade),
        ),
      ),
    );
  }

  void _goToTop(){
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollcontroller.animateTo(
          _scrollcontroller.position.minScrollExtent,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn);
    });
  }
  Widget _floatingCollapsed(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
      ),
      margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(current_market_name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),),
            SizedBox(height: 5,),
            _response.COUNT == null ?
            Visibility(
              child: Text(""),
              visible: false,
            )
            :
            Text("Result : " + _response.COUNT!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),),
          ],
        )
      ),
    );
  }

  Widget showResult(){

    //_panelController!.hide();

    return FrostedBottomBar(
      opacity: 0.6,
      sigmaX: 5,
      sigmaY: 5,
      child: TabBar(
        indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
        controller: tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.blue, width: 4),
          insets: EdgeInsets.fromLTRB(16, 0, 16, 8),
        ),
        tabs: [
          TabsIcon(
              icons: Icons.home,
              color: currentPage == 0 ? colors[0] : Colors.white),
          TabsIcon(
              icons: Icons.search,
              color: currentPage == 1 ? colors[1] : Colors.white),
          TabsIcon(
              icons: Icons.queue_play_next,
              color: currentPage == 2 ? colors[2] : Colors.white),
          TabsIcon(
              icons: Icons.file_download,
              color: currentPage == 3 ? colors[3] : Colors.white),
          TabsIcon(
              icons: Icons.menu,
              color: currentPage == 4 ? colors[4] : Colors.white),
        ],
      ),
      borderRadius: BorderRadius.circular(500),
      duration: const Duration(milliseconds: 800),
      hideOnScroll: true,
      body: (context, controller) =>
          ListView.builder(
            controller: controller,
            itemCount: int.parse(_response.COUNT!),
            itemBuilder: (BuildContext context, int index) {
              return resultPage(index);
            },
          ),
    );

  }

  Widget resultPage(int index){

    bool has_result = false;

    if(_response.RST == "1"){
      has_result = true;
    }
    if(int.parse(_response.COUNT!) > 1){
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: Colors.grey,
            ),
          ]
      ),
      margin: const EdgeInsets.all(10.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            isshowResult = false;
            t.cancel();
            _response = new PostDataAllResult();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                  _response.RST! == "1" ? _response.PRODUCT![index].NOM : "", style: const TextStyle(color: Colors.black,  fontSize: 30), textAlign: TextAlign.center),
              Divider(thickness: 1,),
              Text(
                _response.RST! == "1" ? _response.PRODUCT![index].PRD : tr('no_result_product'),
                style: const TextStyle(color: Colors.lightBlueAccent,  fontSize: 27, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10,),
              has_result ?
              _response.PRODUCT![index].HAS_PRM == "1" ? Text(_response.PRODUCT![index].PRX + " DA", style: TextStyle(color: Colors.red, fontSize: 30, decoration: TextDecoration.lineThrough)) :
              Text(has_result ? _response.PRODUCT![index].PRX + " DA" : "" , style: const TextStyle(color: Colors.green, fontSize: 30,)) :
              Visibility(
                child: Text(""),
                visible: false,
              ),
              SizedBox(height: 10,),
              has_result ?
              _response.PRODUCT![index].HAS_PRM == "1" ? Text(_response.PRODUCT![index].PRM + " DA", style: const TextStyle(color: Colors.green, fontSize: 30,)) :
              Visibility(
                child: Text(""),
                visible: false,
              ):
              Visibility(
                child: Text(""),
                visible: false,
              ),
              SizedBox(height: 10,),
              has_result ?
              Text(tr('last_update') +  DateFormat("dd-MM-yyyy").format(_response.PRODUCT![index].DATE_MAJ), style: const TextStyle(color: Colors.grey, fontSize: 10)) :
              Visibility(
                child: Text(""),
                visible: false,
              ),
              SizedBox(height: 10,),
              has_result ?
              Text(_response.PRODUCT![index].REGION, style: const TextStyle(color: Colors.grey, fontSize: 14)) :
              Visibility(
                child: Text(""),
                visible: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showInsertCode(){
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: Colors.grey,
            ),
          ]
      ),
      margin: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/image_codebarre_help1.png"),
            const SizedBox(height: 5,),
            Text("To get your result manualy without scanning, please insert the code of your product here and tap validate", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey),),
            const SizedBox(height: 5,),

            Padding(
              padding: EdgeInsets.all(3),
              child: TextFormField(
                autofocus: false,
                controller: codebarreController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: Colors.red),
                keyboardType: TextInputType.number,
                /*decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check), onPressed: ()  {
                    connectToServerFromEditText();
                    _panelController!.close();
                  },
                  ),
                  focusedBorder: OutlineInputBorder( //<-- SEE HERE
                    borderSide: BorderSide(width: 1, color: Colors.blueAccent),
                  ),
                ),*/
                validator: (value) {
                  if (value!.isEmpty) {
                    return tr('error_code_barre');
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10,),
            ElevatedButton.icon(
                onPressed: ()  {
                  connectToServerFromEditText();
                  _panelController!.close();
                },
              label: Text(tr('done'), style: TextStyle(color: Colors.white),),
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget ScanWidget(){
    _panelController!.show();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
         // color: Colors.white60,
          padding: EdgeInsets.all(3.0),
          decoration:
          BoxDecoration(
              shape: BoxShape.rectangle,
              //color: Colors.lightGreen,
              border: Border.all(),
          ),
          child: Column(
            children: [
              IconButton(
                icon: Image.asset('assets/images/codebarre2.png',
                  width: 120.0,
                  height: 60.0,
                  fit: BoxFit.cover,
                ),
                iconSize: 50,
               // color: Colors.brown,
                //  tooltip: 'Increase volume by 5',
                onPressed: () {
                  setState(() {
                    _navigateToScanProductScreen(context);
                  });
                },
              ),
              Text(tr('scan_product'), style: TextStyle(fontSize: 18),),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _navigateToScanMarketScreen(BuildContext context) async {

    setState(() {
        isshowResult =false;
        _response = new PostDataAllResult();
    });

    String qrCode;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      qrCode = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.DEFAULT);
      print(qrCode);
      if(qrCode.startsWith("SOUMA_APP")){
        setState(() {
          code_market = getValue(qrCode, "CC");
          current_market_name = getValue(qrCode, "MARKET");
        });
      }else{
        showSnackBarWithKey(tr("error_code_market"));
      }


    } on PlatformException {
      qrCode = 'Failed to get platform version.';
    }

  }

  Future<void> _navigateToScanProductScreen(BuildContext context) async {
      String barcodeScanRes;
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        barcodeScanRes = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.DEFAULT);
        print(barcodeScanRes);
        setState(() {
          code_product = barcodeScanRes;
        });
        connectToServer(code_market, code_product);
      } on PlatformException {
        barcodeScanRes = 'Failed to get platform version.';
      }

  }

  Future<void> _navigateToListMarketScreen(BuildContext context) async {
    if(!mounted)
    {
      return;
    }
    try{

       var result = await Navigator.of(context).push(
         // Use TurnPageRoute instead of MaterialPageRoute.
         TurnPageRoute(
           fullscreenDialog: true,
           overleafColor: Colors.blue,
           animationTransitionPoint: 0.5,
           transitionDuration: const Duration(milliseconds: 300),
           reverseTransitionDuration: const Duration(milliseconds: 300),
           builder: (context) => const ListMarket(),
         ),
       ) as PostData_Market;

       // Handle the returned data here
       setState(() {
         code_market = result.CC;
         current_market_name = result.NOM;
       });

       /*ScaffoldMessenger.of(context)
         ..removeCurrentSnackBar()
         ..showSnackBar(SnackBar(content: Text(code_market)));*/
    } on Exception catch (_) {
      code_market = "00000000";
    }

  }

  void connectToServerFromEditText(){
    if(codebarreController.value.text.isNotEmpty){
      code_product = codebarreController.value.text;
      connectToServer(code_market, code_product);
      codebarreController.text = "";
      FocusScope.of(context).unfocus();
      codebarreController.clear();
    }
  }

  void connectToServer(String code_market, String code_product) async {

    // reset index result indicator
    setState(() {
      currentIndex = 0;
      isshowResult = false;
      _response = new PostDataAllResult();
    });

    FocusScope.of(context).unfocus();
    codebarreController.clear();

    Socket.connect(Env.IP_SERVER, Env.PORT_SERVER, timeout: const Duration(seconds: 5))
        .then((socket) async {
      setState(() {
        clientSocket = socket;
      });

      sendMessage(code_market, code_product);

      String data = "";
      var subscription = socket.listen((Uint8List buffer) async {
          String _buffer = String.fromCharCodes(buffer);
          data += _buffer;

        //  List<int> list = utf8.encode(data);
        //  Uint8List bytes = Uint8List.fromList(list);
        //  String jsonData1 = await CharsetConverter.decode("windows-1256", bytes);
          PostDataAllResult jsonData = PostDataAllResult.fromJson(jsonDecode(data));

          setState(() {
              isshowResult = true;
              _response = jsonData;
              // Anything else you want
          });

          t = Timer(Duration(seconds: 15), () {
            setState(() {
              isshowResult = false;
              _isfloatingVisible = false;
              _panelController!.show();
              _response = new PostDataAllResult();
            });
          });

          data = "";
          disconnectFromServer();
        },
        onDone: onDone,
        onError: onError,
      );

      await subscription.asFuture<void>();

    }).catchError((e) {
      showSnackBarWithKey(e.toString());
    });


  }

  String getValue(String data, String key){
    String result = "";
    const splitter = LineSplitter();
    final sampleTextLines = splitter.convert(data);
    for (var i = 0; i < sampleTextLines.length; i++) {
      if(sampleTextLines[i].startsWith(key)){
        int index = sampleTextLines[i].indexOf(":");
        result = sampleTextLines[i].substring(index+1);
        exitCode;
      }
    }

    return result;
  }

  void onDone() {
    showSnackBarWithKey(tr('connexion_terminated'));
    disconnectFromServer();
  }

  void onError(e) {
    showSnackBarWithKey(e.toString());
    disconnectFromServer();
  }

  void disconnectFromServer() {
    clientSocket!.close();
    setState(() {
      clientSocket = null;
    });
  }

  void sendMessage(String code_market, String code_product) {
    String message = '''CMD:CHECK\nCC:$code_market\nCB:$code_product\nDID:$deviceId\nPLT:$_Platform''';
    clientSocket!.write("$message\n");
  }

  showSnackBarWithKey(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: Colors.black),),
      backgroundColor: Colors.yellow,
      action: SnackBarAction(
        label: tr('done'),
        onPressed: (){},
      ),
    ));
  }

  void reOrderByRegion(){
   setState(() {
     _response.PRODUCT!.sort((a,b) => a.REGION.compareTo(b.REGION));
   });
  }

  void reOrderByPrice(){
    setState(() {
      _response.PRODUCT!.sort((a,b) => a.PRX.compareTo(b.PRX));
    });
  }
  void reOrderByDate(){
    setState(() {
    _response.PRODUCT!.sort((b,a) => a.DATE_MAJ.compareTo(b.DATE_MAJ));
    });
  }
}
