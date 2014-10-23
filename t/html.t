#!perl -w

# $Id: html.t 758 2004-10-21 01:59:22Z theory $

use strict;
use Test::More;
use File::Spec::Functions;

if ($^O eq 'MSWin32') {
    plan skip_all => "SVN::Notify::HTML not yet supported on Win32";
} elsif (eval { require HTML::Entities }) {
    plan tests => 159;
} else {
    plan skip_all => "SVN::Notify::HTML requires HTML::Entities";
}

BEGIN { use_ok('SVN::Notify::HTML') }

my $ext = $^O eq 'MSWin32' ? '.bat' : '';

my $dir = catdir curdir, 't', 'scripts';
$dir = catdir curdir, 't', 'bin' unless -d $dir;

my %args = (
    svnlook    => catfile($dir, "testsvnlook$ext"),
    sendmail   => catfile($dir, "testsendmail$ext"),
    repos_path => 'tmp',
    revision   => '111',
    to         => 'test@example.com',
    linkize    => 1,
);

##############################################################################
# Basic Functionality.
##############################################################################
ok( my $notifier = SVN::Notify::HTML->new(%args),
    "Construct new HTML notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Single method call prepare" );

# Check that the accessors work properly.
is ($notifier->linkize, 1, "Check linkize" );
is ($notifier->bugzilla_url, undef, "Check bugzilla_url" );
is ($notifier->jira_url, undef, "Check jira_url" );
is ($notifier->rt_url, undef, "Check rt_url" );

# Send the mesasge and get the output.
ok( $notifier->execute, "HTML notify" );
my $email = get_output();

# Check the email headers.
like( $email, qr/Subject: \[111\] Did this, that, and the other\.\n/,
      "Check HTML subject" );
like( $email, qr/From: theory\n/, 'Check HTML From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML To');
like( $email, qr{Content-Type: text/html; charset=UTF-8\n},
      'Check HTML Content-Type' );
like( $email, qr{Content-Transfer-Encoding: 8bit\n},
      'Check HTML Content-Transfer-Encoding');

# Make sure that the <html>, <head>, <body>, <title>, and <dl> headers tags
# are included.
for my $tag (qw(html head body title dl)) {
    like( $email, qr/<$tag/, "Check for <$tag> tag" );
    like( $email, qr/<\/$tag>/, "Check for </$tag> tag" );
}

# Make sure we have styles and the appropriate div.
like( $email, qr|<style type="text/css">|, "Check for <style> tag" );
like( $email, qr/<\/style>/, "Check for </style> tag" );
like( $email, qr/#msg dl {background:#ccccff;}/, "Check for style" );
like( $email, qr/<div id="msg">/, "Check for msg div" );

# Make sure we have headers for each of the four kinds of changes.
for my $header ('Log Message', 'Modified Files', 'Added Files',
                'Removed Files', 'Property Changed') {
    like( $email, qr{<h3>$header</h3>}, "HTML $header" );
}

# Check that we have the commit metatdata.
like( $email, qr|<dt>Revision</dt> <dd>111</dd>\n|, 'Check Revision');
like( $email, qr|<dt>Author</dt> <dd>theory</dd>\n|, 'Check Author');
like( $email,
      qr|<dt>Date</dt> <dd>2004-04-20 01:33:35 -0700 \(Tue, 20 Apr 2004\)</dd>\n|,
      'Check Date');

# Check that the log message is there.
like( $email, qr{<pre>Did this, that, and the other\. And then I did some more\. Some\nit was done on a second line\. Go figure\.</pre>}, 'Check for HTML log message' );

# Make sure that Class/Meta.pm is listed twice, once for modification and once
# for its attribute being set.
is( scalar @{[$email =~ m{(<li>trunk/Class-Meta/lib/Class/Meta\.pm</li>)}g]}, 2,
    'Check for two HTML Class/Meta.pm');
# For other file names, there should be only one instance.
is( scalar @{[$email =~ m{(<li>trunk/Class-Meta/lib/Class/Meta/Class\.pm</li>)}g]}, 1,
    'Check for one HTML Class/Meta/Class.pm');
is( scalar @{[$email =~ m{(<li>trunk/Class-Meta/lib/Class/Meta/Type\.pm</li>)}g]}, 1,
    'Check for one HTML Class/Meta/Type.pm');

# Make sure that no diff is included.
unlike( $email, qr{Modified: trunk/Params-CallbackRequest/Changes},
        "Check for html diff" );

##############################################################################
# Make sure that handler delegation works.
##############################################################################
ok( $notifier = SVN::Notify->new(%args, handler => 'HTML'),
    "Construct new HTML notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Single method call prepare" );
ok( $notifier->execute, "HTML notify" );

# Get the output.
$email = get_output();

# Check the email headers.
like( $email, qr/Subject: \[111\] Did this, that, and the other\.\n/,
      "Check HTML subject" );
like( $email, qr/From: theory\n/, 'Check HTML From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML To');
like( $email, qr{Content-Type: text/html; charset=UTF-8\n},
      'Check HTML Content-Type' );
like( $email, qr{Content-Transfer-Encoding: 8bit\n},
      'Check HTML Content-Transfer-Encoding');

##############################################################################
# Include HTML diff and language.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args, with_diff => 1, language => 'en'),
    "Construct new HTML diff notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Single method call prepare" );
