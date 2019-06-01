#!/usr/bin/perl

# MLT
# 06/03/2019
#
# Genere l'ecriture des nsclient.ini (fichiers tout en un)
#

use strict;
use warnings;


#
# TODO :
# - Ne plus utiliser le principe des include. Il faut integrer dans le fichier nsclient.ini le contenu complet du template (d'apres le modele centreon)
#   Le reste du contenu du nsclient.ini (par ex hostname=xxx) doit etre integrer dans centreon et peut etre generer. Cela evitera de devoir lire le fichier nsclient.ini
#
# - Apres l'injection des templates, faut ajouter une lecture de tous les hosts centreon pour integrer en ecrasant une conf
#   Un moyen peut etre d'utiliser les macro sous le format suivant :
#       nsclient.ini                                    macro centreon :
#       [settings/nsca/clients]                         NOM                                 //      VALEUR
#       hostname = SERVEUR.casoli.local                 [SETTINGS/NSCA/CLIENT],HOSTNAME     //      SERVEUR.casoli.local
#
#   
#



# 4 lignes pour charger le module NSClient.pm
use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;

use List::MoreUtils qw(first_index);

# Chargement de la config globale
our $global_opts;
do '/usr/lib/nagios/plugins/itbs/bin/load_config.pl';

use Data::Dumper;

my $path_to_configfiles = "$global_opts->{'path_to_nsclient_config'}/config/clients";
my $path_to_template_files = "$global_opts->{'path_to_nsclient_config'}/config/baseline";

my $now = `date +%s`;
my $logfile = "/tmp/generate_config_ftp-$now.log";

# # # my $config_nsclient = NSClient->new(
	# # # { config_file => './SERVEUR.casoli.local.ini' }
# # # );
# # # my $href = $config_nsclient->parse_host_macro_inside("admin", $global_opts->{'centreon_admin_password'}, "SERVEUR.casoli.local");
# # # print Dumper($config_nsclient);

# # # # # # my $test_nsclient = NSClient->new(
	# # # # # # { config_file => './test_ini.ini' }
# # # # # # );
# # # # # # $test_nsclient->load();
# # # # # # my $href = $test_nsclient->get_config();
# # # # # # $test_nsclient->expand_href_includes($href);
# # # # # # print Dumper($href);

# Generation des macro pour tous les hosts
# _prepare_one_dir ("$path_to_configfiles/obbo.local", "admin", $global_opts->{'centreon_admin_password'});
# prepare_hosts_in_centreon("admin", $global_opts->{'centreon_admin_password'});
# exit ;


# # # Chargement de la liste des hosts centreon
# # # # # log_print ("get_hosts('admin', $global_opts->{'centreon_admin_password'})");
my $hosts = get_hosts("admin", $global_opts->{'centreon_admin_password'});
# # my @temp_list = qw(Modele_NSCA Apps-Backup-VeeamAgent-NSCA);
# # my $hosts = {
    # # 207 => {
        # # 'hostname'  => 'SERVEUR.casoli.local',
        # # 'dns'       => 'casoli.local',
        # # 'templates' => \@temp_list
    # # }
# # };

# # my @temp_list = qw(Modele_NSCA Apps-Backup-Windows-Backup-2008-NSCA Hardware-Server-Hp-Ilo-Xmlapi-NSCA);
# # my $hosts = {
    # # 319 => {
        # # 'hostname'  => 'HYPER-V.ixinabelfort.local',
        # # 'dns'       => 'ixinabelfort.local',
        # # 'templates' => \@temp_list
    # # }
# # };

# # # Mise en relation avec le chemin vers le nsclient.ini
# # # # # log_print ("_read_config_dir($hosts, $path_to_configfiles)");
_read_config_dir($hosts, $path_to_configfiles);
# # $hosts->{207}->{'nsclient.ini'} = "$path_to_configfiles/casoli.local/207/nsclient.ini";

# # $hosts->{319}->{'nsclient.ini'} = "$path_to_configfiles/ixinabelfort.local/319/nsclient.ini";

# # # Exclusion des hosts du groupe 'TESTING'
# # exclude_hostgroup($hosts, 'TESTING');
		
# exit ;

# Synchro des modeles
# `/usr/lib/nagios/plugins/itbs/bin/sync_baseline_to_ftp.sh`;
        
# Boucler sur tous les hosts meme ceux sans config nsclient
# # # # # log_print ("Boucler sur tous les hosts");
foreach my $host_id (keys(%$hosts)){
    # # # # # log_print ("host_id=$host_id, hostname=$hosts->{$host_id}->{hostname}");
	if (defined($hosts->{$host_id}->{'nsclient.ini'})){
		my $config_nsclient = NSClient->new(
			{ config_file => $hosts->{$host_id}->{'nsclient.ini'} }
		);
	
        # Lecture des macros de chaque host
        # # # # # log_print ("parse_host_macro_into_href");
        my $host_macro_config = $config_nsclient->parse_host_macro_into_href("admin", $global_opts->{'centreon_admin_password'}, $hosts->{$host_id}->{'hostname'});
    
        # Applique le include 'client' en 1er pour qu'il puisse etre surcharge par la suite
        my $client_index = first_index {$_ eq "client"} @{$host_macro_config->{'includes'}};
        my ($client_key, $client_value) = splice(@{$host_macro_config->{'includes'}}, $client_index, 2);
        # # # # # log_print ("import_template_inside");
        $config_nsclient->import_template_inside($client_value);
               
		# Application des modeles au host en cours
        # # # # # log_print ("Application des modeles au host en cours");
		foreach my $template (@{$hosts->{$host_id}->{'templates'}}){
			 my $template_file = "$path_to_template_files/$template.ini";
             $config_nsclient->import_template_inside($template_file, '++');
        }

        # Applique les parametres trouves dans les macros
        # leur contenu doit surcharger les modeles predefinis donc on a attendu d'etre a la fin du traitement
        # # # # # log_print ("merge_hash_inside");
        $config_nsclient->merge_hash_inside($host_macro_config);
        
        # # # # # log_print("expand_inside");
        # suppression des /includes
        $config_nsclient->expand_inside();
        
        # ecriture du fichier
        $config_nsclient->save();
	}
}

