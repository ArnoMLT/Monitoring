#!/usr/bin/perl

use strict;
use warnings;

# 4 lignes pour charger le module NSClient.pm
use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;

use Carp;
use List::MoreUtils qw(first_index);


# Chargement de la config globale
our $global_opts;
do '/usr/lib/nagios/plugins/itbs/bin/load_config.pl';

use Data::Dumper;

# $global_opts->{'path_to_nsclient_config'} = '/cygdrive/c//Users/MLT/Documents/Travail/GitHub/nsclient-config/nsclient';
# $global_opts->{'centreon_admin_user'} = 'admin';
# $global_opts->{'centreon_admin_password'} = 'XXX';

my $path_to_configfiles = "$global_opts->{'path_to_nsclient_config'}/config/clients";
my $path_to_template_files = "$global_opts->{'path_to_nsclient_config'}/config/baseline";

my $now = `date +%s`;
my $logfile = "/tmp/generate_config_ftp-$now.log";

# Chargement de la liste des templates
my $templates = NSClient->get_templates($path_to_template_files, '++');

# Chargement de la liste des hosts centreon
my $hosts = get_hosts("admin", $global_opts->{'centreon_admin_password'});

# Mise en relation avec le chemin vers le nsclient.ini
_read_config_dir($hosts, $path_to_configfiles);

# Exclusion des hosts du groupe 'TESTING'
exclude_hostgroup($hosts, 'TESTING');

# Exclusion du template 'Modele_NSCA' qui est inclus dans client.ini
exclude_template($hosts, 'Modele_NSCA');

# Preparation compteur
my $count = 0;
my $current_percent = 0;
my $nb_result = keys(%$hosts);

print "Ecriture des fichiers (FTP)...\n";
# Boucler sur tous les hosts meme ceux sans config nsclient
foreach my $host_id (keys(%$hosts)){
	print "[$current_percent\%...";
	
	if (defined($hosts->{$host_id}->{'nsclient.ini'})){
		my $config_nsclient = NSClient->new(
			{ config_file => $hosts->{$host_id}->{'nsclient.ini'} }
		);
	
		# Application des modeles au host en cours
		$config_nsclient->prune_templates_inside();
		foreach my $template (@{$hosts->{$host_id}->{'templates'}}){
				# generation compteur d'affichage
				$count++;
				my $percent = $count*100/$nb_result;
				if ($percent % 10 == 0 && int($percent) != $current_percent){
					$current_percent = int($percent);
					print "$current_percent\%";
					if ($current_percent < 100){
						print "...";
					}else{
						print "] - OK\n";
					}
				}
		
			 # my $template_file = "$path_to_template_files/$template.ini";
			 # print "Insere $template_file dans $host_id\n";
			 # $config_nsclient->import_template_inside($template_file, '++');
			 $config_nsclient->import_template_inside($templates->{"$template.ini"},'++');
		}
		# $config_nsclient->save();
	}else{
		$count++;
	}
}


#
# _read_config_dir - Renvoie la liste des fichiers d'un repertoire (en mode recursif)
#
sub _read_config_dir {
	my ($hosts, $path) = @_;
	# my $path = $_[0];
	# my $file;
	# my @FilesList=();

	# Lecture de la liste des fichiers
	opendir (my $FhRep, $path) or die "Impossible d'ouvrir le repertoire $path\n";
	my @contenu = grep { !/^\.\.?$/ } readdir($FhRep);
	closedir ($FhRep);

	foreach my $file (@contenu) {
		# Traitement des fichiers
		if ( -f "$path/$file") {
			if ($file eq "nsclient.ini"){
				my ($host_id) = fileparse($path);
				if (defined($hosts->{$host_id})){
					$hosts->{$host_id}->{'nsclient.ini'} = "$path/$file";
				}else{
					print "Warning : pas de config dans centreon pour le host num $host_id ($path/$file).\n";
				}
			}
		}
		# Traitement des repertoires
		elsif ( -d "$path/$file") {
			# Boucle pour lancer la recherche en mode recursif
			_read_config_dir($hosts, "$path/$file");
		}

	}
	return ;
}


#
#
#
sub exclude_hostgroup {
	my ($hosts, $hostgroup) = @_;
	my @clapi_result;
	
	if ($hostgroup){
		@clapi_result = `centreon -u $global_opts->{'centreon_admin_user'} -p $global_opts->{'centreon_admin_password'} -o HG -a GETMEMBER -v $hostgroup `;
		shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
	}
	
	foreach my $host (@clapi_result){
		chomp(@clapi_result);
		my ($host_id) = split(/;/, $host);
		_exclude_hosts_by_id($hosts, $host_id);
	}
}


#
#
#
sub exclude_template {
	my ($hosts, $template) = @_;
	my @includes;
	# my $includes_ref;
	
	foreach my $host_id (keys(%$hosts)){
		my $includes_ref = $hosts->{$host_id}->{'templates'};
		my $i = first_index {$_ eq $template} @$includes_ref;
		
		if ($i > -1){ # existe
			# @includes = splice(@$includes_ref, $i, 1);
			splice(@$includes_ref, $i, 1);
		}
		# @$includes_ref = @includes;
	}
}


#
#
#
sub _exclude_hosts_by_id {
	my ($hosts, @exclude_ids) = @_;
	
	foreach my $host_id (@exclude_ids){
		$hosts->{$host_id} = undef;
	}
}

	
	
#
# retourne un href avec les listes des host_id et 3 keys 
# 'hostname'  = hostname complet
# 'dns'       = suffixe dns
# 'templates' = liste des templates appliqués dans centreon
#
sub get_hosts {
	my ($centreon_user, $centreon_pass) = @_;
	my $hosts = {};
	my $count = 0;
	my $current_percent = 0;
	
	# id et dns
	my @clapi_result = `centreon -u $centreon_user -p $centreon_pass -o HOST -a SHOW `;
	shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
	my $nb_result = @clapi_result;
	
	print "Lecture de la configuration (CLAPI)...\n";
	print "[$current_percent\%...";
	foreach my $host (@clapi_result){
		my @temp_list = ();
		
		# generation compteur d'affichage
		$count++;
		my $percent = $count*100/$nb_result;
		if ($percent % 10 == 0 && int($percent) != $current_percent){
			$current_percent = int($percent);
			print "$current_percent\%";
			if ($current_percent < 100){
				print "...";
			}else{
				print "] - OK\n";
			}
		}
		
		chomp $host;
		
		my @host_infos = split(/;/, $host);
		my $host_id   = $host_infos[0];
		
		my @host_fqdn = split(/\./, $host_infos[1]);
		my $host_name = shift(@host_fqdn);
		my $host_dns  = join('.', @host_fqdn);
		
		# $hosts->{$host_infos[1]}->{'id'}  = $host_id;
		# $hosts->{$host_infos[1]}->{'dns'} = $host_dns;
		$hosts->{$host_id}->{'hostname'} = $host_infos[1];
		$hosts->{$host_id}->{'dns'} = $host_dns;
		
		
		# templates
		my $templates = `centreon -u $centreon_user -p $centreon_pass -o HOST -a gettemplate -v "$host_infos[1]" | tail -n +2 | cut -d ";" -f 2` ;
		chomp($templates);
		
		if ($templates ne ""){
			((), @temp_list) = split('\n', $templates);
		}
		$hosts->{$host_id}->{'templates'} = \@temp_list;
	}
	
	return $hosts;
}
