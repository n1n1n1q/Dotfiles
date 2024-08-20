{
  programs.git = {
    enable = true;
    userName  = "Oleh Basystyi";
    userEmail = "basystyo@gmail.com";
    extraConfig = {
      credential.helper = "store";
    };
  };
}