ok( $notifier->execute, "HTML diff notify" );

# Get the output.
$email = get_output();

like( $email, qr/Subject: \[111\] Did this, that, and the other\.\n/,
      "Check HTML diff subject" );
like( $email, qr/From: theory\n/, 'Check HTML diff From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML diff To');

# Make sure there are no attachment headers
is( scalar @{[ $email =~ m{Content-Type: text/(plain|html); charset=UTF-8\n} ]}, 1,
    'Check for one HTML Content-Type header' );
is( scalar @{[$email =~ m{Content-Transfer-Encoding: 8bit\n}g]}, 1,
      'Check for one HTML Content-Transfer-Encoding header');
is( scalar @{[$email =~ m{Content-Language: en\n}g]}, 1,
      'Check for one HTML Content-Language header');

# Check for the html header.
like( $email, qr|<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">|,
      "Check for HTML tag" );
# Make sure that the diff is included and escaped.
like( $email, qr/<div id="patch">/, "Check for patch div" );
like( $email, qr{Modified: trunk/Params-CallbackRequest/Changes},
      "Check for diff" );

# Make sure that it's not attached.
unlike( $email, qr{Content-Type: multipart/mixed; boundary=},
        "Check for no html diff attachment" );
unlike( $email, qr{Content-Disposition: attachment; filename=},
        "Check for no html diff filename" );
like( $email, qr{isa        =\&gt; 'Apache',}, "Check for HTML escaping" );

# Make sure that the file names have links into the diff.
like( $email,
      qr|<li><a href="#trunkParamsCallbackRequestChanges">trunk/Params-CallbackRequest/Changes</a></li>\n|,
      "Check for file name link." );
like( $email,
      qr|<a id="trunkParamsCallbackRequestChanges">Modified: trunk/Params-CallbackRequest/Changes</a>\n|,
      "Check for file name anchor id" );
like( $email,
      qr|<a id="trunkParamsCallbackRequestlibParamsCallbackpm">Added: trunk/Params-CallbackRequest/lib/Params/Callback\.pm</a>\n|,
      "Check for added file name anchor id" );

##############################################################################
# Attach diff.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args, attach_diff => 1,
                                       boundary => 'frank'),
    "Construct new HTML attach diff notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Single method call prepare" );
ok( $notifier->execute, "Attach HTML attach diff notify" );

# Get the output.
$email = get_output();

like( $email, qr/Subject: \[111\] Did this, that, and the other\.\n/,
      "Check HTML attach diff subject" );
like( $email, qr/From: theory\n/, 'Check HTML attach diff From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML attach diff To');

# Make sure we have two sets of headers for attachments.
is( scalar @{[ $email =~ m{Content-Type: text/(plain|html); charset=UTF-8\n}g ]}, 2,
    'Check for two Content-Type headers' );
is( scalar @{[$email =~ m{Content-Transfer-Encoding: 8bit\n}g]}, 2,
      'Check for two Content-Transfer-Encoding headers');

# No language, so no xml:lang.
like( $email, qr|<html xmlns="http://www.w3.org/1999/xhtml">|,
      "Check for attach diff HTML tag" );

# Make sure that the diff is included.
like( $email, qr{Modified: trunk/Params-CallbackRequest/Changes},
      "Check for diff" );

# Make sure that it's attached.
like( $email, qr{Content-Type: multipart/mixed; boundary="(.*)"\n},
        "Check for html diff attachment" );
like( $email,
      qr{Content-Disposition: attachment; filename=r111-theory.diff\n},
      "Check for html diff filename" );
unlike( $email, qr{<pre>\nModified}, "Check for no pre tag" );

# Check for boundaries.
is( scalar @{[$email =~ m{(--frank\n)}g]}, 2,
    'Check for two boundaries');
is( scalar @{[$email =~ m{(--frank--)}g]}, 1,
    'Check for one final boundary');

##############################################################################
# Try html format with a single file changed.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args, revision => '222'),
    "Construct new HTML file notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare HTML file" );
ok( $notifier->execute, "Notify HTML file" );

# Check the output.
$email = get_output();
like( $email, qr{Subject: \[222\] Hrm hrm\.\n},
      "Check subject header for HTML file" );
