sub _products_view{
  my ($params) = @_;
  my $products = $params->{products};
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
        <td>".$product->{ec_sku}."</td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$product->{ec_sku}."'>
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
          <td>".$item->{ec_sku}."</td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$item->{ec_sku}."'>
            <input type='hidden' name='quantity' value='-1'>
            <input type='submit' value = '-1'>
            </form>
          </td>
          <td>". $item->{ec_quantity} ."</td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='".$item->{ec_sku}."'>
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
    $page .= "\n<p><a href='cart/shipping'> Checkout. </a></p>";
  }
  else{
    $page .= "Your cart is empty. <a href='products'> Continue shopping. </a>";
  }
  $page;
}


sub _shipping_view{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $ec_cart = $params->{ec_cart};

  my $page ="";

  $page .= "
  <h1>Shipping</h1>
  <h2>Cart info</h2>
  <table>
    <tr>
      <th>SKU</th><th>Quantity</th><th>Price</th>
    </tr>";
  foreach my $item ( @{$cart->{items}} ){ 
  $page .= "
    <tr>
      <td>".$item->{ec_sku}."</td>
      <td>". $item->{ec_quantity} ."</td>
      <td>".$item->{ec_price}."</td>
    </tr>"; 
  };
  $page .= "
    <tr>
      <td>Subtotal</td><td>".$cart->{subtotal}."</td>
    </tr>
  </table>
  <p> <a href='../products'>Continue shopping</a> </p>";

  
  if ( $ec_cart->{shipping}->{error} ){
    $page .= "<p>".$ec_cart->{shipping}->{error}."</p>";
  }
  $page .= "
    <p>Shipping info</p>
    <form method='post' action='shipping'>
     Email <input type='text' name='email' value='".$ec_cart->{shipping}->{form}->{email}."' paceholder='email\@domain.com'>
      <input type='submit' value = 'Continue'>
    </form>";
}

sub _billing_view{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $ec_cart = $params->{ec_cart};

  my $page ="";

  $page .= "
  <h1>Billing</h1>";
  if ( $ec_cart->{billing}->{error} ){
    $page .= "<p>".$ec_cart->{billing}->{error}."</p>";
  }
  $page .= "
    <p>Billing info</p>
    <form method='post' action='billing'>
     Email <input type='text' name='email' value='".$ec_cart->{billing}->{form}->{email}."' paceholder='email\@domain.com'>
      <input type='submit' value = 'Continue'>
    </form>";

};

sub _review_view{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $ec_cart = $params->{ec_cart};

  $page = "
    <h1>Review</h1>
    <h2>Cart info</h2>
    <table>
      <tr>
        <th>SKU</th><th>Quantity</th><th>Price</th>
      </tr>";
      foreach my $item ( @{$cart->{items}} ){ 
      $page .= "
        <tr>
          <td>".$item->{ec_sku}."</td>
          <td>". $item->{ec_quantity} ."</td>
          <td>".$item->{ec_price}."</td>
        </tr>"; 
      };
      $page .= "
      <tr>
        <td colspan=2>Subtotal</td><td>".$cart->{subtotal}."</td>
      </tr>
    </table>
    
    <p> <a href='../products'>Continue shopping</a> </p>

    <table>
      <tr><td>Shipping - email</td><td>".$ec_cart->{shipping}->{form}->{email}."</td></tr>
      <tr><td>Billing - email</td><td>".$ec_cart->{billing}->{form}->{email}."</td></tr>
    </table>
    <p>Edit <a href='shipping'>Shipping</a></p>
    <p>Edit <a href='billing'>Billing</a></p>
    <form method='post' action='checkout'>
    <input type='submit' value = 'Place Order'>
    </form>";
  
};


sub _receipt_view{
  my ($params) = @_;
  my $cart = $params->{cart};
  my $page = "";

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
        <td>".$item->{ec_sku}."</td>
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
    <tr><td>Email</td><td>".$cart->{log}->{data}->{ec_cart}->{shipping}->{form}->{email}."</td>
  </table>
  <p> <a href='../products'>Go to products</a> </p>";
  $page;  
};

1;
