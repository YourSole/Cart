package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset);
use Dancer2::Plugin::ECommerce;
get '/' => sub {
  'Hello World'
};

get '/cart/new/:cart_new?' => sub {
  my ($cart_name) = param('cart_new'); 
  my $cart = cart($cart_name); 
  $cart->{'name'};
};

post '/cart/add_product' => sub {
  my $product = param ('sku');
  my $res = cart_add($product);
  $res->{error} ? $res->{error} : $res->{sku};
};

get '/cart/products' => sub {
  Dumper(products);
};

1;
