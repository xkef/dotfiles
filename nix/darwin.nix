# macOS system: nix-darwin owns the system settings, the login shell, and
# the Homebrew casks. home-manager (nix/home.nix) owns the user's files.
# Apply with `dots switch`, which runs `darwin-rebuild switch`.
{ pkgs, settings, ... }:
let
  home = "/Users/${settings.user}";
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = settings.user;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # nix-darwin manages the login shell only for users it knows by uid.
  users.knownUsers = [ settings.user ];
  users.users.${settings.user} = {
    inherit home;
    uid = settings.uid;
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # GUI apps start from launchd, not from a shell, so WezTerm would find
  # neither zoxide nor the overlay tools without this PATH.
  launchd.user.envVariables.PATH = builtins.concatStringsSep ":" [
    "${home}/.local/bin"
    "/etc/profiles/per-user/${settings.user}/bin"
    "/run/current-system/sw/bin"
    "/opt/homebrew/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  # nix-homebrew installs Homebrew itself and takes over an existing
  # install. Homebrew holds the GUI apps and the few tools nixpkgs lags on.
  # cleanup = "uninstall" removes anything not listed here, so Homebrew
  # matches this file after every switch.
  nix-homebrew = {
    enable = true;
    user = settings.user;
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    brews = [
      "nono" # sandbox for AI agents; the profiles need 0.75+, nixpkgs has 0.74
    ];
    casks = [
      "codex" # OpenAI Codex CLI (shipped as a cask)
      "wezterm@nightly" # terminal and multiplexer (no stable release since 2024-02)
      "zed" # GPU-accelerated code editor
      "neovide-app" # GUI client for Neovim
      "1password" # password manager
      "1password-cli" # 1Password CLI (op)
      "dockdoor" # Dock previews and window switcher
      "firefox@developer-edition" # Firefox Developer Edition browser
      "handy" # offline speech-to-text app
      "hiddenbar" # hide menu bar icons
      "rectangle" # window snapping via keyboard
    ];
  };

  # CapsLock sends Escape.
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      # Typing and input
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 3;

      # Finder, dialogs, and windows
      AppleShowAllExtensions = true;
      NSNavPanelExpandedStateForSaveMode = true;
      PMPrintingExpandedStateForPrint = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSWindowResizeTime = 0.001;

      # Trackpad and sound
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.swipescrolldirection" = false;
      "com.apple.trackpad.scaling" = 2.0;
      AppleEnableSwipeNavigateWithScrolls = false;
      "com.apple.sound.beep.feedback" = 0;
    };

    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "Nlsv";
      FXEnableExtensionChangeWarning = false;
      NewWindowTarget = "Home";
      ShowRemovableMediaOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      QuitMenuItem = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;
      show-recents = false;
      mru-spaces = false;
      launchanim = false;
      expose-animation-duration = 0.1;
      tilesize = 36;
      expose-group-apps = true;
      minimize-to-application = true;
      wvous-br-corner = 1;
    };

    WindowManager = {
      GloballyEnabled = false;
      EnableTiledWindowMargins = false;
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableStandardClickToShowDesktop = false;
      StandardHideDesktopIcons = true;
      HideDesktop = true;
    };

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    screencapture = {
      disable-shadow = true;
      type = "png";
      location = "${home}/Pictures/Screenshots";
    };

    trackpad.Clicking = true;

    ActivityMonitor = {
      OpenMainWindow = true;
      IconType = 5;
      ShowCategory = 100;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    # Settings without a nix-darwin option.
    CustomUserPreferences = {
      NSGlobalDomain = {
        TSMLanguageIndicatorEnabled = false;
        AppleICUForce24HourTime = true;
        AppleLocale = "en_US@rg=chzzzz";
        NSGlassTintAmount = 1.0;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint2 = true;
        "com.apple.sound.uiaudio.enabled" = 0;
      };
      "com.apple.finder" = {
        FXPreferredGroupBy = "Kind";
        FXArrangeGroupViewBy = "Name";
        NewWindowTargetPath = "file://${home}/";
        ShowRecentTags = false;
        DisableAllAnimations = true;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Spotlight searches apps, settings, and quick answers only, on
      # Cmd-Space.
      "com.apple.Spotlight".orderedItems =
        map
          (name: {
            inherit name;
            enabled = 1;
          })
          [
            "APPLICATIONS"
            "SYSTEM_PREFS"
            "MENU_CONVERSION"
            "MENU_DEFINITION"
            "MENU_EXPRESSION"
          ]
        ++
          map
            (name: {
              inherit name;
              enabled = 0;
            })
            [
              "BOOKMARKS"
              "CONTACT"
              "DIRECTORIES"
              "DOCUMENTS"
              "EVENT_TODO"
              "FONTS"
              "IMAGES"
              "MESSAGES"
              "MOVIES"
              "MUSIC"
              "MENU_OTHER"
              "PDF"
              "PRESENTATIONS"
              "SOURCE"
              "SPREADSHEETS"
              "MENU_SPOTLIGHT_SUGGESTIONS"
            ];
      "com.apple.symbolichotkeys".AppleSymbolicHotKeys."64" = {
        enabled = true;
        value = {
          parameters = [
            32
            49
            1048576
          ];
          type = "standard";
        };
      };
      "com.apple.print.PrintingPrefs"."Quit When Finished" = true;
      "com.apple.menuextra.clock".ShowDate = 0;
      "com.apple.TextEdit" = {
        RichText = 0;
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
        ConfigDataInstall = 1;
      };
      "com.apple.commerce".AutoUpdate = true;
    };
  };
}
