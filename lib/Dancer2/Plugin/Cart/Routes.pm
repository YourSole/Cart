use Dancer2::Plugin::Email;
use Dancer2::Plugin::Cart::InlineViews;

my $product_pk = app->config->{'plugins'}->{'Cart'}->{product_pk} || 'sku';
my $products_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{products} || undef;
my $cart_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{cart} || undef;
my $cart_receipt_template = app->config->{'plugins'}->{'Cart'}->{views}->{receipt} || undef;
my $cart_checkout_template = app->config->{'plugins'}->{'Cart'}->{views}->{checkout} || undef;
my $mail_sender_account  = undef;
my $mail_logger_account = undef;

if(app->config->{'plugins'}->{'Cart'}->{email}){
  $mail_sender_account = app->config->{'plugins'}->{'Cart'}->{email}->{logger};
  $mail_logger_account = app->config->{'plugins'}->{'Cart'}->{email}->{sender};
}

get '/products' => sub {
  my $template = $products_view_template || '/products.tt' ;
  if( -e config->{views}.$template ) {
    my @products = products;
    template $template, {
      products => products
    };
  }
  else{
     _products_view({ products => products, product_pk => $product_pk });
  }
};

post '/cart/add' => sub {
  my $product = { sku => param('sku'), quantity => param('quantity') };
  my $res = cart_add($product);
  redirect '/cart';
};

get '/cart' => sub {
  my $cart = cart;
  my $template = $cart_view_template || '/cart/cart.tt' ;
  if( -e config->{views}.$template ) {
    template $template, {
      cart => $cart
    };
  }
  else{
     _cart_view({ cart => $cart, product_pk => $product_pk });
  }
};

get '/cart/clear' => sub {
  clear_cart;
  redirect '/cart';
};

get '/cart/checkout' => sub {
  my $cart = cart;
  redirect '/products' unless @{$cart->{items}} > 0;
  my $template = $cart_checkout_template || '/cart/checkout.tt' ;

  my $page = "";
  if( -e config->{views}.$template ){
    $page = template $template, {
      cart => $cart,
      error => session->read('error'),
     };
    session->delete('error');
  }
  else{
     $page = _cart_checkout({ cart => $cart });
  }
  $page;
};

post '/cart/checkout' => sub {
  #Place order
  #Validate user info
  my $email = param('email'); 
  if (! (uc($email) =~ /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/) ){
    session->write('error',"Validation failed");
    redirect '/cart/checkout' 
  }
  session->write('email',$email);
  #Delete cc info.
  #log the info on place order and set the cart_id on session
  session->write('cart_id', place_order);
  #Clear form variables and private info
  session->delete('email');
  
  if( session->read('cart_id')->{error} ){
    session->write('error', session->read('cart_id')->{error} );
    session->delete('cart_id');
    redirect '/cart/checkout';
  }
  else{
    redirect '/cart/receipt';
  }
};

get '/cart/receipt' => sub {

  redirect '/products' unless session->read( 'cart_id' );

  my $cart = cart( { status => 1, cart_id => session->read( 'cart_id' ) } );
  my $template = $cart_receipt_template || '/cart/receipt.tt' ;
  session->delete('cart_id');

  my $page = "";
  $cart->{status} = $cart->{status} ? 'Complete' : 'Incomplete';
  if( -e config->{views}.$template ){
    $page = template $template, {
      cart => $cart,
      log => from_json($cart->{log}),
    };
  }
  else{
    $page = _cart_receipt({ cart => $cart });
  }

  #Send email if it has been configured
  use Try::Tiny;
  if ($mail_sender_account && $mail_logger_account ){
    try{
      email {
        from    => $mail_sender_account,
        to      => from_json( $cart->{log} )->{data}->{email},
        cc     => $mail_logger_account,
        subject => 'Receipt #'.$cart->{id},
        body    =>  $page,
        type    => 'html',
      };
    }
    catch{
      error "Could not send email: $_";
    };
  }
  $page .= "<p><a href='../products'> Product index </a></p>";
  $page;
};
1;
