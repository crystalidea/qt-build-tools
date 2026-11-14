#include "StyleCheckDialog.h"

#include <QtWidgets>

#include <cstdio>

#import <AppKit/AppKit.h>

// A private but exported QtCore function (qcore_mac_p.h): QMacStyle draws the controls for Liquid Glass when it
// returns true, and only then the qtbase-macstyle-*.patch patches take effect
bool qt_apple_runningWithLiquidGlass();

namespace
{
    const int kWideWidth = 180; // progress bars and line edits have no width of their own

    NSFont *fontForSize(NSControlSize size)
    {
        return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:size]];
    }

    // An AppKit control in a Qt window: a foreign NSView in QWindow::fromWinId (Qt retains it) inside a window
    // container. The size is the one the control finds fitting, the width can be given explicitly
    QWidget *nativeWidget(NSView *view, const char *name, int width = 0)
    {
        NSSize size = view.fittingSize;
        const NSSize intrinsic = view.intrinsicContentSize;

        if (intrinsic.height != NSViewNoIntrinsicMetric && intrinsic.height > size.height)
            size.height = intrinsic.height;

        if (width)
            size.width = width;

        [view setFrameSize:size];

        QWidget *widget = QWidget::createWindowContainer(QWindow::fromWinId(reinterpret_cast<WId>(view)));
        widget->setAttribute(Qt::WA_NativeWindow, true);
        widget->setFixedSize(qCeil(size.width), qCeil(size.height));
        widget->setObjectName(name);

        return widget;
    }

    QWidget *nativeProgress(const char *name, double value, bool indeterminate)
    {
        NSProgressIndicator *indicator = [[[NSProgressIndicator alloc] init] autorelease];
        indicator.style = NSProgressIndicatorStyleBar;
        indicator.indeterminate = indeterminate;
        indicator.minValue = 0;
        indicator.maxValue = 100;
        indicator.doubleValue = value;

        if (indeterminate)
            [indicator startAnimation:nil];

        return nativeWidget(indicator, name, kWideWidth);
    }

    QWidget *nativeButton(const char *name, NSString *title, NSControlSize size, bool enabled = true)
    {
        NSButton *button = [NSButton buttonWithTitle:title target:nil action:nil];
        button.controlSize = size;
        button.font = fontForSize(size);
        button.enabled = enabled;

        return nativeWidget(button, name);
    }

    // a text field with a stepper is the AppKit counterpart of QSpinBox
    QWidget *nativeStepper(const char *name, NSControlSize size, bool enabled = true)
    {
        NSTextField *field = [NSTextField textFieldWithString:@"2400"];
        field.controlSize = size;
        field.font = fontForSize(size);
        field.enabled = enabled;
        [field.widthAnchor constraintEqualToConstant:64].active = YES;

        NSStepper *stepper = [[[NSStepper alloc] init] autorelease];
        stepper.controlSize = size;
        stepper.enabled = enabled;

        NSStackView *stack = [NSStackView stackViewWithViews:@[field, stepper]];
        stack.spacing = 2;

        return nativeWidget(stack, name);
    }

    QWidget *nativeCheckBox(const char *name, NSString *title, NSControlStateValue state, bool enabled = true)
    {
        NSButton *box = [NSButton checkboxWithTitle:title target:nil action:nil];
        box.allowsMixedState = YES;
        box.state = state;
        box.enabled = enabled;

        return nativeWidget(box, name);
    }

    QWidget *nativeTextField(const char *name, NSString *text, NSControlSize size, bool enabled = true)
    {
        NSTextField *field = [NSTextField textFieldWithString:text];
        field.controlSize = size;
        field.font = fontForSize(size);
        field.enabled = enabled;

        return nativeWidget(field, name, kWideWidth);
    }

    QProgressBar *progressBar(const char *name, int minimum, int maximum, int value)
    {
        QProgressBar *bar = new QProgressBar;
        bar->setObjectName(name);
        bar->setRange(minimum, maximum);
        bar->setTextVisible(false);
        bar->setFixedWidth(kWideWidth);

        // a value below the minimum keeps the initial state of the bar, as after reset(): an empty groove
        if (value >= minimum)
            bar->setValue(value);

        return bar;
    }

    template <class Widget>
    Widget *named(Widget *widget, const char *name, Qt::WidgetAttribute size = Qt::WA_MacNormalSize)
    {
        widget->setObjectName(name);
        widget->setAttribute(size);

        return widget;
    }

    QPushButton *pushButton(const char *name, const QString &title, Qt::WidgetAttribute size, bool enabled = true)
    {
        QPushButton *button = named(new QPushButton(title), name, size);
        button->setAutoDefault(false); // a default button is drawn in the accent color, the AppKit samples are plain
        button->setEnabled(enabled);

        return button;
    }

    QSpinBox *spinBox(const char *name, Qt::WidgetAttribute size, bool enabled = true)
    {
        QSpinBox *spin = named(new QSpinBox, name, size);
        spin->setRange(0, 6000);
        spin->setValue(2400);
        spin->setEnabled(enabled);

        return spin;
    }

    QLineEdit *lineEdit(const char *name, const QString &text, Qt::WidgetAttribute size = Qt::WA_MacNormalSize)
    {
        QLineEdit *edit = named(new QLineEdit(text), name, size);
        edit->setFixedWidth(kWideWidth);

        return edit;
    }

    // A section of the window: the row caption, the Qt control, the AppKit sample
    QGroupBox *section(const char *name, const QString &title, QGridLayout *&grid)
    {
        QGroupBox *box = new QGroupBox(title);
        box->setObjectName(name);

        grid = new QGridLayout(box);
        grid->addWidget(new QLabel("Qt"), 0, 1);
        grid->addWidget(new QLabel("AppKit"), 0, 2);
        grid->setColumnStretch(3, 1);

        return box;
    }

    void addRow(QGridLayout *grid, const QString &caption, QWidget *qt, QWidget *native = nullptr)
    {
        const int row = grid->rowCount();
        const Qt::Alignment alignment = Qt::AlignLeft | Qt::AlignVCenter;

        grid->addWidget(new QLabel(caption), row, 0);
        grid->addWidget(qt, row, 1, alignment);

        if (native)
            grid->addWidget(native, row, 2, alignment);
    }
}

