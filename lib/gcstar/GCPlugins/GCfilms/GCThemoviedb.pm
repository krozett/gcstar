package GCPlugins::GCfilms::GCthemoviedb;

###################################################
#
#  Copyright 2005-2016 Keith Rozett
#
#  Based on earlier work by Christian Jodar (Zombiepig).
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

use GCPlugins::GCfilms::GCfilmsCommon;
{
    package GCPlugins::GCfilms::GCPluginThemoviedb;

    use base 'GCPlugins::GCfilms::GCfilmsPluginsBase';
    use JSON;

    my $apiBase = 'http://api.themoviedb.org/3';
    my $webBase = 'http://www.themoviedb.org';
    my $imgBase = 'http://image.tmdb.org/t/p';
    my $imgSize = 'w500';
    my $key     = '9fc8c3894a459cac8c75e3284b712dfc';

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless($self, $class);

        $self->{hasField} = {
            title    => 1,
            date     => 1,
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

        foreach my $movie (@{$json->{results}})
        {
            $self->{itemIdx}++;
            $self->{itemsList}[$self->{itemIdx}] = {
                title => $movie->{title},
                date  => $movie->{release_date},
                url   => $self->idToApiUrl($movie->{id}),
            };

            # If the movie's title and original title differ (such as with language differences),
            # offer the user the original title as a separate entry
            if ($movie->{title} ne $movie->{original_title})
            {
                $self->{itemIdx}++;
                $self->{itemsList}[$self->{itemIdx}] = {
                    title => $movie->{original_title},
                    date  => $movie->{release_date},
                    url   => $self->idToApiUrl($movie->{id}),
                };
            }
        }
    }

    sub parseItem
    {
        my ($self, $movie) = @_;

        my $title    = $movie->{title};
        my $original = $movie->{original_title};
        my $selected = $self->{itemsList}[$self->{wantedIdx}]->{title};

        # If the title matches the original title, no need to store it
        if ($title eq $original)
        {
            $original = '';
        }

        # If the movie's title doesn't match what the user selected (i.e. they picked the original title),
        # then use their selection as the real title, and tmdb's translated title as the original
        elsif ($selected && ($title ne $selected))
        {
            $original = $title;
            $title    = $selected;
        }

        $self->{curInfo}->{title}       = $title;
        $self->{curInfo}->{original}    = $original;
        $self->{curInfo}->{date}        = $movie->{release_date};
        $self->{curInfo}->{time}        = "$movie->{runtime} mins";
        $self->{curInfo}->{image}       = "$imgBase/${imgSize}$movie->{poster_path}" if ($movie->{poster_path});
        $self->{curInfo}->{synopsis}    = $movie->{overview};
        $self->{curInfo}->{webPage}     = $self->idToWebUrl($movie->{id});
        $self->{curInfo}->{ratingpress} = int($movie->{vote_average} + 0.5);

        $self->{curInfo}->{country}   = [ map { $_->{name} } @{$movie->{production_countries}} ];
        $self->{curInfo}->{genre}     = [ map { $_->{name} } @{$movie->{genres}} ];

        # The director(s) are buried in the crew somewhere - let's find them
        $self->{curInfo}->{director} = join(', ', map { $_->{name} } grep { $_->{job} eq 'Director' } @{$movie->{credits}->{crew}});

        # Grab the first MAX_ACTORS actors
        splice(@{$movie->{credits}->{cast}}, $GCPlugins::GCfilms::GCfilmsCommon::MAX_ACTORS);
        $self->{curInfo}->{actors} = [ map { [ $_->{name}, $_->{character} ] } @{$movie->{credits}->{cast}} ];
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
            if ($url =~ m|/movie/(\d+)|)
            {
                $url = $self->idToApiUrl($1);
            }
        }
        return $url;
    }

    sub idToApiUrl
    {
        my ($self, $id) = @_;

        return "$apiBase/movie/$id?api_key=$key&append_to_response=credits&language=" . $self->siteLanguage();
    }

    sub idToWebUrl
    {
        my ($self, $id) = @_;

        return "$webBase/movie/$id?language=" . $self->siteLanguage();
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

    sub getSearchUrl
    {
        my ($self, $word) = @_;
        return "$apiBase/search/movie?api_key=$key&language=" . $self->siteLanguage() . "&query=$word";
    }

    sub changeUrl
    {
        my ($self, $url) = @_;
        # Make sure the url is for the api, not the main movie page
        return $self->getItemUrl($url);
    }

    sub siteLanguage
    {
        my $self = shift;

        return 'en';
    }

    sub getName
    {
        return "The Movie DB";
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
        my $self = shift;

        return "UTF-8";
    }

    sub getSearchCharset
    {
        my $self = shift;

        # Need urls to be double character encoded
        return "utf8";
    }

    sub convertCharset
    {
        my ($self, $value) = @_;
        return $value;
    }

    sub getNotConverted
    {
        my $self = shift;
        return [];
    }

    sub isPreferred
    {
        return 1;
    }

    sub needsLanguageTest
    {
        return 1;
    }

    sub testURL
    {
        my ($self, $url) = @_;

        # If the URL lacks a language, assume English
        $url .= '?language=en' if ($url !~ /\?language=/);

        my $lang = $self->siteLanguage();
        return $url =~ /\?language=$lang$/;
    }
}

1;
