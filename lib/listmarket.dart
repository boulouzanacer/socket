import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:animation_search_bar/animation_search_bar.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:souma/Env.dart';
import 'package:souma/models/PostData_Market.dart';

class ListMarket extends StatefulWidget {
  const ListMarket({super.key});

  @override
  State<ListMarket> createState() => _ListMarketState();
}

class _ListMarketState extends State<ListMarket> {

  late final RefreshController _refreshController = RefreshController(initialRefresh: false);
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


  @override
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
                    centerTitle: tr('market_list') + (_filteredData.isNotEmpty ? "\n${_filteredData.length}" : ""),
                    hintText: tr('search'),
                    centerTitleStyle: const TextStyle(fontWeight: FontWeight.w500,color: Colors.white, fontSize: 20),
                    textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
                    cursorColor: Colors.white,
                    duration: const Duration(milliseconds: 500),
                    searchIconColor: Colors.white.withValues(alpha: .7),
                    onChanged: (text) {
                      setState(() {
                        _filteredData = markets.where((e) => e.NOM.toLowerCase().contains(text.toLowerCase())).toList();
                      });
                    },
                    searchTextEditingController: controller),
              ),
          ),
      ),
      body: isLoading ? Loading() : ListMarket(),
    );
  }

  Widget ListMarket(){
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        header:  WaterDropMaterialHeader(
          offset: context.locale.languageCode == "ar" ? -100 : 0,
          backgroundColor: Colors.blue,
        ),
        onRefresh: () => getAllMArketFromServer(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: _filteredData.length,
          itemBuilder: (BuildContext context, int index) {
            final market = _filteredData[index];
            final bool isGlobal = market.CC == "00000000";
            return _buildMarketCard(market: market, isGlobal: isGlobal, onTap: () {
              Navigator.pop(context, market);
            });
          },
          separatorBuilder: (_, __) => const SizedBox(height: 6),
        ),
      ),
    );
  }

  Widget _buildMarketCard({
    required PostData_Market market,
    required bool isGlobal,
    required VoidCallback onTap,
  }) {
    final Color avatarBg = isGlobal ? const Color(0xFFEEF2FF) : const Color(0xFFEFF6FF);
    final Color avatarFg = isGlobal ? const Color(0xFF4F46E5) : const Color(0xFF2563EB);
    final Color borderColor = isGlobal ? const Color(0xFFA5B4FC) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isGlobal ? 1.3 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isGlobal ? 0.06 : 0.035),
              blurRadius: isGlobal ? 20 : 14,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: isGlobal
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEEF2FF).withValues(alpha: 0.55),
                    Colors.white,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.22, 1.0],
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (isGlobal)
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, color: Colors.white, size: 13.5),
                        const SizedBox(width: 4),
                        Text(
                          tr('global'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, isGlobal ? 30 : 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: avatarBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isGlobal ? const Color(0xFFC7D2FE) : const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: Icon(isGlobal ? Icons.language : Icons.storefront_outlined, color: avatarFg, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 1),
                          Text(
                            market.NOM,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              height: 1.22,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isGlobal ? const Color(0xFFEEF2FF) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code_2_outlined, size: 13, color: isGlobal ? const Color(0xFF4338CA) : const Color(0xFF0369A1)),
                                    const SizedBox(width: 4),
                                    Text(
                                      market.CC,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isGlobal ? const Color(0xFF3730A3) : const Color(0xFF0C4A6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_city_outlined, size: 13, color: Color(0xFFB45309)),
                                    const SizedBox(width: 4),
                                    Text(
                                      market.COMUNE,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flag_outlined, size: 13, color: Color(0xFF047857)),
                                    const SizedBox(width: 4),
                                    Text(
                                      market.WILAYA,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isGlobal ? const Color(0xFFA5B4FC) : const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: Icon(Icons.arrow_forward_ios_outlined, size: 15, color: isGlobal ? const Color(0xFF4F46E5) : const Color(0xFF2563EB)),
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

  Widget Loading(){
    return Center(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
            const SizedBox(height: 20,),
            Text(tr('loading')),
          ],
        ),

    );

  }


  void getAllMArketFromServer() async {

    Socket.connect(Env.IP_SERVER, Env.PORT_SERVER, timeout: const Duration(seconds: 5)).then((socket) async {
      setState(() {
        clientSocket = socket;
      });

      sendMessage();

      var bytesBuilder = BytesBuilder();
      bool hasParsed = false;

      Future<void> parseAndApply(Uint8List allBytes) async {
        if (hasParsed) return;
        hasParsed = true;
        try {
          String jsonStr = await CharsetConverter.decode("windows-1256", allBytes);
          List<dynamic> jsonData = (json.decode(jsonStr) is List)
              ? json.decode(jsonStr) as List<dynamic>
              : <dynamic>[];

          markets.clear();
          setState(() {
            PostData_Market globalMarket = PostData_Market(
                CC: "00000000",
                NOM: tr('global_market'),
                COMUNE: tr('global'),
                WILAYA: tr('global'));
            markets.add(globalMarket);
            markets.addAll(List<PostData_Market>.from(
                (jsonData).map((x) => PostData_Market.fromJson(x))));
            _filteredData = markets;
            isLoading = false;
            _refreshController.refreshCompleted();
          });
        } catch (e) {
          showSnackBarWithKey("${tr('error_server')} : $e");
          setState(() {
            isLoading = false;
            _refreshController.refreshCompleted();
          });
        }
      }

      var subscription = socket.listen(
        (Uint8List data) {
          bytesBuilder.add(data);
        },
        onDone: () async {
          await parseAndApply(bytesBuilder.takeBytes());
          disconnectFromServer();
          setState(() {
            isLoading = false;
            _refreshController.refreshCompleted();
          });
        },
        onError: (e) {
          showSnackBarWithKey(e.toString());
          setState(() {
            isLoading = false;
            _refreshController.refreshCompleted();
          });
          disconnectFromServer();
        },
        cancelOnError: true,
      );

      await subscription.asFuture<void>().timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          if (!hasParsed) await parseAndApply(bytesBuilder.takeBytes());
        },
      );
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
      content: Text(message, style: const TextStyle(color: Colors.black),),
      backgroundColor: Colors.yellow,
      action: SnackBarAction(
        label: tr('done'),
        onPressed: (){},
      ),
    ));
  }
}