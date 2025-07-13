#!/usr/bin/env bash
#
# network_scan.sh — Escanea tu red local y muestra las IPs conectadas
#

# Comprueba dependencias
for cmd in ip nmap arp-scan; do
  if ! command -v "${cmd}" &>/dev/null; then
    MISSING+=("${cmd}")
  fi
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "ERROR: Faltan las siguientes herramientas: ${MISSING[*]}"
  echo "Instálalas con: sudo apt install nmap arp-scan iproute2"
  exit 1
fi

# 1. Detectar interfaz y red local
DEFAULT_IF=$(ip route show default | awk '/default/ {print $5; exit}')
CIDR=$(ip -o -f inet addr show dev "${DEFAULT_IF}" \
       | awk '{print $4}' | head -n1)
if [ -z "${CIDR}" ]; then
  echo "No se pudo determinar la red local."
  exit 1
fi

echo "Interfaz: ${DEFAULT_IF}"
echo "Red detectada: ${CIDR}"
echo

# 2. Escaneo con arp-scan (más rápido en LAN)
echo "Escaneando con arp-scan…"
sudo arp-scan --localnet -I "${DEFAULT_IF}" \
  | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1 "\t" $2}' \
  > /tmp/hosts_arp.txt

# 3. Escaneo con nmap (ICMP ping sweep) como alternativa
echo "Escaneando con nmap (ping-scan)…"
nmap -sn "${CIDR}" \
  | awk '/Nmap scan report for/ {print $5}' \
  > /tmp/hosts_nmap.txt

# 4. Mostrar resultados
echo
echo "=== Resultados de arp-scan ==="
column -t /tmp/hosts_arp.txt || cat /tmp/hosts_arp.txt

echo
echo "=== Resultados de nmap ==="
cat /tmp/hosts_nmap.txt

# Limpieza
rm -f /tmp/hosts_arp.txt /tmp/hosts_nmap.txt

exit 0