StyleCheckDialog::StyleCheckDialog(Qt::ColorScheme scheme, QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("Style Check");

    QLabel *info = new QLabel(QString("Qt %1, style \"%2\", Liquid Glass: %3, macOS %4")
                              .arg(qVersion(), style()->name(), qt_apple_runningWithLiquidGlass() ? "yes" : "no",
                                   QSysInfo::productVersion()));

    QComboBox *schemes = new QComboBox;
    schemes->addItems({"System", "Light", "Dark"});

    QObject::connect(schemes, &QComboBox::currentIndexChanged, schemes, [](int index) {
        const Qt::ColorScheme values[] = {Qt::ColorScheme::Unknown, Qt::ColorScheme::Light, Qt::ColorScheme::Dark};
        QGuiApplication::styleHints()->setColorScheme(values[index]);
    });

    if (scheme == Qt::ColorScheme::Light)
        schemes->setCurrentIndex(1);
    else if (scheme == Qt::ColorScheme::Dark)
        schemes->setCurrentIndex(2);

    QHBoxLayout *header = new QHBoxLayout;
    header->addWidget(info);
    header->addStretch();
    header->addWidget(new QLabel("Appearance:"));
    header->addWidget(schemes);

    QVBoxLayout *left = new QVBoxLayout;
    left->addWidget(progressSection());
    left->addWidget(buttonSection());
    left->addWidget(spinSection());
    left->addStretch();

    QVBoxLayout *right = new QVBoxLayout;
    right->addWidget(viewSection());
    right->addWidget(editSection());
    right->addStretch();

    QHBoxLayout *columns = new QHBoxLayout;
    columns->addLayout(left);
    columns->addLayout(right);

    QDialogButtonBox *buttons = new QDialogButtonBox(QDialogButtonBox::Close);
    QObject::connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->addLayout(header);
    layout->addLayout(columns);
    layout->addWidget(buttons);
}

