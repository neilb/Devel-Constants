#!/usr/bin/perl -w

BEGIN {
	chdir 't' if -d 't';
	push @INC, '../blib/lib';
}

use strict;
print "1..18\n";

my $num;
sub ok {
	my ($test, $name) = @_;
	my $msg = $test ? '' : 'not ';
	$msg .= "ok " . ++$num .
		($name ? " # $name\n" : "\n");
	print $msg;
}

use Devel::Constants 'flag_to_names';

use constant ONE	=> 1;
use constant TWO	=> 2;
use constant THREE	=> 4;
use constant FOUR	=> 8;
use constant FIVE	=> 16;

my $val = ONE | TWO | THREE;

my $flagstring = flag_to_names($val);
for (qw( ONE TWO THREE )) {
	ok( $flagstring =~ s/\s?$_\s?//, "$_ flag should be set in string" );
}

my @flaglist = flag_to_names($val);
for my $flag (qw( ONE TWO THREE )) {
	ok( (grep { $_ eq $flag } @flaglist), "$flag flag should be set in list" );
}

ok( Devel::Constants::to_name(8) eq 'FOUR', 'should be able to resolve label ');

my %flags;

# must be done at compile time
Devel::Constants->import(\%flags);

constant->import( A => 1 );
constant->import( B => 2 );
constant->import( C => 3 );

for my $flag (qw( A B C )) {
	my $sub = UNIVERSAL::can('main', $flag);
	ok( $flags{$sub->()}, "$flag exists in passed-in hash");
	ok( $flags{$sub->()} eq $flag, "$flag has correct value too!" );
}

# now check to see if the custom exporter works
Devel::Constants->import( import => 'bar', to_name => 'label', 'flag_to_names');
ok( UNIVERSAL::can('bar', 'flag_to_names'), 
	'should import into requested namespace' );
ok( UNIVERSAL::can('bar', 'label'), 'should export requested name' );

# tell it to capture variables for constants in another package
Devel::Constants->import( package => 'foo', \%foo::fflags);

package foo;

use vars qw( %fflags );

# must be done at compile time
constant->import( NAME	=> 1 );
constant->import( VALUE	=> 2 );

::ok( scalar(keys %fflags), 'should to capture values in another package' );
::ok( $fflags{2} eq 'VALUE', 'captured value in other package should be set' );

package main;

ok( flag_to_names(1, 'foo') eq 'NAME', 'should get names for other package' );
