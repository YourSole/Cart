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
    default => sub { undef }
  );

  has 'product_pk' => (
    is => 'ro',
    from_config => 'product_pk',
    default => sub { undef }
  );

  has 'product_price' => (
    is => 'ro',
    from_config => 'product_price',
    default => sub { undef }
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

  has 'excluded_routes' => (
    is => 'ro',
    from_config => 1,
    default => sub { [] }
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
    close_cart
    adjustments
  /;

  plugin_hooks qw/
    before_cart
    after_cart
    validate_cart_add_params
    before_cart_add
    after_cart_add
    before_cart_add_item
    after_cart_add_item
    validate_shipping_params
    before_shipping
    after_shipping
    validate_billing_params
    before_billing
    after_billing
    validate_checkout_params
    before_checkout
    checkout
    after_checkout
    before_close_cart
    after_close_cart
    before_clear_cart
    after_clear_cart
    before_item_subtotal
    after_item_subtotal
    before_subtotal
    after_subtotal
    adjustments
  /;
}

sub BUILD {
  my $self = shift;
  #Create a session 
  my $settings = $self->app->config;
  my $excluded_routes = $self->excluded_routes;

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
    )if !grep { $_ eq 'products' }@{$excluded_routes};

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
            ec_cart => $app->session->read('ec_cart'),
          } );
        }
        else{
           $page = _cart_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{add}->{error} if $ec_cart->{add}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart' }@{$excluded_routes};

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/add',
      code => sub {
        my $app = shift;
        $self->cart_add;
        $app->redirect('/cart');
      }
    )if !grep { $_ eq 'cart/add' }@{$excluded_routes};


    $self->app->add_route(
      method => 'get',
      regexp => '/cart/clear',
      code => sub {
        my $app = shift;
        $self->clear_cart;
        $app->redirect('/cart');
      } 
    )if !grep { $_ eq 'cart/clear' }@{$excluded_routes};

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
            ec_cart => $app->session->read('ec_cart'),
          });
        }
        else{
          $page = _shipping_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{shipping}->{error} if $ec_cart->{shipping}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart/shipping' }@{$excluded_routes}; 
  
    $self->app->add_route(
      method => 'post',
      regexp => '/cart/shipping',
      code => sub {
        my $app = shift;
        $self->shipping;
        $app->redirect('/cart/billing');
      }
    )if !grep { $_ eq 'cart/shipping' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/billing',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        my $template = $self->billing_view_template || '/cart/billing.tt' ;
        my $page = "";
        if( -e $app->config->{views}.$template ) {
            $page = $app->template( $template, {
            ec_cart => $app->session->read('ec_cart'),
          });
        }
        else{
          $page = _billing_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{billing}->{error} if $ec_cart->{billing}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart/billing' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/billing',
      code => sub {
        my $app = shift;
        $self->billing; 
        $app->redirect('/cart/review');
      }
    )if !grep { $_ eq 'cart/billing' }@{$excluded_routes}; 
    
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
    )if !grep { $_ eq 'cart/review' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/checkout',
      code => sub {
        my $app = shift;
        $self->checkout;
        $app->redirect('/cart/receipt');
      }
    )if !grep { $_ eq 'cart/receipt' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/receipt',
      code => sub {
        my $app = shift;
        my $template = $self->receipt_view_template || '/cart/receipt.tt' ;
        my $ec_cart = $app->session->read('ec_cart');

        $app->redirect('/') unless $ec_cart->{cart}->{id};

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
    )if !grep { $_ eq 'cart/receipt' }@{$excluded_routes}; 
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
  
  $app->execute_hook('plugin.cart.before_cart');
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

  $self->adjustments;
  $ec_cart = $app->session->read('ec_cart');

  my $total = $self->get_total; 
  $ec_cart = $app->session->read('ec_cart');

  $app->execute_hook('plugin.cart.after_cart');
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
    my $product =  undef;

    if($self->product_name && $self->product_pk ){
      $product = $self->dbic->schema($schema)->resultset($self->product_name)->search({ $self->product_pk => $ci->sku })->single;
    }

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
  my ($self, $params) = @_;
  my ($name, $schema) = _parse_params($params);

  my $app = $self->app;
  my $form_params = { $app->request->params };
  my $product = undef;
  
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{add}->{form} = $form_params; 
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
      my $ec_price = $self->product_price;


      if($self->product_name && $self->product_pk && $self->product_price ) {
        my $product_temp = $self->dbic->schema($schema)->resultset($self->product_name)->search({ $self->product_pk => $ec_cart->{add}->{form}->{ec_sku}  })->single;
        if ( $product_temp ){
          my $ec_price = $self->product_price;
          $ec_cart->{add}->{form}->{ec_price} = $product_temp->$ec_price;
        }
      }
       
      $app->execute_hook( 'plugin.cart.before_cart_add_item' );
      $product = $self->cart_add_item({
          ec_sku => $ec_cart->{add}->{form}->{'ec_sku'},
          ec_quantity => $ec_cart->{add}->{form}->{'ec_quantity'},
          ec_price => $ec_cart->{add}->{form}->{'ec_price'} || 0
        }
      );
      $app->execute_hook( 'plugin.cart.after_cart_add_item' );

      #Cart operations after adding product to the cart
      $app->execute_hook( 'plugin.cart.after_cart_add' );
      $ec_cart = $app->session->read('ec_cart');
      delete $ec_cart->{add};
      $app->session->write( 'ec_cart', $ec_cart );
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
    $app->execute_hook( 'plugin.cart.after_shipping' );
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
    $app->execute_hook( 'plugin.cart.after_billing' );
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
    $app->execute_hook( 'plugin.cart.checkout' ); 
    $self->close_cart;
    $app->execute_hook( 'plugin.cart.after_checkout' );
  }
}

