my $product_name = undef;
my $product_pk = undef;


$product_name = app->config->{'plugins'}->{'Cart'}->{product_name} || 'EcProduct';
$product_pk = app->config->{'plugins'}->{'Cart'}->{product_pk} || 'sku';
$product_price_f = app->config->{'plugins'}->{'Cart'}->{product_price_f} || 'sellprice';

get '/products' => sub {
  my $page = "<h1>Product list</h1>";
  $page .= "<table><tr><th>Sku</th><th>Action</th></tr>";
  my @products = products;
  map {
    $page .= "<tr><td>".$_->$product_pk."</td><td><form method='post' action='cart/add'>
    <input type='hidden' name='sku' value='".$_->$product_pk."'>
    <input type='hidden' name='quantity' value='1'> 
    <input type='submit' value = 'Add'>
    </form></td></tr>\n";
  } @products; 
  $page .= "</table>";
  $page;
};

post '/cart/add' => sub {
  my $product = { sku => param('sku'), quantity => param('quantity') };
  my $res = cart_add($product);
  redirect '/cart';
};

get '/cart' => sub {
  my $products = cart_products;
  my $page = "<h1>Cart</h1>";

  if (@{$products} > 0 ) {
    $page .= "<a href='products'> Continue shopping. </a>";
    $page .= "<table><tr><th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th></tr>\n";
    map{
      $page .= "<tr><td>".$_->{$product_pk}."</td><td><form method='post' action='cart/add'>
      <input type='hidden' name='sku' value='".$_->{$product_pk}."'>
      <input type='hidden' name='quantity' value='-1'>
      <input type='submit' value = '-1'>
      </form></td><td>". $_->{ec_quantity} ."</td><td>
      <form method='post' action='cart/add'>
        <input type='hidden' name='sku' value='".$_->{$product_pk}."'>
        <input type='hidden' name='quantity' value='1'>
        <input type='submit' value = '+1'>
      </form></td><td>".$_->{ec_price}."</td></tr>\n";
    } @{$products};
    $page .= "<tr><td colspan=4>Subtotal</td><td>".subtotal."</td></tr>";
    $page .= "</table>";
    $page .= "<p><a href='cart/clear'> Clear your cart. </a></p>";
    $page .= "<p><a href='cart/checkout'> Checkout. </a></p>";
  }
  else{
    $page .= "Your cart is empty. <a href='products'> Continue shopping. </a>";
  }
  $page;
};

get '/cart/clear' => sub {
  clear_cart;
  redirect '/cart';
};

get '/cart/checkout' => sub {
  my $products = cart_products;

  my $page = "<h1>Cart info</h1>";

  $page .= "<table><tr><th>SKU</th><th>Quantity</th><th>Price</th></tr>";
  map{ $page .= "<tr><td>".$_->{$product_pk}."</td><td>". $_->{ec_quantity} ."</td><td>".$_->{ec_price}."</td></tr>"; } @{$products};
  $page .= "<tr><td colspan=2>Subtotal</td><td>".subtotal."</td></tr>";
  $page .= "</table>";


  if (  session->read('error') ){
    $page .= "<p>".session('error')."</p>"; 
    session->delete('error');
  }
  $page .= "<p>Info required to check out:</p>
    <form method='post' action='checkout'>
    Email <input type='text' name='email' value='".param('email')."' paceholder='email\@domain.com'>
    <input type='submit' value = 'Process checkout'>
    </form>";
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

  #log the info on place order and set the cart_id on session
  session->write('cart_id', place_order);

  redirect '/cart/receipt'
};

get '/cart/receipt' => sub {
  my $page = "<p>Checkout has been successful!!</p>";
  my $cart = cart_complete( { cart_id => session->read( 'cart_id' ) } );
  $page .= "<h1>Cart info</h1>";
  $page .= "<table><tr><th>SKU</th><th>Quantity</th><th>Price</th></tr>";
  map{ $page .= "<tr><td>".$_->{$product_pk}."</td><td>". $_->{ec_quantity} ."</td><td>".$_->{ec_price}."</td></tr>"; } @{$cart->{products}};
  $page .= "<tr><td colspan=2>Subtotal</td><td>".$cart->{subtotal}."</td></tr>";
  $page .= "</table>";

  $page .= "<h1>Log info</h1>";
  my $status = $cart->{status} == '0' ? 'Incomplete' : 'Complete';
  $page .= "<table>";
  $page .= "<tr><td>Cart logged info: </td><td>". $cart->{log} ."</td></tr>";
  $page .= "<tr><td>Cart status:</td><td>". $status."</td></tr>";
  $page .= "</table>";
  $page .= "<p><a href='../products'> Product index </a></p>";
};

1;



