# Passerelle Wake-on-LAN ESP32

L'ESP32 reste allumé et connecté au Wi-Fi. Il reçoit des commandes MQTT sur
Internet puis envoie un paquet Wake-on-LAN UDP sur le réseau local. Les PC
peuvent donc rester en Ethernet ; l'ESP32 doit seulement être sur le même
réseau IP, sans isolation Wi-Fi activée.

## Sécurité et architecture

Le relais MQTT doit être accessible publiquement **en TLS**. L'ESP32 initie la
connexion : aucun port entrant n'est ouvert dans le réseau local. Désactivez
les connexions anonymes et créez des autorisations minimales :

- l'ESP32 publie seulement `wol/<DEVICE_ID>/status` ;
- l'ESP32 s'abonne seulement à `wol/<DEVICE_ID>/command` et
  `wol/<DEVICE_ID>/config` ;
- le client de l'interface mobile publie seulement sur ces deux derniers
  sujets et s'abonne à `status`.

## Installation

1. Installez PlatformIO dans VS Code.
2. Copiez `include/secrets.example.h` vers `include/secrets.h` et renseignez
   le Wi-Fi, le relais MQTT, son certificat d'autorité et les identifiants.
3. Compilez avec `pio run`. Le téléversement matériel reste à confirmer.

## Machines à réveiller

Publiez ce JSON retenu (*retained*) sur `wol/<DEVICE_ID>/config` pour ajouter
ou modifier des machines. `id` est utilisé par les commandes et doit être
unique. L'adresse `broadcast` est normalement l'adresse de diffusion du LAN,
par exemple `192.168.1.255`, et non l'adresse IP du PC.

```json
{
  "targets": [
    {
      "id": "serveur-linux",
      "name": "Serveur Linux",
      "mac": "AA:BB:CC:DD:EE:FF",
      "broadcast": "192.168.1.255"
    },
    {
      "id": "pc-bureau",
      "name": "PC bureau",
      "mac": "11:22:33:44:55:66",
      "broadcast": "192.168.1.255"
    }
  ]
}
```

Pour réveiller une machine, publiez :

```json
{"target":"serveur-linux"}
```

sur `wol/<DEVICE_ID>/command`. Le résultat apparaît sur
`wol/<DEVICE_ID>/status`.

## Prérequis Wake-on-LAN

Activez Wake-on-LAN dans le BIOS/UEFI et dans le pilote réseau de chaque
machine. L'interface Ethernet doit rester alimentée en veille ou arrêt. Testez
d'abord depuis le réseau local. Certains points d'accès bloquent les broadcasts
entre Wi-Fi et Ethernet : désactivez l'isolation des clients Wi-Fi si besoin.
