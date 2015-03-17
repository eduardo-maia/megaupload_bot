#!/usr/bin/perl
use LWP::UserAgent;

# BLOG TO SCAN FOR MEGAUPLOAD LINKS
#$blog_url='http://cinespacemonster.blogspot.com/';
#$blog_url='http://www.ankman.de/mame/';
$blog_url='http://www.pinsimdb.org/pinball/index-10-future_pinball';


# WHAT LINKS ARE YOU SEARCHING. 
# You can specify (for example) 'http://www.megaupload.com' if you wish to download all megaupload links from this website.
# You can also specify 'mailto:' if you wish to download all emails address
#$links_beggining_with='http://www.megaupload.com/?d=';
#$links_beggining_with='http://ankman.tombstones.org.uk/mameroms/';
$links_beggining_with='http://www.pinsimdb.org/pinball/table-';


# FILE TO SAVE MEGAUPLOAD LINKS
#$outputfile='cinespacemonster_full.urls';
$outputfile='pinlinks.txt';


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


# key {pages to be downloaded} => value 0
# key {pages already downloaded} => value 1
%pages = ($blog_url => 0);


$newloop=1;
$downloaded=0;
while ($newloop)
	{
	$newloop=0;
	while ( my ($key, $value) = each(%pages) )
		{
		if ($value==0) # page wasn't downloaded yet
			{
			$pages{$key}=1;
			print "\n";
			#print "Pages already downloaded: $downloaded from " . keys(%pages) . "\n";
			print "Links matching: " . keys(%downloadme) . "\n";
			print "Downloading $key ...\n";
			print "Downloading " . ($downloaded+1) . " from " . keys(%pages) . " ...\n";
	
			my $status_ok=0;
			while (!$status_ok)
				{
				($status_ok,$page_source) = download($key);
				print "$page_source\n" if (!$status_ok);
				last if ($page_source eq "404 Not Found");
				# print "I will sleep for 10 seconds before trying again...\n";
				# sleep(10);
				}
			$downloaded++;
		
			#find more blog links to download more megaupload links
			my @e=find_link($blog_url,$page_source);
			for (@e)
				{
				if (! defined $pages{$_} && $_!~/\.ico$|\.jpg$|\.gif$|\.swf$|\.css$|\.js$/)
					{
					print "New url to scan: $_\n\n";
					$newloop=1;
					$pages{$_}=0;
					}
				}

			#scan for megaupload links
			@e=find_link($links_beggining_with,$page_source);
			open(OUT,">>$outputfile") || die $!;
			for (@e)
				{
				if (!$downloadme{$_})
					{
					$downloadme{$_}=1;
					print "FOUND $_\n";
					print OUT "$_\n" || die $!;
					}
				}
			close(OUT);
			}
		}
	}

print "\nDONE. OK. BYE.\n";