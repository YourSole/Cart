use Dancer2::Plugin::Email;

my $product_name = undef;
my $product_pk = undef;

$product_name = app->config->{'plugins'}->{'Cart'}->{product_name} || 'EcProduct';
$product_pk = app->config->{'plugins'}->{'Cart'}->{product_pk} || 'sku';
$product_price_f = app->config->{'plugins'}->{'Cart'}->{product_price_f} || 'sellprice';
$products_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{products} || undef;
$cart_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{cart} || undef;
$cart_receipt_template = app->config->{'plugins'}->{'Cart'}->{views}->{receipt} || undef;
$cart_checkout_template = app->config->{'plugins'}->{'Cart'}->{views}->{checkout} || undef;
$mail_sender_account  = undef;
$mail_logger_account = undef;
if(app->config->{'plugins'}->{'Cart'}->{email}){
  $mail_sender_account = app->config->{'plugins'}->{'Cart'}->{email}->{logger};
  $mail_logger_account = app->config->{'plugins'}->{'Cart'}->{email}->{sender};
}

get '/products' => sub {
  my $template = $products_view_template || '/products.tt' ;
  if( -e config->{views}.$template ) {
    template $template;
  }
  else{
     _products_view();
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
    template $template, { cart => $cart };
  }
  else{
     _cart_view({ cart => $cart });
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
  if( -e config->{views}.$template ){
    template $template, { cart => $cart };
  }
  else{
     _cart_checkout({ cart => $cart });
  }
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
  if( -e config->{views}.$template ){
    $page = template $template, { cart => $cart };
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

sub _products_view{
  my ($params) = @_;
  my $page ="";
  $page .= "
  <h1>Product list</h1>
  <table>
    <thead>
      <tr>
        <th>Sku</th><th>Action</th>
      </tr>
    </thead>
    <tbody>";
  my @products = products;
  foreach my $product (products) {
    $page .= "
      <tr>
        <td>".$product->$product_pk."</td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$product->$product_pk."'>
            <input type='hidden' name='quantity' value='1'>
            <input type='submit' value = 'Add'>
          </form>
        </td>
      </tr>";
  };
  $page .= "
    </tbody>
  </table>";
  $page;
}

sub _cart_view{
  my ($params) = @_;
  my $page = "";
  my $cart = $params->{cart};
  $page .=  "<h1>Cart</h1>\n";
  if (@{$cart->{items}} > 0 ) {
    $page .= "<a href='products'> Continue shopping. </a>\n";
    $page .= "
    <table>
      <thead>
        <tr>
          <th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th>
        </tr>
      </thead>
      <tbody>";
    foreach my $item (@{$cart->{items}}){
      $page .= "
        <tr>
          <td>".$item->{$product_pk}."</td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$item->{$product_pk}."'>
            <input type='hidden' name='quantity' value='-1'>
            <input type='submit' value = '-1'>
            </form>
          </td>
          <td>". $item->{ec_quantity} ."</td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$item->{$product_pk}."'>
            <input type='hidden' name='quantity' value='1'>
            <input type='submit' value = '+1'>
            </form>
          </td>
          <td>".$item->{ec_price}."</td>
        </tr>";
    }
    $page .= "
      </tbody>
      <tfoot>
        <tr>
          <td colspan=4>Subtotal</td><td>".$cart->{subtotal}."</td>
        </tr>
      </tfoot>
    </table>";
    $page .= "\n<p><a href='cart/clear'> Clear your cart. </a></p>";
    $page .= "\n<p><a href='cart/checkout'> Checkout. </a></p>";
  }
  else{
    $page .= "Your cart is empty. <a href='products'> Continue shopping. </a>";
  }
  $page;
}

sub _cart_checkout{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $page ="";

  $page .= "

  <h1>Cart info</h1>
  <h2>Receipt: ".$cart->{id}."</h2>";
  
  $page .= "
  <table>
    <tr>
      <th>SKU</th><th>Quantity</th><th>Price</th>
    </tr>";
  foreach my $item ( @{$cart->{items}} ){ 
  $page .= "
    <tr>
      <td>".$item->{$product_pk}."</td>
      <td>". $item->{ec_quantity} ."</td>
      <td>".$item->{ec_price}."</td>
    </tr>"; 
  };
  $page .= "
    <tr>
      <td colspan=2>Subtotal</td><td>".$cart->{subtotal}."</td>
    </tr>
  </table>";


  if (  session->read('error') ){
    $page .= "<p>".session('error')."</p>";
    session->delete('error');
  }
  $page .= "
    <p>Info required to check out:</p>
    <form method='post' action='checkout'>
     Email <input type='text' name='email' value='".param('email')."' paceholder='email\@domain.com'>
      <input type='submit' value = 'Process checkout'>
    </form>";
}

sub _cart_receipt{
  my ($params) = @_;
  my $page = "";
  my $cart =  $params->{cart};
  my $log = from_json($cart->{log});

  $page .= "
  <p>Checkout has been successful!!</p>
  <h1>Receipt #: ".$cart->{id}." </h1>
  <h2>Cart Info</h2>
  <table>
    <thead>
      <tr>
        <th>SKU</th><th>Quantity</th><th>Price</th>
      </tr>
    </thead>
    <tbody>";
  foreach my $item ( @{ $cart->{items} } ){
    $page .= "
      <tr>
        <td>".$item->{$product_pk}."</td>
        <td>". $item->{ec_quantity} ."</td>
        <td>".$item->{ec_price}."</td>
      </tr>";
  }
  $page .= "
    </tbody>
    <tfoot>
      <tr>
        <td colspan=2>Subtotal</td><td>".$cart->{subtotal}."</td>
      </tr>
    </tfoot>
  </table>
  <h2>Log Info</h2>";
  my $status = $cart->{status} == '0' ? 'Incomplete' : 'Complete';
  $page .= "
  <table>
    <tr><td>Cart status:</td><td>". $status."</td></tr>
    <tr><td>Email</td><td>".$log->{data}->{email}."</td>
  </table>";
  $page;  
};

1;
