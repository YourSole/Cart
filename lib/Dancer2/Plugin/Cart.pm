package Dancer2::Plugin::Cart;
use strict;
use warnings;
use Dancer2::Plugin2;
use Dancer2::Plugin::Cart::InlineViews;
our $VERSION = '0.0001';  #Version

BEGIN{
  has 'dbic' => (
      is => 'ro',
      lazy => 1,
      default => sub {
          scalar $_[0]->app->with_plugin( 'DBIC' )
      },
      handles => { 'schema' => 'schema', 'resultset' => 'resultset' },
  );


  has 'cart_name' => (
    is => 'ro',
    from_config => 'cart_name',
    default => sub { 'EcCart' }
  );

  has 'cart_product_name' => (
    is => 'ro',
    from_config => 'cart_product_name',
    default => sub { 'EcCartProduct' }
  );

  has 'product_name' => (
    is => 'ro',
    from_config => 'product_name',
    default => sub { 'EcProduct' }
  );

  has 'product_pk' => (
    is => 'ro',
    from_config => 'product_pk',
    default => sub { 'sku' }
  );

  has 'product_price' => (
    is => 'ro',
    from_config => 'product_price',
    default => sub { 'price' }
  );

  has 'product_filter' => (
    is => 'ro',
    from_config => 'product_filter',
    default => sub { undef } 
  );

  has 'product_order' => (
    is => 'ro',
    from_config => 'product_order',
    default => sub { undef }
  );

  has 'products_view_template' => (
    is => 'ro',
    from_config => 'views.products',
    default => sub {}
  );

  has 'cart_view_template' => (
    is => 'ro',
    from_config => 'views.products',
    default => sub {}
  );

  has 'cart_receipt_template' => (
    is => 'ro',
    from_config => 'views.receipt',
    default => sub {}
  );

  has 'cart_checkout_template' => (
    is => 'ro',
    from_config => 'views.checkout',
    default => sub {}
  );

  has 'shipping_view_template' => (
    is => 'ro',
    from_config => 'views.shipping',
    default => sub {}
  );

  has 'billing_view_template' => (
    is => 'ro',
    from_config => 'views.billing',
    default => sub {}
  );

  has 'review_view_template' => (
    is => 'ro',
    from_config => 'views.review',
    default => sub {}
  );

  has 'receipt_view_template' => (
    is => 'ro',
    from_config => 'views.receipt',
    default => sub {}
  );

  has 'default_routes' => (
    is => 'ro',
    from_config => 1,
    default => sub { '1' }
  );

  plugin_keywords qw/ 
    products
    cart
    cart_add
    cart_add_item
    cart_items
    clear_cart
    subtotal
    billing
    shipping
    checkout
    place_order
  /;

  plugin_hooks qw/
    validate_cart_add_params
    before_cart_add
    after_cart_add
    validate_shipping_params
    before_shipping
    get_rates 
    after_shipping
    validate_billing_params
    before_billing
    billing
    after_billing
    validate_checkout_params
    before_checkout
    after_checkout
    before_clear_cart
    after_clear_cart
    before_item_subtotal
    after_item_subtotal
    before_subtotal
    after_subtotal
    taxes
  /;
}

