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
sub create_shipping_view;
sub create_billing_view;
sub create_review_view;
sub create_receipt_view;


# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args < 1) {
    print "\nUsage: ./bin/create_views.pl open_tag_def close_tag_def \n";
    print "\ntag_def it's the open a close tag for the template, by default open_tag_def is <%  and close_tag_def is %>\n";
    print "\n e.g. ./bin/create_views.pl partnumber <% %>\n";
    exit;
}
$open_t =  $ARGV[0] || $open_t;
$close_t =  $ARGV[1] || $close_t;
 
my $dir = 'views';

if (-e $dir and -d $dir) {
  make_path('views/cart/');
  print "Creating views/cart directory\n";
  create_products_view;
  print "Products view created at $dir/products.tt\n";
  create_cart_view;
  print "Cart view created at $dir/cart/cart.tt\n";
  create_shipping_view;
  print "Shipping view created at $dir/cart/shipping.tt\n";
  create_billing_view;
  print "Billing view created at $dir/cart/billing.tt\n";
  create_review_view;
  print "Review view created at $dir/cart/review.tt\n"; 
  create_receipt_view;
  print "Receipt view created at $dir/cart/receipt.tt\n"; 
} 
else {
  print "view directory needs to exists in order to proceed, please be sure you are in the root of your application.\n";
}

sub create_products_view{
  my $page = "";
  $page .= "
  <h1>Product list</h1>
  <table>
    <thead>
      <tr>
        <th>Sku</th><th>Price</th><th>Action</th>
      </tr>
    </thead>
    <tbody>";
    $page .= "
    $open_t FOREACH product IN products $close_t
      <tr>
        <td> $open_t product.ec_sku $close_t </td>
        <td> $open_t product.ec_price $close_t </td>
        <td>
          <form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='$open_t product.ec_sku $close_t'>
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
  my $page = "";
  $page .=  "<h1>Cart</h1>
  $open_t IF ec_cart.cart.items.size $close_t";
    $page .= "<a href='products'> Continue shopping. </a>\n";

    $page .= "
    <table>
      <thead>
        <tr>
          <th>SKU</th><th></th><th>Quantity</th><th></th><th>Price</th>
        </tr>
      </thead>
      <tbody>
    $open_t FOREACH item IN ec_cart.cart.items $close_t
        <tr>
          <td>  $open_t item.ec_sku $close_t </td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='$open_t item.ec_sku $close_t'>
            <input type='hidden' name='ec_quantity' value='-1'>
            <input type='submit' value = '-1'>
            </form>
          </td>
          <td>$open_t item.ec_quantity  $close_t </td>
          <td><form method='post' action='cart/add'>
            <input type='hidden' name='ec_sku' value='$open_t item.ec_sku $close_t'>
            <input type='hidden' name='ec_quantity' value='1'>
            <input type='submit' value = '+1'>
            </form>
          </td>
          <td>$open_t item.ec_price $close_t </td>
        </tr>
    $open_t END $close_t
      </tbody>
      <tfoot>
        <tr>
          <td colspan=4>Subtotal</td><td>$open_t ec_cart.cart.subtotal $close_t</td>
        </tr>
      </tfoot>
    </table>
    $open_t FOREACH error = ec_cart.add.error $close_t
      <p> $open_t error $close_t </p>
    $open_t END $close_t
    <p><a href='cart/clear'> Clear your cart. </a></p>
    <p><a href='cart/shipping'> Checkout </a></p>
  $open_t ELSE $close_t
    <p>Your cart is empty. <a href='products'> Continue shopping. </a></p>
  $open_t END $close_t";
  create_view( 'cart/cart.tt', $page );
  return 1;

};

sub create_shipping_view{
  my $page ="";
  $page .= "
  <h1>Shipping</h1>
  <h2>Cart info</h2>
    <table>
      <thead>
        <tr>
          <th>SKU</th><th>Quantity</th><th>Price</th>
        </tr>
      </thead>
      <tbody>
    $open_t FOREACH item IN ec_cart.cart.items $close_t
        <tr>
          <td>  $open_t item.ec_sku $close_t </td>
          <td>$open_t item.ec_quantity  $close_t </td>
          <td>$open_t item.ec_price $close_t </td>
        </tr>
    $open_t END $close_t
      </tbody>
      <tfoot>
        <tr>
          <td colspan=2>Subtotal</td><td>$open_t cart.subtotal $close_t</td>
        </tr>
      </tfoot>
    </table>
  <p> <a href='../products'>Continue shopping</a> </p>
  $open_t FOREACH error = ec_cart.shipping.error $close_t
    <p> $open_t error $close_t </p>
  $open_t END $close_t
  <p>Shipping info</p>
  <form method='post' action='shipping'>
   <p>Email <input type='text' name='email' value='$open_t ec_cart.shipping.form.email $close_t' paceholder='email\@domain.com'><input type='submit' value = 'Continue'></p>
  </form>";
  create_view( 'cart/shipping.tt', $page );
}

sub create_billing_view{
  my $page = "";
  $page .= "
  <h1>Billing</h1>
  $open_t FOREACH error = ec_cart.billing.error $close_t
    <p> $open_t error $close_t </p>
  $open_t END $close_t
  <p> <a href='../products'>Continue shopping</a> </p>
  <p>Billing info</p>
  <form method='post' action='billing'>
   <p> Email <input type='text' name='email' value='$open_t ec_cart.billing.form.email $close_t' paceholder='email\@domain.com'><input type='submit' value = 'Continue'> </p>
  </form>";
  create_view( 'cart/billing.tt', $page );
}

sub create_review_view{
  my $page = "";
  $page .= "
  <h1>Review</h1>
  <h2>Cart info</h2>
    <table>
      <thead>
        <tr>
          <th>SKU</th><th>Quantity</th><th>Price</th>
        </tr>
      </thead>
      <tbody>
    $open_t FOREACH item IN ec_cart.cart.items $close_t
        <tr>
          <td>$open_t item.ec_sku $close_t </td>
          <td>$open_t item.ec_quantity  $close_t </td>
          <td>$open_t item.ec_price $close_t </td>
        </tr>
    $open_t END $close_t
      </tbody>
      <tfoot>
        <tr>
          <td colspan=2>Subtotal</td><td>$open_t ec_cart.cart.subtotal $close_t</td>
        </tr>
      </tfoot>
    </table>
  <p> <a href='../products'>Continue shopping</a> </p>
  <table>
      <tr><td>Shipping - email</td><td>$open_t ec_cart.shipping.form.email $close_t</td></tr>
      <tr><td>Billing - email</td><td>$open_t ec_cart.billing.form.email $close_t</td></tr>
  </table>
  <form method='post' action='checkout'>
  <input type='submit' value = 'Place Order'>
  </form>";
  create_view( 'cart/review.tt', $page );
}

sub create_receipt_view{
  my $page ="";
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
        <td>$open_t item.ec_sku $close_t</td>
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
    <tr><td>Email</td><td> $open_t cart.log.data.ec_cart.shipping.form.email $close_t </td>
  </table>
  <p><a href='../products'> Product index </a></p>";
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
