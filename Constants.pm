package Devel::Constants;

use strict;
use vars qw( $VERSION %EXPORT_OK );

$VERSION = '0.20';

%EXPORT_OK = (
	flag_to_names	=> \&flag_to_names,
	to_name			=> \&to_name,
);

use constant;
use subs ('oldimport');

{
	local $^W = 0;
	*oldimport = \&constant::import;
	*constant::import = \&newimport;
}


my %constants;

sub import {
	my $class = shift;

	my $pkg = my $import = caller();
	my $flagholder = {};

	my @exports;

	while (my $arg = shift) {
		if (ref($arg) eq 'HASH') {
			$flagholder = $arg;
		} elsif ($arg eq 'package') {
			$pkg = shift if @_;
		} elsif ($arg eq 'import') {
			$import = shift if @_;
		} elsif (exists $EXPORT_OK{$arg}) {
			my $name = shift if (@_ and !(exists $EXPORT_OK{$_[0]}));
			push @exports, [ $name || $arg, $EXPORT_OK{$arg} ];
		}
	}

	$constants{$pkg} = $flagholder;

	no strict 'refs';
	foreach my $export (@exports) {
		*{ $import . "::$export->[0]" } = $export->[1];
	}

}

sub newimport {
	my ($class, @args) = @_;
	my $pkg = caller();

	if (defined $constants{$pkg}) {
		while (@args) {
			my ($name, $val) = splice(@args, 0, 2);
			last unless $val;
			$constants{$pkg}{$val} = $name;
		}
	}

	goto &oldimport;
}

sub flag_to_names {
	my ($val, $pkg) = @_;
	$pkg ||= caller(); 
	
	my $constants = $constants{$pkg} or return;

	my @flags;
	foreach my $flag (keys %$constants) {
		push @flags, $constants->{$flag} if $val & $flag;
	}
	return wantarray() ? @flags : join(' ', @flags);
}

sub to_name {
	my ($val, $pkg) = @_;
	$pkg ||= caller();

	my $constants = $constants{$pkg} or return;
	if (exists $constants->{$val}) {
		return $constants->{$val};
	}
}

1;

__END__

=head1 NAME

Devel::Constants - Perl module to translate constants back to their named symbols

=head1 SYNOPSIS

	# must precede use constant
	use Devel::Constants 'flag_to_names';

	use constant A => 1;
	use constant B => 2;
	use constant C => 4;

	my $flag = A | B;
	print "Flag is: ", join(' and ', flag_to_names($flag) ), "\n";

=head1 DESCRIPTION

Declaring constants is very convenient for writing programs, but as they're
often inlined by Perl, retrieving their symbolic names can be tricky.  This is
made worse with lowlevel modules that use constants for bit-twiddling.

Devel::Constants makes this much more manageable.

It silently wraps around the L<constant> module, intercepting all constant
declarations.  It builds a hash, associating the values to their names.  The
names can then be retrieved as necessary.

Note that Devel::Constants B<must> be used B<before> C<constant> is, or the
magic will not work and you will be very disappointed.  This is very important,
and if you ignore this warning, the authors will feel free to laugh at you.  At
least a little.

By default, Devel::Constants will only intercept constant declarations within
the same package that used the module.  Also by default, it stores the
constants for a package within a private (read, otherwise inaccessible)
variable.  Both of these can be overridden.

Passing the C<package> flag to Devel::Constants with a valid package name will
make the module intercept all constants subsequently declared within that
package.  For example, in package main one might say:

	use Devel::Constants package => NetPacket::TCP;
	use NetPacket::TCP;

All of the TCP flags declared within L<NetPacket::TCP> are now available.

It is also possible to pass in a hash reference where the constant values and
names wil be stored:

	my %constant_map;
	use Devel::Constants \%constant_map;

	use constant NAME	=> 1;
	use constant RANK	=> 2;
	use constant SERIAL	=> 4;

	print join(' ', values %constant_map), "\n";

=head2 EXPORT

By default, Devel::Constants exports no subroutines.  Its two helper functions 
can optionally be exported by passing them on the use line: 

	use Devel::Constants qw( flag_to_names to_name );

	use constant FOO => 1;
	use constant BAR => 2;

	print flag_to_names(2);
	print to_name(1);

These functions may also be imported with different names, if necessary.  Pass
the alternate name after the function name.  B<Beware> that this is the most
fragile of all options.  If a name is not passed, Devel::Constants may become
confused:

	# good
	use Devel::Constants 
		flag_to_names => 'resolve',
		'to_name';
	
	# WILL WORK IN SPITE OF POOR FORM (the author thinks he's clever)
	use Devel::Constants
		'to_name',
		flag_to_names => 'resolve';

	# WILL PROBABLY BREAK, SO DO NOT USE
	use Devel::Constants
		'to_name',
		package => WD::Kudra;

Passing the C<import> flag will import any requested functions into the named
package.  This is occasionally helpful, but it will overwrite any existing
functions in the named package.  Be a good neighbor:

	use Devel::Constants
		import => 'my::other::namespace',
		'flag_to_names',
		'to_name';

Note that L<constant> also exports subroutines, by design.

=head1 FUNCTIONS

=over 4

=item C<flag_to_names($flag, [ $package ])>

This function resolves a flag into its component named bits.  This is generally
only useful for flags known to be composed of named constants logically
combined.  It can be very handy though.  The first parameter is required, and
must be the flag to decompose.  It is not modified.  The second parameter is
optional.  If provided, it will use flags set in another package.  In the
L<NetPacket::TCP> example above, it could be used to find the symbolic names of
TCP packets, such as SYN or RST set on a NetPacket::TCP object.

=item C<to_name($value, [ $package ])>

This function resolves a value into its constant name.  This does not mean that
the value was set by the constant, only that it has the same value as the
constant.  (For example, 2 could be the result of a mathematical operation, or
it could be a sign to dump core and bail out.  C<to_name> only guarantees the
same value, and not the same semantics.  See L<PSI::ESP> if this is not
acceptable.)  As with L<flag_to_names>, the optional C<$package> parameter will
look for constants declared in a package other than the current.

=back

=head1 HISTORY

=over 4

=item * 0.20 (9 October 2001)

Added C<to_name>, %EXPORT_OK, 'import' flag
Many small tweaks and renames
Another step toward World Domination

=item * 0.10 (7 October 2001)

Initial version.

=back

=head1 TODO

=over 4

=item * figure out a better way to handle C<flag_to_names> (inefficient
algorithm)

=item * allow potential capture lists?

=item * sync up better with allowed constant names in C<constant>

=item * evil nasty Damianesque idea: locally redefining constants

=back

=head1 AUTHOR

chromatic <chromatic@wgz.org>, with thanks to "Benedict" at Perlmonks.org for
the germ of the idea (L<http://perlmonks.org/index.pl?node_id=117146>).

Thanks also to Tim Potter and Stephanie Wehner for C<NetPacket::TCP>, though
they don't know it yet.  :)

=head1 SEE ALSO

L<constant>

=cut