sub BUILD {
  my $self = shift;
  #Create a session 
  my $settings = $self->app->config;
  if( $self->default_routes ){  
    $self->app->add_route(
      method => 'get',
      regexp => '/products',
      code   => sub { 
        my $app = shift;
        #generate session if didn't exists
        $app->session;
        my $template = $self->products_view_template || '/products.tt' ;
        if( -e $self->app->config->{views}.$template ) {
          my @products = $self->products;
          $app->template( $template, {
            products => $self->products
          } );
        }
        else{
          _products_view({ products => $self->products, product_pk => $self->product_pk });
        }
      },
    );

    $self->app->add_route(
      method => 'get',
      regexp => '/cart',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        #Generate session if didn't exists
        $app->session;
        my $template = $self->cart_view_template || '/cart/cart.tt' ;
        my $page = "";
        if( -e $self->app->config->{views}.$template ) {
          $page = $app->template(  $template, {
            cart => $cart
          } );
        }
        else{
           $page = _cart_view({ cart => $cart, product_pk => $self->product_pk });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{add}->{error} if $ec_cart->{add}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    );

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/add',
      code => sub {
        my $app = shift;
        $self->cart_add;
        $app->redirect('/cart');
      }
    );

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/clear',
      code => sub {
        my $app = shift;
        $self->clear_cart;
        $app->redirect('/cart');
      } 
    );

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/shipping',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        my $template = $self->shipping_view_template || '/cart/shipping.tt';
        my $page = "";
        if( -e $app->config->{views}.$template ) {
            $page = $app->template ($template, {
            cart => $cart,
            ec_cart => $app->session->read('ec_cart'),
          });
        }
        else{
          $page = _shipping_view({ cart => $cart, ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{shipping}->{error} if $ec_cart->{shipping}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    ); 
  
    $self->app->add_route(
      method => 'post',
      regexp => '/cart/shipping',
      code => sub {
        $self->shipping;
      }
    );

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/billing',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        my $template = $self->billing_view_template || '/cart/billing.tt' ;
        if( -e $app->config->{views}.$template ) {
            $app->template( $template, {
              cart => $cart,
              ec_cart => $app->session->read('ec_cart'),
            });
        }
        else{
          _billing_view({ ec_cart => $app->session->read('ec_cart') });
        }
      }
    );

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/billing',
      code => sub {
        $self->billing; 
      }
    );
    
    $self->app->add_route(
      method => 'get',
      regexp => '/cart/review',
      code => sub { 
        my $app = shift;
        my $cart = $self->cart;
        my $page = "";
        my $template = $self->review_view_template || '/cart/review.tt' ;
        if( -e $app->config->{views}.$template ) {
            $page = $app->template($template,{
              cart => $cart,
              ec_cart => $app->session->read('ec_cart'),
            });
        }
        else{
          $page = _review_view( { cart => $cart , ec_cart => $app->session->read('ec_cart') } );
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{checkout}->{error} if $ec_cart->{checkout}->{error};
        $app->session->write('ec_cart',$ec_cart);
        $page;
      }
    );

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/checkout',
      code => sub {
        $self->checkout;
      }
    );

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/receipt',
      code => sub {
        my $app = shift;
        my $template = $self->receipt_view_template || '/cart/receipt.tt' ;
        my $ec_cart = $app->session->read('ec_cart');
        $app->redirect('/products') unless $ec_cart->{cart}->{id};
        my $cart = $self->cart( { status => 1, cart_id => $ec_cart->{cart}->{id} });
        require Dancer2::Serializer::JSON;
        $cart->{log} =  Dancer2::Serializer::JSON::from_json( $cart->{log} );
        my $page = "";
        if( -e $app->config->{views}.$template ) {
            $page = $app->template($template, { cart => $cart } );
        }
        else{
          $page = _receipt_view({ cart => $cart });
        }
        $app->session->delete('ec_cart');
        $page;
      }
    );
  }
};


sub products {
  my ($self, $params) = @_;
  my ($name, $schema) = _parse_params($params);

  my $product_filter_eval = $self->product_filter ? eval $self->product_filter : {};
  my $product_order_eval  = $self->product_order ? { order_by => { eval $self->product_order } } : {};

  my $arr = [];
  my $products = $self->dbic->schema($schema)->resultset($self->product_name)->search( $product_filter_eval, $product_order_eval );

  while( my $product = $products->next ){
    my $ec_sku = $self->product_pk;
    my $ec_price = $self->product_price;
    push @{$arr}, { $product->get_columns, ec_sku => $product->$ec_sku, ec_price => $product->$ec_price || 0 };
  }
  $arr;
}
sub cart_add_item {
  my ( $self, $product, $params ) = @_;
  my ( $name, $schema ) = _parse_params($params);

  #check if the product exists other whise create a new one
  my $cart_product = $self->dbic->schema($schema)->resultset($self->cart_product_name)->find({
    cart_id =>  $self->cart( $params )->{id},
    sku => $product->{ ec_sku },
  });
  if( $cart_product ){
   if ( $cart_product->quantity + $product->{ec_quantity} > 0 ){
      $cart_product->update({
        quantity => $cart_product->quantity + $product->{ec_quantity}
      });
    }
    else{
      $cart_product->delete;
    }
  } 
  else{
    my $cart_id = $self->cart( $params )->{id};
    my $place = $self->dbic->schema($schema)->resultset($self->cart_product_name)->search({ cart_id=> $cart_id })->get_column('place')->max() || 0;
     $cart_product = $self->dbic->schema($schema)->resultset($self->cart_product_name)->create({
      cart_id => $cart_id, 
      sku => $product->{ec_sku},
      price => $product->{ec_price} || 0,
      quantity => $product->{ec_quantity} || 0,
      place => $place + 1,
    });
  }
  return $cart_product ? { $cart_product->get_columns } : { error => "Error trying to create CartProduct."};
};

