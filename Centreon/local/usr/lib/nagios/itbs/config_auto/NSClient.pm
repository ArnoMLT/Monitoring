# MLT
# 06/03/2019
#
# Package de manipulation des fichiers ini produits par NSClient++ (windows)
#

package NSClient;

use strict;
use warnings;
use Carp;

use Data::Dumper;
use List::MoreUtils qw(first_index);
use LWP::Simple;


#
# TODO :
#





sub new {
	my ($class, $args) = @_;
	my $self = {};
	
	bless $self, $class;
	
	$self->{config_href} = { 'default' => {} };
	$self->{config_file} = $args->{config_file};
	
	# $self->load($args->{token});
	
	return $self;
}



#
# Lit le fichier ini $config_file et retourne une reference vers le href crée
# les noms de section sont converties en minuscules
# les clés aussi. Seules les valeurs restent inchangées.
# $token modifie le comportement :
# si défini, on ne lit que les lignes de commentaire qui commencent par ce token
#   le token'++' va permettre d'ajouter uniquement ces lignes
#
sub read_from_file {
	my ($self, $config_file, $token) = @_;
	my $current_section;
	my $href = {};
	
	# Ouverture du fichier de config NSClient++
	if (open(my $file, '<', $config_file)){
		while (my $line  = <$file> ){
            $current_section = $self->_read_one_line($line, $current_section, $href, $token);
		}
		close($file);
	
	} else {
		warn "Impossible d'ouvrir '$config_file' : $!<BR>";
	}
	
	return $href;
}


#
# Lit le fichier ini a l'url $url et retourne une reference vers le href crée
# les noms de section sont converties en minuscules
# les clés aussi. Seules les valeurs restent inchangées.
# $token modifie le comportement :
# si défini, on ne lit que les lignes de commentaire qui commencent par ce token
#   le token'++' va permettre d'ajouter uniquement ces lignes
#
sub read_from_url {
    my ($self, $url, $token) = @_;
    my $current_section;
    my $href = {};
    
    # Telecharge de contenu du fichier
    my $file = get($url);
    
    if ($file){
        my @lines = split /\n/, $file;
        
        foreach my $line (@lines){
            $current_section = $self->_read_one_line($line, $current_section, $href, $token);
        }    
    }else{
        warn "$url introuvable<BR>";
    }
    
    return $href;
}


