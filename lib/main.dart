import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:charset_converter/charset_converter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_loader_with_app_icon/overlay_loader_with_app_icon.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:souma/Env.dart';
import 'package:souma/models/PostData_All_Result.dart';
import 'package:souma/models/PostData_Market.dart';
import 'package:souma/utils/DeviceHelper.dart';
import 'package:souma/utils/IntentUtils.dart';
import 'package:turn_page_transition/turn_page_transition.dart';
import 'package:upgrader/upgrader.dart';
import 'ScanMarketScreen.dart';
import 'ScanProductScreen.dart';
import 'listmarket.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  //await Upgrader.clearSavedSettings();

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
      home:  UpgradeAlert(
          child:const MyHomePage(),
      ),
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
  //late Timer t;
  late PostDataAllResult _response;
  late Socket? clientSocket;
  String current_market_name = tr('global_market');
  String code_market = "00000000";
  String code_product = "";
  bool isshowResult = false;
  final List<Widget> fancyCards = [];
  String _currentSort = 'region';
  bool _isPanelOpen = false;

  TextEditingController codebarreController = TextEditingController();
  final PanelController _panelController = PanelController();
  final ScrollController _scrollcontroller = ScrollController();
  DateFormat format = DateFormat("dd/MM/yyyy");
  final bool _isfloatingVisible = false;
  bool _loading = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _response = PostDataAllResult();
    _scrollcontroller.addListener(_onScrollEvent);
    loadInfo();
    super.initState();
  }

  @override
  void dispose() {
    _scrollcontroller.removeListener(_onScrollEvent);
    super.dispose();
  }

  void _onScrollEvent() {

    if (_scrollcontroller.offset >= _scrollcontroller.position.maxScrollExtent && !_scrollcontroller.position.outOfRange) {
      _panelController.hide();
       /* setState(() {
          _isfloatingVisible = true;
        });*/
    }else{
      _panelController.show();
      /*setState(() {
        _isfloatingVisible = false;
      });*/
    }

    /*t.cancel();
    t = Timer(Duration(seconds: 15), () {
      setState(() {
        isshowResult = false;
        _isfloatingVisible = false;
        _panelController!.show();
        _response = new PostDataAllResult();
      });
    });*/

  }

  Future<void> loadInfo() async {
    Map<String, dynamic> data = await DeviceHelper.deviceData();
    print(data);
    deviceId = data['device_id'];
  }

  @override
  Future<void> didChangeDependencies() async {
    //deviceId  = await PlatformDeviceId.getDeviceId;
    if(Platform.isAndroid){
      _Platform = "ANDROID";
    }else{
      _Platform = "IOS";
    }
    super.didChangeDependencies();
  }

  Widget _buildSortPopupButton({required BuildContext context}) {
    const colorActiveBg = Color(0xFFE8F0FF);
    const colorActiveFg = Color(0xFF2563EB);

    final options = <Map<String, dynamic>>[
      {'value': 'region', 'label': tr('by_region'), 'icon': Icons.sort_by_alpha, 'trailing': const Text('A → Z', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600))},
      {'value': 'price',  'label': tr('by_price'),  'icon': Icons.trending_up,   'trailing': const Icon(Icons.arrow_upward, size: 16, color: Colors.grey)},
      {'value': 'date',   'label': tr('by_date'),   'icon': Icons.schedule,      'trailing': Icon(Icons.history, size: 16, color: Colors.grey[600])},
    ];

    PopupMenuItem<String> itemFor(Map<String, dynamic> o) {
      final selected = _currentSort == o['value'];
      final row = Container(
        decoration: BoxDecoration(
          color: selected ? colorActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(o['icon'] as IconData, size: 20, color: selected ? colorActiveFg : Colors.grey[700]),
            const SizedBox(width: 10),
            Text(
              o['label'] as String,
              style: TextStyle(
                color: selected ? colorActiveFg : Colors.grey[900],
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            o['trailing'] as Widget,
          ],
        ),
      );
      return PopupMenuItem<String>(
        value: o['value'] as String,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: row,
      );
    }

    void apply(String v) {
      setState(() {
        _currentSort = v;
        if (v == 'region') reOrderByRegion();
        if (v == 'price')  reOrderByPrice();
        if (v == 'date')   reOrderByDate();
      });
    }

    return PopupMenuButton<String>(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      elevation: 8,
      onSelected: apply,
      padding: const EdgeInsets.all(6),
      itemBuilder: (_) => options.map(itemFor).toList(),
      child: Container(
        height: 40,
        width: 40,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: const Icon(Icons.tune, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double maxPanelH = (screenHeight * 0.90).clamp(340.0, 620.0);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/images/souma_logo2.png',
              fit: BoxFit.contain,
              height: 42,
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
          if (isshowResult && _response.PRODUCT != null && _response.PRODUCT!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSortPopupButton(context: context),
            ),
        ],
      ),
        body: OverlayLoaderWithAppIcon(
            isLoading: _loading,
            circularProgressColor: Colors.blue,
            appIcon:  Image.asset('assets/images/thinking.png'),
            child: SlidingUpPanel(
              controller: _panelController,
              renderPanelSheet: false,
              collapsed: _floatingCollapsed(),
              panelBuilder: showInsertCode,
              defaultPanelState: PanelState.CLOSED,
              minHeight: 52,
              maxHeight: maxPanelH,
              backdropEnabled: false,
              panelSnapping: true,
              isDraggable: true,
              onPanelOpened: () { if (mounted) setState(() => _isPanelOpen = true); },
              onPanelClosed: () { if (mounted) setState(() => _isPanelOpen = false); },
              body: isshowResult ? showResult() : ScanWidget(),
            ),
        ),
      floatingActionButton: Visibility(
        visible: _isfloatingVisible,
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: _goToTop,
          child: const Icon(Icons.upgrade),
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
    final bool hasResult = _response.RST != "0" && (_response.PRODUCT?.length ?? 0) > 0;
    final int resultCount = _response.PRODUCT?.length ?? 0;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (_panelController.isPanelClosed) {
            _panelController.open();
          } else if (_panelController.isPanelOpen) {
            _panelController.close();
          }
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                spreadRadius: -6,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    current_market_name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.1,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                if (hasResult) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          "$resultCount",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  turns: _isPanelOpen ? 0.5 : 0.0,
                  child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white.withValues(alpha: 0.85), size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showResult(){

    if(_response.RST == "0"){
      return  GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            isshowResult = false;
            _response = PostDataAllResult();
          });
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.fromLTRB(10, 10, 10, MediaQuery.of(context).padding.bottom + 52 + 72 + 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('no_result_product'), style: const TextStyle(color: Colors.blue,  fontSize: 25), textAlign: TextAlign.center, overflow: TextOverflow.visible,),
              const Image (
                fit: BoxFit.fitHeight,
                image: AssetImage('assets/images/dizzy.png'),
              ),
            ],
          )
        ),
      );
    }else{
      final int count = _response.PRODUCT?.length ?? 0;
      final bottomSafe = MediaQuery.of(context).padding.bottom;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            isshowResult = false;
            _response = PostDataAllResult();
          });
        },
        child: ListView.builder(
          controller: _scrollcontroller,
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 4,
            bottom: bottomSafe + 52 + 72 + 24,
          ),
          itemCount: count + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Container(
                width: double.infinity,
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: Colors.blue.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('products'),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.4)),
                          const SizedBox(height: 3),
                          Text("$count ${tr('references')}",
                              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return buildTripCard(index - 1);
          },
        ),
      );
    }

  }


  Widget buildTripCard(int index) {

    final p = _response.PRODUCT![index];
    final bool isBest = p.IS_THE_BEST;
    final bool hasPromo = p.HAS_PRM == "1";
    final bool hasLocation = p.LO != 0 && p.LA != 0;

    final NumberFormat moneyFr = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'DA',
      decimalDigits: 2,
    );
    final String priceNow = hasPromo ? moneyFr.format(p.PRM) : moneyFr.format(p.PRX);
    final String? priceOld = hasPromo ? moneyFr.format(p.PRX) : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          isshowResult = false;
          _response = PostDataAllResult();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
          border: isBest
              ? Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.45), width: 1.4)
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        foregroundDecoration: isBest
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xFF22C55E).withValues(alpha: 0.06),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28, 1.0],
                ),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              if (isBest)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.white, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          tr('best_price'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: isBest ? 130 : 0),
                      child: Text(
                        p.NOM,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          height: 1.22,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                      ),
                      child: Text(
                        p.PRD,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 0.9),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.location_on_outlined, color: Color(0xFFB45309), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.REGION,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: const Color(0xFF78350F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (hasLocation) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_outlined, size: 13, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: hasPromo ? const Color(0xFFECFDF5) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasPromo ? const Color(0xFF86EFAC) : const Color(0xFFBBF7D0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: hasPromo ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              hasPromo ? Icons.discount_outlined : Icons.payments_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPromo ? '${tr('price')} • Promo' : tr('price'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF166534),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  priceNow,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 24,
                                    height: 1.05,
                                    color: const Color(0xFF15803D),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (priceOld != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Text(
                                priceOld,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  color: const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: const Color(0xFFB91C1C),
                                  decorationThickness: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Text(
                                tr('last_update') + DateFormat("dd-MM-yyyy").format(p.DATE_MAJ),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (hasLocation)
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () async => IntentUtils.openMapsSheet(context, p.LA, p.LO),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.navigation_outlined, size: 17),
                              label: Text(
                                tr('go'),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget showInsertCode(){

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: Colors.black26,
              offset: Offset(0, -3),
            ),
          ]
      ),
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Image.asset(
                "assets/images/image_codebarre_help1.png",
                fit: BoxFit.contain,
                height: 110,
              ),
              const SizedBox(height: 6),
              Text(
                tr('help_manual_scan'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: TextFormField(
                      autofocus: false,
                      controller: codebarreController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Color(0xFFB91C1C), fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('error_code_barre');
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: tr('error_code_barre'),
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: ()  {
                    connectToServerFromEditText();
                    _panelController.close();
                  },
                  label: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(tr('done'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5),),
                  ),
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 19,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget ScanWidget(){
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSafe + 52 + 72 + 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Material(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _navigateToScanProductScreen(context);
                });
              },
              child: Container(
                width: 140,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF94A3B8), width: 1.3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/codebarre2.png',
                      width: 118.0,
                      height: 54.0,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('scan_product'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
      ),
    );
  }


  Future<void> _navigateToScanMarketScreen(BuildContext context) async {
    setState(() {
      isshowResult = false;
      _response = PostDataAllResult();
    });

    try {
      // Push scanning screen and wait for result
      final qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScanMarketScreen()),
      );

      print(qrCode);

      if (qrCode != null && qrCode != "-1") {
        if (qrCode.startsWith("SOUMA_APP")) {
          setState(() {
            code_market = getValue(qrCode, "CC");
            current_market_name = getValue(qrCode, "MARKET");
          });
        } else {
          showSnackBarWithKey(tr("error_code_market"));
        }
      }
    } catch (e) {
      print("Error scanning QR code: $e");
    }
  }



  Future<void> _navigateToScanProductScreen(BuildContext context) async {
    try {
      // Push the scanning screen and wait for result
      final barcodeScanRes = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScanProductScreen()),
      );

      print(barcodeScanRes);

      if (barcodeScanRes != null && barcodeScanRes != "-1") {
        setState(() {
          code_product = barcodeScanRes;
        });
        // Call your server connection function
        connectToServer(code_market, code_product);
      }
    } catch (e) {
      print("Error scanning product barcode: $e");
    }
  }

  Future<void> _navigateToListMarketScreen(BuildContext context) async {

    setState(() {
      isshowResult = false;
      _panelController.show();
    });

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

  void connectToServer(String codeMarket, String codeProduct) async {

    // reset index result indicator
    setState(() {
      _loading = true;
      isshowResult = false;
      _response = PostDataAllResult();
    });

    FocusScope.of(context).unfocus();
    codebarreController.clear();

    Socket.connect(Env.IP_SERVER, Env.PORT_SERVER, timeout: const Duration(seconds: 5)).then((socket) async {
      setState(() {
        clientSocket = socket;
      });

      sendMessage(codeMarket, codeProduct);

      var bytesBuilder = BytesBuilder();
      bool hasParsed = false;

      Future<void> parseAndApply(Uint8List allBytes) async {
        if (hasParsed) return;
        hasParsed = true;
        try {
          String jsonStr = await CharsetConverter.decode("windows-1256", allBytes);
          PostDataAllResult jsonData = PostDataAllResult.fromJson(jsonDecode(jsonStr));

          setState(() {
            isshowResult = true;
            _loading = false;
            _response = jsonData;
            if (_response.PRODUCT != null &&
                _response.PRODUCT!.isNotEmpty &&
                _response.RST == "1") {
              _response.PRODUCT![0].IS_THE_BEST = true;
            }
          });

          if (_response.RST == "1" &&
              _response.PRODUCT != null &&
              _response.PRODUCT!.isNotEmpty) {
            //AudioService().playSound(AssetSource('audio/success_sound.mp3'));
          }
        } catch (e) {
          showSnackBarWithKey("${tr('error_server')} : $e");
          setState(() {
            _loading = false;
            isshowResult = false;
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
        },
        onError: (e) {
          showSnackBarWithKey(e.toString());
          setState(() {
            _loading = false;
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
        _loading = false;
      });
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

  void sendMessage(String codeMarket, String codeProduct) {
    String message = '''CMD:CHECK\nCC:$codeMarket\nCB:$codeProduct\nDID:$deviceId\nPLT:$_Platform''';
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