sub cart {
  my ($self, $params ) = @_;
  my ($name, $schema, $status, $cart_id) = _parse_params($params);
  my $app = $self->app;
  my $cart_info = {
    session => $self->app->session->{'id'},
  };

  $cart_info->{name} = $name || 'main';
  $cart_info->{status} = $status ? $status : 0;

  if ( $cart_id ){
    $cart_info->{id} = $cart_id;
    delete $cart_info->{session};
  }
  
  my $cart = undef;
  if ( $cart_info->{status} == 0 ){
    $cart = $self->dbic->schema($schema)->resultset($self->cart_name)->find_or_create($cart_info);
  }
  else{
    $cart = $self->schema($schema)->resultset($self->cart_name)->search($cart_info)->first;
  }
  $params->{cart_id} = $cart->id if $cart;

  my $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart} = { $cart->get_columns } if $cart;
  $app->session->write( 'ec_cart', $ec_cart );

  #Get cart items
  my $cart_items = $self->cart_items ( $params );
 
  #get subtotal
  my $subtotal = $self->subtotal;

  $app->execute_hook('plugin.cart.taxes');
  $ec_cart = $app->session->read('ec_cart');
  
  return { $cart->get_columns, items => $ec_cart->{cart}->{items} , subtotal => $ec_cart->{cart}->{subtotal} } if $cart;

};

sub cart_items {
  my ( $self, $params ) = @_;
  my ($name, $schema, $status, $cart_id ) = _parse_params($params);
  my $app = $self->app;
  my $arr_items = [];
  my $cart_items = $self->dbic->schema($schema)->resultset($self->cart_product_name)->search( 
    { 
      cart_id => $cart_id,
    },
    {
      order_by => { '-asc' => 'place' }
    }
  );

  while( my $ci = $cart_items->next ){
    my $product =  $self->dbic->schema($schema)->resultset($self->product_name)->search({ $self->product_pk => $ci->sku })->single;

    my $item_subtotal = $self->item_subtotal( { ec_sku => $ci->sku, ec_quantity => $ci->quantity, ec_price => $ci->price } ) || 0;
    
    if ($product) {
      push @{$arr_items}, { $product->get_columns, ec_sku => $ci->sku , ec_quantity => $ci->quantity, ec_price  => $ci->price, ec_subtotal => $item_subtotal  };
    }
    else{
      push @{$arr_items}, { ec_sku => $ci->sku , ec_quantity => $ci->quantity, ec_price  => $ci->price, ec_subtotal => $item_subtotal };
    }
  } 

  my $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart}->{items} = $arr_items;
  $app->session->write( 'ec_cart', $ec_cart );
  
  return { items => $ec_cart->{cart}->{items} };
};

sub item_subtotal{
  my ($self, $params) = @_;
  my $app = $self->app;
  my $subtotal = 0;
  my $ec_cart = $app->session->read('ec_cart');

  $ec_cart->{item} = $params;
  $app->session->write( 'ec_cart', $ec_cart );

  $app->execute_hook('plugin.cart.before_item_subtotal');
  $ec_cart = $app->session->read('ec_cart');

  $ec_cart->{item}->{subtotal} = $ec_cart->{item}->{ec_price} * $ec_cart->{item}->{ec_quantity};
  $app->session->write( 'ec_cart', $ec_cart );

  $app->execute_hook('plugin.cart.after_item_subtotal');
  $ec_cart = $app->session->read('ec_cart');
  $subtotal = $ec_cart->{item}->{subtotal};

  delete $ec_cart->{item};

  $app->session->write( 'ec_cart', $ec_cart );

  $subtotal;
};


sub subtotal{
  my ($self, $params) = @_;
  my ($name,$schema) = _parse_params($params);
  my $app = $self->app;

  $self->execute_hook ('plugin.cart.before_subtotal');

  my $ec_cart = $app->session->read('ec_cart');
  my $subtotal = 0;

  foreach my $item_subtotal ( @{ $ec_cart->{cart}->{items} } ){
    $subtotal += $item_subtotal->{ec_subtotal};
  }

  $ec_cart->{cart}->{subtotal} = $subtotal;
  $app->session->write('ec_cart',$ec_cart);
  $self->execute_hook ('plugin.cart.after_subtotal');
  $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart}->{subtotal};
}


sub clear_cart {
  my ($self, $params ) = @_;
  my ($name, $schema) = _parse_params($params);

  $self->execute_hook ('plugin.cart.before_clear_cart');
  #get cart_id
  my $cart_id = $self->cart({ name => $name, schema => $schema })->{id}; 

  #delete the cart_product info
  $self->schema($schema)->resultset($self->cart_product_name)->search({ cart_id => $cart_id })->delete_all;
  #delete products
  $self->schema($schema)->resultset($self->cart_name)->search({ id => $cart_id })->delete;
  $self->app->session->delete('ec_cart');
  $self->execute_hook ('plugin.cart.after_clear_cart');
}


