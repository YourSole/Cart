my $product_name = undef;
my $product_pk = undef;

$product_name = app->config->{'plugins'}->{'Cart'}->{product_name} || 'EcProduct';
$product_pk = app->config->{'plugins'}->{'Cart'}->{product_pk} || 'sku';
$product_price_f = app->config->{'plugins'}->{'Cart'}->{product_price_f} || 'sellprice';
$products_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{products} || undef;
$cart_view_template = app->config->{'plugins'}->{'Cart'}->{views}->{cart} || undef;
$cart_receipt_template = app->config->{'plugins'}->{'Cart'}->{views}->{receipt} || undef;
$cart_checkout_template = app->config->{'plugins'}->{'Cart'}->{views}->{checkout} || undef;

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
  redirect '/cart/receipt'
};

get '/cart/receipt' => sub {
  my $cart = cart( { status => 1, cart_id => session->read( 'cart_id' ) } );
  my $template = $cart_receipt_template || '/cart/receipt.tt' ;
  session->delete('cart_id');
  if( -e config->{views}.$template ){
    template $template, { cart => $cart };
  }
  else{
     _cart_receipt({ cart => $cart });
  }
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

sub _cart_receipt{
  my ($params) = @_;
  my $page = "";
  my $cart =  $params->{cart};

  $page .= "
  <p>Checkout has been successful!!</p>
  <h1>Cart info</h1>
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
  <h1>Log Info</h1>";
  my $status = $cart->{status} == '0' ? 'Incomplete' : 'Complete';
  $page .= "
  <table>
    <tr><td>Cart logged info: </td><td>". $cart->{log} ."</td></tr>
    <tr><td>Cart status:</td><td>". $status."</td></tr>
  </table>
  <p><a href='../products'> Product index </a></p>";
  $page;  
};

sub _cart_checkout{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $page ="";

  $page .= "<h1>Cart info</h1>\n";

  $page .= "<table><tr><th>SKU</th><th>Quantity</th><th>Price</th></tr>";
  map{ $page .= "<tr><td>".$_->{$product_pk}."</td><td>". $_->{ec_quantity} ."</td><td>".$_->{ec_price}."</td></tr>"; } @{$cart->{items}};
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
}
1;



