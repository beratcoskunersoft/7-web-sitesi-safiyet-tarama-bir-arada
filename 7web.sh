#!/bin/bash

# Renk tanımları
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear

pause() {
  echo -e "${CYAN}Devam etmek için ENTER'a basın...${NC}"
  read -r
}

loading_animation() {
  for i in {1..5}; do
    echo -ne "${YELLOW}Taranıyor${i}... \r${NC}"
    sleep 0.5
  done
  echo -ne "\n"
}

show_menu() {
  echo -e "${GREEN}1) Tarama Başlat"
  echo "2) Raporları Göster"
  echo "3) Ayarlar"
  echo "4) Yardım"
  echo -e "5) Çıkış${NC}"
}

validate_domain() {
  if [[ $1 =~ ^https?:// ]]; then
    return 0
  else
    echo -e "${RED}Hata: URL 'http://' veya 'https://' ile başlamalı!${NC}"
    return 1
  fi
}

start_scan() {
  read -p "Tarama için hedef domain (http/https ile): " TARGET

  if ! validate_domain "$TARGET"; then
    return
  fi

  OUTDIR="raporlar/$(echo "$TARGET" | sed 's|https\?://||' | sed 's|/|-|g')_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$OUTDIR"

  echo -e "${YELLOW}[1/6] WhatWeb ile teknoloji keşfi başlıyor...${NC}"
  loading_animation
  whatweb -v "$TARGET" > "$OUTDIR/whatweb_en.txt"
  echo "Hedef teknolojiler:" > "$OUTDIR/whatweb_tr.txt"
  whatweb -v "$TARGET" | while IFS= read -r line; do echo "- $line" >> "$OUTDIR/whatweb_tr.txt"; done
  echo -e "${GREEN}WhatWeb tamamlandı.${NC}\n"

  echo -e "${YELLOW}[2/6] Nikto ile sunucu zafiyetleri taranıyor...${NC}"
  loading_animation
  nikto -h "$TARGET" > "$OUTDIR/nikto_en.txt"
  echo -e "${GREEN}Nikto tamamlandı.${NC}\n"

  echo -e "${YELLOW}[3/6] Wapiti ile uygulama güvenlik taraması...${NC}"
  loading_animation
  wapiti -u "$TARGET" -f html -o "$OUTDIR/wapiti_report.html"
  echo -e "${GREEN}Wapiti raporu oluşturuldu.${NC}\n"

  echo -e "${YELLOW}[4/6] Dirsearch ile gizli dizinler aranıyor...${NC}"
  loading_animation
  dirsearch -u "$TARGET" -e php,html,txt,conf -o "$OUTDIR/dirsearch_en.txt"
  echo -e "${GREEN}Dirsearch tamamlandı.${NC}\n"

  HOST=$(echo "$TARGET" | awk -F/ '{print $3}')
  echo -e "${YELLOW}[5/6] Nmap ile port ve servis taraması yapılıyor...${NC}"
  loading_animation
  nmap -sV --script vuln "$HOST" -oN "$OUTDIR/nmap_vuln_en.txt"
  echo -e "${GREEN}Nmap taraması tamamlandı.${NC}\n"

  if whatweb "$TARGET" | grep -iq wordpress; then
    echo -e "${YELLOW}[6/6] WPScan ile WordPress zafiyetleri kontrol ediliyor...${NC}"
    loading_animation
    wpscan --url "$TARGET" --enumerate vp --no-update --output "$OUTDIR/wpscan_en.txt"
    echo -e "${GREEN}WPScan tamamlandı.${NC}\n"
  else
    echo -e "${YELLOW}WordPress bulunamadı, WPScan atlandı.${NC}\n"
  fi

  echo -e "${GREEN}✨ Tüm taramalar tamamlandı! Raporlar klasörü: $OUTDIR${NC}"
  pause
}

show_reports() {
  echo -e "${CYAN}Raporlar 'raporlar/' klasöründe kayıtlıdır.${NC}"
  pause
}

show_settings() {
  echo -e "${CYAN}Ayarlar özelliği henüz eklenmedi.${NC}"
  pause
}

show_help() {
  echo -e "${CYAN}
1 - Tarama başlatır.
2 - Rapor klasörünü gösterir.
3 - Ayarları gösterir.
4 - Yardım menüsünü açar.
5 - Programdan çıkar.
${NC}"
  pause
}

clear
figlet "TR YASIN" | lolcat
echo -e "${YELLOW}TikTok: Berat_bey.exe${NC}\n"

while true; do
  show_menu
  read -p "Seçiminizi yapın [1-5]: " choice

  case $choice in
    1) start_scan ;;
    2) show_reports ;;
    3) show_settings ;;
    4) show_help ;;
    5) echo -e "${RED}Çıkış yapılıyor...${NC}"; exit 0 ;;
    *) echo -e "${RED}Geçersiz seçim! Tekrar deneyin.${NC}"; sleep 1 ;;
  esac
done
