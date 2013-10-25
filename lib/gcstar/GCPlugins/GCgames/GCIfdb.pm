package GCPlugins::GCgames::GCIfdb;

###################################################
#
#  Copyright 2005-2013 Keith Rozett
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
    package GCPlugins::GCgames::GCPluginIfdb;
    use base 'GCPlugins::GCgames::GCgamesPluginsBase';
    use XML::Simple;

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless($self, $class);

        $self->{hasField} = {
            name => 1,
            released => 1
        };

        return $self;
    }

    sub parse
    {
        my ($self, $page) = @_;

        return unless $page =~ /^<\?xml/;

        if ($self->{parsingList})
        {
            $self->parseSearch($page);
        }
        else
        {
            $self->parseItem($page);
        }
    }

    sub parseSearch
    {
        my ($self, $page) = @_;
        my $xml;
        my $xs = XML::Simple->new;

        if ($page !~ m|<games></games>|)
        {
            $xml = $xs->XMLin(
                $page,
                ForceArray => ['game'],
                SuppressEmpty => ''
            );

            foreach my $game (@{$xml->{games}->{game}})
            {
                $self->{itemIdx}++;
                $self->{itemsList}[$self->{itemIdx}] =
                {
                    name     => $game->{title},
                    released => $game->{published}->{machine},
                    url      => $game->{link} . '&ifiction'
                };
            }
        }
    }

    sub parseItem
    {
        my ($self, $page) = @_;
        my $xml;
        my $xs = XML::Simple->new;

        # Turn HTML breaks into newlines
        $page =~ s:<br\s*/>:\n:gi;

        $xml = $xs->XMLin(
            $page,
            ForceArray => ['ifid'],
            SuppressEmpty => ''
        );

        return if !($xml->{story});

        # Simple fields
        $self->{curInfo}->{name}        = $xml->{story}->{bibliographic}->{title}          // '';
        $self->{curInfo}->{platform}    = $xml->{story}->{identification}->{format}        // '';
        $self->{curInfo}->{developer}   = $xml->{story}->{bibliographic}->{author}         // '';
        $self->{curInfo}->{released}    = $xml->{story}->{bibliographic}->{firstpublished} // '';
        $self->{curInfo}->{web}         = $xml->{story}->{ifdb}->{link};
        $self->{curInfo}->{boxpic}      = $xml->{story}->{ifdb}->{coverart}->{url}         // '';

        # IFDB returns a rating out of 5 stars, but GCstar wants it out of 10
        $self->{curInfo}->{ratingpress} = ($xml->{story}->{ifdb}->{starRating} * 2) // 0;

        # Treat IFID as a serial number (use the first if more than one are returned)
        $self->{curInfo}->{serialnumber} = $xml->{story}->{identification}->{ifid}->[0] // '';

        # Description is normally plain text but sometimes has HTML elements
        # If there are HTML elements, description will be a hash
        # Any remaining text will be a string or array of strings
        my $desc = $xml->{story}->{bibliographic}->{description} // '';
        if (ref($desc) eq 'HASH')
        {
            $desc = ref($desc->{content}) eq 'ARRAY' ? join('', @{$desc->{content}}) : $desc->{content};
        }
        $self->{curInfo}->{description} = $desc;

        # Genre can be a slash-separated list
        if ($xml->{story}->{bibliographic}->{genre})
        {
            foreach my $genre (split('/', $xml->{story}->{bibliographic}->{genre}))
            {
                # Trim whitespace
                $genre =~ s/^\s+//;
                $genre =~ s/\s+$//;
                push @{$self->{curInfo}->{genre}}, [ $genre ];
            }
        }
        else
        {
            $self->{curInfo}->{genre} = '';
        }

        # Map short format name to full name
        # These formats are listed in section 5.5.2 of the Treaty of Babel, Draft 7
        # (http://babel.ifarchive.org/babel_rev7.txt)
        # These may not be ideal for platforms, but it's what we've got
        my $platforms = {
            adrift     => 'ADRIFT',
            advsys     => 'AdvSys',
            agt        => 'AGT',
            alan       => 'Alan',
            executable => 'Executable',
            glulx      => 'Glulx',
            hugo       => 'Hugo',
            level9     => 'Level 9',
            magscrolls => 'Magnetic Scrolls',
            tads2      => 'TADS 2',
            tads3      => 'TADS 3',
            zcode      => 'Z-Machine',
        };
        $self->{curInfo}->{platform} = $platforms->{$xml->{story}->{identification}->{format}} // '';

        # Series and rank aren't part of the normal games model (as of 1.7.0)
        # But I added these fields with another patch of mine
        # So if you can use these fields, here you go :)
#        $self->{curInfo}->{serie} = $xml->{story}->{bibliographic}->{series}       // '';
#        $self->{curInfo}->{rank}  = $xml->{story}->{bibliographic}->{seriesnumber} // '';
    }

    sub getSearchUrl
    {
        my ($self, $word) = @_;
        return "http://ifdb.tads.org/search?xml&game&searchfor=$word";
    }

    sub getItemUrl
    {
        my ($self, $url) = @_;

        return $url if $url;
        return 'http://ifdb.tads.org/';
    }

    sub getTipsUrl
    {
        my $self = shift;

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
        return 'IFDB';
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
}

1;