#
# Lit et traite une ligne d'un fichier ini
#
sub _read_one_line {
    my ($self, $line, $current_section, $href, $token) = @_;

    chomp($line);

    # ---> $token n'est pas renseigné <---
    # On saute les commentaires et les lignes vides
    # prise en compte en debut de ligne de l'encode BOM éventuel
    if (! $token && $line !~ /^[^[:print:]]*\s*[;#]/ && $line !~ /^[^[:print:]]*\s*$/){
        $current_section = $self->_parse_one_line($href, $current_section, $line);
        
    }else{
        # ---> $token est renseigné <---
        #ligne de commentaire ou ligne vide et on sait pas pour $token
        if ($token && $line =~ /^[;#]/ && $line !~ /^\s*$/){
            $line =~ s/^[;#]+\s*//; # enleve la mise en commentaire
            
            if ($line =~/^\Q$token/){		
                $line =~ s/^\Q$token\E\s*//;
                $current_section = $self->_parse_one_line($href, $current_section, $line);
            }
        }
    }
    
    return $current_section;
}


#
# injecte le href cree par read_from_file dans le $config_href de la classe en l'ecrasant
#
sub read_from_file_inside {
	my ($self, $config_file, $token) = @_;
		
	$token = 'default' unless (defined $token);
	
	$self->{config_href}->{$token} = $self->read_from_file($config_file, $token);
	
	return $self->get_config($token);
}


#
# charge le fichier de la classe
#
sub load {
	my ($self, $token) = @_;
	
	return $self->read_from_file_inside($self->{config_file}, $token);
}


#
# lance l'écriture du contenu du config_href de la classe dans le fichier $config_file
#
sub write_to_file {
	my ($self, $config_file) = @_;
	
	# Ouverture du fichier de config NSClient++
	if (open(my $file, ">", $config_file)){
		$self->_write_hash_to_file($file, $self->get_config(), "");	
		
		close($file) or warn "Erreur a l'enregistrement du fichier";
	
	}else{
		warn "Impossible de créer '$config_file' : $!<BR>";
		return;
	}
}


#
# enregistre le fichier de la classe
#
sub save {
	my $self = shift;
	
	return $self->write_to_file($self->{config_file});
}


#
# scan le fichier $template_file et traite les lignes avec ++ comme un ajout
# dans le fichier de config de la classe
#
sub import_template_inside {
	my ($self, $template, $template_token) = @_;
        
	if (ref($template) eq "NSClient"){
		# Import a partir d'un hash de templates
		$self->merge_hash_inside($template->get_config($template_token));
	
	}else{
        # Optimisation : si possible, on lit en local et pas sur le site http distant
        $template =~ s/^http:\/\/monitoring\.it\-bs\.fr\/nsclient/$main::global_opts->{'path_to_nsclient_config'}/;

        if ($template =~ /^http:\/\//){
            # Import a partir d'un fichier a l'aide d'une url
            # print "Insertion depuis une url\n";
            $self->merge_hash_inside($self->read_from_url($template, $template_token));
        
        }else{
            # Import a partir d'un fichier a l'aide d'un path local
            $self->merge_hash_inside($self->read_from_file($template, $template_token));
        }
    }
}


#
# Vide la liste des 'includes' dans le config_href de la classe
# hormis l'entrée 'client' qui n'est pas un template
#
sub prune_templates_inside {
	my $self = shift;
	my @includes;
	my $includes_ref = $self->get_config()->{'includes'};
	
	my $i = first_index {$_ eq "client"} @$includes_ref;
	
	if ($i > -1){ # existe
		@includes = splice(@$includes_ref, $i, 2);
	}
	
	@$includes_ref = @includes;
}


#
# Lit recursivement le contenu des '/includes' et retourne un href "à plat"
# = supprime l'imbrication des includes
#
sub _expand_includes {
    my ($self, @includes) = @_;
    my $href_out = {};
    my $href_read = {};
    
	while (@includes){
		my $key = shift(@includes);
		my $value = shift(@includes);
        
        # Optimisation : si possible, on lit en local et pas sur le site http distant
        $value =~ s/^http:\/\/monitoring\.it\-bs\.fr\/nsclient/$main::global_opts->{'path_to_nsclient_config'}/;
        
        if ($value =~ /^http:\/\//){
        
            # Import a partir d'un fichier a l'aide d'une url
            $href_read = $self->read_from_url($value);
            
        }else{
            # Import a partir d'un fichier a l'aide d'un path local
            $href_read = $self->read_from_file($value);
        }
        
        $self->expand_href_includes($href_read);
        $self->_merge_hash($href_out, $href_read);
    }
    
    return $href_out;
}


#
# Modifie le $href passe en parametre
# En appliquant _expand_includes sur les /includes
# A la fin, le $href ne contient plus aucune imbrication
#
sub expand_href_includes {
    my ($self, $href) = @_;
    
    # expand de tous les includes
    my $href_temp = $self->_expand_includes(@{$href->{includes}});
    
    delete $href->{'includes'};
    
    # merge sans ecrasement
    $self->_merge_hash($href, $href_temp, 0);
}


#
# Supprime les /includes dans le config_href
# en appliquand expand_href_includes
#
sub expand_inside {
    my ($self, $token) = @_;
    
	# $token = 'default' unless (defined $token);
    
    my $href_temp = $self->get_config($token);
    $self->expand_href_includes($href_temp);
}


#
# retourne un href avec tous les templates disponibles dans $path
#
sub get_templates {
	my ($self, $path, $token) = @_;
	my $templates = {};
	
	# Lecture de la liste des fichiers
	opendir (my $FhRep, $path) or die "Impossible d'ouvrir le repertoire $path\n";
	my @contenu = grep { !/^\.\.?$/ } readdir($FhRep);
	closedir ($FhRep);
	
	foreach my $file (@contenu) {
	# Traitement des fichiers
		if ( -f "$path/$file") {
			$templates->{$file} = NSClient->new(
				{	config_file => 	"$path/$file",
					token =>		$token
				}
			);
		}
	}
		
	return $templates;
}


#
# traite une $line en lecture et l'insere dans $href
#
sub _parse_one_line {
	my ($self, $href, $current_section, $line) = @_;
	
	# Sections
	if ($line =~ /\[(.*)\]/){
		if (substr ($1, 0, 1) ne "/"){
			warn "Exclusion de la ligne $. : La section ne commence pas par '/'<BR>";
			return undef;
		}
		
		$current_section = lc $1;
		
		# Si on est sur la section '/includes' on insère dans une liste pour respecter l'ordre
		if ($current_section eq "/includes"){
			$href->{'includes'} = ();
		# }
		}else{
			my @sections = split (/\//, $current_section);
			shift @sections;
		
			$self->_merge_hash($href, $self->_split_sections_into_href(@sections));
		}
	
	} else { # clés
		if (defined($current_section)){
			my @keys = split(/=/, $line);
			# if (scalar(@keys) > 2){
				# warn "Exclusion de la ligne $. : Plusieurs signes '='<BR>";
			
			# }else{
				# my ($key, $value) = @keys;
				my $key = shift @keys;
				my $value = join('=', @keys);
				
				$key=~ s/^\s*(.*?)\s*$/$1/;
				$key = lc $key;
				$value=~ s/^\s*(.*?)\s*$/$1/;
				# print "key=$key; value=$value;\n";

				# Si on est sur la section '/includes' on insère dans une liste pour respecter l'ordre
				if ($current_section eq "/includes"){
					$self->_set_order_section_value($href, $current_section, $key, $value);
				
				}else{				
					$self->set_section_value($href, $current_section, $key, $value);
				}
			# }
		}else{
			warn "Exclusion de la ligne $. : Pas de section définie. $line<BR>";
		}
	}

	return $current_section;
}


#
# creation RECURSIVE d'un href d'apres le contenu d'une section
# ex: /settings/nrpe
# -->  'settings' => {
#						'nrpe' => {}
#					 }
#
sub _split_sections_into_href {
	my ($self, $section_up, @sections) = @_;
	my $href = {};
	
	if (defined($section_up)){
		$href->{lc $section_up} = $self->_split_sections_into_href(@sections);
	}

	return $href;
}


#
# Genere un href d'apres le contenu des macros d'un host
# retourne le href genere
#
sub parse_host_macro_into_href {
    my ($self, $centreon_user, $centreon_pass, $hostname) = @_;
    my $href = {};
    # print "DEBUG in parse_host_macro_into_href - $hostname\n";
    my @clapi_result = `centreon -u $centreon_user -p $centreon_pass -o HOST -a GETMACRO -v  "$hostname"`;
    # macro name;macro value;is_password;description;source
    # macro name contient [/section],key
	shift @clapi_result;  # la 1ere ligne contient les entetes de colonnes
    
    foreach my $line (@clapi_result){
        chomp $line;
        my @fields = split(/;/, $line);
        splice(@fields,-3); # retire les 3 derniers champs
        # Il reste : [SECTION],KEY;value
        
        my ($section, $key) = split(/,/, $fields[0]);
        shift @fields;
        # my ($section, $key, @value) = @fields;
        # my $value = join(';', @value);
        my $value = join(';', @fields);

        # traitement sur [/SECTION/SECTION2]
        $section =~ s/\[(.*)\]/$1/;
        $section = lc $section;
        my @section_words = split (/\//, $section);
        shift @section_words;
        
        # traitement sur KEY
        $key =~ s/^\s*(.*?)\s*$/$1/;
		$key = lc $key;
        
        # traitement sur value
        $value=~ s/^\s*(.*?)\s*$/$1/;

        # Si on est sur la section '/includes' on insère dans une liste pour respecter l'ordre
		if ($section eq "/includes"){
			# $href->{'includes'} = ();
            $self->_set_order_section_value($href, $section, $key, $value) or croak "$hostname : Impossible d'inserer dans '$section'<BR>";
		}else{
            # maintenant on ajoute ca au href
            $self->_merge_hash($href, $self->_split_sections_into_href(@section_words));
            $self->set_section_value($href, $section, $key, $value) or croak "$hostname : Impossible d'inserer dans '$section'<BR>";
        }   
    }
    
    return $href;
}


#
# injecte un href cree d'apres les macros d'un host dans le href de la classe
# En ecrasant ce qui existe deja
#
sub parse_host_macro_inside {
    my ($self, $centreon_user, $centreon_pass, $hostname) = @_;
    
    my $href = $self->parse_host_macro_into_href($centreon_user, $centreon_pass, $hostname);
    $self->merge_hash_inside($href);

    return $href;
}


#
# injecte avec ecrasement le contenu de $file_out (string) dans le fichier de conf de la classe
# la methode load() doit avoir ete appelee avant.
#
sub merge_file_inside {
	my ($self, $file_out, $token) = @_;
	
	# print Dumper($file_out);
	croak "load() non effectué ou \$config_href invalide<BR>" if (not $self->get_config($token));
	
	# Charge le fichier $file_out
	my $nsclient_out = NSClient->new({config_file => $file_out});
	$nsclient_out->load() or croak "Impossible de charger le fichier '$file_out'<BR>";
	
	$self->merge_hash_inside($nsclient_out->get_config(), $token);
	
	return $self->save();
}


#
# retourne le config_href de la classe
#
sub get_config {
	my ($self, $token) = @_;
	$token = 'default' unless (defined $token);
	
	return $self->{config_href}->{$token};
}


#
# fusion du contenu du hash_new dans $hash1 RECURSIVEMENT
# si $overwrite est positionne sur true, ecrasement possible dans $hash1
# sinon pas d'ecrasement
# par defaut (si omis) $overwrite est positionné
# 
sub _merge_hash {
	my ($self, $hash1, $hash_new, $overwrite) = @_;
	my @keys;

    # Par defaut on ecrase
    $overwrite = 1 unless (defined $overwrite);
    
	# On n'insere pas un hash vide {} si key est deja existante
	if (%$hash_new){
		foreach my $key (keys(%$hash_new)){
			if (defined($hash1->{$key}) && ref($hash1->{$key}) eq 'HASH'){
				$self->_merge_hash($hash1->{$key}, $hash_new->{$key}, $overwrite);
			
			# Prise en compte de listes pour les sections dont l'ordre est important
			}elsif (defined($hash1->{$key}) && ref($hash1->{$key}) eq 'ARRAY'){
				$self->_merge_list($hash1->{$key}, $hash_new->{$key}, $overwrite);
			
			}else{
                if (! defined $hash1->{$key} || $overwrite){
                    $hash1->{$key} = $hash_new->{$key};
                }
			}
		}
	}

	return undef;
}


#
# fusion avec ecrasement du $hash_new dans le config_href de la classe
#
sub merge_hash_inside {
	my ($self, $hash_new, $token) = @_;
    
	# $token = 'default' unless (defined $token);
	    
	return $self->_merge_hash($self->get_config($token), $hash_new);
}


#
#
#
sub _merge_list {
	my ($self, $list1, $list_new, $overwrite) = @_;
	
    # par defaut on ecrase
    $overwrite = 1 unless (defined $overwrite);
    
	# creation d'une liste a part pour ne pas travailler
	# directement sur un modele
	my @list_new_copy = @$list_new;
	
	# while (defined (@list_new_copy) && @list_new_copy){ # defined is deprecated
	while (@list_new_copy){
		my $key = shift(@list_new_copy);
		my $value = shift(@list_new_copy);
		
        my $i = first_index {$_ eq $key} @$list1;
        
        if ($i == -1){ # N'existe pas : on insere dans tous les cas
            push(@$list1, ($key, $value));

        }else{
            if ($overwrite){ # existe deja et overwrite
                # on supprime la clé et la valeur associée pour mettre la nouvelle entrée a la fin
                splice(@$list1, $i, 2);	
                push(@$list1, ($key, $value));

            }else{
                # existe deja et sans overwrite : on ne fait rien
            }            
        }
	}
}

#
# renvoie un href vers la section (string)
# retourne undef si n'existe pas
#
sub get_section_href {
	my ($self, $hash, $section) = @_;
	my $href = $hash;
	
	my @sections = split (/\//, $section);
	shift @sections;
	
	while (@sections){
		$href = $href->{shift @sections};
	}
	
	return $href;
}

#
# renvoie la valeur de $hash->{$key} dans la section concernée
# retourne undef si $key ou $section n'existe pas
# 
sub get_section_value {
	my ($self, $hash, $section, $key) = @_;
	my ($value, $href);
	
	$href = $self->get_section_href($hash, $section);
	if (defined($href)){
		$value = $href->{$key};
	}
	
	return $value;
}


#
# Ajoute $key => $value dans la section
# retourne le href de la section, undef si n'existe pas
#
sub set_section_value {
	my ($self, $hash, $section, $key, $value) = @_;
	my $href;
	
	$href = $self->get_section_href($hash, $section);
	if (defined($href)){
		$href->{$key} = $value;
	}
	
	return $href;
}


#
# idem que set_section_value mais crée un liste plutot qu'un hash
#
sub _set_order_section_value {
	my ($self, $href, $section, $key, $value) = @_;
	my $list_ref;
	
	push (@{$href->{substr($section,1)}}, ($key, $value));		
	
	return $href->{substr($section,1)}
	
}


#
# 
# Ecrit toutes les valeurs de la section courante
# puis fait de meme RECURSIVEMENT pour les sous sections
# $current_section est un string de la section en cours
#  ex: /settings/nsca
#
sub _write_hash_to_file{
	my ($self, $file, $href, $current_section) = @_;
	my (%values, %hrefs);
	my @list = ();
	
	# Creation de 2 listes avec les valeurs, et les href
	foreach my $key (keys(%$href)){
		if (ref($href->{$key}) eq "HASH"){
			$hrefs{$key} = $href->{$key};
			
		}elsif (ref($href->{$key}) eq "ARRAY"){
			push (@list, ("$current_section/$key"));
			push (@list, @{$href->{$key}});
			
		}else{
			$values{$key} = $href->{$key};
		}
	}
	
	# Si %values contient des donnees, il faudra aussi écrire la [section]
	if(%values){ 
		print $file "[$current_section]\r\n";
		# print "[$current_section]\n";
		
		foreach my $key (sort {lc $a cmp lc $b} keys(%values)){	
			print $file "$key = $values{$key}\r\n";
			# print "$key = $values{$key}\n";
		}
		
		print $file "\r\n";
		# print "\n";
	}
	
	# Cette section ne doit pas etre triée pour garder la priorité et l'héritage des templates
	if (scalar(@list)){
		my $order_section = shift(@list);
		
		print $file "[$order_section]\r\n";
		# print "[$order_section]\n";
		
		while (@list){
			my $key_in_list = shift(@list);
			my $value_in_list = shift(@list);
			print $file "$key_in_list = $value_in_list\r\n";
			# print "$key_in_list = $value_in_list\n";
		}
		
		print $file "\r\n";
		# print "\n";
	}
	
	# sous sections
	foreach my $key (sort {lc $a cmp lc $b} keys(%hrefs)){
		$self->_write_hash_to_file($file, \%{$hrefs{$key}}, $current_section."/".$key);
	}
}


1;
__END__

	
	
	