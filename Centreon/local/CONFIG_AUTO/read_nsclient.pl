#!/bin/perl

use strict;
use warnings;

#use Switch;
use Data::Dumper;

sub read_nsclient {
	my ($config_file) = @_;
	my $config_href = {};
	my $current_section;
	
	# Ouverture du fichier de config NSClient++
	open(my($file), '<', $config_file) or die ("Impossible d'ouvrir $config_file : $!\n");
	
	while (my $line  = <$file> ){
		chomp($line);
		$line = lc($line);

		# On saute les commentaires et les lignes vides
		if ($line !~ /^[;#]/ && $line !~ /^\s*$/){
			#print "$line\n";
			
			# Sections
			if ($line =~ /\[(.*)\]/){
				if (substr ($1, 0, 1) ne "/"){
					$current_section = undef;
					next;
				}
				
				$current_section = $1;
				my @sections = split (/\//, $current_section);
				shift @sections;
				
				merge_hash($config_href, split_sections_into_href(@sections));
			
			} else {
				if (defined($current_section)){
					my @keys = split(/=/, $line);
					if (scalar(@keys) > 2){
						print "DEBUG - File: ", __FILE__, " Line: ", __LINE__, "\n";
					}else{
						my ($key, $value) = @keys;
						$key=~ s/^\s*(.*?)\s*$/$1/;
						$value=~ s/^\s*(.*?)\s*$/$1/;
						#print "key=$key; value=$value;\n";
						set_section_value($config_href, $current_section, $key, $value);
					}
				}
			}
		}	
	}
	
	print "==END read_nsclient==\n";
	
	return $config_href;
}


sub split_sections_into_href {
	my ($section_up, @sections) = @_;
	my $temp = {};
	
	if (defined($section_up)){
		$temp->{$section_up} = split_sections_into_href(@sections);
	}

	return $temp;
}


sub merge_hash {
	my ($hash1, $hash_new) = @_;
	my @keys;
	
	# On n'insere pas un hash vide {} s'il key est deja existante
	if (%$hash_new){
		foreach my $key (keys(%$hash_new)){
			if (defined($hash1->{$key})){
				merge_hash($hash1->{$key}, $hash_new->{$key})
			}else{
				$hash1->{$key} = $hash_new->{$key};
			}
		}
	}
	
	return undef;
}


sub get_section_href {
	my ($hash, $section) = @_;
	my  $href = $hash;
	
	my @sections = split (/\//, $section);
	shift @sections;
	
	while (@sections){
		#print Dumper(@sections);
		$href = $href->{shift @sections};
		#print Dumper($href);
	}
	
	return $href;
}


sub get_section_value {
	my ($hash, $section, $key) = @_;
	my ($value, $href);
	
	$href = get_section_href($hash, $section);
	if (defined($href)){
		$value = $href->{$key};
	}
	
	return $value;
}


sub set_section_value {
	my ($hash, $section, $key, $value) = @_;
	my $href;
	
	$href = get_section_href($hash, $section);
	if (defined($href)){
		$href->{$key} = $value;
	}
	
	return $href;
}

my $tab_config;
my $fichier_nsclient = '/cygdrive/c/Users/MLT/Desktop/nsclient.ini';

$tab_config = read_nsclient ($fichier_nsclient);

#my $string = "{settings}{default}";
#print $tab_config->$string;

#print Dumper(get_section_href($tab_config, "/settings/nrpe"));

print Dumper($tab_config);
#print Dumper(get_section_href($tab_config, "/settings/scheduler/schedules"));

my $hash_test = {settings=>
					{
						nrpe=>{
							default => {
								key1=>"value1",
								key2=>"value2"
							},
							config => {}
						}
					}
				};
#merge_hash($tab_config, $hash_test);
#print Dumper($tab_config);
	
#print Dumper(get_section_href($tab_config, "/settings/nrpe"));
#print Dumper(get_section_value($tab_config, "/settings/nrpe/default", "key2"));


	
	
	
	
	
	
	
	
	
	