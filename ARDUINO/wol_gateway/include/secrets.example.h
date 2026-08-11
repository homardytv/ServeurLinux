#pragma once

// Copier ce fichier vers secrets.h puis renseigner les valeurs locales.
// Ne jamais versionner secrets.h.
#define WIFI_SSID ""
#define WIFI_PASSWORD ""

// Relais MQTT accessible depuis Internet, obligatoirement en TLS.
#define MQTT_HOST ""
#define MQTT_PORT 8883
#define MQTT_USERNAME ""
#define MQTT_PASSWORD ""

// Identifiant stable et unique de cette passerelle, sans espace ni slash.
#define DEVICE_ID "wol-maison"

// Certificat PEM de l'autorité ayant signé le certificat du relais MQTT.
// Une chaîne vide est refusée : la connexion TLS doit vérifier le serveur.
static const char MQTT_ROOT_CA[] = R"EOF(

)EOF";

