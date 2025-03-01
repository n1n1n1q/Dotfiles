{ config, pkgs, ... }:
{

  home.file = {
    ".config/rofi/config.rasi" = {
      text = ''
        * {
            active-background: #3f4b65;
            urgent-background: #6299AF;

            background: #3f4b65;
            foreground: #e2e0df;

            bg: @background;
            fg: @foreground;
            bgt: #3f4b6595;
            active: @active-background;
            urgent: @urgent-background;
            selected-bg: @bg;
            selected-fg: @fg;
            t: transparent;
        }
        configuration{
            modes: "window,drun,run,ssh";
            font: "JetBrainsMono NF 18";
            drun-display-format: "{name}";
        }
        window {
            fullscreen: true;
            padding: 35% 30%;       // you might want to ajust these to resize rofi.
            transparency: "real";
            background-color: @bgt;
            border-color: @t;
        }

        listview {
            border: 0 0 0 0;
            padding: 23 0 0;
            scrollbar: true;
        }

        scrollbar {
            width:        4px;
            border:       0;
            handle-color: @fg;
            handle-width: 8px;
            padding:      0 5;
        }

        entry {
            placeholder: "";
        }

        // less interesting stuff {{{

        // using elements from:
        // https://github.com/bardisty/gruvbox-rofi/blob/master/gruvbox-common.rasi

        textbox {
            text-color: @fg;
        }

        element {
            border:  0;
            padding: 2px;
        }
        element.normal.normal {
            background-color: @t;
            text-color:       @fg;
        }
        element.normal.urgent {
            background-color: @t;
            text-color:       @urgent;
        }
        element.normal.active {
            background-color: @t;
            text-color:       @active;
        }
        element.selected.normal {
            background-color: @selected-bg;
            text-color:       @selected-fg;
        }
        element.selected.urgent {
            background-color: @selected-bg;
            text-color:       @urgent;
        }
        element.selected.active {
            background-color: @selected-bg;
            text-color:       @selected-fg;
        }
        element.alternate.normal {
            background-color: @t;
            text-color:       @fg;
        }
        element.alternate.urgent {
            background-color: @t;
            text-color:       @urgent;
        }
        element.alternate.active {
            background-color: @t;
            text-color:       @active;
        }

        sidebar {
            border:       2px 0 0;
            border-color: @fg;
        }

        inputbar {
            spacing:    0;
            text-color: @fg;
            padding:    2px;
            children:   [ prompt, textbox-prompt-sep, entry, case-indicator ];
        }

        case-indicator,
        entry,
        prompt,
        button {
            spacing:    0;
            text-color: @fg;
        }

        button.selected {
            background-color: @bg;
            text-color:       @fg;
        }

        textbox-prompt-sep {
            expand:     false;
            str:        ":";
            text-color: @fg;
            margin:     0 0.3em 0 0;
        }
      '';
    };
    ".config/wal/templates/rofi.rasi" = {
      text = ''
        * {{
            active-background: {color2};
            urgent-background: {color1};

            background: {background};
            foreground: {foreground};

            bg: @background;
            fg: @foreground;
            bgt: {background}95;
            active: @active-background;
            urgent: @urgent-background;
            selected-bg: @bg;
            selected-fg: @fg;
            t: transparent;
        }}
      '';
    };
  };
}
