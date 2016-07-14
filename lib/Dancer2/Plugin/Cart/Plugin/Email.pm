package Dancer2::Plugin::Cart::Email;
# ABSTRACT: Email plugin for Dancer2::Plugin::Cart
use strict;
use warnings;
use Dancer2;
use Dancer2::Plugin;
our $VERSION = '0.0001'; #Version
BEGIN{
	has 'sender' => (
		is => 'ro',
		from_config => 1,
		default => sub { '' }
	);
}

sub BUILD {
  my $self = shift;
	$self->app->add_hook(
            Dancer2::Core::Hook->new(
                name => 'plugin.cart.checkout',
                code => sub {
									debug(' This is working' );
									debug(to_dumper( session->read('ec_cart') ));
							 },
            )
        ); 
}


1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::Cart::Plugin::Email

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

	use Dancer2;
	use Dancer2::Plugin::Cart;
	use Dancer2::Plugin::Cart::Plugin::Email;

=head1 DESCRIPTION

This is and extention to Dancer2::Plugin::Cart in order to add emai funcionality on the checkout process.


=encoding utf8

=head1 CONFIGURATION
  plugins:
	  Cart:
  	  plugin:
				Email:
					sender: 'ruben@rubenamortegui.com'


=head1 AUTHOR

YourSole Core Developers

=head1 DEVELOPERS

Ruben Amortegui <ruben.amortegui@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ruben Amortegui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
