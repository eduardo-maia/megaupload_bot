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



# INPUT[0]=links to be found. Example: http://www.megaupload.com/* (do not use wild cards, only first chars from the complete url)
# INPUT[1]=html source code
# RETURNS: all links matching ^INPUT[0]
sub find_link($$)
{
my $what=shift;
my $where=shift;
my @begin=("href=\"","href='");
my @end=("\"","'");
my @r = ();
for (my $i=0;$i<=length($where);$i++)
	{
	for (my $j=0;$j<@begin;$j++)
		{
		if (substr($where,$i,length($begin[$j])) eq $begin[$j] && substr($where,$i+length($begin[$j]),length($what)) eq $what)
			{
			my $elem="";
			while ($i<=length($where) && substr($where,$i+length($begin[$j]),1) ne $end[$j])
				{
				$elem.=substr($where,$i+length($begin[$j]),1);
				$i++;
				}
			$r[@r]=$elem;
			}
		}
	}
return @r;
}


# INPUT: page url
# RETURNS: new array(0,error message) or new array(1,html source code)
sub download($)
{
my $url = shift;


	$conectou = open_TCP(F, "www.pinsimdb.org", 80);
	
	if (!($conectou))
		{
		return(0,"Falha de conexao");
		}

$cookie{"PSDB_user2"}="56925";
$cookie{"PSDB_session2"}="pimsnclqlfbcv15drbckphe0s5";
$cookie{"PSDB_hash2"}="791fac1c987882342aa977716fa4f6d6";
$cookie{"__utmz"}="180271525.1424355706.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not provided)";
$cookie{"__utmc"}="180271525";
$cookie{"__utma"}="180271525.1793478296.1424355706.1426544001.1426549986.6";


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
		@buffer=<F>;
		close (F);
		
	
return (1,join("",@buffer));
}


my $processing_line=0;
my $links_found=0;
open (IN, "pinlinks.txt") || die $!;
while($page=<IN>)
	{
	$processing_line++;
	print "\nProcessing line $processing_line - $page\n";
	my $sucess=0;
	while ( $sucess==0 )
		{
		chomp($page);
		my ($sucess,$html) = download($page);
				open(OUT,">teste1.html");
				binmode(OUT);
				print OUT $html;
				close(OUT);

		if ($sucess)
			{
			print "Procurando links...\n";
			my @links = find_link('http://www.pinsimdb.org/res/download-',$html);
			if (@links)
				{
				print "We found links!\n";
				open(OUT,">>tables_download.txt");
				for (my $i=0; $i<@links; $i++)
					{
					$links_found++;
					print OUT "$links[$i]\r\n";
					print "Found link #$links_found - $links[$i]\n";
					}
				close(OUT);
				}
			last;
			}
		}
	}
close(IN);


print "\nDONE. OK. BYE.\n";