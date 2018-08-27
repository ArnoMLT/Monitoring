#!/bin/perl

use strict;
use warnings;

use Data::Dumper;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;


my $nsclient = NSClient->new(
	{ config_file => '/cygdrive/c/Users/MLT/Desktop/nsclient.ini' }
);

$nsclient->load() or die "KO";

$nsclient->write_to_file ("/cygdrive/c/Users/MLT/Desktop/nsclient_new.ini") or die "KO";

# pour tests uniquement
$nsclient->{config_file} = "/cygdrive/c/Users/MLT/Desktop/nsclient_new.ini";
$nsclient->merge_file_inside("/cygdrive/c/Users/MLT/Desktop/template.ini") or die "KO2";
