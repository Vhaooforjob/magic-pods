#include "audio_manager.h"

#include <comdef.h>
#include <iostream>
#include <wrl/client.h>
#include <comutil.h>
#include <vector>

#pragma comment(lib, "Ole32.lib")
#pragma comment(lib, "comsuppw.lib")

using Microsoft::WRL::ComPtr;

// PolicyConfig interface structure
MIDL_INTERFACE("f6bc5491-726d-4efc-9304-0337da6e67e1")
IPolicyConfig : public IUnknown {
 public:
  virtual HRESULT STDMETHODCALLTYPE GetMixFormat(PCWSTR, WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetDeviceFormat(PCWSTR, int, WAVEFORMATEX**) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDeviceFormat(PCWSTR, WAVEFORMATEX*, WAVEFORMATEX*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetProcessingPeriod(PCWSTR, int, REFERENCE_TIME*, REFERENCE_TIME*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetProcessingPeriod(PCWSTR, REFERENCE_TIME*) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetShareMode(PCWSTR, int*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetShareMode(PCWSTR, int) = 0;
  virtual HRESULT STDMETHODCALLTYPE GetPropertyValue(PCWSTR, const PROPERTYKEY&, PROPVARIANT*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetPropertyValue(PCWSTR, const PROPERTYKEY&, PROPVARIANT*) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetDefaultEndpoint(PCWSTR deviceId, ERole role) = 0;
  virtual HRESULT STDMETHODCALLTYPE SetEndpointVisibility(PCWSTR, int) = 0;
};

// Known CLSIDs and IIDs for PolicyConfig
const CLSID CLSID_PolicyConfig1 = {0x870af99c, 0x171d, 0x4f9e, {0xaf, 0x0d, 0xe6, 0x3d, 0xf4, 0x0c, 0x2b, 0xc9}};
const CLSID CLSID_PolicyConfig2 = {0x294935ce, 0xf637, 0x4e7c, {0x92, 0x7b, 0x1f, 0x84, 0xa6, 0x31, 0x5c, 0x2d}};

const IID IID_IPolicyConfig1 = {0xf6bc5491, 0x726d, 0x4efc, {0x93, 0x04, 0x03, 0x37, 0xda, 0x6e, 0x67, 0xe1}};
const IID IID_IPolicyConfig2 = {0x870af99c, 0x171d, 0x4f9e, {0xaf, 0x0d, 0xe6, 0x3d, 0xf4, 0x0c, 0x2b, 0xc9}};
const IID IID_IPolicyConfig3 = {0x568b9108, 0x44bf, 0x40fe, {0x85, 0xa1, 0x7c, 0x50, 0x87, 0xb0, 0xa3, 0x0b}};

AudioManager::AudioManager(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.magicpods/audio",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { this->HandleMethodCall(call, std::move(result)); });
}

AudioManager::~AudioManager() {}

void AudioManager::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name() == "getOutputDevices") {
    result->Success(GetOutputDevices());
  } else if (method_call.method_name() == "setDefaultDevice") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto id_it = arguments->find(flutter::EncodableValue("id"));
      if (id_it != arguments->end()) {
        std::string id = std::get<std::string>(id_it->second);
        result->Success(flutter::EncodableValue(SetDefaultDevice(id)));
        return;
      }
    }
    result->Error("INVALID_ARGUMENTS", "Expected 'id' in arguments");
  } else if (method_call.method_name() == "setVolume") {
     result->Success();
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableValue AudioManager::GetOutputDevices() {
  flutter::EncodableList devices;
  
  ComPtr<IMMDeviceEnumerator> enumerator;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) return flutter::EncodableValue(devices);

  ComPtr<IMMDeviceCollection> collection;
  hr = enumerator->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, &collection);
  if (FAILED(hr)) return flutter::EncodableValue(devices);

  UINT count;
  collection->GetCount(&count);

  ComPtr<IMMDevice> default_device;
  enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &default_device);
  LPWSTR default_id_w = nullptr;
  if (default_device) default_device->GetId(&default_id_w);

  for (UINT i = 0; i < count; i++) {
    ComPtr<IMMDevice> device;
    collection->Item(i, &device);

    LPWSTR id_w;
    device->GetId(&id_w);
    
    auto ConvertWideToUtf8 = [](LPWSTR wstr) -> std::string {
        if (!wstr) return "";
        int size = WideCharToMultiByte(CP_UTF8, 0, wstr, -1, nullptr, 0, nullptr, nullptr);
        std::string str(size, 0);
        WideCharToMultiByte(CP_UTF8, 0, wstr, -1, &str[0], size, nullptr, nullptr);
        str.resize(size - 1);
        return str;
    };

    std::string id = ConvertWideToUtf8(id_w);

    ComPtr<IPropertyStore> properties;
    device->OpenPropertyStore(STGM_READ, &properties);
    
    PROPVARIANT name_var;
    PropVariantInit(&name_var);
    properties->GetValue(PKEY_Device_FriendlyName, &name_var);
    std::string name = ConvertWideToUtf8(name_var.pwszVal);
    PropVariantClear(&name_var);

    flutter::EncodableMap device_map;
    device_map[flutter::EncodableValue("id")] = flutter::EncodableValue(id);
    device_map[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
    device_map[flutter::EncodableValue("isDefault")] = flutter::EncodableValue(default_id_w && wcscmp(id_w, default_id_w) == 0);
    
    devices.push_back(flutter::EncodableValue(device_map));
    CoTaskMemFree(id_w);
  }
  if (default_id_w) CoTaskMemFree(default_id_w);

  return flutter::EncodableValue(devices);
}

bool AudioManager::SetDefaultDevice(const std::string& device_id) {
  std::cout << "[AudioManager] Switching to: " << device_id.substr(0, 30) << "..." << std::endl;
  
  _bstr_t bstr_id(device_id.c_str());
  const CLSID* clsids[] = { &CLSID_PolicyConfig1, &CLSID_PolicyConfig2 };
  const IID* iids[] = { &IID_IPolicyConfig1, &IID_IPolicyConfig2, &IID_IPolicyConfig3 };

  for (const CLSID* clsid : clsids) {
    for (const IID* iid : iids) {
      ComPtr<IPolicyConfig> policy_config;
      HRESULT hr = CoCreateInstance(*clsid, nullptr, CLSCTX_ALL, *iid, &policy_config);
      if (SUCCEEDED(hr)) {
        hr = policy_config->SetDefaultEndpoint((const wchar_t*)bstr_id, eMultimedia);
        if (SUCCEEDED(hr)) {
          policy_config->SetDefaultEndpoint((const wchar_t*)bstr_id, eCommunications);
          std::cout << "  SUCCESS (CLSID type " << (clsid == &CLSID_PolicyConfig1 ? "1" : "2") << ")" << std::endl;
          return true;
        }
      }
    }
  }

  std::cerr << "  FAILED: All combinations failed." << std::endl;
  return false;
}
