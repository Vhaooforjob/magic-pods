#ifndef AUDIO_MANAGER_H_
#define AUDIO_MANAGER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <mmdeviceapi.h>
#include <endpointvolume.h>
#include <functiondiscoverykeys_devpkey.h>

#include <memory>
#include <string>
#include <vector>

class AudioManager {
 public:
  AudioManager(flutter::BinaryMessenger* messenger);
  virtual ~AudioManager();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::EncodableValue GetOutputDevices();
  bool SetDefaultDevice(const std::string& device_id);
  bool SetVolume(double volume);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // AUDIO_MANAGER_H_
