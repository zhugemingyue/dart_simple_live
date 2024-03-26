import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_alilistplayer.dart';
import 'package:get/get.dart';
import 'package:simple_live_tv_app/modules/live_room/aliplayer/aliplayer_controller.dart';

class AliPlayerPage extends GetView<AliPlayerControlelr> {
  const AliPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: Get.width,
        height: Get.height,
        child: AliPlayerView(
          key: controller.playerKey,
          onCreated: controller.onCreatedPlayView,
          x: 0,
          y: 0,
          width: Get.width,
          height: Get.height,
        ),
      ),
    );
  }
}
