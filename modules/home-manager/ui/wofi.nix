{...}:

{
    programs.wofi = {
        enable = true;
        settings = {
            width=490;
            location="center";
            show="drun";
            prompt="";
            filter_rate=100;
            allow_markup=true;
            no_actions=true;
            halign="fill";
            orientation="vertical";
            content_halign="start";
            insensitive=true;
            allow_images=true;
            image_size=34;
            gtk_dark=true;
        };
        style = ''

#window {
    background-color: transparent;
    font-family: "Ubuntu Nerd Font";
    font-size: 18px;
}

#outer-box {
    border-radius: 10px;
    padding: 0 5px;
    background-color: rgba(18, 20, 20, 0.8);
}

#input {
    margin: 10px;
    color: #d6d6d6;
    font-size: 34px;
    background-color: rgba(0, 0, 0, 0);
    border-radius: 30px;
}
#input:focus {
    transition-duration:0.3s;
    background: rgba(255,255,255,0.04);
}

#inner-box {
    color: #d6d6d6;
    margin: 4px;
    border-radius: 10px;
}

#scroll {
    margin: 5px;
    margin-bottom: 5px;
    border-radius: 10px;
}

#text {
    color: #E0E0E0;
    padding-left : 15px;
}
#text:selected {
    color: #ffffff;
}

#entry {
    color: transparent;
    padding: 10px;
    padding-left: 20px;
    margin-bottom: 5px;
    border-radius: 10px;
}
#entry:selected {
    background: rgba(173, 224, 224, 0.2x);
}
        
        '';
    };
}