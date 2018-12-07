# AVAudioInputNode sample rate conversion issue : demo project

This project aims at demonstrating issues with AVAudioInputNode sample rate conversion (non-)capabilities.

According to documentation, AVAudioInputNode shouldn't be able to perform sample rate conversion, but it appears that it can perform it on some cases.

The question following is: shall we or shall we not rely on AVAudioInputNode for sample rate conversion?


****

Two test projects are provided for comparisons. Both test contain the same demo project, the only modification between the two is the content of the `handConfigurationChange` function.

All the behaviours described below have been confirmed on the following devices:
- iPad Air 2, iOS 11.3
- iPad Air 2, iOS 12.1.1
- iPad Pro 12.9", iOS 11.3
- iPad Pro 11", iOS 12.1.1
- iPhone 5S, iOS 11.3
- iPhone 6, iOS 12.0
- various simulators with iOS 11.3, 12.0 and 12.1

with Xcode 10.1, compiling with latest iOS SDK (12.1) and the deployement target set to iOS 9.0.


****

The demo project consists of the following simple audio setup :
```
|------------|      |---------|     |------------|     |-------------|
| INPUT NODE |----->| MIXER 1 |---->| MAIN MIXER |---->| OUTPUT NODE |
|------------|      |---------|     |------------|     |-------------|
```

* AudioSession is set to `PlayAndRecord` category, with `DefaultToSpeaker` and `AllowBluetooth` options. Prefered buffer duraiton is set to 5 ms. This corresponds to a classic setup for an interfactive musical apps. The sample rates of the AudioSession and of all the connections are set to the standard 48kHz.

* Interruptions, and media service reset are not dealt with in this project for simplicity, as they have nothing to do with the problem illustrated here. Please restart the demo apps if any of these happen.

* The input is permanently linked to the output through Mixer 1 and Main Mixer. Consequently, we advise to test this project with headphones only in order to avoid audio feedbacks.

* The main interface provides a `Log` button, which triggers the logging, in the terminal, of all the connections' format (also automatically done at startup and when audio configuration change).


****

The two tests perform exactly the same actions.

In order to see the problem, execute the following steps:

1. First, be sure to have a bluetooth headset (bluetooth headphones with microphone) connected to you device.

2. Switch the headset off, and connect a wired headphones on the device.

3. Compile and launch the demo app, the audio units should be connected as follows after startup (check log in terminal):
```
                   48kHz |------------| 48kHz |---------| 48kHz |------------| 48kHz |-------------| 48kHz
Device Microphone ------>| INPUT NODE |------>| MIXER 1 |------>| MAIN MIXER |------>| OUTPUT NODE |------> Wired headphones
                         |------------|       |---------|       |------------|       |-------------|
```
at this point, you should be able to hear what comes in the microphone in your headphones (direct audio feedback).

4. Switch on the bluetooth headset. It should connect automatically and set the sample rate to a different (16kHz, 8kHz or 44.1kHz for most bluetooth headsets). The `handleConfigurationChange` function is triggered and the audio engine is restarted with the following connections (adapt the hardware sample rate to the one set by your headset):
```
                    16kHz |------------| 48kHz |---------| 48kHz |------------| 16kHz |-------------| 16kHz
Headset Microphone ------>| INPUT NODE |------>| MIXER 1 |------>| MAIN MIXER |------>| OUTPUT NODE |------> Headset headphones
                          |------------|       |---------|       |------------|       |-------------|
```


****

Surprisingly, the two tests have different behaviours:

1. In the project `TEST01`, during step 4, `Mixer 1` is completerly disconnected and reconnected before restarting the audio engine. As expected, connecting the `Input node` to `Mixer 1` with a sample rate different for the hardware sample rate ends up in a exception with the following error:
```
[avae] AVAEInternal.h:70:_AVAE_Check: required condition is false: [AVAudioIONodeImpl.mm:911:SetOutputFormat: (format.sampleRate == hwFormat.sampleRate)]`
```

2. In the project `TEST02`, during step 4, nothing is disconnected and the audio engine is restarted as is. It appears that this does not triggers any exception, and that the resulting graph, with an Input Node connected with two different sample rates on input and output, works perfectly and the direct audio feedback is back.
