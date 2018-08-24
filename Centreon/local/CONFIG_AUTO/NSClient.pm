package NSClient;

use strict;
use warnings;

use Data::Dumper;


sub new {
	my ($class, $args) = @_;
	my $self = {};
	
	bless $self, $class;
	
	$self->{config_href} = {};
	
	return $self;
}


#
# Lit le fichier ini $config_file
# et retourne un href avec le contenu du fichier
# les noms de section sont converties en minuscules
# les clés aussi. Seules les valeurs restent inchangées.
#
sub read_from_file {
	my ($self, $config_file) = @_;
	my $current_section;
	
	# Ouverture du fichier de config NSClient++
	if (open(my $file, '<', $config_file)){
		while (my $line  = <$file> ){
			chomp($line);

			# On saute les commentaires et les lignes vides
			if ($line !~ /^[;#]/ && $line !~ /^\s*$/){
				#print "$line\n";
				
				# Sections
				if ($line =~ /\[(.*)\]/){
					if (substr ($1, 0, 1) ne "/"){
						$current_section = undef;
						next;
					}
					
					$current_section = lc $1;
					my @sections = split (/\//, $current_section);
					shift @sections;
					
					$self->merge_hash($self->{config_href}, $self->split_sections_into_href(@sections));
				
				} else { # clés
					if (defined($current_section)){
						my @keys = split(/=/, $line);
						if (scalar(@keys) > 2){
							warn "exclusion de la ligne $. : Plusieurs signes '='";
						}else{
							my ($key, $value) = @keys;
							$key=~ s/^\s*(.*?)\s*$/$1/;
							$key = lc $key;
							$value=~ s/^\s*(.*?)\s*$/$1/;
							#print "key=$key; value=$value;\n";
							$self->set_section_value($current_section, $key, $value);
						}
					}
				}
			}	
		}
		close($file);
	
	} else {
		warn "Impossible d'ouvrir $config_file : $!";
	}
	
	return %{$self->{config_href}};
}


#
# lance l'écriture du contenu du href $config_href dans le fichier $config_file
#
sub write_to_file {
	my ($self, $config_file) = @_;
	
	# Ouverture du fichier de config NSClient++
	open(my $file, ">", $config_file) or die ("Impossible de créer $config_file : $!\n");
	
	$self->write_hash_to_file($file, $self->{config_href}, "");
	
	close($file);
}


#
# 
# Ecrit toutes les valeurs de la section courante
# puis fait de meme RECURSIVEMENT pour les sous sections
# $current_section est un string de la section en cours
#  ex: /settings/nsca
#
sub write_hash_to_file{
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
		$self->write_hash_to_file($file, \%{$hrefs{$key}}, $current_section."/".$key);
	}
}


#
# creation RECURSIVE d'un href d'apres le contenu d'une section
# ex: /settings/nrpe
# -->  'settings' => {
#						'nrpe' => {}
#					 }
#
sub split_sections_into_href {
	my ($self, $section_up, @sections) = @_;
	my $temp = {};
	
	if (defined($section_up)){
		$temp->{lc $section_up} = $self->split_sections_into_href(@sections);
	}

	return $temp;
}


#
# fusion du contenu du hash_new dans $hash1
# 
sub merge_hash {
	my ($self, $hash1, $hash_new) = @_;
	my @keys;
	
	# On n'insere pas un hash vide {} si key est deja existante
	if (%$hash_new){
		foreach my $key (keys(%$hash_new)){
			if (defined($hash1->{$key})){
				$self->merge_hash($hash1->{$key}, $hash_new->{$key})
			}else{
				$hash1->{$key} = $hash_new->{$key};
			}
		}
	}
	
	return undef;
}


#
# renvoie un href vers la section
# retourne undef si n'existe pas
#
sub get_section_href {
	my ($self, $section) = @_;
	my  $href = $self->{config_href};
	
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
	my ($self, $section, $key) = @_;
	my ($value, $href);
	
	$href = $self->get_section_href($section);
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
	my ($self, $section, $key, $value) = @_;
	my $href;
	
	$href = $self->get_section_href($section);
	if (defined($href)){
		$href->{$key} = $value;
	}
	
	return $href;
}


1;
__END__

	
	
	