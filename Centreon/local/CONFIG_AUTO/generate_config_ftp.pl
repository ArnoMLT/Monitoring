#!/usr/bin/perl

use strict;
use warnings;

# 4 lignes pour charger le module NSClient.pm
use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;

use Data::Dumper;

# Configuration centreon
my $centreon_admin_password = 'P@ssword!itbs';
my $path_to_nsclient_config = "/usr/share/centreon/nsclient";
my $path_to_configfiles = "$path_to_nsclient_config/config/clients";
my $path_to_template_files = "$path_to_nsclient_config/config/baseline";

my $now = `date +%s`;
my $logfile = "/tmp/generate_config_ftp-$now.log";

# Chargement de la liste des hosts centreon
my $hosts = get_hosts("admin", $centreon_admin_password);

# Pour test
# my $hosts = {'HP-MLT.ITBS.net' => {'dns' => 'ITBS.net',
										# 'id' => '150',
										# 'templates' => [
														# 'Modele_NSCA',
														# 'OS-Windows-NSCA'
													   # ]
									  # }
				# };

# Boucler sur tous les hosts
foreach my $host_name (keys(%$hosts)){
	# Lire la config du host
	my $path_nsclient;
	if ($hosts->{$host_name}->{'dns'}){
		$path_nsclient = "$path_to_configfiles/$hosts->{$host_name}->{'dns'}/$hosts->{$host_name}->{'id'}/nsclient.ini";
	}else{
		$path_nsclient = "$path_to_configfiles/$hosts->{$host_name}->{'id'}/nsclient.ini";
	}
	
	my $config_nsclient = NSClient->new(
		 { config_file => $path_nsclient }
	);

	# Application des modeles au host en cours
	foreach my $template (@{$hosts->{$host_name}->{'templates'}}){
		 my $template_file = "$path_to_template_files/$template.ini";
		 # print "Insere $template_file dans $host_name\n";
		 $config_nsclient->import_template_inside($template_file);
		 $config_nsclient->save();
	}
}

	
#
# retourne un href avec les listes des hosts et 3 keys 
# 'id'        = HOST_ID
# 'dns'       = suffixe dns
# 'templates' = liste des templates appliqués dans centreon
#
sub get_hosts {
	my ($centreon_user, $centreon_pass) = @_;
	my $hosts = {};
	my $count = 0;
	
	# id et dns
	my @clapi_result = `centreon -u $centreon_user -p $centreon_pass -o HOST -a SHOW `;
	shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
	my $nb_result = @clapi_result;
	
	print "Lecture de la configuration...\n";
	foreach my $host (@clapi_result){
		my @temp_list = ();
		
		# generation compteur d'affichage
		$count++;
		my $percent = $count*100/$nb_result;
		print int($percent) . "..." if ($percent % 10 == 0);
		
		chomp $host;
		
		my @host_infos = split(/;/, $host);
		my $host_id   = $host_infos[0];
		
		my @host_fqdn = split(/\./, $host_infos[1]);
		my $host_name = shift(@host_fqdn);
		my $host_dns  = join('.', @host_fqdn);
		
		$hosts->{$host_infos[1]}->{'id'}  = $host_id;
		$hosts->{$host_infos[1]}->{'dns'} = $host_dns;
		
		# templates
		my $templates = `centreon -u $centreon_user -p $centreon_pass -o HOST -a gettemplate -v "$host_infos[1]" | tail -n +2 | cut -d ";" -f 2` ;
		chomp($templates);
		
		if ($templates ne ""){
			((), @temp_list) = split('\n', $templates);
		}
		$hosts->{$host_infos[1]}->{'templates'} = \@temp_list;
	}
	
	return $hosts;
}