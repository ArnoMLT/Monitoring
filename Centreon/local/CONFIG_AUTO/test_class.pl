#!/bin/perl

use strict;
use warnings;

use Data::Dumper;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;


# my $nsclient = NSClient->new(
	# { config_file => '/cygdrive/c/Users/MLT/Desktop/nsclient.ini' }
# );

# $nsclient->load() or die "KO";

# $nsclient->write_to_file ("/cygdrive/c/Users/MLT/Desktop/nsclient_new.ini") or die "KO";

#pour tests uniquement
# $nsclient->{config_file} = "/cygdrive/c/Users/MLT/Desktop/nsclient_new.ini";
# $nsclient->merge_file_inside("/cygdrive/c/Users/MLT/Desktop/template.ini") or die "KO2";
print "load\n";
my $nsclient = NSClient->new(
 { config_file => '/cygdrive/c/Users/MLT/Desktop/testing centreon/nsclient.ini' }
);

print Dumper($nsclient);

#$nsclient->load();
print "Import_inside\n";
$nsclient->import_template_inside("/cygdrive/c/Users/MLT/Desktop/testing centreon/Modele_NSCA.ini");
$nsclient->save();



$nsclient->import_template_inside("/cygdrive/c/Users/MLT/Desktop/testing centreon/Apps-Backup-VeeamAgent-Backup-NSCA.ini");
$nsclient->save();


$nsclient->import_template_inside("/cygdrive/c/Users/MLT/Desktop/testing centreon/OS-Windows-NSCA.ini");
$nsclient->save();
