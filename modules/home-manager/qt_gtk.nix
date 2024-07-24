{pkgs, ...}:

{
  # GTK
  gtk = {
    enable = true;
    theme.package = pkgs.gnome-themes-extra;
    theme.name = "Adwaita-dark";
  };
  
  # QT
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.package = pkgs.adwaita-qt;
    style.name = "adwaita-dark";
  };
}