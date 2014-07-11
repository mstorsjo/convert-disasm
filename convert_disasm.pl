#!/usr/bin/env perl

use strict;

my @functions;
my %function_content;
my $cur_function;
my %temp_labels;
my $temp_label_next = 0;

while (<STDIN>) {
	s/[\r\n]*$//;
	if (/^([0-9a-f]+) <(\w+)>:/) {
		$cur_function = $2;
		push(@functions, $cur_function);
	} elsif (/^\s*([0-9a-f]+):\s*([0-9a-f]{4}(?: ?[0-9a-f]{4})?)\s+(.*)/) {
		my $addr = $1;
		my $opcode = $2;
		my $instr = $3;
		$instr =~ s/;.*//;
		$instr =~ s/^([^\s]+)\.n(\s+)/$1$2/;
		$instr =~ s/\s+$//;
		my $temp_label = "temp_label_$temp_label_next";
		if ($instr =~ s/([0-9a-f]+)\s+<[\w\+]+>$/$temp_label/) {
			push(@{$temp_labels{$1}}, $temp_label);
			$temp_label_next++;
		}
		push(@{$function_content{$cur_function}}, [$addr, $instr]);
	}
}

print "\tTHUMB\n";
print "\tAREA |.text|, CODE, READONLY, ALIGN=2, CODEALIGN\n";
print "\tALIGN 4\n";
foreach my $func (@functions) {
	print "\tEXPORT $func\n";
	print "$func PROC\n";
	foreach my $tuple (@{$function_content{$func}}) {
		my $addr = @{$tuple}[0];
		my $instr = @{$tuple}[1];
		if (exists $temp_labels{$addr}) {
			foreach my $label (@{$temp_labels{$addr}}) {
				print "$label\n";
			}
		}
		print "\t$instr\n";
	}
	print "\tENDP\n";
}
print "\tEND\n";