sub close_cart{
  my ($self, $params) = @_;
  my ($name, $schema) = _parse_params($params);
  my $app = $self->app;

  my $cart = $self->cart({ name => $name, schema => $schema });
  return { error => 'Cart without items' } unless @{$cart->{items}} > 0;

  my $cart_temp = $self->dbic->schema($schema)->resultset($self->cart_name)->find($cart->{id});
  return { error => 'Cart not found' } unless $cart_temp;
  require Dancer2::Serializer::JSON;

  $app->execute_hook( 'plugin.cart.before_close_cart' ); 
  $cart_temp->update({
    status => 1,
    log => Dancer2::Serializer::JSON::to_json( {
      session => $app->session->{id},
      data => $app->session->{data},
      ec_cart => $app->session->read('ec_cart'),
    })
  });

  $app->session->delete( 'ec_cart' );
  $app->session->write('ec_cart',{ cart => { id => $cart_temp->id } } );

  $app->execute_hook( 'plugin.cart.after_close_cart' ); 

  my $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart}->{id};
}

sub adjustments {
  my ($self, $params) = @_;
  my ($name, $schema) = _parse_params($params);
  my $app = $self->app;
  my $ec_cart = $app->session->read('ec_cart');
  my $default_adjustments = [
    {
      description => 'Discounts',
      value => '0'
    },
    {
      description => 'Shipping',
      value => '0'
    },
    {
      description => 'Taxes',
      value => '0'
    },
  ];
  $ec_cart->{cart}->{adjustments} = $default_adjustments;
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook('plugin.cart.adjustments');
}


sub get_total {
  my ($self) = shift;
  my $app = $self->app;
  my $total = 0;
  my $ec_cart = $app->session->read('ec_cart');
  
  $total += $ec_cart->{cart}->{subtotal};
  foreach my $adjustment ( @{$ec_cart->{cart}->{adjustments}}){
    $total += $adjustment->{value};
  }

  $ec_cart->{cart}->{total} = $total;
  $app->session->write('ec_cart', $ec_cart );

  return $total;
}

sub _parse_params {
  my ($params) = @_;
  return ($params->{name}, $params->{schema}, $params->{status}, $params->{cart_id});
}

1;
__END__
