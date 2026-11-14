# StyleCheck: QMacStyle under Liquid Glass

A window with every control the five QMacStyle patches change (`patches/qtbase-macstyle-*.patch`), each next to the same control made with AppKit. A script shoots the window in the light and dark appearance and measures what can be measured without eyes.

## What the window shows

| Section | Patch | What to look at |
|---|---|---|
| QProgressBar | progressbar-liquid-glass | 60 %; 70 of 20…120 (= 50 %); reset: an empty groove; busy; busy, then 30 % a second later; disabled |
| Push buttons | small-pushbutton-margins | regular, small, mini, small with a long title, disabled: the title is centered and not clipped |
| QSpinBox arrows | spinbox-arrows | regular, small, mini, QDoubleSpinBox, disabled: the arrows are entirely inside |
| Check boxes in item views | itemview-checkboxes | table, tree, list: checked, unchecked, partially checked, disabled, on the selected row |
| QLineEdit focus ring | lineedit-focus-ring | the focus ring follows the rounded edit; an edit with its own background, with a placeholder, small, disabled |

The top line of the window shows the Qt version, the style and `Liquid Glass: yes/no`: the patches take effect only with `yes`. An app gets Liquid Glass when it is built against the macOS 26 SDK or later and runs on macOS 26 or later. qmake doesn't put `UIDesignRequiresCompatibility` into the Info.plist, so nothing opts the window out.

## Build and run

Needs Qt 6.8.5 built by this repository (`/usr/local/Qt-6.8.5` by default) and Xcode.

```sh
/usr/local/Qt-6.8.5/bin/qmake && make
```

```sh
./StyleCheck.app/Contents/MacOS/StyleCheck dark
```

`light` or `dark` sets the appearance, without an argument the system one is used. The window also has an appearance switch.

## Automatic check

```sh
./stylecheck.sh [output_dir]
```

The script builds the window and the analyzer when needed (`QMAKE` overrides the qmake path), then for each appearance it starts the window, waits for its report and shoots the window four times 0.25 s apart. The shots, the crops of the sections (`light|dark/sc_group_*.png`, and the table, tree and list separately) and the build log go to `shots/` or to the directory given as the argument.

- The app the script runs from (Terminal and the like) needs the Screen Recording permission, otherwise `screencapture` saves an empty window.
- The window has to become active: an inactive window draws the progress bars gray and without the focus ring. If macOS doesn't give it the focus (you're typing in another window), the script retries up to three times. Better leave the keyboard and mouse alone for 10–15 seconds.

The analyzer prints:

- `fill`: the filled part of a progress bar, the longest row of saturated pixels against the bar width.
- `busy`: the indeterminate bar in each of the four frames, the length of the moving segment and its start, in points. The position has to change.
- `visible`: the visible size of a control in points. Compare the pairs `sc_…` (Qt) and `ns_…` (AppKit) of the same size.

## Reference results

2026-10-27: Qt 6.8.5 with the patches of this repository, Xcode 27.1, macOS 27.0, both appearances.

- `fill`: `sc_pb_60` 0.60, `sc_pb_offset` 0.50, `sc_pb_reset` 0.00, `sc_pb_busydone` 0.30; AppKit `ns_pb_60` 0.60.
- `busy`: the segment in Qt is up to 45 pt long and moves. In AppKit the segment changes its length almost to the whole bar, the animation is different.
- Push buttons: Qt and AppKit heights match (24 / 20 / 16 pt), the titles are centered. Qt buttons are wider: regular +5, small +23, mini +7 pt.
- QSpinBox: 19 / 16 / 16 pt high against the AppKit fields of 24 / 22 / 19 pt. The arrows are of the mini size and not clipped.
- QLineEdit: 21 / 18 pt high against 24 / 22 pt. The focus ring follows the rounded edit and extends 3 pt beyond it.
- Check boxes in item views are visible in every state, on the selected row too.

Differences from AppKit the patches don't fix:

- the progress bar fill is more saturated than in AppKit; at zero AppKit draws a dot, Qt an empty groove;
- small Qt buttons are wider; QLineEdit and QSpinBox are lower than the AppKit fields;
- an edit with its own `QPalette::Base` looks different from what one expects: in the light appearance the background is white, in the dark one it is blended with the dark, and the rectangular fill shows in the corners behind the rounded bezel.

## Cleanup

`make distclean` removes the `Makefile`, the object files and `StyleCheck.app`; `scanalyze` and `shots/` are removed by hand. Git ignores all of them.
