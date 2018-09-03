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
our $centreon_admin_password = 'P@ssword!itbs';
our $centreon_admin_user = 'admin';
my $path_to_nsclient_config = "/usr/share/centreon/nsclient";
my $path_to_configfiles = "$path_to_nsclient_config/config/clients";
my $path_to_template_files = "$path_to_nsclient_config/config/baseline";

my $now = `date +%s`;
my $logfile = "/tmp/generate_config_ftp-$now.log";

# Chargement de la liste des hosts centreon
my $hosts = get_hosts("admin", $centreon_admin_password);

# Mise en relation avec le chemin vers le nsclient.ini
_read_config_dir($hosts, $path_to_configfiles);

# Exclusion des hosts du groupe 'TESTING'
exclude_hostgroup($hosts, 'TESTING');

# Pour test
# my $hosts = {'HP-MLT.ITBS.net' => {'dns' => 'ITBS.net',
										# 'id' => '150',
										# 'templates' => [
														# 'Modele_NSCA',
														# 'OS-Windows-NSCA'
													   # ]
									  # }
				# };


				
# Boucler sur tous les hosts meme ceux sans config nsclient
foreach my $host_id (keys(%$hosts)){
	# Lire la config du host
	# my $path_nsclient;
	# if ($hosts->{$host_name}->{'dns'}){
		# $path_nsclient = "$path_to_configfiles/$hosts->{$host_name}->{'dns'}/$hosts->{$host_name}->{'id'}/nsclient.ini";
	# }else{
		# $path_nsclient = "$path_to_configfiles/$hosts->{$host_name}->{'id'}/nsclient.ini";
	# }
	
	if (defined($hosts->{$host_id}->{'nsclient.ini'})){
		my $config_nsclient = NSClient->new(
			{ config_file => $hosts->{$host_id}->{'nsclient.ini'} }
		);
	
		# Application des modeles au host en cours
		$config_nsclient->prune_templates_inside();
		foreach my $template (@{$hosts->{$host_id}->{'templates'}}){
			 my $template_file = "$path_to_template_files/$template.ini";
			 # print "Insere $template_file dans $host_name\n";
			 $config_nsclient->import_template_inside($template_file);
			 $config_nsclient->save();
		}
	}
}

# Envoi de la config vers le FTP
system("lftp ftp.it-bs.fr -e 'mirror --parallel=50 -e -R /usr/share/centreon/nsclient/ nsclient/ ; quit'");

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
				# push ( @FilesList, "$path/$file" );
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
			# push (@FilesList, _read_config_dir("$path/$file") );
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
		@clapi_result = `centreon -u $centreon_admin_user -p $centreon_admin_password -o HG -a GETMEMBER -v $hostgroup `;
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
	
	print "Lecture de la configuration...\n";
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