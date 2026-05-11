#ifndef RUNNER_BLE_SCANNER_H_
#define RUNNER_BLE_SCANNER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Foundation.h>

#include <memory>
#include <string>

class BleScanner {
 public:
  BleScanner(flutter::BinaryMessenger* messenger);
  ~BleScanner();

  void StartScan();
  void StopScan();

 private:
  void OnAdvertisementReceived(
      winrt::Windows::Devices::Bluetooth::Advertisement::BluetoothLEAdvertisementWatcher const& sender,
      winrt::Windows::Devices::Bluetooth::Advertisement::BluetoothLEAdvertisementReceivedEventArgs const& args);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  winrt::Windows::Devices::Bluetooth::Advertisement::BluetoothLEAdvertisementWatcher watcher_{ nullptr };
  winrt::event_token advertisement_received_token_;
};

#endif  // RUNNER_BLE_SCANNER_H_
