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
my $product_price_f = undef;
 
register 'cart' => \&_cart;
register 'cart_add' => \&_cart_add;
register 'products' => \&_products;
register 'clear_cart' => \&_clear_cart;
register 'product_quantity' => \&_product_quantity;
register 'subtotal' => \&_subtotal;

register_hook 'before_get_product_info';

my $load_settings = sub {
  $settings = plugin_setting;
  $cart_name = $settings->{cart_name} || 'EcCart';
  $cart_product_name = $settings->{cart_product_name} || 'EcCartProduct';
  $product_name = $settings->{product_name} || 'EcProduct';
  $product_pk = $settings->{product_pk} || 'sku';
  $product_price_f = $settings->{product_price_f} || 'price';
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
    my $product =  $dsl->schema->resultset($product_name)->search({ $product_pk => $cp->sku })->single;
    push @{$arr}, {$product->get_columns, quantity => $cp->quantity, price  => $cp->price };
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
   if ( $cart_product->quantity + $quantity > 0 ){
      $cart_product->update({
        quantity => $cart_product->quantity + $quantity
      });
    }
    else{
      $cart_product->delete;
    }
  } 
  else{
     $cart_product = $dsl->schema($schema)->resultset($cart_product_name)->create({
      cart_id =>  _cart($dsl)->{id},
      sku => $product_info->{$product_pk},
      price => $product_info->{$product_price_f} || 0,
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
  $dsl->schema($schema)->resultset($cart_name)->search({ id => $cart_id })->delete;
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

sub _subtotal{
  my ($dsl, $schema) = @_;
  my $subtotal = 0;
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search(
    {
      cart_id => _cart($dsl)->{id},
    },
  );
  while( my $cp = $cart_products->next ){
    $subtotal += $cp->price * $cp->quantity;
  }
  $subtotal;
}

register_plugin;
1;
__END__