sub cart_add {
  my $self = shift;
  my $app = $self->app;
  my $params = { $app->request->params };
  my $product = undef;
  
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{add}->{form} = $params; 
  $app->session->write( 'ec_cart', $ec_cart );

  #Param validation
  $app->execute_hook( 'plugin.cart.validate_cart_add_params' );
  $ec_cart = $app->session->read('ec_cart');

  if ( $ec_cart->{add}->{error} ){
    $self->app->redirect( $app->request->referer || $app->request->uri  );
  }
  else{
    #Cart operations before add product to the cart.
    $app->execute_hook( 'plugin.cart.before_cart_add' );
    $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{add}->{error} ){
      $self->app->redirect( $app->request->referer || $app->request->uri  );
    }
    else{
      $product = $self->cart_add_item({
          ec_sku => $ec_cart->{add}->{form}->{'ec_sku'},
          ec_quantity => $ec_cart->{add}->{form}->{'ec_quantity'}
        }
      );

      #Cart operations after adding product to the cart
      $app->execute_hook( 'plugin.cart.after_cart_add' );
      $self->app->redirect( '/cart' );
    }
  }
}

sub shipping {
  my $self = shift;
  my $app = $self->app;
  my $params = { $app->request->params };
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{shipping}->{form} = $params; 
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.validate_shipping_params' );
  $ec_cart = $app->session->read('ec_cart');
  if ( $ec_cart->{shipping}->{error} ){ 
    $app->redirect( $app->request->referer || $app->request->uri );
  }
  else{
    $app->execute_hook( 'plugin.cart.before_shipping' );
    my $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{shipping}->{error} ){
      
      $app->redirect( ''.$app->request->referer || $app->request->uri  );
    }
    else{  
      $app->execute_hook( 'plugin.cart.get_rates' );
    }
    $app->execute_hook( 'plugin.cart.after_shipping' );
    $app->redirect('/cart/billing');
  }
}

sub billing{
  my $self = shift;
  my $app = $self->app;
  my $params = { $app->request->params };
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{billing}->{form} = $params; 
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.validate_billing_params' );
  $ec_cart = $app->session->read('ec_cart');
  if ( $ec_cart->{billing}->{error} ){
    $app->redirect( $app->request->referer || $app->request->uri );
  }
  else{
    $app->execute_hook( 'plugin.cart.before_billing' );
    my $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{billing}->{error} ){
      $app->redirect( $app->request->referer || $app->request->uri  );
    }
    else{  
      $app->execute_hook( 'plugin.cart.billing' );
    }
    $app->execute_hook( 'plugin.cart.after_billing' );
    $app->redirect('/cart/review');
  }
}

sub checkout{
  my $self = shift;
  my $app = $self->app;

  my $params = ($app->request->params);
  $app->execute_hook( 'plugin.cart.validate_checkout_params' );
  my $ec_cart = $app->session->read('ec_cart');

  if ( $ec_cart->{checkout}->{error} ){
    $app->redirect( $app->request->referer || $app->request->uri  );
  }
  else{
    $app->execute_hook( 'plugin.cart.before_checkout' ); 
    my $cart_id = $self->place_order;
    $app->session->delete( 'ec_cart' );
    $app->session->write('ec_cart',{ cart => { id => $cart_id } } );
    $app->execute_hook( 'plugin.cart.after_checkout' );
    $app->redirect('/cart/receipt');
  }
}

sub place_order{
  my ($self, $params) = @_;
  my ($name, $schema) = _parse_params($params);
  my $app = $self->app;

  my $cart = $self->cart({ name => $name, schema => $schema });
  return { error => 'Cart without items' } unless @{$cart->{items}} > 0;

  my $cart_temp = $self->dbic->schema($schema)->resultset($self->cart_name)->find($cart->{id});
  return { error => 'Cart not found' } unless $cart_temp;
  require Dancer2::Serializer::JSON;
  
  $cart_temp->update({
    status => 1,
    log => Dancer2::Serializer::JSON::to_json( {
      data => $app->session->{data},
      session => $app->session->{id},
      cart => $app->session->{ec_cart}
    })
  });
  $cart_temp->id;
}

sub _parse_params {
  my ($params) = @_;
  return ($params->{name}, $params->{schema}, $params->{status}, $params->{cart_id});
}

1;
__END__
