#ifndef BLUETOOTH_MANAGER_H_
#define BLUETOOTH_MANAGER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Devices.Bluetooth.h>

#include <memory>
#include <string>

class BluetoothManager {
 public:
  BluetoothManager(flutter::BinaryMessenger* messenger);
  virtual ~BluetoothManager();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ConnectDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void DisconnectDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // BLUETOOTH_MANAGER_H_
