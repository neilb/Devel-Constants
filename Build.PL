#! perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	license     => 'perl',
	module_name => 'Devel::Constants',
	requires    =>
	{
	},
	build_requires =>
	{
		'Test::More'   => '0.60',
	},
	create_makefile_pl => 'traditional',
	sign               => '1',
);

$build->create_build_script();
