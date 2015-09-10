package Dancer2::Plugin::ECommerce;
our $VERSION = '0.0001';  #Version
use strict;
use warnings;
use Dancer2::Plugin;
  
register 'cart' => \&_cart;

sub _cart {
    my ($dsl, $name) = @_;
    $name ||= 'main';
    my $cart = $dsl->schema->resultset('Cart')->find_or_create({
      session => $dsl->session->{'id'},
      name => $name
    });
    
    return {$cart->get_columns};
};




register_plugin;
1;
__END__


