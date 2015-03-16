#!/usr/bin/perl
use strict;
use LWP::UserAgent;
use threads;

# BLOG TO SEARCH FOR MEGAUPLOAD LINKS
our $blog_url='http://gothicrock2009.blogspot.com/';

# WHAT KIND OF LINKS ARE YOU SEARCHING?
# You can specify (for example) 'http://www.megaupload.com' if you wish to download all megaupload links from this website.
# You can also specify 'mailto:' if you wish to download all emails address (6)
our $links_beggining_with='http://www.megaupload.com';

# FILE TO SAVE MEGAUPLOAD LINKS
our $outputfile='megalinks.txt';

# HOW MANY SIMULTANEOUS DOWNLOADS
our $threads=20;


#############################
# END CONFIGURATION DATA
#############################


# key {pages to be downloaded / processed} => value 0
# key {pages already downloaded / processed} => value 1
# key {pages begin downloaded / processed} => value 2
our %pages = ($blog_url => 0);
our %downloadme;


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
my $ua = LWP::UserAgent->new;
$ua->agent("Maiafox 1.0"); # no fun
my $req = HTTP::Request->new(GET => $_[0]);
my $res = $ua->request($req);
if ($res->is_success)
	{
	return (1,$res->content);
	}
else
	{
	return (0,$res->status_line);
	}
}


sub download_process($$)
{
my $key=shift; # url to be downloaded and processed
my $value=shift; # download status

#print "\nDownloading $key\n";
my $status_ok=0;
my $page_source;
while (!$status_ok)
	{
	($status_ok,$page_source) = download($key);
	print $! . "\n" if (!$status_ok);
	sleep(10);
	}

#find more blog links to download, more megaupload links
my @e=find_link($blog_url,$page_source);
for (@e)
	{
	if (! defined $pages{$_} && $_!~/\.ico$|\.jpg$|\.gif$|\.swf$|\.css$|\.js$/)
		{
		#print "New url to scan: $_\n\n";
		$pages{$_}=0;
		}
	}

#scan for megaupload links
@e=find_link($links_beggining_with,$page_source);
while (!open(OUT,">>$outputfile"))
	{
	sleep(0.5);#maybe archive is being used by another thread
	}
for (@e)
	{
	if (!$downloadme{$_})
		{
		$downloadme{$_}=1;
		#print "FOUND $_\n";
		print OUT "$_\n" || die $!;
		}
	}
close(OUT);
$pages{$key}=1;
}


sub thread_void_main()
{
while ( my ($key, $value) = each(%pages) )
	{
	if ($value==0) # page wasn't downloaded yet
		{
		$pages{$value}=2; # mark page as being downloaded
		download_process($key,$value);
		}
	}
}


sub counter()
{
system('cls');
my $processed=0;
my $being_processed=0;
my $to_be_processed=0;
foreach my $key (keys %pages)
	{
	if ($pages{$key}==1)
		{
		$processed++;
		}
	elsif ($pages{$key}==2)
		{
		$being_processed++;
		}
	elsif ($pages{$key}==0)
		{
		$to_be_processed++;
		}
	}
print "Total webpages: " . keys(%pages) . "\n";
print "Processed: $processed\n";
print "To be processed: $to_be_processed\n";
print "Being processed: $being_processed\n";
print "Desired links found: " . keys(%downloadme) . "\n";

if ($processed==keys(%pages) && $being_processed==0 && $to_be_processed==0)
	{
	print "Executado com sucesso. Pronto.\n";
	}
sleep(1.5);
}



print "Downloading and processing $blog_url\n";
download_process($blog_url,0);
print "DONE\n";

if (keys(%pages)>1) #there are more pages to be scanned
	{
	for (my $i=1;$i<=$threads;$i++)
		{
		threads->create('thread_void_main');
		}
	while (1)
		{
		counter();
		}
	}



 