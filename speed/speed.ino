#include <WiFi.h>
#include <WebSocketsClient.h>
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 5    // SDA Pin for RFID
#define RST_PIN 22  // RST Pin for RFID
#define BUZZER_PIN 4 // GPIO pin for Buzzer

MFRC522 mfrc522(SS_PIN, RST_PIN); // Create MFRC522 instance

const char* ssid = "ana";
const char* password = "12345678";
// Replace with your server IP (e.g., "192.168.1.100")
const char* websocket_host = "192.168.43.9"; 
const uint16_t websocket_port = 3000;     // WebSocket server port
const char* websocket_url = "/";          // WebSocket URL path

WebSocketsClient webSocket;

unsigned long lastPingTime = 0;
const unsigned long pingInterval = 30000; // 30 seconds

void setup() {
  Serial.begin(115200);
  SPI.begin();        // Init SPI bus
  mfrc522.PCD_Init(); // Init MFRC522

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW); // Ensure buzzer is off initially

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  connectWebSocket();
}

void loop() {
  webSocket.loop();
  if (millis() - lastPingTime > pingInterval) {
    webSocket.sendPing();
    lastPingTime = millis();
  }
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    String rfid_tag = "";
    for (byte i = 0; i < mfrc522.uid.size; i++) {
      rfid_tag += String(mfrc522.uid.uidByte[i], HEX);
    }
    Serial.println("RFID Tag: " + rfid_tag);
    webSocket.sendTXT(rfid_tag);
    soundBuzzer();
    delay(1000); // Avoid multiple reads
  }
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.println("Disconnected from WebSocket server");
      connectWebSocket();
      break;
    case WStype_CONNECTED:
      Serial.println("Connected to WebSocket server");
      break;
    case WStype_TEXT:
      Serial.printf("Message from server: %s\n", payload);
      break;
    case WStype_PING:
      webSocket.sendPing();
      break;
    case WStype_PONG:
      Serial.println("Pong received");
      break;
  }
}

void connectWebSocket() {
  webSocket.begin(websocket_host, websocket_port, websocket_url, "arduino");
  webSocket.onEvent(webSocketEvent);
}

void soundBuzzer() {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(500); // Buzzer sound duration
  digitalWrite(BUZZER_PIN, LOW);
}