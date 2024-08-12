import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

import common from '@ohos.app.ability.common';
import { AudioRecorder } from './AudioRecorder';

import util from '@ohos.util';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';

const permissions: Array<Permissions> = ['ohos.permission.MICROPHONE'];

/** FlutterAudioRecorderPlugin **/
export default class FlutterAudioRecorderPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private recorder: AudioRecorder | null = null;
  private context: common.Context | null = null;

  constructor() {}

  getUniqueClassName(): string {
    return "FlutterAudioRecorderPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_audio_recorder");
    this.channel.setMethodCallHandler(this)
    this.context = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "hasPermissions":
        this.handleHasPermission(result);
        break;
      case "init":
        this.recorder = new AudioRecorder();
        this.recorder.init();
        let initResult : Map<string, Object> = new Map();
        initResult.set("duration", 0);
        initResult.set("path", this.recorder?.filePath ?? "");
        initResult.set("audioFormat", "wav");
        initResult.set("peakPower", 0);
        initResult.set("averagePower", 0);
        initResult.set("isMeteringEnabled", true);
        initResult.set("status", this.recorder?.mStatus ?? "");
        result.success(initResult);
        break;
      case "current":
        let currentResult : Map<string, Object> = new Map();
        currentResult.set("duration", 0);
        currentResult.set("path", this.recorder?.filePath ?? "");
        currentResult.set("audioFormat", "wav");
        currentResult.set("peakPower", 0);
        currentResult.set("averagePower", 0);
        currentResult.set("isMeteringEnabled", true);
        currentResult.set("status", this.recorder?.mStatus ?? "");
        result.success(currentResult);
        break;
      case "start":
        this.recorder?.start();
        result.success(null);
        break;
      case "pause":
        this.recorder?.stop();
        result.success(null);
        break;
      case "resume":
        this.recorder?.start();
        result.success(null);
        break;
      case "stop":
        if (this.recorder?.mStatus == "stopped") {
          result.success(null);
        } else {
          let currentResult : Map<string, Object> = new Map();
          currentResult.set("duration", 0);
          currentResult.set("path", this.recorder?.filePath ?? "");
          currentResult.set("audioFormat", "wav");
          currentResult.set("peakPower", 0);
          currentResult.set("averagePower", 0);
          currentResult.set("isMeteringEnabled", true);
          currentResult.set("status", this.recorder?.mStatus ?? "");
          this.recorder?.stop();
          this.recorder?.release();
          result.success(currentResult);
        }
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  async handleHasPermission(result: MethodResult): Promise<void> {
    let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkPermissionGrant(permissions[0]);

    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 已经授权，可以继续访问目标操作
      result.success(true);
    } else {
      result.success(await this.reqPermissionsFromUser(permissions));
    }
  }

  // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
  async reqPermissionsFromUser(permissions: Array<Permissions>): Promise<boolean> {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      let data = await atManager.requestPermissionsFromUser(getContext(this), permissions);
      let grantStatus: Array<number> = data.authResults;
      return grantStatus[0] === 0;
    } catch (e) {
      console.error(`Failed to request permissions from user. Code is ${e.code}, message is ${e.message}`);
    }
    return false;
  }

  async checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }
    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }
    return grantStatus;
  }
}