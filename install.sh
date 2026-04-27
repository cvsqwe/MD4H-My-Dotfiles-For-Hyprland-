#!/bin/bash

export CLR_G='\033[0;32m'
export CLR_Y='\033[1;33m'
export CLR_R='\033[0;31m'
export CLR_N='\033[0m'

clear
echo "Select language / Выберите язык:"
echo "1) English"
echo "2) Русский"
read -p "Selection (1/2): " lang_choice

if [[ "$lang_choice" == "2" ]]; then
  S_WELCOME="MD4H - Мои конфиги для Hyprland"
  S_STYLE_SEL="Выберите стиль оформления:"
  S_STYLE_1="1) Old style (старый)"
  S_STYLE_2="2) New style (новый)"
  S_STYLE_PROMPT="Ваш выбор (1/2): "
  S_OS_ERR="Этот скрипт предназначен только для Arch-based систем."
  S_AUR_WARN="AUR помощник не найден. Устанавливаю yay..."
  S_NV_WARN="Обнаружена видеокарта NVIDIA. Добавляю пакеты..."
  S_INST_DEP="Установка зависимостей через"
  S_PREP_DIR="Подготовка директорий и бэкап..."
  S_APPLY_CFG="Применение новых конфигов..."
  S_ZSH_CH="Меняю стандартную оболочку на ZSH..."
  S_DONE="Готово! Бэкап старых конфигов лежит в:"
  S_REBOOT_W="Рекомендуется перезагрузить систему."
  S_REBOOT_P="Перезагрузиться сейчас? (y/n): "
  S_PROCEED="Продолжить? (y/n): "
else
  S_WELCOME="MD4H - My Dotfiles for Hyprland"
  S_STYLE_SEL="Select visual style:"
  S_STYLE_1="1) Old style"
  S_STYLE_2="2) New style"
  S_STYLE_PROMPT="Selection (1/2): "
  S_OS_ERR="This script is for Arch-based systems only."
  S_AUR_WARN="AUR helper not found. Installing yay..."
  S_NV_WARN="NVIDIA GPU detected. Adding necessary packages..."
  S_INST_DEP="Installing dependencies via"
  S_PREP_DIR="Preparing directories and backup..."
  S_APPLY_CFG="Applying new configurations..."
  S_ZSH_CH="Changing default shell to ZSH..."
  S_DONE="Done! Backup of old configs is in:"
  S_REBOOT_W="System reboot is recommended."
  S_REBOOT_P="Reboot now? (y/n): "
  S_PROCEED="Proceed? (y/n): "
fi

# Выбор стиля
clear
echo -e "${CLR_Y}${S_STYLE_SEL}${CLR_N}"
echo "$S_STYLE_1"
echo "$S_STYLE_2"
read -p "$S_STYLE_PROMPT" style_choice

if [[ "$style_choice" == "1" ]]; then
  STYLE_DIR="old"
else
  STYLE_DIR="new"
fi

print_status() { echo -e "${CLR_G}[*] $1${CLR_N}"; }
print_warn() { echo -e "${CLR_Y}[!] $1${CLR_N}"; }
print_error() { echo -e "${CLR_R}[ERROR] $1${CLR_N}"; }

clear
echo -e "${CLR_Y}${S_WELCOME} [Загружается: ${STYLE_DIR} style]${CLR_N}"
echo "------------------------------------------"

if [ ! -f /etc/arch-release ]; then
  print_error "$S_OS_ERR"
  exit 1
fi

if command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
else
  print_warn "$S_AUR_WARN"
  sudo pacman -S --needed base-devel git --noconfirm
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay && makepkg -si --noconfirm && cd -
  rm -rf /tmp/yay
  AUR_HELPER="yay"
fi

if lspci | grep -iE 'vga|3d' | grep -iq nvidia; then
  print_warn "$S_NV_WARN"
  PACKAGES_NVIDIA="nvidia-dkms qt5-wayland qt6-wayland libva-nvidia-driver-git"
else
  PACKAGES_NVIDIA=""
fi

PACKAGES="hyprland kitty zsh waybar rofi nvim mako swww nwg-look ttf-jetbrains-mono-nerd ttf-roboto-mono thunar $PACKAGES_NVIDIA"

print_status "$S_INST_DEP $AUR_HELPER..."
$AUR_HELPER -S --needed --noconfirm $PACKAGES

print_status "$S_PREP_DIR"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

CONFIGS=(hypr waybar kitty nvim rofi mako gtk-3.0 gtk-4.0 nwg-look)
for item in "${CONFIGS[@]}"; do
  if [ -d "$HOME/.config/$item" ]; then
    mv "$HOME/.config/$item" "$BACKUP_DIR/" 2>/dev/null
  fi
done

print_status "$S_APPLY_CFG"
mkdir -p ~/.config

# 1. Копируем конфиги (.config)
if [ -d "$STYLE_DIR/config" ]; then
  cp -r "$STYLE_DIR/config/"* ~/.config/
fi

# 2. Копируем скрытые файлы в домашнюю папку (например, .zshrc)
if [ -d "$STYLE_DIR/home" ]; then
  cp -r "$STYLE_DIR/home/".* ~ 2>/dev/null || true
fi

# 3. Копируем обои
if [ -d "$STYLE_DIR/wallpaper" ]; then
  mkdir -p ~/.config/hypr/wallpaper
  cp -r "$STYLE_DIR/wallpaper/"* ~/.config/hypr/wallpaper/
fi

if [[ $SHELL != "/usr/bin/zsh" ]]; then
  print_status "$S_ZSH_CH"
  sudo chsh -s $(which zsh) $USER
fi

print_status "$S_DONE $BACKUP_DIR"
print_warn "$S_REBOOT_W"

read -p "$S_REBOOT_P" reboot_now
if [[ $reboot_now == [yY] ]]; then
  systemctl reboot
fi
