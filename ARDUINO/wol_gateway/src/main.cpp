#include <Arduino.h>
#include <ArduinoJson.h>
#include <LittleFS.h>
#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

#include "secrets.h"

namespace {
constexpr uint16_t WOL_PORT = 9;
constexpr size_t MAX_DEVICES = 32;
constexpr unsigned long WIFI_RETRY_MS = 10000;
constexpr unsigned long MQTT_RETRY_MS = 10000;

WiFiClientSecure tlsClient;
PubSubClient mqtt(tlsClient);
WiFiUDP udp;
unsigned long lastWiFiAttempt = 0;
unsigned long lastMqttAttempt = 0;
String commandTopic;
String configTopic;
String statusTopic;

struct Target {
  String id;
  String name;
  String mac;
  IPAddress broadcast;
};

Target targets[MAX_DEVICES];
size_t targetCount = 0;
StaticJsonDocument<4096> configurationDocument;

bool parseMac(const String &text, uint8_t output[6]) {
  unsigned int octets[6];
  if (sscanf(text.c_str(), "%x:%x:%x:%x:%x:%x", &octets[0], &octets[1],
             &octets[2], &octets[3], &octets[4], &octets[5]) != 6) {
    return false;
  }
  for (size_t i = 0; i < 6; ++i) {
    if (octets[i] > 0xFF) return false;
    output[i] = static_cast<uint8_t>(octets[i]);
  }
  return true;
}

bool sendMagicPacket(const Target &target) {
  uint8_t mac[6];
  if (!parseMac(target.mac, mac)) return false;

  uint8_t packet[102];
  memset(packet, 0xFF, 6);
  for (size_t repeat = 0; repeat < 16; ++repeat) {
    memcpy(packet + 6 + repeat * 6, mac, 6);
  }

  if (!udp.beginPacket(target.broadcast, WOL_PORT)) return false;
  if (udp.write(packet, sizeof(packet)) != sizeof(packet)) {
    udp.endPacket();
    return false;
  }
  return udp.endPacket() == 1;
}

void publishStatus(const char *event, const char *target = nullptr) {
  if (!mqtt.connected()) return;
  StaticJsonDocument<256> doc;
  doc["event"] = event;
  if (target != nullptr) doc["target"] = target;
  doc["rssi"] = WiFi.RSSI();
  doc["uptime"] = millis() / 1000;
  char payload[256];
  const size_t length = serializeJson(doc, payload, sizeof(payload));
  mqtt.publish(statusTopic.c_str(), reinterpret_cast<const uint8_t *>(payload),
               length, false);
}

bool loadTargets(JsonDocument &doc) {
  JsonArray list = doc["targets"].as<JsonArray>();
  if (list.isNull() || list.size() > MAX_DEVICES) return false;

  Target staged[MAX_DEVICES];
  size_t count = 0;
  for (JsonObject item : list) {
    const char *id = item["id"] | "";
    const char *name = item["name"] | "";
    const char *mac = item["mac"] | "";
    const char *broadcast = item["broadcast"] | "";
    uint8_t macBytes[6];
    IPAddress broadcastIp;
    if (strlen(id) == 0 || strlen(name) == 0 || !parseMac(mac, macBytes) ||
        !broadcastIp.fromString(broadcast)) {
      return false;
    }
    staged[count++] = {id, name, mac, broadcastIp};
  }
  memcpy(targets, staged, sizeof(Target) * count);
  targetCount = count;
  return true;
}

bool saveConfiguration(const uint8_t *payload, size_t length) {
  File file = LittleFS.open("/targets.json.tmp", FILE_WRITE);
  if (!file) return false;
  const bool ok = file.write(payload, length) == length;
  file.close();
  if (!ok) {
    LittleFS.remove("/targets.json.tmp");
    return false;
  }
  LittleFS.remove("/targets.json");
  return LittleFS.rename("/targets.json.tmp", "/targets.json");
}

void applyConfiguration(const uint8_t *payload, size_t length) {
  configurationDocument.clear();
  if (deserializeJson(configurationDocument, payload, length) ||
      !loadTargets(configurationDocument) ||
      !saveConfiguration(payload, length)) {
    publishStatus("config_rejected");
    return;
  }
  publishStatus("config_applied");
}

void loadSavedConfiguration() {
  File file = LittleFS.open("/targets.json", FILE_READ);
  if (!file) return;
  configurationDocument.clear();
  if (!deserializeJson(configurationDocument, file)) {
    loadTargets(configurationDocument);
  }
  file.close();
}

void handleCommand(const uint8_t *payload, size_t length) {
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, payload, length)) {
    publishStatus("command_rejected");
    return;
  }
  const char *targetId = doc["target"] | "";
  for (size_t i = 0; i < targetCount; ++i) {
    if (targets[i].id == targetId) {
      publishStatus(sendMagicPacket(targets[i]) ? "wol_sent" : "wol_failed", targetId);
      return;
    }
  }
  publishStatus("target_unknown", targetId);
}

void onMqttMessage(char *topic, uint8_t *payload, unsigned int length) {
  if (String(topic) == configTopic) applyConfiguration(payload, length);
  if (String(topic) == commandTopic) handleCommand(payload, length);
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED || millis() - lastWiFiAttempt < WIFI_RETRY_MS) return;
  lastWiFiAttempt = millis();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void connectMqtt() {
  if (WiFi.status() != WL_CONNECTED || mqtt.connected() ||
      millis() - lastMqttAttempt < MQTT_RETRY_MS) return;
  lastMqttAttempt = millis();
  if (mqtt.connect(DEVICE_ID, MQTT_USERNAME, MQTT_PASSWORD,
                   statusTopic.c_str(), 1, true, "{\"event\":\"offline\"}")) {
    mqtt.subscribe(commandTopic.c_str(), 1);
    mqtt.subscribe(configTopic.c_str(), 1);
    publishStatus("online");
  }
}
}  // namespace

void setup() {
  Serial.begin(115200);
  LittleFS.begin(true);
  loadSavedConfiguration();
  commandTopic = "wol/" + String(DEVICE_ID) + "/command";
  configTopic = "wol/" + String(DEVICE_ID) + "/config";
  statusTopic = "wol/" + String(DEVICE_ID) + "/status";
  tlsClient.setCACert(MQTT_ROOT_CA);
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(onMqttMessage);
  mqtt.setBufferSize(4096);
  WiFi.mode(WIFI_STA);
  connectWiFi();
}

void loop() {
  connectWiFi();
  connectMqtt();
  mqtt.loop();
}
