use File::Copy qw(copy);

my $branch = "5.6.1";

mkdir "qt-$branch";
chdir "qt-$branch";

my @modules = ( 'qtbase', 'qtdeclarative', 'qtdoc', 'qtimageformats', 'qtmacextras', 'qttools', 'qtwinextras' );

foreach $module (@modules)
{
	`wget --no-check-certificate https://codeload.github.com/qtproject/$module/zip/$branch -O$module-$branch.zip`;
	#`unzip $module-$branch.zip`;
	#`del $module-$branch.zip`;
	#`mv $module-$branch $module`;
}

#copy "../compile_mac.pl", ".";

#`zip -r ../qt-$branch.zip *`;
#chdir "..";
#`rmdir qt-$branch /S /Q`;
