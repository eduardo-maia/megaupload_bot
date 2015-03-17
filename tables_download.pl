#!/usr/bin/perl
use Socket;
$|=1;


sub open_TCP
{
my ($FS, $dest, $port) = @_;
my $proto = getprotobyname('tcp');

socket($FS, PF_INET, SOCK_STREAM, $proto);
my $sin = sockaddr_in($port,inet_aton($dest));
connect($FS,$sin) || return undef;
       
my $old_fh = select($FS); 
$| = 1;
select($old_fh);
1;
}




# INPUT: page url
# RETURNS: new array(0,error message) or new array(1,html source code)
sub download($)
{
my $url = shift;


$conectou = open_TCP(F, "www.pinsimdb.org", 80);

if (!($conectou))
	{
	return 0;
	}

$cookie{"PSDB_user2"}="56925";
$cookie{"PSDB_session2"}="pimsnclqlfbcv15drbckphe0s5";
$cookie{"PSDB_hash2"}="791fac1c987882342aa977716fa4f6d6";
$cookie{"__utmz"}="180271525.1424355706.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not provided)";
$cookie{"__utmc"}="180271525";
$cookie{"__utma"}="180271525.1793478296.1424355706.1426544001.1426549986.6";

my $filename="";

# -------- SOLICITANDO O DOCUMENTO HTML -------- #
print F "GET $url HTTP/1.0\r\n";
print F "Proxy-Connection: Keep-Alive\r\n";
print F "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0\r\n";
print F "Referer: http://www.pinsimdb.org/pinball/index-10-future_pinball?field=download&order=desc\r\n";
print F "Connection: keep-alive\r\n";
print F "Cache-Control: max-age=0\r\n";
print F "Host: www.pinsimdb.org\r\n";
print F "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*\r\n";
print F "Accept-Encoding: text/plain\r\n";
print F "Accept-Language: en\r\n";
print F "Accept-Charset: iso-8859-1,*,utf-8\r\n";
print F "Cookie: ";
foreach my $key (keys %cookie)
	{
	print F "$key=$cookie{$key};";
	}
print F "\r\n\r\n";
while ($line = <F>)
	{
	$line=~s/\r//g;
	$line=~s/\n//g;
	last if ($line eq "");
	if ($line=~/Content-Disposition: attachment; filename=/)
		{
		$filename=$line;
		$filename=~s/Content-Disposition: attachment; filename="//;
		$filename=~s/";//;
		}
	print "$line\n";
	}


if ($filename ne "")
	{
	print "Baixando $filename...\n";
	open (OUT, ">tables\\" . $filename) || die $!;
	binmode(OUT);
	while (<F>)
		{
		print OUT $_;
		}
	close(OUT);
	}
else
	{
	die "Deu merda no URL $url";
	}
	

close (F);


	
return 1;
}





my $processing_line=0;
open (IN, "tables_download.txt") || die $!;
while($page=<IN>)
	{
	$processing_line++;
	chomp($page);
	print "\nProcessing line $processing_line - $page\n";
	my $sucess=0;
	while ( $sucess==0 )
		{
		$sucess = download($page);
		}
	}
close(IN);


print "\nDONE. OK. BYE.\n";