#
# Copyright 2018 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author : ArnoMLT
#

package storage::netgear::readynas::snmp::mode::components::fan;

use strict;
use warnings;

my ($mapping, $oid_fanTable);

my $mapping_v6 = {
    fanStatus   => { oid => '.1.3.6.1.4.1.4526.22.4.1.3' },
};
my $oid_fanTable_v6 = '.1.3.6.1.4.1.4526.22.4';

my $mapping_v4 = {
    fanRPM   => { oid => '.1.3.6.1.4.1.4526.18.4.1.2' },
};
my $oid_fanTable_v4 = '.1.3.6.1.4.1.4526.18.4';

sub load {
    my ($self) = @_;
    
	$mapping = $self->{mib_ver} == 4 ? $mapping_v4 : $mapping_v6;
	$oid_fanTable = $self->{mib_ver} == 4 ? $oid_fanTable_v4 : $oid_fanTable_v6;
	
    push @{$self->{request}}, { oid => $oid_fanTable };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fan");
    $self->{components}->{fan} = {name => 'fan', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

	if ($self->{mib_ver} == 6){
		foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanTable}})) {
			next if ($oid !~ /^$mapping->{fanStatus}->{oid}\.(\d+)/);
			my $instance = $1;
			my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanTable}, instance => $instance);

			next if ($self->check_filter(section => 'fan', instance => $instance));
			$self->{components}->{fan}->{total}++;

			$self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s.", $instance, $result->{fanStatus}));
			my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{fanStatus});
			if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
				$self->{output}->output_add(severity => $exit,
											short_msg => sprintf("fan '%s' status is %s", $instance, $result->{fanStatus}));
			}
		}
	}elsif ($self->{mib_ver} == 4){
		foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanTable}})) {
			next if ($oid !~ /^$mapping->{fanRPM}->{oid}\.(\d+)/);
			my $instance = $1;
			my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanTable}, instance => $instance);

			next if ($self->check_filter(section => 'fan', instance => $instance));
			$self->{components}->{fan}->{total}++;
			
			$self->{output}->output_add(long_msg => sprintf("fan '%s' rpm is %s.", $instance, $result->{fanRPM}));	
			my ($exit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{fanRPM});
			if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
				$self->{output}->output_add(severity => $exit,
											short_msg => sprintf("fan '%s' rpm is %s", $instance, $result->{fanRPM}));
			}
			$self->{output}->perfdata_add(label => "fan_" . $instance, unit => 'RPM', value => $result->{fanRPM});
		}
    }
}

1;