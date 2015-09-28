my $product_name = undef;
my $product_pk = undef;


$product_name = app->config->{'plugins'}->{'ECommerce::Cart'}->{product_name} || 'EcProduct';
$product_pk = app->config->{'plugins'}->{'ECommerce::Cart'}->{product_pk} || 'sku';
$product_price_f = app->config->{'plugins'}->{'ECommerce::Cart'}->{product_price_f} || 'sellprice';

get '/products' => sub {
  my $page = "<table><tr><th>Sku</th><th>Action</th></tr>";
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
  my $page = "";

  if (@{$products} > 0 ) {
    $page .= "<a href='products'> Continue shooping. </a>";
    $page .= "<table><tr><th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th></tr>\n";
    map{
      $page .= "<tr><td>".$_->{$product_pk}."</td><td><form method='post' action='cart/add'>
      <input type='hidden' name='sku' value='".$_->{$product_pk}."'>
      <input type='hidden' name='quantity' value='-1'>
      <input type='submit' value = '-1'>
      </form></td><td>". $_->{quantity} ."</td><td>
      <form method='post' action='cart/add'>
        <input type='hidden' name='sku' value='".$_->{$product_pk}."'>
        <input type='hidden' name='quantity' value='1'>
        <input type='submit' value = '+1'>
      </form></td><td>".$_->{price}."</td</tr>\n";
    } @{$products};
    $page .= "<tr><td colspan=4>Subtotal</td><td>".subtotal."</td></tr>";
    $page .= "</table>";
    $page .= "<a href='cart/clear'> Clear your cart. </a>";
  }
  else{
    $page .= "Your cart is empty. <a href='products'> Continue shooping. </a>";
  }
  $page;
};

get '/cart/clear' => sub {
  clear_cart;
  redirect '/cart';
};

1;



