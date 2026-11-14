#ifndef StyleCheckDialog_h__
#define StyleCheckDialog_h__

#include <QDialog>

// A window with the controls QMacStyle draws its own way under Liquid Glass (patches/qtbase-macstyle-*.patch):
// QProgressBar, small push buttons, QSpinBox arrows, check boxes in item views, the QLineEdit focus ring, the heights
// of QLineEdit and QSpinBox. Each Qt control has the same AppKit control next to it. 2.5 s after it is shown, the
// window prints its window number and the geometry of the controls ("stylecheck ..." lines), which the window shots
// are analyzed by (stylecheck.sh, scanalyze.swift)

class QGroupBox;
class QLineEdit;

class StyleCheckDialog : public QDialog
{
    Q_OBJECT

public:

    // scheme is the initial appearance, Unknown means the system one
    explicit StyleCheckDialog(Qt::ColorScheme scheme = Qt::ColorScheme::Unknown, QWidget *parent = nullptr);

    void activate();
    void report();

private:

    QGroupBox *progressSection();
    QGroupBox *buttonSection();
    QGroupBox *spinSection();
    QGroupBox *viewSection();
    QGroupBox *editSection();

    QLineEdit *m_focusEdit = nullptr;
    int m_activateAttempts = 0;
};

#endif // StyleCheckDialog_h__
