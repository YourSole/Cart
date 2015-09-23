package Dancer2::Plugin::ECommerce::Cart;
our $VERSION = '0.0001';  #Version
use strict;
use warnings;
use Dancer2::Plugin;
use namespace::clean;

my $settings = undef;
my $cart_name = undef;
my $cart_product_name = undef; 
my $product_name = undef;
my $product_pk = undef;
 
register 'cart' => \&_cart;
register 'cart_add' => \&_cart_add;
register 'products' => \&_products;
register 'clear_cart' => \&_clear_cart;
register 'product_quantity' => \&_product_quantity;

register_hook 'before_get_product_info';

my $load_settings = sub {
  $settings = plugin_setting;
  $cart_name = $settings->{cart_name} || 'Cart';
  $cart_product_name = $settings->{cart_product_name} || 'CartProduct';
  $product_name = $settings->{product_name} || 'Product';
  $product_pk = $settings->{product_pk} || 'sku';
};


on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;
    $load_settings->();
};

sub _cart {
  my ($dsl, $name, $schema ) = @_;
  my $cart_info = {
    session => $dsl->session->{'id'}
  };
  
  $cart_info->{name} = $name ? $name : 'main';

  my $cart = $dsl->schema($schema)->resultset($cart_name)->find_or_create($cart_info);
  return {$cart->get_columns};
};

sub _cart_add {
  my ($dsl , $product, $schema) = @_;
  my $product_info = get_product_info($dsl, $product, $schema);
  return $product_info if $product_info->{error};
  my $cart_product = cart_add_product($dsl, $product_info, $product->{quantity}, $schema);
  return $cart_product if $cart_product->{error};
  return $cart_product;
};

sub _products {
  my ($dsl, $schema) = @_;
  my $arr = [];
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search( 
    { 
      cart_id => _cart($dsl)->{id}, 
    },
  );
  while( my $cp = $cart_products->next ){
    my $product =  $dsl->schema->resultset($product_name)->find({ $product_pk => $cp->$product_pk });
    push @{$arr}, {$product->get_columns};
  }

  $arr;
};

sub get_product_info {
  my ( $dsl, $product, $schema ) = @_;

  my $product_info = $dsl->schema($schema)->resultset($product_name)->find({ $product_pk => $product->{sku} });
  return $product_info ? { $product_info->get_columns } : { error => "Product doesn't exists."};
};

sub cart_add_product {
  my ( $dsl, $product_info, $quantity, $schema ) = @_;
  #check if the product exists other whise create a new one
  my $cart_product = $dsl->schema($schema)->resultset($cart_product_name)->find({
    cart_id =>  _cart($dsl)->{id},
    sku => $product_info->{$product_pk},
  });
  if( $cart_product ){
    $cart_product->update({
      quantity => $cart_product->quantity + $quantity
    });
  } 
  else{
     $cart_product = $dsl->schema($schema)->resultset($cart_product_name)->create({
      cart_id =>  _cart($dsl)->{id},
      sku => $product_info->{$product_pk},
      price => $product_info->{price},
      quantity => $quantity,
    });
  }
  return $cart_product ? { $cart_product->get_columns } : { error => "Error trying to create CartProduct."};
};

sub _clear_cart {
  my ($dsl, $name, $schema) = @_;

  #get cart_id
  my $cart_id = _cart($dsl, $name, $schema)->{id}; 

  #delete the cart_product info
  $dsl->schema($schema)->resultset($cart_product_name)->search({ cart_id => $cart_id })->delete_all;
  #delete products
  $dsl->schema($schema)->resultset($cart_name)->find($cart_id)->delete;
}


sub _product_quantity{
  my ($dsl, $schema) = @_;
  my $cart_id = _cart($dsl)->{id}; 
  my $rs = $dsl->schema($schema)->resultset($cart_product_name)->search(
    { 
      cart_id => $cart_id 
    },
    {
      select => [{ sum => 'quantity' }],
      as => ['quantity']
    });
 $rs->first->get_column('quantity') ? $rs->first->get_column('quantity') : 0;
}

register_plugin;
1;
__END__


