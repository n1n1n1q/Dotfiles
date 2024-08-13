{pkgs, ...}:

{
  # GTK
  gtk = {
    enable = true;
    theme.package = pkgs.gnome-themes-extra;
    theme.name = "Adwaita-dark";
    font.name = "Ubuntu NF";
    font.size = 15;

    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Modern-Ice";
  };
  # home.pointerCursor.gtk.enable = true;
  
  # QT
  qt = {
    enable = true;
    # platformTheme.name = "adwaita";
    style.package = pkgs.adwaita-qt;
    style.name = "adwaita-dark";
  };
}