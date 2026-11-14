#include "StyleCheckDialog.h"

#include <QApplication>
#include <QTimer>

// StyleCheck [light|dark]: the system appearance without an argument
int main(int argc, char *argv[])
{
    // window containers of the AppKit controls must not make their sibling widgets native, as in our apps
    QCoreApplication::setAttribute(Qt::AA_DontCreateNativeWidgetSiblings, true);

    QApplication app(argc, argv);

    const QString name = app.arguments().value(1);
    Qt::ColorScheme scheme = Qt::ColorScheme::Unknown;

    if (name == "light")
        scheme = Qt::ColorScheme::Light;
    else if (name == "dark")
        scheme = Qt::ColorScheme::Dark;

    StyleCheckDialog dialog(scheme);
    dialog.show();

    // the "busy, then 30 %" bar becomes determinate after a second, so the report comes later
    QTimer::singleShot(0, &dialog, &StyleCheckDialog::activate);
    QTimer::singleShot(2500, &dialog, &StyleCheckDialog::report);

    return app.exec();
}