# Envoi sur le FTP
`/usr/lib/nagios/plugins/itbs/bin/sync_ftp.sh`;





sub log_print {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $nice_timestamp = sprintf ( "%04d%02d%02d %02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    print $nice_timestamp . " --- " . shift() . "\n";
    
    return ;
}








#
# retourne un href avec tous les templates disponibles
#
sub get_templates {

	my $templates = {};
	
	return $templates;
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
					print "Warning : pas de config dans centreon pour le host num $host_id ($path/$file).<BR>\n";
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
    # EDIT : SHOWWITHTPL est une commande custom ajoutée dans centreonHost.class.php
    # qui affiche la liste des templates associés au host
    # id;name;alias;address;activate;templates
    # id;name;alias;address;activate;tpl1,tpl2,tpl3
	my @clapi_result = `centreon -u $centreon_user -p $centreon_pass -o HOST -a SHOWWITHTPL `;
	shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
	my $nb_result = @clapi_result;
	
	foreach my $host (@clapi_result){
		my @temp_list = ();
				
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
        @temp_list = split(',', $host_infos[5]);
		# my $templates = `centreon -u $centreon_user -p $centreon_pass -o HOST -a gettemplate -v "$host_infos[1]" | tail -n +2 | cut -d ";" -f 2` ;
		# chomp($templates);
		
		# if ($templates ne ""){
			# ((), @temp_list) = split('\n', $templates);
		# }
		$hosts->{$host_id}->{'templates'} = \@temp_list;
	}
	
	return $hosts;
}





sub _conf_host {
    my ($config_file, $hostname, $centreon_user, $centreon_pass) = @_;
    my $current_section;

    
	# Ouverture du fichier de config NSClient++
	if (open(my $file, '<', $config_file)){
		while (my $line  = <$file> ){
            # $current_section = $self->_read_one_line($line, $current_section, $href, $token);
            chomp($line);
            
            if ($line !~ /^[^[:print:]]*\s*[;#]/ && $line !~ /^[^[:print:]]*\s*$/){
                # $current_section = $self->_parse_one_line($href, $current_section, $line);
                # Sections
                if ($line =~ /\[(.*)\]/){
                    if (substr ($1, 0, 1) ne "/"){
                        warn "Exclusion de la ligne $. : La section ne commence pas par '/'";
                        return undef;
                    }
                    
                    $current_section = lc $1;
                
                
                } else { # clés
                    if (defined($current_section)){
                        my @keys = split(/=/, $line);

                        my $key = shift @keys;
                        my $value = join('=', @keys);
                        
                        $key=~ s/^\s*(.*?)\s*$/$1/;
                        $key = lc $key;
                        $value=~ s/^\s*(.*?)\s*$/$1/;
                        
                        # Si on n'est pas sur la section '/includes'
                        if ($current_section eq "/includes"){
                            if ($key eq "client"){
                                `centreon -u $centreon_user -p $centreon_pass -o HOST -a setmacro -v "$hostname;[$current_section],$key;$value"`;
                            }
                            
                        }else{
                            # $self->set_section_value($href, $current_section, $key, $value);
                            # ecriture d'une ligne de macro dans centreon
                            `centreon -u $centreon_user -p $centreon_pass -o HOST -a setmacro -v "$hostname;[$current_section],$key;$value"`;
                        }

                    }else{
                        warn "Exclusion de la ligne $. : Pas de section définie. $line";
                    }
                }
            }
		}
		close($file);
	
	} else {
		warn "Impossible d'ouvrir '$config_file' : $!";
	}



}



#
# Fonction qui va ecrire les parametres necessaires directement dans centreon
# pour preparer la suppression des includes
#
sub prepare_hosts_in_centreon {
    my ($centreon_user, $centreon_pass) = @_;
    
    my $path_to_configfiles = "$global_opts->{'path_to_nsclient_config'}/config/clients";
    my $path_to_template_files = "$global_opts->{'path_to_nsclient_config'}/config/baseline";
    
    
    # Parcours de toute l'arbo pour trouver des nsclient.ini
    _prepare_one_dir($path_to_configfiles, $centreon_user, $centreon_pass);
    
}


sub _prepare_one_dir {
	my ($path, $centreon_user, $centreon_pass) = @_;
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
                my @clapi_result = `centreon -u $centreon_user -p $centreon_pass -o HOST -a SHOW `;
                shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
                # @clapi_result = split(/;/, @clapi_result);
                # splice(@clapi_result, -3);
                
                my @path_split = split('/', $path);
                my $host_id = pop @path_split;
                
                my $i = first_index {$_ =~ /^$host_id;/} @clapi_result;
                my @fields = split(/;/, $clapi_result[$i]);
                my $hostname = $fields[1];
                print "$hostname\n";
				_conf_host("$path/$file", $hostname, $centreon_user, $centreon_pass);
			}
		}
		# Traitement des repertoires
		elsif ( -d "$path/$file") {
			# Boucle pour lancer la recherche en mode recursif
			_prepare_one_dir("$path/$file", $centreon_user, $centreon_pass);
		}

	}
	return ;
}