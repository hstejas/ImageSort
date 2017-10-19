#!/usr/bin/env perl6

use Inline::Perl5;
use HTTP::UserAgent;
use JSON::Tiny;
use Image::ExifTool:from<Perl5>;

sub getUrl($type, $key)
{
    if $type ~~ "osm"
    {
        return "http://nominatim.openstreetmap.org/reverse?";
    }
    elsif $type ~~ /"locationiq"/
    {
        die "API key missing" if ! $key.defined;
        return "http://locationiq.org/v1/reverse.php?key=$key&";
    }
    else
    {
        die "url source type $type not handled";
    }
}

sub getCoords($image)
{
    my $exifTool = Image::ExifTool.new;
    my $ret = $exifTool.ExtractInfo($image.Str);
    if $ret == 1
    {
        $exifTool.Options(CoordFormat => '%+.6f');
        my $lat = $exifTool.GetValue("GPSLatitude");
        my $lon = $exifTool.GetValue("GPSLongitude");
        #say "[$lat, $lon]";
        return ($lat, $lon);
    }
    else
    {
        warn "ERROR: " ~ $exifTool.GetValue('Error');
    }
    return ();
}

sub MAIN(Str :$src! , Str :$dest!, Str :$apikey)
{
    die "Source Directory $src not found" if ! $src.IO.d;
    die "Destination Directory $dest not found" if ! $dest.IO.d;

    my $url = getUrl("locationiq", $apikey);
    my $ua = HTTP::UserAgent.new(:useragent<firefox_linux>);

    my @files = dir $src;

    for @files.kv -> $idx, $file
    {
        say "[$idx/@files.elems()] $file.basename()";
        my ($lat, $lon) = getCoords($file);
        # TODO: cache bounding boxes
        if $lat.defined && $lon.defined && $lat !~~ "" && $lon !~~ ""
        {
            # wait few sec b/w each requests (nominatim TOC)
            sleep 0.5;
            #say $url ~ "format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1&accept-language=en-US";
            my $response = $ua.get($url ~ "format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1&accept-language=en-US");

            if $response.is-success
            {
                my $respStr = from-json( $response.content );
                #say $response.content;
                if $respStr{"address"}{"country"}
                {
                    my $lvl2="";
                    if $respStr{"address"}{"city"}
                    {
                        $lvl2 = $respStr{"address"}{"city"};
                    }
                    elsif $respStr{"address"}{"town"}
                    {
                        $lvl2 = $respStr{"address"}{"town"};
                    }
                    elsif $respStr{"address"}{"village"}
                    {
                        $lvl2 = $respStr{"address"}{"village"};
                    }
                    elsif $respStr{"address"}{"state"}
                    {
                        $lvl2 = $respStr{"address"}{"state"};
                    }
                    else
                    {
                        say "city/village/town not found ===> " ~ $respStr.perl;
                    }
                    my $country = $respStr{"address"}{"country"};
                    say " -> Moving to $dest/$country/$lvl2/$file.basename()";
                    mkdir "$dest/$country/$lvl2";
                    move $file, "$dest/$country/$lvl2/$file.basename()";
                }
                else
                {
                    warn "NO Country ===> " ~ $respStr.perl;
                }
            }
            else
            {
                warn $response;
            }
        }
    }
}
