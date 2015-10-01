package Dancer2::Plugin::Cart;
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
my $product_filter = undef;
my $product_order = undef;
 
register 'cart' => \&_cart;
register 'cart_complete' => \&_cart_complete;
register 'cart_add' => \&_cart_add;
register 'cart_products' => \&_cart_products;
register 'products' => \&_products;
register 'clear_cart' => \&_clear_cart;
register 'product_quantity' => \&_product_quantity;
register 'subtotal' => \&_subtotal;
register 'place_order' => \&_place_order;

register_hook 'before_get_product_info';

my $load_settings = sub {
  $settings = plugin_setting;
  $cart_name = $settings->{cart_name} || 'EcCart';
  $cart_product_name = $settings->{cart_product_name} || 'EcCartProduct';
  $product_name = $settings->{product_name} || 'EcProduct';
  $product_pk = $settings->{product_pk} || 'sku';
  $product_price_f = $settings->{product_price_f} || 'price';
  $product_filter = $settings->{product_filter} || undef;
  $product_order = $settings->{product_order} || undef;
};


on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;
    $load_settings->();
};

sub _cart {
  my ($dsl, $params ) = @_;
  my ($name, $schema) = _parse_params($params);
  
  $load_settings->();

  my $cart_info = {
    session => $dsl->session->{'id'},
  };
  
  $cart_info->{name} = $name ? $name : 'main';

  my $cart = $dsl->schema($schema)->resultset($cart_name)->find_or_create($cart_info);

  $params->{cart_id} = $cart->id;
  my $cart_product_info = _cart_product_info ( $dsl, $params );

  return { $cart->get_columns, products => $cart_product_info->{products}, subtotal => $cart_product_info->{subtotal} } if $cart;

  return {$cart->get_columns};
};

sub _cart_complete {
  my ($dsl, $params ) = @_;
  my ($name, $schema) = _parse_params($params);
 
  $params->{status} = 1;
  my $cart = _cart_info( $dsl, $params);

  return { error => 'Cart not found' } unless $cart;

  $params->{cart_id} = $cart->id;
  my $cart_product_info = _cart_product_info ( $dsl, $params );

  return { $cart->get_columns, products => $cart_product_info->{products}, subtotal => $cart_product_info->{subtotal} } if $cart;

  return { error => 'Cart not found' };
};


sub _cart_info {
  my ($dsl, $params ) = @_;
  my ($name, $schema) = _parse_params($params);
  my $status = $params->{status} ? $params->{status} : 0;
  
  my $cart_info = {
    status => $status,
  };

  $cart_info->{id} = $params->{cart_id} if $params->{cart_id};
  $cart_info->{name} = $name ? $name : 'main';

  my $cart = $dsl->schema($schema)->resultset($cart_name)->search($cart_info)->first;

  return $cart;
};

sub _cart_product_info {
  my ($dsl, $params ) = @_;
  my ($name, $schema) = _parse_params($params);
  my $cart_id = $params->{cart_id};

  my $arr = [];
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search( 
    { 
      cart_id => $cart_id,
    },
  );
  my $subtotal = 0;
  while( my $cp = $cart_products->next ){
    my $product =  $dsl->schema->resultset($product_name)->search({ $product_pk => $cp->sku })->single;
    $subtotal += $cp->price * $cp->quantity;
    push @{$arr}, {$product->get_columns, ec_quantity => $cp->quantity, ec_price  => $cp->price };
  }
  return { products => $arr , subtotal => $subtotal };
};

sub _cart_add {
  my ($dsl , $product, $params) = @_;
  my ($name, $schema) = _parse_params($params);

  my $product_info = get_product_info($dsl, $product, { schema => $schema } );
  return $product_info if $product_info->{error};
  my $cart_product = cart_add_product($dsl, $product_info, $product->{quantity}, $params);
  return $cart_product if $cart_product->{error};
  return $cart_product;
};

sub _products {
  my ($dsl, $schema) = @_;
  $product_filter = $product_filter ? eval $product_filter : {};
  $product_order = $product_order ? { order_by => { eval $product_order } } : {};

  my @products = $dsl->schema($schema)->resultset($product_name)->search( $product_filter , $product_order );
  @products;
}

sub _cart_products {
  my ( $dsl, $params )  = @_;
  my ($name, $schema) = _parse_params($params);

  my $arr = [];
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search( 
    { 
      cart_id => _cart($dsl,{ name => $name, schema => $schema } )->{id}, 
    },
  );
  while( my $cp = $cart_products->next ){
    my $product =  $dsl->schema->resultset($product_name)->search({ $product_pk => $cp->sku })->single;
    push @{$arr}, {$product->get_columns, ec_quantity => $cp->quantity, ec_price  => $cp->price };
  }

  $arr;
};

sub get_product_info {
  my ( $dsl, $product, $params ) = @_;
  my $schema = $params->{schema} || undef;

  my $product_info = $dsl->schema($schema)->resultset($product_name)->find({ $product_pk => $product->{sku} });
  return $product_info ? { $product_info->get_columns } : { error => "Product doesn't exists."};
};

sub cart_add_product {
  my ( $dsl, $product_info, $quantity, $params ) = @_;
  my $schema = $params->{schema} || undef;

  #check if the product exists other whise create a new one
  my $cart_product = $dsl->schema($schema)->resultset($cart_product_name)->find({
    cart_id =>  _cart($dsl,{ schema => $schema  })->{id},
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
      cart_id =>  _cart($dsl,undef, $schema)->{id},
      sku => $product_info->{$product_pk},
      price => $product_info->{$product_price_f} || 0,
      quantity => $quantity,
    });
  }
  return $cart_product ? { $cart_product->get_columns } : { error => "Error trying to create CartProduct."};
};

sub _clear_cart {
  my ($dsl, $params ) = @_;
  my ($name, $schema) = _parse_params($params);

  #get cart_id
  my $cart_id = _cart($dsl, { name => $name, schema => $schema } )->{id}; 

  #delete the cart_product info
  $dsl->schema($schema)->resultset($cart_product_name)->search({ cart_id => $cart_id })->delete_all;
  #delete products
  $dsl->schema($schema)->resultset($cart_name)->search({ id => $cart_id })->delete;
}


sub _product_quantity{
  my ($dsl, $params) = @_;
  my ($name, $schema) = _parse_params($params);
  my $cart_id = _cart($dsl,{name => $name,  schema => $schema })->{id}; 
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
  my ($dsl, $params) = @_;
  my ($name,$schema) = _parse_params($params);
  my $subtotal = 0;
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search(
    {
      cart_id => _cart($dsl,$name,$schema)->{id},
    },
  );
  while( my $cp = $cart_products->next ){
    $subtotal += $cp->price * $cp->quantity;
  }
  $subtotal;
}


sub _place_order{
  my ($dsl, $name, $schema) = @_;
  my $cart = _cart($dsl,$name,$schema);
  my $cart_temp = $dsl->schema($schema)->resultset($cart_name)->search( { id => $cart->{id} } )->single;
  $cart_temp->update({
    status => 1,
    session => $dsl->session->{id}."_1",
    log => $dsl->to_json( {
      data => $dsl->session->{data},
      session => $cart_temp->id,
      products => _cart_products( $dsl, $schema ),
      subtotal => _subtotal( $dsl, $schema ) },
    ),
  });
  $cart_temp->id;
}

sub _parse_params {
  my ($params) = @_;
  return ($params->{name}, $params->{schema});
}

register_plugin;
1;
__END__


