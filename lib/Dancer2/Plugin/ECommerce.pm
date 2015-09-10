package Dancer2::Plugin::ECommerce;
our $VERSION = '0.0001';  #Version
use strict;
use warnings;
use Dancer2::Plugin;
  
register 'cart' => \&_cart;
register 'cart_add' => \&_cart_add;
sub _cart {
  my ($dsl, $name) = @_;
  my $cart_info = {
    session => $dsl->session->{'id'}
  };
  $cart_info->{name} = $name ? $name : 'main';
  my $cart = $dsl->schema->resultset('Cart')->find_or_create($cart_info);
  return {$cart->get_columns};
};

sub _cart_add {
  my ($dsl , $product) = @_;
  my $product_info = get_product_info($dsl, $product);
  return $product_info if $product_info->{error};
  my $cart_product = cart_add_product($dsl, $product_info);
  return $cart_product if $cart_product->{error};
  return $product_info;
};

sub get_product_info {
  my ( $dsl, $product ) = @_;
  my $product_info = $dsl->schema->resultset('Product')->find( $product );
  return $product_info ? { $product_info->get_columns } : { error => "Product doesn't exists."};
};

sub cart_add_product {
  my ( $dsl, $product_info ) = @_;
  my $cart_product = $dsl->schema->resultset('CartProduct')->create({
    cart_id =>  _cart($dsl)->{id},
    product_id => $product_info->{id},
    price => $product_info->{price},
    quantity => 1,
  });
  return $cart_product ? { $cart_product->get_columns } : { error => "Error trying to create CartProduct."};
};

register_plugin;
1;
__END__


