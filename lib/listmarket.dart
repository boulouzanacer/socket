import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:animation_search_bar/animation_search_bar.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:souma/Env.dart';
import 'package:souma/models/PostData_Market.dart';

class ListMarket extends StatefulWidget {
  const ListMarket({Key? key}) : super(key: key);

  @override
  State<ListMarket> createState() => _ListMarketState();
}

class _ListMarketState extends State<ListMarket> {

  late RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool isLoading = true;
  List<PostData_Market> markets = [];
  List<PostData_Market> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController controller;
  late Socket? clientSocket;
  int market_count = 0;

  @override
  void initState() {
    super.initState();
    // call server to get all market
    WidgetsBinding.instance.addPostFrameCallback((_) => getAllMArketFromServer());
    _filteredData = markets;
   // _searchController.addListener(_performSearch);
    controller = TextEditingController();
  }


  void dispose() {
    //_searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size(double.infinity, 65),
          child: SafeArea(
              child: Container(
                decoration: const BoxDecoration(color: Colors.blue, boxShadow: [
                  BoxShadow(
                      color: Colors.white,
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: Offset(0, 5))
                ]),
                alignment: Alignment.center,
                child: AnimationSearchBar(
                    backIconColor: Colors.white,
                    closeIconColor: Colors.white,
                    centerTitle: tr('market_list') + (_filteredData.length != 0 ? "\n" + _filteredData.length.toString() : ""),
                    hintText: tr('search'),
                    centerTitleStyle: const TextStyle(fontWeight: FontWeight.w500,color: Colors.white, fontSize: 20),
                    textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
                    cursorColor: Colors.white,
                    duration: const Duration(milliseconds: 500),
                    searchIconColor: Colors.white.withOpacity(.7),
                    onChanged: (text) {
                      setState(() {
                        _filteredData = markets.where((e) => e.NOM.toLowerCase().contains(text.toLowerCase())).toList();
                      });
                    },
                    searchTextEditingController: controller),
              ))),
     /* appBar: AppBar(
          title: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: tr('search'),
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Perform search functionality here
            },
          ),
        backgroundColor: Colors.blue,
      ),*/
      body: isLoading ? Loading() : ListMarket(),
    );
  }

  Widget ListMarket(){
    return Scaffold(
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        header:  WaterDropMaterialHeader(
          offset: context.locale.languageCode == "ar" ? -100 : 0,
          backgroundColor: Colors.blue,
        ),
        onRefresh: () => getAllMArketFromServer(),
        child:ListView.separated(
          padding: const EdgeInsets.all(6),
          itemCount: _filteredData.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: EdgeInsets.all(5),
              child: _filteredData[index].CC == "00000000" ?
              ClipPath(
                clipper: TicketPassClipper(holeRadius:  25),
                child: Card(
                  color: Colors.red ,
                  borderOnForeground: true,
                  elevation: 10,
                  //shadowColor: Colors.blue,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    //splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      Navigator.pop(context, _filteredData[index]);
                    },
                    child: _buildmarket(_filteredData[index]),
                  ),
                ),
              ) :
              Card(
                color: Colors.white,
                borderOnForeground: true,
                elevation: 10,
                shadowColor: Colors.blue,
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  //splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    Navigator.pop(context, _filteredData[index]);
                  },
                  child: _buildmarket(_filteredData[index]),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
        ),
      ),
    );
  }

  Widget _buildmarket(PostData_Market market) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_outlined, color: Colors.blue,),
              const SizedBox(width: 5,),
              Flexible(
                child:  Text(market.NOM, style: const TextStyle(color: Colors.black,  fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.start, overflow: TextOverflow.visible,),
              ),
            ],
          ),
          const SizedBox(height: 5,),
          Row(
            children: [
              const Icon(Icons.qr_code, color: Colors.blue,),
              const SizedBox(width: 5,),
              Text(tr('market_code'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), ),
              const SizedBox(width: 5,),
              Text(market.CC,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),),
            ],
          ),
          const SizedBox(height: 5,),
          Row(
            children: [
              const Icon(Icons.stadium_outlined, color: Colors.blue,),
              const SizedBox(width: 5,),
              Text(tr('region'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
              const SizedBox(width: 5,),
              Text(market.COMUNE,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),),
            ],
          ),
          const SizedBox(height: 5,),
          Row(
            children: [
              const Icon(Icons.area_chart_outlined, color: Colors.blue,),
              const SizedBox(width: 5,),
              Text(tr('state'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
              const SizedBox(width: 5,),
              Text(market.WILAYA,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),),
            ],
          ),

        ],
      ),
    );
  }

  Widget Loading(){
    return Center(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
            ),
            SizedBox(height: 20,),
            Text(tr('loading')),
          ],
        ),

    );

  }


  void getAllMArketFromServer() async {

    Socket.connect(Env.IP_SERVER, Env.PORT_SERVER, timeout: const Duration(seconds: 5))
        .then((socket) async {
      setState(() {
        clientSocket = socket;
      });

      sendMessage();

      String jsonData1 = "";
      var _buffer = BytesBuilder();
      Future.delayed(const Duration(seconds: 1)).then((_) {
        setState(() {
          isLoading = false;
          _refreshController.refreshCompleted();
        });
      });
      var subscription = socket.listen((Uint8List buffer) async {
        //String _buffer = String.fromCharCodes(buffer);
        //data += _buffer;

        _buffer.add(buffer);
        var unit8 = _buffer.toBytes();
        String jsonData1 = await CharsetConverter.decode("windows-1256", unit8);
        List<dynamic> jsonData = json.decode(jsonData1) as List<dynamic>;

        markets.clear();

        setState(() {
          // add global market to first list
          PostData_Market global_market = new PostData_Market(CC: "00000000", NOM: tr('global_market'), COMUNE: tr('global'), WILAYA: tr('global'));
          markets.add(global_market);
          markets.addAll(List<PostData_Market>.from((jsonData).map((x) => PostData_Market.fromJson(x))));
          _filteredData = markets;
         // _response = data;
          isLoading = false;
          _refreshController.refreshCompleted();
        });

        jsonData1 = "";
        disconnectFromServer();
      },
        onDone: onDone,
        onError: onError,
      );

      await subscription.asFuture<void>();

    }).catchError((e) {
      showSnackBarWithKey(tr('error_server'));
      setState(() {
        isLoading = false;
        _refreshController.refreshCompleted();
      });
      disconnectFromServer();
    });


  }

  void onDone() {
    showSnackBarWithKey(tr('connexion_terminated'));
    setState(() {
      isLoading = false;
      _refreshController.refreshCompleted();
    });
    disconnectFromServer();
  }

  void onError(e) {
    showSnackBarWithKey(e.toString());
    setState(() {
      isLoading = false;
      _refreshController.refreshCompleted();
    });
    disconnectFromServer();
  }

  void disconnectFromServer() {
    clientSocket!.close();
    setState(() {
      clientSocket = null;
    });
  }

  void sendMessage() {
    String message = '''CMD:LIST''';
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
}