package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset);
use Dancer2::Plugin::ECommerce::Cart;
use Data::Dumper;

get '/' => sub {
  'Hello World'
};

get '/cart/new/:cart_new?' => sub {
  my ($cart_name) = param('cart_new'); 
  my $cart = cart($cart_name); 
  $cart->{'name'};
};

post '/cart/add_product' => sub {
  my $product = { sku => param('sku'), quantity => param('quantity') };
  my $res = cart_add($product);
  $res->{error} ? $res->{error} : Dumper($res);
};

get '/cart/quantity/:schema?' => sub {
  my $schema = param('schema');
  'quantity='.product_quantity($schema);
};

post '/cart/add_product_bar' => sub {
  my $product = { sku => param('sku'), quantity => param('quantity') };
  my $res = cart_add($product, 'bar');
  $res->{error} ? $res->{error} : Dumper($res);
};

get '/cart/products' => sub {
  Dumper(products);
};

get '/cart/clear_cart/:schema?' => sub {
  my $schema = param('schema');
  clear_cart('main',$schema);
  Dumper(products($schema));
};

1;
