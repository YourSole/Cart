my $product_name = undef;
my $product_pk = undef;

$product_name = $settings->{product_name} || 'EcProduct';
$product_pk = $settings->{product_pk} || 'sku';

get '/products' => sub {
  my $page = "<table><tr><th>Sku</th><th>Action</th></tr>";
  my @products = schema->resultset($product_name)->all; 
  map {
    $page .= "<tr><td>".$_->sku."</td><td><form method='post' action='add'>
    <input type='hidden' name='sku' value='".$_->sku."'>
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
  my $page = "<table><tr><th>SKU</th><th></th><th>Quantity</th><th></th></th>\n";
  my $products = products;
  map{
    $page .= "<tr><td>".$_->{sku}."</td><td><form method='post' action='add'>
    <input type='hidden' name='sku' value='".$_->{sku}."'>
    <input type='hidden' name='quantity' value='-1'> 
    <input type='submit' value = '-1'>
    </form></td><td>". $_->{quantity} ."</td><td><form method='post' action='add'>
    <input type='hidden' name='sku' value='".$_->{sku}."'>
    <input type='hidden' name='quantity' value='1'> 
    <input type='submit' value = '+1'>
    </form></td></tr>\n";
  } @{$products};
  $page .= "</table>"; 
  $page;
};



1;



