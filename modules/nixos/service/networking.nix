{ pkgs, ... }:
{
  networking.networkmanager.enable = true;
  # as with default networking conf it's impossible connecting to a network
  # with username + password, stuff below fixes the issue
  # (found somewhere on the internet idk what it does / some networking magic)
  systemd.services.wpa_supplicant.environment.OPENSSL_CONF = pkgs.writeText "openssl.cnf" ''
    openssl_conf = openssl_init
    [openssl_init]
    ssl_conf = ssl_sect
    [ssl_sect]
    system_default = system_default_sect
    [system_default_sect]
    Options = UnsafeLegacyRenegotiation
    [system_default_sect]
    CipherString = Default:@SECLEVEL=0
  '';
}
