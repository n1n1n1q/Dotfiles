#!/bin/bash
theme_path="/usr/share/sddm/themes/corners/theme.conf"
color1=$(cat ~/.cache/wal/colors | sed -n '1p')
color2=$(cat ~/.cache/wal/colors | sed -n '2p')
color3=$(cat ~/.cache/wal/colors | sed -n '3p')
bg="$HOME/.cache/currbg"
sudo cp $bg /usr/share/sddm/themes/corners/backgrounds/

sudo sed -i "66c\\InputColor=$color1" $theme_path
sudo sed -i "80c\\LoginButtonTextColor=$color1" $theme_path
sudo sed -i "92c\\PopupActiveColor=$color1" $theme_path
sudo sed -i "104c\\SessionIconColor=$color1" $theme_path
sudo sed -i "106c\\PowerIconColor=$color1" $theme_path

sudo sed -i "48c\\UserColor=$color2" $theme_path
sudo sed -i "67c\\InputTextColor=$color2" $theme_path
sudo sed -i "93c\\PopupActiveTextColor=$color2" $theme_path
sudo sed -i "123c\\DateColor=$color2" $theme_path
sudo sed -i "129c\\TimeColor=$color2" $theme_path

sudo sed -i "47c\\UserBorderColor=$color3" $theme_path
sudo sed -i "69c\\InputBorderColor=$color3" $theme_path
sudo sed -i "82c\\LoginButtonColor=$color3" $theme_path
sudo sed -i "91c\\PopupColor=$color3" $theme_path
sudo sed -i "103c\\SessionButtonColor=$color3" $theme_path
sudo sed -i "105c\\PowerButtonColor=$color3" $theme_path

sudo sed -i '25c\\BgSource="backgrounds/currbg"' $theme_path
