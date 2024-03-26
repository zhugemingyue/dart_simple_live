import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:simple_live_tv_app/app/controller/base_controller.dart';
import 'package:get/get.dart';
import 'package:ns_danmaku/ns_danmaku.dart';
import 'package:simple_live_tv_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_tv_app/app/log.dart';

mixin PlayerMixin {
  GlobalKey globalPlayerKey = GlobalKey();
  GlobalKey globalDanmuKey = GlobalKey();

  /// 播放器实例
  late final player = FlutterAliPlayerFactory.createAliPlayer();
}
mixin PlayerStateMixin on PlayerMixin {
  /// 是否显示弹幕
  RxBool showDanmakuState = false.obs;

  /// 是否显示控制器
  RxBool showControlsState = false.obs;

  /// 是否显示设置窗口
  RxBool showSettingState = false.obs;

  /// 是否显示弹幕设置窗口
  RxBool showDanmakuSettingState = false.obs;

  /// 是否处于锁定控制器状态
  RxBool lockControlsState = false.obs;

  /// 是否处于全屏状态
  RxBool fullScreenState = false.obs;

  /// 显示手势Tip
  RxBool showGestureTip = false.obs;

  /// 手势Tip文本
  RxString gestureTipText = "".obs;

  /// 显示提示底部Tip
  RxBool showBottomTip = false.obs;

  /// 提示底部Tip文本
  RxString bottomTipText = "".obs;

  /// 自动隐藏控制器计时器
  Timer? hideControlsTimer;

  /// 自动隐藏提示计时器
  Timer? hideSeekTipTimer;

  /// 缓冲中
  RxBool bufferingState = false.obs;

  /// 缓冲信息
  RxString bufferingText = "缓冲中...".obs;

  /// 弹幕视图
  Widget? danmakuView;

  var showQualites = false.obs;
  var showLines = false.obs;

  /// 隐藏控制器
  void hideControls() {
    showControlsState.value = false;
    hideControlsTimer?.cancel();
  }

  void setLockState() {
    lockControlsState.value = !lockControlsState.value;
    if (lockControlsState.value) {
      showControlsState.value = false;
    } else {
      showControlsState.value = true;
    }
  }

  /// 显示控制器
  void showControls() {
    showControlsState.value = true;
    resetHideControlsTimer();
  }

  /// 开始隐藏控制器计时
  /// - 当点击控制器上时功能时需要重新计时
  void resetHideControlsTimer() {
    hideControlsTimer?.cancel();

    hideControlsTimer = Timer(
      const Duration(
        seconds: 5,
      ),
      hideControls,
    );
  }

  void updateScaleMode() async {
    var mode = FlutterAvpdef.AVP_SCALINGMODE_SCALEASPECTFIT;

    int scaleMode = AppSettingsController.instance.scaleMode.value;
    if (scaleMode == 0) {
      mode = FlutterAvpdef.AVP_SCALINGMODE_SCALEASPECTFIT;
    } else if (scaleMode == 1) {
      mode = FlutterAvpdef.AVP_SCALINGMODE_SCALETOFILL;
    } else if (scaleMode == 2) {
      mode = FlutterAvpdef.AVP_SCALINGMODE_SCALEASPECTFILL;
    }
    await player.setScalingMode(mode);
  }
}
mixin PlayerDanmakuMixin on PlayerStateMixin {
  /// 弹幕控制器
  DanmakuController? danmakuController;

  void initDanmakuController(DanmakuController e) {
    danmakuController = e;
    danmakuController?.updateOption(
      DanmakuOption(
        fontSize: AppSettingsController.instance.danmuSize.value.w,
        area: AppSettingsController.instance.danmuArea.value,
        duration: AppSettingsController.instance.danmuSpeed.value,
        opacity: AppSettingsController.instance.danmuOpacity.value,
        strokeWidth: AppSettingsController.instance.danmuStrokeWidth.value.w,
      ),
    );
  }

  void updateDanmuOption(DanmakuOption? option) {
    if (danmakuController == null || option == null) return;
    danmakuController!.updateOption(option);
  }

  void disposeDanmakuController() {
    danmakuController?.clear();
  }

  void addDanmaku(List<DanmakuItem> items) {
    if (!showDanmakuState.value) {
      return;
    }
    danmakuController?.addItems(items);
  }
}
mixin PlayerSystemMixin on PlayerMixin, PlayerStateMixin, PlayerDanmakuMixin {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  /// 初始化一些系统状态
  void initSystem() async {
    // 开始隐藏计时
    resetHideControlsTimer();
  }
}

class PlayerController extends BaseController
    with PlayerMixin, PlayerStateMixin, PlayerDanmakuMixin, PlayerSystemMixin {
  @override
  void onInit() {
    initSystem();
    initStream();
    super.onInit();
  }

  var width = 0.obs;
  var height = 0.obs;

  void initStream() {
    player.setOnError((errorCode, errorExtra, errorMsg, playerId) {
      Log.d("播放器错误：$errorCode $errorExtra $errorMsg $playerId");

      mediaError(errorMsg ?? '');
    });

    player.setOnCompletion((playerId) {
      mediaEnd();
    });

    player.setOnInfo((infoCode, extraValue, extraMsg, playerId) {
      Log.d("播放器信息：$infoCode $extraValue $extraMsg $playerId");
    });

    player.setOnLoadingStatusListener(
      loadingBegin: (playerId) {
        bufferingState.value = true;
      },
      loadingProgress: (percent, netSpeed, playerId) {
        Log.d("缓冲进度：$percent $netSpeed $playerId");
        bufferingText.value = "$percent%   $netSpeed KB/s";
      },
      loadingEnd: (playerId) {
        bufferingState.value = false;
      },
    );

    player.setOnStateChanged((newState, playerId) {
      switch (newState) {
        case FlutterAvpdef.AVPStatus_AVPStatusIdle: //空转、闲时、静态
          Log.d("播放器状态：$newState(空转、闲时、静态) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusInitialzed: //初始化完成
          Log.d("播放器状态：$newState(初始化完成) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusPrepared: //准备完成
          Log.d("播放器状态：$newState(准备完成) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStarted: //正在播放
          Log.d("播放器状态：$newState(正在播放) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusPaused: //播放暂停
          Log.d("播放器状态：$newState(播放暂停) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStopped: //播放停止
          Log.d("播放器状态：$newState(播放停止) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusCompletion: //播放完成
          Log.d("播放器状态：$newState(播放完成) $playerId");
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusError: //播放错误
          Log.d("播放器状态：$newState(播放错误) $playerId");
          break;
        default:
      }
    });
    player.setOnVideoSizeChanged((w, h, rotation, playerId) {
      Log.d("播放器视频尺寸：$w $h $rotation $playerId");
      width.value = w;
      height.value = h;
    });
  }

  void mediaEnd() {}

  void mediaError(String error) {}

  void onCreatedPlayView(viewId) async {
    await player.setPlayerView(viewId);
    //updateScaleMode();
  }

  @override
  void onClose() async {
    Log.w("播放器关闭");

    disposeDanmakuController();

    await player.destroy();
    super.onClose();
  }
}
