#!/usr/bin/perl

use strict;
use warnings;

# 4 lignes pour charger le module NSClient.pm
use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;

use Data::Dumper;

my $centreon_admin_password = 'P@ssword!itbs';

my $now = `date +%s`;
my $logfile = "/tmp/generate_config_ftp-$now.log";
my $path_to_configfiles = "/tmp/nsclient/config/clients";




# Boucler sur tous les hosts
	my $host_name = "HP-MLT.ITBS.net";

	# Obtenir la liste des templates du Host
	my @templates=`centreon -u admin -p $centreon_admin_password -o HOST -a gettemplate -v "$host_name" | tail -n +2 | cut -d ";" -f 2`;

	print "Templates\n";
	print Dumper(@templates);
	
	# Obtenir l'ID du Host dans centreon
	my $host_id = `centreon -u admin -p $centreon_admin_password -o HOST -a SHOW | sed -rn "s/^([0-9]+);$host_name;.*/\1/pI`;
	#chomp $host_id;
	print "host_id = $host_id\n";

	# Lire la config du host
	my $config_nsclient = NSClient->new(
		 { config_file => '$path_to_configfiles/$host_id/nsclient.ini' }
	);

	print Dumper($config_nsclient);


	foreach my $template (@templates){
		print "Insere $template dans config_nsclient\n";
	}

