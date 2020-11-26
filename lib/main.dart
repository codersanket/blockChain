import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHome());
  }
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final String myadress = "0x6D9b1D8A01796152bC69B9DEA7ab59b01F127535";
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();

  Web3Client web3client;

  bool loading = false;
  Client httpClient;

  TextEditingController _textEditingController = TextEditingController();

  var balance;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    web3client = Web3Client(
        "https://rinkeby.infura.io/v3/3b26586f87f144f6a1fe81ddfaf931c2",
        httpClient);
    getBalance();
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/aib.json");
    String contractAdress = "0xb6Ba40124eB25Adf96059D825642d5CB92f6D5A0";
    final Contract = DeployedContract(ContractAbi.fromJson(abi, "coins"),
        EthereumAddress.fromHex(contractAdress));
    return Contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await web3client.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance() async {
    setState(() {
      loading = true;
    });
    // EthPrivateKey adress = EthPrivateKey.fromHex(myadress);
    List<dynamic> result = await query("getBalance", []);
    print(result);
    balance = result[0];

    setState(() {
      loading = false;
    });
  }

  Future<String> submit(String functioName, List<dynamic> args) async {
    EthPrivateKey _key = EthPrivateKey.fromHex(
        "8b64483e2455c04b6a70297b879959bbfd9ce3f83b273012e2244956cf3a8bf8");
    final contract = await loadContract();
    final ethFunction = contract.function(functioName);
    final result = await web3client.sendTransaction(
        _key,
        Transaction.callContract(
          contract: contract,
          function: ethFunction,
          parameters: args,
        ),
        fetchChainIdFromNetworkId: true);

    return result;
  }

  Future<void> depositBalance(String amount) async {
    int amo = double.parse(amount).round();
    var result = await submit("deposit", [BigInt.from(amo)]);
    _globalKey.currentState.showSnackBar(SnackBar(
      content: Text(result),
    ));
    getBalance();
    _textEditingController.text = "";

    return result;
  }

  Future<void> withDrawBalance(String amount) async {
    int amo = double.parse(amount).round();
    var result = await submit("withdraw", [BigInt.from(amo)]);
    _globalKey.currentState.showSnackBar(SnackBar(
      content: Text("Txn Hash:" + result),
    ));
    getBalance();
    _textEditingController.text = "";
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      backgroundColor: Vx.gray300,
      body: SingleChildScrollView(
        child: ZStack([
          VxBox()
              .red500
              .size(context.screenWidth, context.percentHeight * 40)
              .make(),
          VStack(
            [
              (context.percentHeight * 10).heightBox,
              "Coins".text.xl5.white.center.makeCentered(),
              (context.percentHeight * 10).heightBox,
              VxBox(
                      child: VStack([
                "Balance".text.gray800.xl2.bold.makeCentered(),
                balance == null
                    ? CircularProgressIndicator().centered().p16()
                    : "$balance\$".text.xl6.red500.makeCentered().p16()
              ]))
                  .white
                  .size(context.screenWidth, context.safePercentHeight * 20)
                  .rounded
                  .shadowLg
                  .make()
                  .p16(),
              TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                    labelText: "Enter Amount",
                    focusColor: Colors.black,
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Vx.red300, width: 4)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(width: 4)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(width: 4))),
              ).p32(),
              (context.percentHeight * 5).heightBox,
              HStack(
                [
                  FlatButton.icon(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Vx.red500,
                    onPressed: getBalance,
                    icon: Icon(
                      Icons.refresh,
                      color: Vx.white,
                    ),
                    label: "Refresh".text.white.make(),
                    shape: Vx.roundedSm,
                  ),
                  FlatButton.icon(
                    shape: Vx.roundedSm,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Colors.green,
                    onPressed: () =>
                        depositBalance(_textEditingController.text),
                    icon: Icon(
                      Icons.call_made,
                      color: Vx.white,
                    ),
                    label: "Deposit".text.white.make(),
                  ),
                  FlatButton.icon(
                    shape: Vx.roundedSm,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Colors.red,
                    onPressed: () =>
                        withDrawBalance(_textEditingController.text),
                    icon: Icon(
                      Icons.call_received,
                      color: Vx.white,
                    ),
                    label: "Withdraw".text.white.make(),
                  ),
                ],
                alignment: MainAxisAlignment.spaceAround,
                axisSize: MainAxisSize.max,
              ),
              Visibility(
                visible: loading,
                child: CircularProgressIndicator().centered(),
              )
            ],
          ),
        ]),
      ),
    );
  }
}

class SliderWidget extends StatefulWidget {
  final double sliderHeight;
  final int min;
  final int max;
  final fullWidth;
  final double amount;
  final Function value;

  SliderWidget(
      {this.sliderHeight = 48,
      this.max = 10,
      this.min = 0,
      this.amount,
      this.fullWidth = false,
      this.value});

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  @override
  Widget build(BuildContext context) {
    double paddingFactor = .2;

    if (this.widget.fullWidth) paddingFactor = .3;

    return Container(
      width: this.widget.fullWidth
          ? double.infinity
          : (this.widget.sliderHeight) * 5.5,
      height: (this.widget.sliderHeight),
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.all(
          Radius.circular((this.widget.sliderHeight * .3)),
        ),
        gradient: new LinearGradient(
            colors: [
              const Color(0xFF00c6ff),
              const Color(0xFF0072ff),
            ],
            begin: const FractionalOffset(0.0, 0.0),
            end: const FractionalOffset(1.0, 1.00),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(this.widget.sliderHeight * paddingFactor,
            2, this.widget.sliderHeight * paddingFactor, 2),
        child: Row(
          children: <Widget>[
            Text(
              '${this.widget.min}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: this.widget.sliderHeight * .3,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: this.widget.sliderHeight * .1,
            ),
            Expanded(
              child: Center(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white.withOpacity(1),
                    inactiveTrackColor: Colors.white.withOpacity(.5),

                    trackHeight: 4.0,
                    thumbShape: CustomSliderThumbCircle(
                      thumbRadius: this.widget.sliderHeight * .4,
                      min: this.widget.min,
                      max: this.widget.max,
                    ),
                    overlayColor: Colors.white.withOpacity(.4),
                    //valueIndicatorColor: Colors.white,
                    activeTickMarkColor: Colors.white,
                    inactiveTickMarkColor: Colors.red.withOpacity(.7),
                  ),
                  child: Slider(value: widget.amount, onChanged: widget.value),
                ),
              ),
            ),
            SizedBox(
              width: this.widget.sliderHeight * .1,
            ),
            Text(
              '${this.widget.max}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: this.widget.sliderHeight * .3,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSliderThumbCircle extends SliderComponentShape {
  final double thumbRadius;
  final int min;
  final int max;

  const CustomSliderThumbCircle({
    @required this.thumbRadius,
    this.min = 0,
    this.max = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
    double textScaleFactor,
    Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = Colors.white //Thumb Background Color
      ..style = PaintingStyle.fill;

    TextSpan span = new TextSpan(
      style: new TextStyle(
        fontSize: thumbRadius * .8,
        fontWeight: FontWeight.w700,
        color: sliderTheme.thumbColor, //Text Color of Value on Thumb
      ),
      text: getValue(value),
    );

    TextPainter tp = new TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawCircle(center, thumbRadius * .9, paint);
    tp.paint(canvas, textCenter);
  }

  String getValue(double value) {
    return (min + (max - min) * value).round().toString();
  }
}
