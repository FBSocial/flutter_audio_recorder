
import util from '@ohos.util';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'AudioCapturerDemo';

class Options {
  offset?: number;
  length?: number;
}

let context = getContext(this);
let bufferSize: number = 0;
let audioCapturer: audio.AudioCapturer | undefined = undefined;
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
  channels: audio.AudioChannel.CHANNEL_2, // 通道
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
}
let audioCapturerInfo: audio.AudioCapturerInfo = {
  source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型
  capturerFlags: 0 // 音频采集器标志
}
let audioCapturerOptions: audio.AudioCapturerOptions = {
  streamInfo: audioStreamInfo,
  capturerInfo: audioCapturerInfo
}


export class AudioRecorder {
  private _file : fileIo.File | undefined = undefined;
  private _filePath : string = getContext().cacheDir + '/' + util.generateRandomUUID() + '.wav';
  private _mStatus: string = "unset";

  get filePath(): string {return this._filePath;}
  get mStatus(): string {return this._mStatus;}

  // 初始化，创建实例，设置监听事件
  init() {
    this._mStatus = "initialized";
    this._file = fileIo.openSync(this._filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    let readDataCallback = (buffer: ArrayBuffer) => {
      let options: Options = {
        offset: bufferSize,
        length: buffer.byteLength
      }
      fileIo.writeSync(this._file!.fd, buffer, options);
      bufferSize += buffer.byteLength;
    }
    audio.createAudioCapturer(audioCapturerOptions, (err, capturer) => { // 创建AudioCapturer实例
      if (err) {
        console.error(`Invoke createAudioCapturer failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      console.info(`${TAG}: create AudioCapturer success`);
      audioCapturer = capturer;
      if (audioCapturer !== undefined) {
        (audioCapturer as audio.AudioCapturer).on('readData', readDataCallback);
      }
    });
  }

  // 开始一次音频采集
  start() {
    if (audioCapturer !== undefined) {
      let stateGroup = [audio.AudioState.STATE_PREPARED, audio.AudioState.STATE_PAUSED, audio.AudioState.STATE_STOPPED];
      if (stateGroup.indexOf((audioCapturer as audio.AudioCapturer).state.valueOf()) === -1) { // 当且仅当状态为STATE_PREPARED、STATE_PAUSED和STATE_STOPPED之一时才能启动采集
        console.error(`${TAG}: start failed`);
        return;
      }

      // 启动采集
      (audioCapturer as audio.AudioCapturer).start((err: BusinessError) => {
        if (err) {
          console.error('Capturer start failed.');
        } else {
          this._mStatus = "recording";
          console.info('Capturer start success.');
        }
      });
    }
  }

  // 停止采集
  stop() {
    if (audioCapturer !== undefined) {
      // 只有采集器状态为STATE_RUNNING或STATE_PAUSED的时候才可以停止
      if ((audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_RUNNING && (audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_PAUSED) {
        console.info('Capturer is not running or paused');
        return;
      }

      //停止采集
      (audioCapturer as audio.AudioCapturer).stop((err: BusinessError) => {
        if (err) {
          console.error('Capturer stop failed.');
        } else {
          fileIo.close(this._file);
          this._mStatus = "paused";
          console.info('Capturer stop success.');
        }
      });
    }
  }

  // 销毁实例，释放资源
  release() {
    if (audioCapturer !== undefined) {
      // 采集器状态不是STATE_RELEASED或STATE_NEW状态，才能release
      if ((audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_RELEASED || (audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_NEW) {
        console.info('Capturer already released');
        return;
      }

      //释放资源
      (audioCapturer as audio.AudioCapturer).release((err: BusinessError) => {
        if (err) {
          console.error('Capturer release failed.');
        } else {
          this._mStatus = "stopped";
          console.info('Capturer release success.');
        }
      });
    }
  }
}