QGroupBox *StyleCheckDialog::progressSection()
{
    QGridLayout *grid = nullptr;
    QGroupBox *box = section("sc_group_progress", "QProgressBar (progressbar-liquid-glass)", grid);

    addRow(grid, "60 %", progressBar("sc_pb_60", 0, 100, 60), nativeProgress("ns_pb_60", 60, false));
    addRow(grid, "70 of 20...120", progressBar("sc_pb_offset", 20, 120, 70));
    addRow(grid, "reset", progressBar("sc_pb_reset", 0, 100, -1), nativeProgress("ns_pb_0", 0, false));
    addRow(grid, "busy", progressBar("sc_pb_busy", 0, 0, 0), nativeProgress("ns_pb_busy", 0, true));

    // like a download bar: indeterminate first, then determinate
    QProgressBar *done = progressBar("sc_pb_busydone", 0, 0, 0);
    addRow(grid, "busy, then 30 %", done);

    QTimer::singleShot(1000, done, [done] {
        done->setRange(0, 100);
        done->setValue(30);
    });

    QProgressBar *disabled = progressBar("sc_pb_disabled", 0, 100, 60);
    disabled->setEnabled(false);
    addRow(grid, "disabled 60 %", disabled);

    return box;
}

QGroupBox *StyleCheckDialog::buttonSection()
{
    QGridLayout *grid = nullptr;
    QGroupBox *box = section("sc_group_buttons", "Push buttons (small-pushbutton-margins)", grid);

    addRow(grid, "regular", pushButton("sc_btn_regular", "Push Button", Qt::WA_MacNormalSize),
           nativeButton("ns_btn_regular", @"Push Button", NSControlSizeRegular));
    addRow(grid, "small", pushButton("sc_btn_small", "Small Button", Qt::WA_MacSmallSize),
           nativeButton("ns_btn_small", @"Small Button", NSControlSizeSmall));
    addRow(grid, "mini", pushButton("sc_btn_mini", "Mini Button", Qt::WA_MacMiniSize),
           nativeButton("ns_btn_mini", @"Mini Button", NSControlSizeMini));
    addRow(grid, "small, long title", pushButton("sc_btn_small_long", "Small button with a longer title", Qt::WA_MacSmallSize),
           nativeButton("ns_btn_small_long", @"Small button with a longer title", NSControlSizeSmall));
    addRow(grid, "small, disabled", pushButton("sc_btn_small_disabled", "Disabled", Qt::WA_MacSmallSize, false),
           nativeButton("ns_btn_small_disabled", @"Disabled", NSControlSizeSmall, false));

    return box;
}

QGroupBox *StyleCheckDialog::spinSection()
{
    QGridLayout *grid = nullptr;
    QGroupBox *box = section("sc_group_spin", "QSpinBox (spinbox-arrows, textfield-heights)", grid);

    addRow(grid, "regular", spinBox("sc_spin_regular", Qt::WA_MacNormalSize), nativeStepper("ns_spin_regular", NSControlSizeRegular));
    addRow(grid, "small", spinBox("sc_spin_small", Qt::WA_MacSmallSize), nativeStepper("ns_spin_small", NSControlSizeSmall));
    addRow(grid, "mini", spinBox("sc_spin_mini", Qt::WA_MacMiniSize), nativeStepper("ns_spin_mini", NSControlSizeMini));

    QDoubleSpinBox *real = named(new QDoubleSpinBox, "sc_spin_double");
    real->setRange(0, 100);
    real->setValue(42.5);
    addRow(grid, "double", real);

    addRow(grid, "disabled", spinBox("sc_spin_disabled", Qt::WA_MacNormalSize, false),
           nativeStepper("ns_spin_disabled", NSControlSizeRegular, false));

    return box;
}

