#!/usr/bin/perl
use File::Path qw(make_path);
use strict;
use warnings;

our $open_t = '<%';
our $close_t = '%>';

sub create_products_view;
sub create_cart_view;
sub create_checkout_view;
sub create_receipt_view;


# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args < 1) {
    print "\nUsage: ./bin/create_views.pl product_pk open_tag_def close_tag_def \n";
    print "\nproduct_pk it's the sku value of your product table\n";
    print "\ntag_def it's the open a close tag for the template, by default open_tag_def is <%  and close_tag_def is %>\n";
    print "\n e.g. ./bin/create_views.pl partnumber <% %>";
    exit;
}
my $product_pk = $ARGV[0];
my $open_t =  $ARGV[1] || $open_t;
my $close_t =  $ARGV[2] || $close_t;
 
my $dir = 'views';

if (-e $dir and -d $dir) {
  make_path('views/cart/');
  print "Creating views/cart directory\n";
  create_products_view($product_pk);
  print "Products view created at $dir/products.tt\n";
  create_cart_view($product_pk);
  print "Cart view created at $dir/cart/cart.tt\n";
  create_checkout_view($product_pk);
  print "Checkout view created at $dir/cart/checkout.tt\n";
  create_receipt_view($product_pk);
  print "Receipt view created at $dir/cart/receipt.tt\n";
} 
else {
  print "view directory needs to be create, please be sure you are in the root of your path of your application.\n";
}

sub create_products_view{
  my ($product_pk) = @_;
  my $page = "";
  $page .= "
  <h1>Product list</h1>
  <table>
    <thead>
      <tr>
        <th>Sku</th><th>Action</th>
      </tr>
    </thead>
    <tbody>";
    $page .= "
    $open_t FOREACH product IN products $close_t
      <tr>
        <td> $open_t product.$product_pk $close_t </td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='$open_t product.$product_pk $close_t'>
            <input type='hidden' name='quantity' value='1'>
            <input type='submit' value = 'Add'>
          </form>
        </td>
      </tr>
    $open_t END $close_t";
  $page .= "
    </tbody>
  </table>";
  create_view( 'products.tt', $page );
  return 1;
};

sub create_cart_view{
  my ($product_pk) = @_;
  my $page = "";
  $page .=  "<h1>Cart</h1>
  $open_t IF cart.items $close_t";
    $page .= "<a href='products'> Continue shopping. </a>\n";
    $page .= "
    <table>
      <thead>
        <tr>
          <th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th>
        </tr>
      </thead>
      <tbody>
    $open_t FOREACH item IN cart.items $close_t
        <tr>
          <td>  $open_t item.$product_pk $close_t </td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='$open_t item.$product_pk $close_t'>
            <input type='hidden' name='quantity' value='-1'>
            <input type='submit' value = '-1'>
            </form>
          </td>
          <td>$open_t item.ec_quantity  $close_t </td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='sku' value='$open_t item.$product_pk $close_t'>
            <input type='hidden' name='quantity' value='1'>
            <input type='submit' value = '+1'>
            </form>
          </td>
          <td>$open_t item.ec_price $close_t </td>
        </tr>
    $open_t END $close_t
      </tbody>
      <tfoot>
        <tr>
          <td colspan=4>Subtotal</td><td>$open_t cart.subtotal $close_t</td>
        </tr>
      </tfoot>
    </table>
    <p><a href='cart/clear'> Clear your cart. </a></p>
    <p><a href='cart/checkout'> Checkout. </a></p>
  $open_t ELSE $close_t
    Your cart is empty. <a href='products'> Continue shopping. </a>
  $open_t END $close_t";
  create_view( 'cart/cart.tt', $page );
  return 1;

}

sub create_checkout_view{
  my ($product_pk) = @_;
  my $page ="";
  $page .= "
  <h1>Checkout process</h1>
  <h2>Cart info</h2>
  <table>
    <tr>
      <th>SKU</th><th>Quantity</th><th>Price</th>
    </tr>
    $open_t FOREACH item IN cart.items $close_t
    <tr>
      <td>$open_t item.$product_pk $close_t</td>
      <td>$open_t item.ec_quantity $close_t</td>
      <td>$open_t item.ec_price $close_t</td>
    </tr>
    $open_t END $close_t
    <tr>
      <td colspan=2>Subtotal</td><td> $open_t cart.subtotal $close_t </td>
    </tr>
  </table>
  <p> $open_t error $close_t </p>
  <p>Info required to check out:</p>
  <form method='post' action='checkout'>
  Email <input type='text' name='email' value='' paceholder='email\@domain.com'>
  <input type='submit' value = 'Process checkout'>
  </form>";
  create_view( 'cart/checkout.tt', $page );
  return 1;
}

sub create_receipt_view{
  my ($product_pk) = @_;
  my $page ="";
   my ($params) = @_;
  $page .= "
  <p>Checkout has been successful!!</p>
  <h1>Receipt #: $open_t cart.id $close_t </h1>
  <h2>Cart Info</h2>
  <table>
    <thead>
      <tr>
        <th>SKU</th><th>Quantity</th><th>Price</th>
      </tr>
    </thead>
    <tbody>
    $open_t FOREACH item IN cart.items $close_t
      <tr>
        <td>$open_t item.$product_pk $close_t</td>
        <td>$open_t item.ec_quantity $close_t</td>
        <td>$open_t item.ec_price $close_t</td>
      </tr>
    $open_t END $close_t
    
    </tbody>
    <tfoot>
      <tr>
        <td colspan=2>Subtotal</td><td>$open_t cart.subtotal $close_t</td>
      </tr>
    </tfoot>
  </table>
  <h2>Log Info</h2>
  <table>
    <tr><td>Cart status:</td><td>$open_t  cart.status $close_t</td></tr>
    <tr><td>Email</td><td> $open_t log.data.email $close_t </td>
  </table>
  <p><a href='../products'> Product index </a></p>";
  $page;
  create_view( 'cart/receipt.tt', $page );
}

sub create_view{
  my ($name, $body) = @_;
  my $filename = "views/$name";
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $body;
  close $fh;
};

1;
