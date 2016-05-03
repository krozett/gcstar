package GCPlugins::GCbooks::GCGoogleBooks;

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

use GCPlugins::GCbooks::GCbooksCommon;
{
    package GCPlugins::GCbooks::GCPluginGoogleBooks;
    use base qw(GCPlugins::GCbooks::GCbooksPluginsBase);

    use JSON;

    my $apiBase         = 'https://www.googleapis.com/books/v1';
    my $webBase         = 'http://books.google.com';
    my $searchFieldList = 'items(selfLink,volumeInfo(authors,publishedDate,title))';
    my $itemFieldList   = 'volumeInfo(authors,averageRating,canonicalVolumeLink,categories,description,imageLinks,industryIdentifiers,language,pageCount,publishedDate,publisher,title)';
    my @imgSizes        = ( 'small', 'thumbnail', 'smallThumbnail' );

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless($self, $class);

        $self->{hasField} = {
            title => 1,
            authors => 1,
            publication => 1,
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

        foreach my $item (@{$json->{items}})
        {
            my $book = $item->{volumeInfo};
            my $authors = $book->{authors} // [];

            $self->{itemIdx}++;
            $self->{itemsList}[$self->{itemIdx}] = {
                title       => $book->{title},
                authors     => join(', ', @$authors),
                publication => $book->{publishedDate},
                url         => "$item->{selfLink}?source=gcstar&fields=$itemFieldList"
            };
        }
    }

    sub parseItem
    {
        my ($self, $json) = @_;

        my $book       = $json->{volumeInfo};
        my $authors    = $book->{authors}    // [];
        my $categories = $book->{categories} // [];

        $self->{curInfo} = {
            title       => $book->{title},
            authors     => [ map { [ $_ ] } @$authors ],
            publisher   => $book->{publisher},
            publication => $book->{publishedDate},
            language    => $book->{language},
            genre       => [ map { [ $_ ] } @$categories ],
            description => $book->{description},
            pages       => $book->{pageCount},
            web         => $book->{canonicalVolumeLink},
            # Rating is between 1 and 5, normalize to 0-10
            rating      => int(((($book->{averageRating} // 1) - 1) * 2.5) + 0.5)
        };

        # Prefer ISBN-13, but ISBN-10 will do
        my ($isbn_13, $isbn_10);
        foreach my $id (@{$book->{industryIdentifiers}})
        {
            $isbn_10 = $id->{identifier} if ($id->{type} eq 'ISBN_10');
            $isbn_13 = $id->{identifier} if ($id->{type} eq 'ISBN_13');
        }

        if (defined $isbn_13)
        {
            $self->{curInfo}->{isbn} = $isbn_13;
        }
        elsif (defined $isbn_10)
        {
            $self->{curInfo}->{isbn} = $isbn_10;
        }

        # Try to get a good-sized image, going by imgSizes in order of preference
        foreach my $size (@imgSizes)
        {
            if ($book->{imageLinks}->{$size})
            {
                $self->{curInfo}->{cover} = $book->{imageLinks}->{$size};
                last;
            }
        }
    }

    sub getSearchUrl
    {
        my ($self, $word) = @_;

        my $type = $self->{searchField} eq 'isbn' ? 'isbn' : 'intitle';

        return "$apiBase/volumes?printType=books&source=gcstar&fields=$searchFieldList&q=$type:$word";
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
            # Not an API URL, so let's try to grab an ID
            if ($url =~ /[&?]id=([^&]+)/)
            {
                $url = "$apiBase/volumes/$1?source=gcstar&fields=$itemFieldList";
            }
        }

        return $url;
    }

    sub changeUrl
    {
        my ($self, $url) = @_;
        return $self->getItemUrl($url);
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
        return 'Google Books';
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

    sub getSearchFieldsArray
    {
        return ['isbn', 'title'];
    }
}

1;
