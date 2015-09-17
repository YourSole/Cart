package Dancer2::Plugin::ECommerce;
our $VERSION = '0.0001';  #Version
use strict;
use warnings;
use Dancer2::Plugin;
 
my $cart_result_name = undef;
my $cart_product_result_name = undef; 
my $product_result_name = undef;
 
register 'cart' => \&_cart;
register 'cart_add' => \&_cart_add;
register 'products' => \&_products;
register_hook 'before_get_product_info';

sub _check_result_names {
  $cart_result_name = plugin_setting->{cart_result_name} ? plugin_setting->{cart_result_name}: 'Cart' unless $cart_result_name;
  $cart_product_result_name = plugin_setting->{cart_product_result_name}? plugin_setting->{cart_product_result_name}: 'CartProduct' unless $cart_product_result_name;
  $product_result_name = plugin_setting->{product_result_name} ? plugin_setting->{product_result_name} : 'Product' unless $product_result_name;
}

sub _cart {
  my ($dsl, $name) = @_;
  _check_result_names;
  my $cart_info = {
    session => $dsl->session->{'id'}
  };
  $cart_info->{name} = $name ? $name : 'main';
  my $cart = $dsl->schema->resultset($cart_result_name)->find_or_create($cart_info);
  return {$cart->get_columns};
};

sub _cart_add {
  my ($dsl , $product) = @_;
  _check_result_names;
  my $product_info = get_product_info($dsl, $product);
  return $product_info if $product_info->{error};
  my $cart_product = cart_add_product($dsl, $product_info, $product->{quantity});
  return $cart_product if $cart_product->{error};
  return $cart_product;
};

sub _products {
  my ($dsl) = @_;
  my $arr = [];
  my $cart_products = $dsl->schema->resultset($cart_product_result_name)->search( 
    { 
      cart_id => _cart($dsl)->{id}, 
    },
  );
  while( my $cp = $cart_products->next ){
    my $product =  $dsl->schema->resultset($product_result_name)->find({ sku => $cp->sku });
    push @{$arr}, {$product->get_columns};
  }

  $arr;
};

sub get_product_info {
  my ( $dsl, $product ) = @_;
  my $product_info = $dsl->schema->resultset($product_result_name)->find({ sku => $product->{sku} });
  return $product_info ? { $product_info->get_columns } : { error => "Product doesn't exists."};
};

sub cart_add_product {
  my ( $dsl, $product_info, $quantity ) = @_;
  #check if the product exists other whise create a new one
  my $cart_product = $dsl->schema->resultset($cart_product_result_name)->find({
    cart_id =>  _cart($dsl)->{id},
    sku => $product_info->{sku},
  });
  if( $cart_product ){
    $cart_product->update({
      quantity => $cart_product->quantity + $quantity
    });
  } 
  else{
     $cart_product = $dsl->schema->resultset($cart_product_result_name)->create({
      cart_id =>  _cart($dsl)->{id},
      sku => $product_info->{sku},
      price => $product_info->{price},
      quantity => $quantity,
    });
  }
  return $cart_product ? { $cart_product->get_columns } : { error => "Error trying to create CartProduct."};
};

register_plugin;
1;
__END__


