{ ... }:

{

  home.file = {
    ".config/zed/settings.json" = {
      text = ''
        // Zed settings
        //
        // For information on how to configure Zed, see the Zed
        // documentation: https://zed.dev/docs/configuring-zed
        //
        // To see all of Zed's default settings without changing your
        // custom settings, run the `open default settings` command
        // from the command palette or from `Zed` application menu.
        {
          "theme": "Sandcastle",

          "ui_font_size": 21,
          "buffer_font_size": 21,
          "ui_font_family": "UbuntuNF",
          "buffer_font_family": "CaskaydiaMonoNF-Regular",

          "show_copilot_suggestions": false,
          "notification_panel": {
            "dock": "left"
          },
          "terminal": {
            "dock": "bottom"
          },
          "chat_panel": {
            "dock": "left"
          },
          "collaboration_panel": {
            "dock": "left"
          },
          "project_panel": {
            "dock": "right"
          },
          "features": {
            "copilot": false
          },

          "autosave": {
            "after_delay": {
              "milliseconds": 1000
            }
          },
          "auto_update": false,
          "current_line_highlight": "all",
          "tabs": {
            "close_position": "right",
            "git_status": true
          },
          "format_on_save": "off",
          "show_whitespaces": "selection"
        }
      '';
      executable = false;
    };
  };
}
