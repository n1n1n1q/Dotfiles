{ pkgs, ... }:

{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    # size = 52;
    package = pkgs.bibata-cursors;
  };
}
