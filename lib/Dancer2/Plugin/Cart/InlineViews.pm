sub _products_view{
  my ($params) = @_;
  my $products = $params->{products};
  my $product_pk = $params->{product_pk};
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
  foreach my $product (@{$products}) {
    $page .= "
      <tr>
        <td>".$product->{$product_pk}."</td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$product->{$product_pk}."'>
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
  my $product_pk = $params->{product_pk};
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
  <h1>Checkout process</h1>
  <h2>Cart info</h2>
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
  <h2>Log Info</h2>
  <table>
    <tr><td>Cart status:</td><td>".$cart->{status}."</td></tr>
    <tr><td>Email</td><td>".$log->{data}->{email}."</td>
  </table>";
  $page;  
};
1;