like( $email, qr/From: theory\n/, 'Check HTML file From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML file To');
like( $email, qr{Content-Type: text/html; charset=UTF-8\n},
      'Check HTML file Content-Type' );
like( $email, qr{Content-Transfer-Encoding: 8bit\n},
      'Check HTML file Content-Transfer-Encoding');

##############################################################################
# Try view_cvs_url + HTML.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args,
     viewcvs_url => 'http://svn.example.com/?rev=%s&view=rev',
),
    "Construct new HTML view_cvs_url notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare HTML view_cvs_url" );
ok( $notifier->execute, "Notify HTML view_cvs_url" );

# Check the output.
$email = get_output();
like( $email,
      qr|<dt>Revision</dt>\s+<dd><a href="http://svn\.example\.com/\?rev=111\&amp;view=rev">111</a></dd>\n|,
      'Check for HTML URL');

##############################################################################
# Try charset.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args, charset => 'ISO-8859-1'),
    "Construct new charset notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare charset" );
ok( $notifier->execute, "Notify charset" );

# Check the output.
$email = get_output();
like( $email, qr{Content-Type: text/html; charset=ISO-8859-1\n},
      'Check Content-Type charset' );

##############################################################################
# Try html format with propsets.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(%args, with_diff => 1, revision => '333'),
    "Construct new HTML propset notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare HTML propset" );
ok( $notifier->execute, "Notify HTML propset" );

# Check the output.
$email = get_output();
like( $email, qr{Subject: \[333\] Property modification\.\n},
      "Check subject header for propset HTML" );
like( $email, qr/From: theory\n/, 'Check HTML propset From');
like( $email, qr/To: test\@example\.com\n/, 'Check HTML propset To');
like( $email, qr{Content-Type: text/html; charset=UTF-8\n},
      'Check HTML propset Content-Type' );
like( $email, qr{Content-Transfer-Encoding: 8bit\n},
      'Check HTML propset Content-Transfer-Encoding');

like( $email,
      qr|<a id="trunkactivitymailbinactivitymail">Modified: trunk/activitymail/bin/activitymail</a>\n|,
      "Check for file name anchor id" );
like( $email,
      qr|<a id="trunkactivitymailtactivitymailt">Property changes on: trunk/activitymail/t/activitymail\.t</a>\n|,
      "Check for propset file name anchor id" );

##############################################################################
# Try linkize and Bug tracking URLs.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(
    %args,
    revision => 222,
    viewcvs_url  => 'http://viewsvn.bricolage.cc/?rev=%s&view=rev',
    rt_url       => 'http://rt.cpan.org/NoAuth/Bugs.html?id=%s',
    bugzilla_url => 'http://bugzilla.mozilla.org/show_bug.cgi?id=%s',
    jira_url     => 'http://jira.atlassian.com/secure/ViewIssue.jspa?key=%s',
),
    "Construct new HTML URL notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare HTML URL" );
ok( $notifier->execute, "Notify HTML URL" );

$email = get_output();

# Check linkize results.
like($email, qr|<a href="mailto:foo\@example\.com">foo\@example\.com</a>|,
     "Check for linked email address");
