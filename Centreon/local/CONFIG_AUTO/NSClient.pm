# MLT
# 26/08/2018
#
# Package de manipulation des fichiers ini produits par NSClient++ (windows)
#

package NSClient;

use strict;
use warnings;
use Carp;

use Data::Dumper;



#
# TODO :
#  - Gerer l'ordre des attachements




sub new {
	my ($class, $args) = @_;
	my $self = {};
	
	bless $self, $class;
	
	$self->{config_href} = {};
	$self->{config_file} = $args->{config_file};
	
	$self->load();
	
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
			chomp($line);

			# On saute les commentaires et les lignes vides
			# prise en compte en debut de ligne de l'encode BOM éventuel
			if (! $token && $line !~ /^[^[:print:]]*\s*[;#]/ && $line !~ /^[^[:print:]]*\s*$/){
				$current_section = $self->_parse_one_line($href, $current_section, $line);
				
			}else{
				#ligne de commentaire ou ligne vide et on sait pas pour $token
				if ($token && $line =~ /^[;#]/ && $line !~ /^\s*$/){
					$line =~ s/^[;#]+\s*//; # enleve la mise en commentaire
					
					if ($line =~/^\Q$token/){		
						$line =~ s/^\Q$token\E\s*//;
						$current_section = $self->_parse_one_line($href, $current_section, $line);
					}
				}
			}
		}
		close($file);
	
	} else {
		warn "Impossible d'ouvrir '$config_file' : $!";
	}
	
	return $href;
}


#
# injecte le href cree par read_from_file dans le $config_href de la classe en l'ecrasant
#
sub read_from_file_inside {
	my ($self, $config_file, $token) = @_;

	$self->{config_href} = $self->read_from_file($config_file, $token);
	
	return $self->get_config();
}


#
# charge le fichier de la classe
#
sub load {
	my $self = shift;
	
	return $self->read_from_file_inside($self->{config_file});
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
		warn "Impossible de créer '$config_file' : $!";
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
	my ($self, $template_file) = @_;
	my $template_hash;
	
	$self->merge_hash_inside($self->read_from_file($template_file, "++"));
}


#
# traite une $line en lecture et l'insere dans $href
#
sub _parse_one_line {
	my ($self, $href, $current_section, $line) = @_;
	
	# Sections
	if ($line =~ /\[(.*)\]/){
		if (substr ($1, 0, 1) ne "/"){
			warn "Exclusion de la ligne $. : La section ne commence pas par '/'";
			return undef;
		}
		
		$current_section = lc $1;
		my @sections = split (/\//, $current_section);
		shift @sections;
		
		$self->_merge_hash($href, $self->_split_sections_into_href(@sections));
	
	} else { # clés
		if (defined($current_section)){
			my @keys = split(/=/, $line);
			if (scalar(@keys) > 2){
				warn "Exclusion de la ligne $. : Plusieurs signes '='";
			}else{
				my ($key, $value) = @keys;
				$key=~ s/^\s*(.*?)\s*$/$1/;
				$key = lc $key;
				$value=~ s/^\s*(.*?)\s*$/$1/;
				# print "key=$key; value=$value;\n";
				$self->set_section_value($href, $current_section, $key, $value);
			}
		}else{
			warn "Exclusion de la ligne $. : Pas de section définie. $line";
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
# injecte le contenu de $file_out (string) dans le fichier de conf de la classe
# la methode load() doit avoir ete appelee avant.
#
sub merge_file_inside {
	my ($self, $file_out) = @_;
	
	# print Dumper($file_out);
	croak "load() non effectué ou \$config_href invalide" if (not get_config());
	
	# Charge le fichier $file_out
	my $nsclient_out = NSClient->new({config_file => $file_out});
	$nsclient_out->load() or croak "Impossible de charger le fichier '$file_out'";
	
	$self->merge_hash_inside($nsclient_out->get_config());
	
	return $self->save();
}


#
# retourne le config_href de la classe
#
sub get_config {
	my $self = shift;
	
	return $self->{config_href};
}


#
# fusion du contenu du hash_new dans $hash1 RECURSIVEMENT
# 
sub _merge_hash {
	my ($self, $hash1, $hash_new) = @_;
	my @keys;

	# On n'insere pas un hash vide {} si key est deja existante
	if (%$hash_new){
		foreach my $key (keys(%$hash_new)){
			if (defined($hash1->{$key}) && ref($hash1->{$key}) eq 'HASH'){
				$self->_merge_hash($hash1->{$key}, $hash_new->{$key})
			}else{
				$hash1->{$key} = $hash_new->{$key};
			}
		}
	}

	return undef;
}


#
# fusion du $hash_new dans le config_href de la classe
#
sub merge_hash_inside {
	my ($self, $hash_new) = @_;
	
	return $self->_merge_hash($self->get_config(), $hash_new);
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
		#print Dumper(@sections);
		$href = $href->{shift @sections};
		#print Dumper($href);
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
# 
# Ecrit toutes les valeurs de la section courante
# puis fait de meme RECURSIVEMENT pour les sous sections
# $current_section est un string de la section en cours
#  ex: /settings/nsca
#
sub _write_hash_to_file{
	my ($self, $file, $href, $current_section) = @_;
	my (%values, %hrefs);
	
	# Creation de 2 listes avec les valeurs, et les href
	foreach my $key (keys(%$href)){
		if (ref($href->{$key}) eq "HASH"){
			$hrefs{$key} = $href->{$key};
			
		}else{
			$values{$key} = $href->{$key};
		}
	}
	
	# Si %values contient des donnees, il faudra aussi écrire la [section]
	if(%values){
		print $file "[$current_section]\r\n";
		#print "[$current_section]\n";
		
		foreach my $key (sort {lc $a cmp lc $b} keys(%values)){	
			print $file "$key = $values{$key}\r\n";
			#print "$key = $values{$key}\n";
		}
		print $file "\r\n";
		#print "\n";
	}
	
	# sous sections
	foreach my $key (sort {lc $a cmp lc $b} keys(%hrefs)){
		$self->_write_hash_to_file($file, \%{$hrefs{$key}}, $current_section."/".$key);
	}
}


1;
__END__

	
	
	