QGroupBox *StyleCheckDialog::viewSection()
{
    QGroupBox *box = new QGroupBox("Check boxes in item views (itemview-checkboxes)");
    box->setObjectName("sc_group_views");

    // checked, unchecked, partially checked, checked and disabled; the first row is selected
    const Qt::CheckState states[] = {Qt::Checked, Qt::Unchecked, Qt::PartiallyChecked, Qt::Checked};

    QStandardItemModel *fans = new QStandardItemModel(0, 2, box);
    fans->setHorizontalHeaderLabels({"Fan", "Speed"});

    for (int i = 0; i < 4; ++i)
    {
        QStandardItem *item = new QStandardItem(QString("Fan %1").arg(i + 1));
        item->setCheckable(true);
        item->setCheckState(states[i]);
        item->setEnabled(i != 3);

        fans->appendRow({item, new QStandardItem(QString("%1 rpm").arg(1200 + i * 300))});
    }

    QTableView *table = named(new QTableView, "sc_table");
    table->setModel(fans);
    table->verticalHeader()->hide();
    table->horizontalHeader()->setStretchLastSection(true);
    table->selectRow(0);
    table->setFixedSize(240, 140);

    QStandardItemModel *sensors = new QStandardItemModel(box);
    QStandardItem *group = new QStandardItem("Sensors");
    group->setCheckable(true);
    group->setCheckState(Qt::PartiallyChecked);

    for (int i = 0; i < 3; ++i)
    {
        QStandardItem *item = new QStandardItem(QString("Sensor %1").arg(i + 1));
        item->setCheckable(true);
        item->setCheckState(states[i]);
        group->appendRow(item);
    }

    sensors->appendRow(group);

    QTreeView *tree = named(new QTreeView, "sc_tree");
    tree->setModel(sensors);
    tree->setHeaderHidden(true);
    tree->expandAll();
    tree->setCurrentIndex(sensors->index(0, 0, sensors->index(0, 0)));
    tree->setFixedSize(180, 140);

    QListWidget *list = named(new QListWidget, "sc_list");

    for (int i = 0; i < 4; ++i)
    {
        QListWidgetItem *item = new QListWidgetItem(QString("Item %1").arg(i + 1), list);
        item->setFlags(item->flags() | Qt::ItemIsUserCheckable);
        item->setCheckState(states[i]);

        if (i == 3)
            item->setFlags(item->flags() & ~Qt::ItemIsEnabled);
    }

    list->setCurrentRow(0);
    list->setFixedSize(140, 140);

    QHBoxLayout *views = new QHBoxLayout;
    views->addWidget(table);
    views->addWidget(tree);
    views->addWidget(list);
    views->addStretch();

    // the patch doesn't touch plain check boxes: they are here to compare with the ones in item views
    QCheckBox *checked = named(new QCheckBox("Checked"), "sc_check_on");
    checked->setChecked(true);

    QCheckBox *unchecked = named(new QCheckBox("Unchecked"), "sc_check_off");

    QCheckBox *mixed = named(new QCheckBox("Mixed"), "sc_check_mixed");
    mixed->setTristate(true);
    mixed->setCheckState(Qt::PartiallyChecked);

    QCheckBox *disabled = named(new QCheckBox("Disabled"), "sc_check_disabled");
    disabled->setChecked(true);
    disabled->setEnabled(false);

    QHBoxLayout *qtBoxes = new QHBoxLayout;
    qtBoxes->addWidget(new QLabel("Qt"));

    for (QCheckBox *checkBox : {checked, unchecked, mixed, disabled})
        qtBoxes->addWidget(checkBox);

    qtBoxes->addStretch();

    QHBoxLayout *nativeBoxes = new QHBoxLayout;
    nativeBoxes->addWidget(new QLabel("AppKit"));
    nativeBoxes->addWidget(nativeCheckBox("ns_check_on", @"Checked", NSControlStateValueOn));
    nativeBoxes->addWidget(nativeCheckBox("ns_check_off", @"Unchecked", NSControlStateValueOff));
    nativeBoxes->addWidget(nativeCheckBox("ns_check_mixed", @"Mixed", NSControlStateValueMixed));
    nativeBoxes->addWidget(nativeCheckBox("ns_check_disabled", @"Disabled", NSControlStateValueOn, false));
    nativeBoxes->addStretch();

    QVBoxLayout *layout = new QVBoxLayout(box);
    layout->addLayout(views);
    layout->addLayout(qtBoxes);
    layout->addLayout(nativeBoxes);

    return box;
}