like($email, qr{<a href="http://www\.kineticode\.com/">http://www\.kineticode\.com/</a>},
     "Check for linked URL" );
like($email,
     qr{<a href="http://foo\.bar\.com/one/two/do\.pl\?this=1&amp;that=2">http://foo\.bar\.com/one/two/do\.pl\?this=1&amp;that=2</a>},
     "Check for fancy linked URL" );

# Check for application URLs.
like( $email,
      qr|<dt>Revision</dt>\s+<dd><a href="http://viewsvn\.bricolage\.cc/\?rev=222\&amp;view=rev">222</a></dd>\n|,
      'Check for main ViewCVS URL');
like($email,
     qr{<a href="http://rt\.cpan\.org/NoAuth/Bugs\.html\?id=4321">Ticket # 4321</a>},
     "Check for RT URL");
like($email,
     qr{<a href="http://viewsvn\.bricolage\.cc/\?rev=606&amp;view=rev">Revision # 606</a>},
     "Check for log mesage ViewCVS URL");
like( $email,
      qr{<a href="http://bugzilla\.mozilla\.org/show_bug\.cgi\?id=709">Bug # 709</a>},
      "Check for Bugzilla URL" );
like( $email,
      qr{<a href="http://jira\.atlassian\.com/secure/ViewIssue\.jspa\?key=TST-1608">TST-1608</a>},
      "Check for Jira URL" );

##############################################################################
# Major linkize and Bug tracking URLs, as well as complex diff.
##############################################################################
ok( $notifier = SVN::Notify::HTML->new(
    %args,
    with_diff    => 1,
    revision     => 444,
    viewcvs_url  => 'http://viewsvn.bricolage.cc/?rev=%s&view=rev',
    rt_url       => 'http://rt.cpan.org/NoAuth/Bugs.html?id=%s',
    bugzilla_url => 'http://bugzilla.mozilla.org/show_bug.cgi?id=%s',
    jira_url     => 'http://jira.atlassian.com/secure/ViewIssue.jspa?key=%s',
),
    "Construct new complext notifier" );
isa_ok($notifier, 'SVN::Notify::HTML');
isa_ok($notifier, 'SVN::Notify');
ok( $notifier->prepare, "Prepare complex example" );
ok( $notifier->execute, "Notify complex example" );

$email = get_output();

# Make sure multiple lines are still multiple!
like($email, qr/link\.\n\nWe/, "Check for multiple lines" );

# Check linkize results.
like($email, qr|<a href="mailto:recipient\@example\.com">recipient\@example\.com</a>\.|,
     "Check for linked email address");
like($email, qr{<a href="http://www\.kineticode\.com/">http://www\.kineticode\.com/</a>\!},
     "Check for linked URL" );
like($email,
     qr{<a href="http://www\.example\.com/my\.pl\?one=1&amp;two=2&amp;f=w\*\*t">http://www\.example\.com/my\.pl\?one=1&amp;two=2&amp;f=w\*\*t</a>\.},
     "Check for fancy linked URL" );

# Check for RT URLs.
like($email,
     qr{<a href="http://rt\.cpan\.org/NoAuth/Bugs\.html\?id=6">Ticket # 6</a>,},
     "Check for first RT URL");
like($email,
     qr{<a href="http://rt\.cpan\.org/NoAuth/Bugs\.html\?id=12">Ticket\n12</a>,},
     "Check for split RT URL");
unlike($email,
     qr{<a href="http://rt\.cpan\.org/NoAuth/Bugs\.html\?id=69">ticket 69</a>},
     "Check for no Ticket 69 URL");
like($email,
     qr{<a href="http://rt\.cpan\.org/NoAuth/Bugs\.html\?id=23">RT-Ticket: #23</a>},
     "Check for Jesse RT URL");

# Check for ViewCVS URLs.
like( $email,
      qr|<dt>Revision</dt>\s+<dd><a href="http://viewsvn\.bricolage\.cc/\?rev=444\&amp;view=rev">444</a></dd>\n|,
      'Check for main ViewCVS URL');
like($email,
     qr{<a href="http://viewsvn\.bricolage\.cc/\?rev=6000&amp;view=rev">Revision 6000</a>\.},
     "Check for first log mesage ViewCVS URL");
like($email,
     qr{<a href="http://viewsvn\.bricolage\.cc/\?rev=6001&amp;view=rev">rev\n6001</a>\.},
     "Check for split line log mesage ViewCVS URL");
unlike($email,
       qr{<a href="http://viewsvn\.bricolage\.cc/\?rev=200&amp;view=rev">rev 200</a>,},
       "Check for no grev 200 ViewCVS URL");

# Check for Bugzilla URLs.
like( $email,
      qr{<a href="http://bugzilla\.mozilla\.org/show_bug\.cgi\?id=1234">Bug # 1234</a>},
      "Check for first Bugzilla URL" );
like( $email,
      qr{<a href="http://bugzilla\.mozilla\.org/show_bug\.cgi\?id=8">bug 8</a>,},
      "Check for second Bugzilla URL" );
unlike( $email,
      qr{<a href="http://bugzilla\.mozilla\.org/show_bug\.cgi\?id=3">bug 3</a>\.},
      "Check for no humbug URL" );
like( $email,
      qr{<a href="http://bugzilla\.mozilla\.org/show_bug\.cgi\?id=4321">Bug\n#4321</a>},
      "Check for split line Bugzilla URL" );

# Check for JIRA URLs.
like( $email,
      qr{<a href="http://jira\.atlassian\.com/secure/ViewIssue\.jspa\?key=TST-1234">TST-1234</a>\.},
      "Check for Jira URL" );
unlike( $email,
      qr{<a href="http://jira\.atlassian\.com/secure/ViewIssue\.jspa\?key=JRA-\n4321">JRA-\n4321-1234</a>},
      "Check for no split line Jira URL" );
unlike( $email,
      qr{<a href="http://jira\.atlassian\.com/secure/ViewIssue\.jspa\?key=studlyCAPS-1234">studlyCAPS-1234</a>\.},
      "Check for no studlyCAPS Jira URL" );

##############################################################################
# Functions.
##############################################################################

sub get_output {
    my $outfile = catfile qw(t data output.txt);
    open CAP, "<$outfile" or die "Cannot open '$outfile': $!\n";
    my $email = do { local $/;  <CAP>; };
    close CAP;
    return $email;
}
