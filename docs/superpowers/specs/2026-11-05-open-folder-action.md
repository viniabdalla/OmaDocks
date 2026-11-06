# macOS-style Open in File Manager action

Approved in chat on 2026-11-05 after reviewing macOS Fan and Apple Grid screenshots.

Fan always ends with a curved arrow inside a circle and “Open in File Manager”, replacing Show all, including small and empty folders. Reserve space for that action within the existing screen-height limit. Grid includes the same action as its last scrolling cell, also reachable by keyboard. Clicking opens the currently displayed folder through the existing controller and closes the stack. Remove this action from the right-click menu; retain the other settings and the existing List action. Keep existing files, transfers and appearance settings. Do not start or restart the dock.

Use a shared, independently drawn QML arrow icon. Reuse existing delegates and signals rather than a separate toolbar. Sources: https://blog.alexbeals.com/images/screenshot-folder-in-dock/3.png and https://help.apple.com/assets/62A8ED2F99A5D0045E612A42/62A8ED3DCA32D1047032C8FF/en_GB/8ddd7ae2c69629f600f896acfb2eafbc.png .