QGroupBox *StyleCheckDialog::editSection()
{
    QGridLayout *grid = nullptr;
    QGroupBox *box = section("sc_group_edits", "QLineEdit (lineedit-focus-ring, textfield-heights)", grid);

    m_focusEdit = lineEdit("sc_edit_focused", "Focused line edit");
    addRow(grid, "focused", m_focusEdit, nativeTextField("ns_edit_regular", @"Text field", NSControlSizeRegular));

    addRow(grid, "normal", lineEdit("sc_edit_normal", "Line edit"));

    QLineEdit *custom = lineEdit("sc_edit_custom", "Custom background");
    QPalette palette = custom->palette();
    palette.setColor(QPalette::Base, QColor("#fff2b3"));
    palette.setColor(QPalette::Text, Qt::black);
    custom->setPalette(palette);
    addRow(grid, "custom base", custom);

    QLineEdit *placeholder = lineEdit("sc_edit_placeholder", QString());
    placeholder->setPlaceholderText("Placeholder");
    addRow(grid, "placeholder", placeholder);

    addRow(grid, "small", lineEdit("sc_edit_small", "Small line edit", Qt::WA_MacSmallSize),
           nativeTextField("ns_edit_small", @"Small text field", NSControlSizeSmall));

    QLineEdit *disabled = lineEdit("sc_edit_disabled", "Disabled");
    disabled->setEnabled(false);
    addRow(grid, "disabled", disabled, nativeTextField("ns_edit_disabled", @"Disabled", NSControlSizeRegular, false));

    return box;
}

void StyleCheckDialog::activate()
{
    // An inactive window has no focus ring and gray progress bars: QMacStyle colors them in the active window only
    raise();
    activateWindow();
    [NSApp activateIgnoringOtherApps:YES];

    m_focusEdit->setFocus();
}

void StyleCheckDialog::report()
{
    // macOS may not give the focus to an app started from behind another window. Ask again, but no longer than 5 s:
    // then the report is printed as it is, with active=0
    if (!isActiveWindow() && m_activateAttempts++ < 10)
    {
        activate();
        QTimer::singleShot(500, this, &StyleCheckDialog::report);
        return;
    }

    NSWindow *window = reinterpret_cast<NSView *>(winId()).window;
    const NSRect frame = window.frame;
    const NSRect content = [window contentRectForFrameRect:frame];

    // top is the title bar height: a window shot starts at the frame, the control coordinates at the content
    printf("stylecheck ready window=%ld scale=%g top=%g liquidglass=%d scheme=%s active=%d focus=%d\n",
           long(window.windowNumber), double(window.backingScaleFactor), double(NSHeight(frame) - NSHeight(content)),
           int(qt_apple_runningWithLiquidGlass()),
           QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark ? "dark" : "light",
           int(isActiveWindow()), int(m_focusEdit->hasFocus()));

    for (QWidget *widget : findChildren<QWidget *>())
    {
        const QString name = widget->objectName();

        if (!name.startsWith("sc_") && !name.startsWith("ns_"))
            continue;

        const QPoint at = widget->mapTo(this, QPoint(0, 0));

        printf("stylecheck rect %s %d %d %d %d\n", qPrintable(name), at.x(), at.y(), widget->width(), widget->height());
    }

    printf("stylecheck end\n");
    fflush(stdout);
}
