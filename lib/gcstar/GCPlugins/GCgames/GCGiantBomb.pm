package GCPlugins::GCgames::GCGiantBomb;

###################################################
#
#  Copyright 2005-2016 Keith Rozett
#
#  This file is part of GCstar.
#
#  GCstar is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  GCstar is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with GCstar; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#
###################################################

use strict;
use utf8;

use GCPlugins::GCgames::GCgamesCommon;
{
    package GCPlugins::GCgames::GCPluginGiantBomb;
    use base 'GCPlugins::GCgames::GCgamesPluginsBase';

    use JSON;

    my $apiBase         = 'http://www.giantbomb.com/api';
    my $webBase         = 'http://www.giantbomb.com';
    my $key             = '49a23f028df04c04ffe3ebcc2be9148fb923318c';
    my $searchFieldList = 'name,platforms,original_release_date,api_detail_url';
    my $itemFieldList   = 'name,image,images,platforms,publishers,developers,original_release_date,deck,site_detail_url,genres';

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless($self, $class);

        $self->{hasField} = {
            name => 1,
            released => 1,
            platform => 1,
        };

        return $self;
    }

    sub parse
    {
        my ($self, $page) = @_;

        return unless $page =~ /^{/;
        my $json = decode_json($page);

        if ($self->{parsingList})
        {
            $self->parseSearch($json);
        }
        else
        {
            $self->parseItem($json);
        }
    }

    sub parseSearch
    {
        my ($self, $json) = @_;

        foreach my $game (@{$json->{results}})
        {
            # Treat each platform as its own entry, even though a game only has one ID
            foreach my $platform (@{$game->{platforms}})
            {
                $self->{itemIdx}++;
                $self->{itemsList}[$self->{itemIdx}] = {
                    name     => $game->{name},
                    released => $self->dateOnly($game->{original_release_date}),
                    platform => $self->platformName($platform),
                    url      => "$game->{api_detail_url}?api_key=$key&format=json&field_list=$itemFieldList",
                };
            }
        }
    }

    sub parseItem
    {
        my ($self, $json) = @_;

        my $game = $json->{results};

        $self->{curInfo} = {
            name        => $game->{name},
            boxpic      => $game->{image}->{small_url},
            released    => $self->dateOnly($game->{original_release_date}),
            description => $game->{deck},
            web         => $game->{site_detail_url},
            editor      => join(', ', map { $_->{name} } @{$game->{publishers}}),
            developer   => join(', ', map { $_->{name} } @{$game->{developers}}),
            genre       => [ map { [ $_->{name} ] } @{$game->{genres}} ],
        };

        # If this is a new item, get the platform from what the user entered during search
        my $abbr;
        if (defined $self->{wantedIdx})
        {
            $self->{curInfo}->{platform} = $self->{itemsList}[$self->{wantedIdx}]->{platform};

            # Get the abbreviation of the platform
            my @matches = grep { $_->{name} eq $self->{curInfo}->{platform} || $_->{abbreviation} eq $self->{curInfo}->{platform} } @{$game->{platforms}};
            $abbr = $matches[0]->{abbreviation} if (@matches);
        }

        $self->getScreenshots($abbr, $game->{images});
    }

    sub getScreenshots
    {
        my ($self, $abbr, $images) = @_;

        # Prefer thumbnail size
        my $size = 'thumb_url';

        # Sort all the found images into buckets based on their tags.
        # Unfortunately GB doesn't have well-defined tags, just a few loose conventions.
        # Here are the buckets (higher number is a better match):
        # 2. @platform - platform screenshot (ex: 'NES screenshot')
        # 1. @screens  - screenshot (ex: 'screenshot')
        # 0. @general  - everything else

        my (@platform, @screens, @general);
        foreach my $image (@$images)
        {
            # If the tag contains some variant of the word 'screenshot' then it probably is one
            if ($image->{tags} =~ /screen ?shot/i)
            {
                # Plus if it has the platform abbreviation in it, it's ranked higher
                if ($abbr && $image->{tags} =~ /\b$abbr\b/i)
                {
                    push(@platform, $image->{$size});
                }

                # Otherwise it's a screenshot but possibly from another platform
                else
                {
                    push(@screens, $image->{$size});
                }
            }

            # General image, still worth saving if nothing better was found
            else
            {
                push(@general, $image->{$size});
            }

            # If we already got 2 platform screenshots, stop because we won't find anything better
            last if (@platform >= 2);
        }

        # Combine the buckets in order of precedence
        my @all = (@platform, @screens, @general);

        # Get the two best matches from the front
        $self->{curInfo}->{screenshot1} = shift(@all);
        $self->{curInfo}->{screenshot2} = shift(@all);
    }

    sub getSearchUrl
    {
        my ($self, $word) = @_;

        # Temporary hack to allow paging through large result sets
        #$word =~ s/%26page%3D(\d+)$//i;
        #my $page = $1 || 1;
        $word =~ s/%26offset%3D(\d+)$//i;
        my $offset = $1 || 0;

        return "$apiBase/games/?api_key=$key&format=json&field_list=$searchFieldList&filter=name:$word&offset=$offset";
    }

    sub getItemUrl
    {
        my ($self, $url) = @_;

        if (!$url)
        {
            # If we're not passed a url, return a hint so that gcstar knows what type
            # of addresses this plugin handles
            $url = $webBase;
        }
        elsif (index($url, $apiBase) < 0)
        {
            # Not an API URL, so let's try to grab a numeric ID
            if ($url =~ m|/([\d-]+)/?$|)
            {
                $url = "$apiBase/game/$1/?api_key=$key&format=json&field_list=$itemFieldList";
            }
        }
        return $url;
    }

    sub changeUrl
    {
        my ($self, $url) = @_;
        return $self->getItemUrl($url);
    }

    sub getTipsUrl
    {
        return '';
    }

    sub preProcess
    {
        my ($self, $html) = @_;

        return $html;
    }

    sub decodeEntitiesWanted
    {
        return 0;
    }

    sub getName
    {
        return 'Giant Bomb';
    }

    sub getAuthor
    {
        return 'KeroHazel';
    }

    sub getLang
    {
        return 'EN';
    }

    sub getCharset
    {
        return "UTF-8";
    }

    sub convertCharset
    {
        my ($self, $value) = @_;
        return $value;
    }

    sub getDefaultPictureSuffix
    {
        return '.jpg';
    }

    sub platformName
    {
        my ($self, $platform) = @_;

        # For a few well-known platforms with very long formal names, go with their abbreviations instead
        return $platform->{abbreviation} if ($platform->{abbreviation} =~ /^S?NES$/);

        # Otherwise the full name is best
        return $platform->{name};
    }

    sub dateOnly
    {
        my ($self, $date) = @_;

        # Remove the timestamp from a date/time string
        $date =~ s/ \d\d:\d\d:\d\d$//;
        return $date;
    }
}

1;
