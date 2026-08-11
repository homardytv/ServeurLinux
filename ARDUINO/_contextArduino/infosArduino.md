# Contexte de reprise — passerelle Wake-on-LAN ESP32

## État

- Le projet `wol_gateway` est compilé avec succès pour `esp32dev`.
- Il reçoit des commandes MQTT TLS puis envoie des paquets Wake-on-LAN UDP.
- La liste blanche de 32 machines au maximum est mise à jour via une
  configuration MQTT retenue, conservée dans LittleFS.

## Prérequis et règles

- L'ESP32 D1 R32 reste connecté au Wi-Fi, sur le même réseau IP que les
  machines Ethernet ; l'isolation Wi-Fi doit être désactivée.
- Un relais MQTT public avec TLS, authentification et ACL minimales est requis.
- Les identifiants Wi-Fi, MQTT et le certificat d'autorité sont uniquement dans
  `wol_gateway/include/secrets.h`, ignoré par Git.
- Ne pas désactiver la validation TLS ni exposer de serveur entrant sur l'ESP32.

## Livrables

- `wol_gateway/src/main.cpp` : firmware ESP32.
- `wol_gateway/README.md` : installation, sujets MQTT et format de la liste.
- `wol_gateway/platformio.ini` : build PlatformIO et dépendances.

## Décisions et blocage

- Un relais MQTT hébergé est retenu afin que le serveur Linux puisse être
  éteint.
- Le firmware ne doit pas être téléversé avant que `secrets.h` soit renseigné.

## Prochaine action

Configurer le relais MQTT TLS et `secrets.h`, puis téléverser sur l'ESP32 et
tester le réveil d'une machine Ethernet.
