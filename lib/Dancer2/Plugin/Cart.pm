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
register 'cart_add' => \&_cart_add;
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
    $load_settings->();
};

sub _cart {
  my ($dsl, $params ) = @_;
  my ($name, $schema, $status, $cart_id) = parse_params($params);
  $load_settings->();
  my $cart_info = {
    session => $dsl->session->{'id'},
  };

  $cart_info->{name} = $name ? $name : 'main';
  $cart_info->{status} = $status ? $status : 0;

  if ( $cart_id ){
    $cart_info->{id} = $cart_id;
    delete $cart_info->{session};
  }

  my $cart = undef;

  if ( $cart_info->{status} == 0 ){
    $cart = $dsl->schema($schema)->resultset($cart_name)->find_or_create($cart_info);
  }
  else{
    $cart = $dsl->schema($schema)->resultset($cart_name)->search($cart_info)->first;
  }
  $params->{cart_id} = $cart->id;
  my $cart_items = cart_items ( $dsl, $params );
  return { $cart->get_columns, items => $cart_items->{items} , subtotal => $cart_items->{subtotal} } if $cart;
};

sub cart_items {
  my ($dsl, $params ) = @_;
  my ($name, $schema, $status, $cart_id ) = parse_params($params);

  my $arr = [];
  my $cart_items = $dsl->schema($schema)->resultset($cart_product_name)->search( 
    { 
      cart_id => $cart_id,
    },
  );
  my $subtotal = 0;
  while( my $ci = $cart_items->next ){
    my $product =  $dsl->schema->resultset($product_name)->search({ $product_pk => $ci->sku })->single;
    $subtotal += $ci->price * $ci->quantity;
    push @{$arr}, {$product->get_columns, ec_quantity => $ci->quantity, ec_price  => $ci->price };
  }
  return { items => $arr , subtotal => $subtotal };
};

sub _cart_add {
  my ($dsl , $product, $params) = @_;
  $load_settings->();
  my ($name, $schema) = parse_params($params);

  my $product_info = get_product_info($dsl, $product, { schema => $schema } );
  return $product_info if $product_info->{error};

  my $cart_item = cart_add_product($dsl, $product_info, $product->{quantity}, $params);
  return $cart_item;
};

sub _products {
  my ($dsl, $schema) = @_;

  my $product_filter_eval = $product_filter ? eval $product_filter : {};
  my $product_order_eval  = $product_order ? { order_by => { eval $product_order } } : {};
  
  my @products = $dsl->schema($schema)->resultset($product_name)->search( $product_filter_eval , $product_order_eval );
  @products;
}

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
  my ($name, $schema) = parse_params($params);

  #get cart_id
  my $cart_id = _cart($dsl, { name => $name, schema => $schema } )->{id}; 

  #delete the cart_product info
  $dsl->schema($schema)->resultset($cart_product_name)->search({ cart_id => $cart_id })->delete_all;
  #delete products
  $dsl->schema($schema)->resultset($cart_name)->search({ id => $cart_id })->delete;
}

sub _product_quantity{
  my ($dsl, $params) = @_;
  my ($name, $schema) = parse_params($params);
  my $cart_id = _cart($dsl,{name => $name,  schema => $schema })->{id}; 
  my $rs = $dsl->schema($schema)->resultset($cart_product_name)->search(
    { 
      cart_id => $cart_id 
    },
    {
      select => [{ sum => 'quantity' }],
      as => ['quantity']
    }
  );
  $rs->first->get_column('quantity') ? $rs->first->get_column('quantity') : 0;
}

sub _subtotal{
  my ($dsl, $params) = @_;
  my ($name,$schema) = parse_params($params);
  my $subtotal = 0;
  my $cart_products = $dsl->schema($schema)->resultset($cart_product_name)->search(
    {
      cart_id => _cart($dsl,$name,$schema)->{id},
    },
  );
  while( my $ci = $cart_products->next ){
    $subtotal += $ci->price * $ci->quantity;
  }
  $subtotal;
}

sub _place_order{
  my ($dsl, $params) = @_;
  my ($name, $schema) = parse_params($params);
  my $cart = _cart($dsl,{ name => $name, schema => $schema });
  my $cart_temp = $dsl->schema($schema)->resultset($cart_name)->find($cart->{id});
  return { error => 'Cart not found' } unless $cart_temp;
  $cart_temp->update({
    status => 1,
    session => $dsl->session->{id}."_1",
    log => $dsl->to_json( {
      data => $dsl->session->{data},
      session => $dsl->session->{id},
      items => cart_items( $dsl, 
        { 
          cart_id => _cart($dsl,{ name => $name, schema => $schema } )->{id}, 
          schema => $schema 
        } 
      ),
      subtotal => _subtotal( $dsl, { name => $name, schema => $schema } ) },
    ),
  });
  $cart_temp->id;
}

sub parse_params {
  my ($params) = @_;
  return ($params->{name}, $params->{schema}, $params->{status}, $params->{cart_id});
}

register_plugin;
1;
__END__
