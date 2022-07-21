# Sample Project That Demonstrates Voice Processing Problem


## Steps to Reproduce

1. Install the VoiceProcessing app on an iOS device
2. Launch the VoiceProcessing app
3. The app is now playing the audio file
4. Connect Bluetooth headset
5. Conf change count should go up by one and the audio should continue on the headset
6. Disconnect Bluetooth headset
7. Conf change count should go up by one and the audio should continue on the device speaker
8. Press **Set Voice Processing On** button
9. After the audio plays again connect Bluetooth headset
10. Conf change count has not changed and the audio wont play on the headset
11. Disconnect Bluetooth headset
12. Conf change count has not changed and the audio plays again

Expected result: By definition AVAudioEngineConfigurationChange notification should be triggered every time there is a change in the engine I/O 

Actual result: AVAudioEngineConfigurationChange notification is not triggered when voiceProcessing is turned on
