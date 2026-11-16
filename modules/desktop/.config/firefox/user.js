// Firefox Developer Edition look. dots apply links this file into the
// profile, and Firefox applies it at every startup, over the prefs that
// Firefox Sync brings. A change made in the browser lasts until the next
// restart, so change this file instead.

// Toolbars -------------------------------------------------------------

// Every extension button sits in the extensions menu, and the rest of
// the buttons sit in the overflow menu. Firefox fills in the fields this
// layout leaves out. An extension missing from the layout gets its
// button back at every startup. A string in single quotes can span lines
// and needs no escaped double quotes.
user_pref("browser.uiCustomization.state", '{
  "placements": {
    "TabsToolbar": ["tabbrowser-tabs", "new-tab-button"],
    "nav-bar": [
      "sidebar-button",
      "back-button",
      "vertical-spacer",
      "forward-button",
      "urlbar-container",
      "unified-extensions-button",
      "reset-pbm-toolbar-button"
    ],
    "widget-overflow-fixed-list": [
      "firefox-view-button",
      "profiler-button",
      "developer-button",
      "fxa-toolbar-menu-button",
      "downloads-button"
    ],
    "unified-extensions-area": [
      "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action",
      "ublock0_raymondhill_net-browser-action",
      "jid1-mnnxcxisbpnsxq_jetpack-browser-action",
      "sponsorblocker_ajay_app-browser-action",
      "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
    ]
  },
  "currentVersion": 28
}');
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("extensions.unifiedExtensions.button.always_visible", true);

// Sidebar --------------------------------------------------------------

user_pref("sidebar.visibility", "hide-on-close");
user_pref("sidebar.main.tools", "aichat,syncedtabs,history,bookmarks,passwords");
user_pref("browser.ml.chat.provider", "https://claude.ai/new");

// New tabs -------------------------------------------------------------

user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.homepage", "chrome://browser/content/blanktab.html");

// Clutter --------------------------------------------------------------

// Hides the suggestions, counters, and warnings that Firefox adds to
// the address bar and pages.
user_pref("browser.urlbar.trackerCount.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.suggest.trending", false);
user_pref("browser.ml.chat.shortcuts", false);
user_pref("full-screen-api.warning.timeout", 0);
user_pref("browser.aboutConfig.showWarning", false);

// Reader view ----------------------------------------------------------

user_pref("reader.content_width", 5);
user_pref("reader.font_size", 9);
user_pref("reader.line_height", 3);
