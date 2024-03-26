import 'package:flutter/widgets.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:simple_live_tv_app/app/controller/base_controller.dart';

class AliPlayerControlelr extends BaseController {
  final GlobalKey playerKey = GlobalKey();
  final FlutterAliplayer fAliplayer = FlutterAliPlayerFactory.createAliPlayer();

  void onCreatedPlayView(viewId) {
    fAliplayer.setPlayerView(viewId);
  }

  @override
  void onInit() {
    startPlay();
    super.onInit();
  }

  void startPlay() async {
    await fAliplayer.setAutoPlay(true);
    await fAliplayer.setUrl(
        "https://stream-fujian2-ct-117-25-149-15.edgesrv.com:443/live/288016rlols5_2000p.flv?wsAuth=af941f1aaea9d027b410d99a9b7b64ac&token=web-h5-0-288016-e9416291174176ee20f930c0da1e23b2806baec400f399de&logo=0&expire=0&did=10000000000000000000000000001501&pt=2&st=0&sid=387920221&mcid2=0&vhost=play2&origin=tct&mix=0&isp=scdnctfujxm");
    await fAliplayer.prepare();
    //fAliplayer.setScalingMode(FlutterAvpdef.AVP_SCALINGMODE_SCALEASPECTFIT);
  }

  void setConfig() async {
    var config = AVPConfig();

    fAliplayer.setPlayConfig(config);
  }

  @override
  void onClose() {
    fAliplayer.destroy();
    super.onClose();
  }
}
