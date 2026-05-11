#include "ble_scanner.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>

#include <iostream>
#include <vector>

using namespace winrt;
using namespace Windows::Devices::Bluetooth::Advertisement;
using namespace Windows::Storage::Streams;

BleScanner::BleScanner(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.magicpods/ble_scanner",
      &flutter::StandardMethodCodec::GetInstance());

  watcher_ = BluetoothLEAdvertisementWatcher();
  watcher_.ScanningMode(BluetoothLEScanningMode::Active);

  advertisement_received_token_ = watcher_.Received({ this, &BleScanner::OnAdvertisementReceived });
}

BleScanner::~BleScanner() {
  StopScan();
  if (watcher_ != nullptr) {
    watcher_.Received(advertisement_received_token_);
  }
}

void BleScanner::StartScan() {
  if (watcher_.Status() != BluetoothLEAdvertisementWatcherStatus::Started) {
    watcher_.Start();
  }
}

void BleScanner::StopScan() {
  if (watcher_.Status() == BluetoothLEAdvertisementWatcherStatus::Started) {
    watcher_.Stop();
  }
}

void BleScanner::OnAdvertisementReceived(
    BluetoothLEAdvertisementWatcher const& sender,
    BluetoothLEAdvertisementReceivedEventArgs const& args) {
  
  auto advertisement = args.Advertisement();
  auto manufacturer_data_list = advertisement.ManufacturerData();

  for (auto const& data : manufacturer_data_list) {
    // Apple Company ID = 0x004C
    if (data.CompanyId() == 0x004C) {
      auto data_reader = DataReader::FromBuffer(data.Data());
      std::vector<uint8_t> bytes(data_reader.UnconsumedBufferLength());
      data_reader.ReadBytes(bytes);

      flutter::EncodableMap result_map;
      
      // Convert Bluetooth Address to string (XX:XX:XX:XX:XX:XX)
      char address_str[18];
      uint64_t addr = args.BluetoothAddress();
      sprintf_s(address_str, "%02llX:%02llX:%02llX:%02llX:%02llX:%02llX",
                (addr >> 40) & 0xFF, (addr >> 32) & 0xFF, (addr >> 24) & 0xFF,
                (addr >> 16) & 0xFF, (addr >> 8) & 0xFF, addr & 0xFF);

      result_map[flutter::EncodableValue("address")] = flutter::EncodableValue(std::string(address_str));
      result_map[flutter::EncodableValue("name")] = flutter::EncodableValue(winrt::to_string(advertisement.LocalName()));
      result_map[flutter::EncodableValue("rssi")] = flutter::EncodableValue((int)args.RawSignalStrengthInDBm());
      result_map[flutter::EncodableValue("manufacturerData")] = flutter::EncodableValue(bytes);

      channel_->InvokeMethod("onAdvertisementReceived", std::make_unique<flutter::EncodableValue>(result_map));
    }
  }
}
