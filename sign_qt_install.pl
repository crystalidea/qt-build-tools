# Signs the libraries of an installed Qt tree with the signtool wrapper from
# %MY_COMMON%.
#
# Windows 11 with Smart App Control on refuses to load a library without a valid
# signature into a running process, and an installer that carries Qt beside the
# application hands it exactly such libraries. Signed where Qt is installed, they
# are already signed in every product built against this Qt.
#
# Debug libraries stay out: no product ships them, and every signature costs a run
# of signtool.
#
# Usage: perl sign_qt_install.pl <qt install dir> [--list]
#
#   --list   name the libraries and sign nothing

use strict;
use File::Find;

my @args = @ARGV;
my $list_only = grep { $_ eq '--list' } @args;

@args = grep { $_ ne '--list' } @args;

my $install_dir = $args[0];

die "Usage: perl sign_qt_install.pl <qt install dir> [--list]\n" if (!$install_dir);

$install_dir =~ s{/}{\\}g;
$install_dir =~ s{\\+$}{};

die "Error: '$install_dir' holds no 'bin', so it is not a Qt installation\n" if (!-d "$install_dir\\bin");

my $signtool;

if (!$list_only)
{
    my $common = $ENV{'MY_COMMON'};

    die "Error: MY_COMMON is not set, the signtool wrapper cannot be found\n" if (!$common);

    $signtool = "$common\\deploy\\bin\\signtool.exe";

    die "Error: '$signtool' does not exist\n" if (!-f $signtool);
}

my @libraries;

foreach my $dir ("$install_dir\\bin", "$install_dir\\plugins")
{
    next if (!-d $dir);

    find (sub
    {
        return if (!-f || !/\.dll$/i);

        my $path = $File::Find::name;

        $path =~ s{/}{\\}g; # File::Find joins with '/', and signtool is given Windows-style paths

        push (@libraries, $path);

    }, $dir);
}

# A debug library sits next to its release twin: Qt6Cored.dll beside Qt6Core.dll
@libraries = grep { my $twin = $_; $twin =~ s{d\.dll$}{.dll}i; $twin eq $_ || !-f $twin } @libraries;

die "Error: no libraries found in '$install_dir'\n" if (!@libraries);

if ($list_only)
{
    print "$_\n" foreach (@libraries);

    printf ("%d libraries in %s\n", scalar (@libraries), $install_dir);

    exit (0);
}

my $failed = 0;

foreach my $library (@libraries)
{
    # /sha256 - a single SHA256 signature instead of the SHA1 + SHA256 pair: Qt 6 runs
    # on Windows 10 and newer, where a SHA1 signature counts for nothing anyway
    if (system ("\"$signtool\" \"$library\" \"Qt\" /sha256") != 0)
    {
        print "FAILED to sign $library\n";

        $failed++;
    }
}

printf ("Signed %d of %d libraries in %s\n", scalar (@libraries) - $failed, scalar (@libraries), $install_dir);

exit ($failed ? 1 : 0);
