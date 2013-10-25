package GCPlugins::GCTVepisodes::GCTVepisodesCommon;

###################################################
#
#  Copyright 2005-2010 Christian Jodar
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

our $MAX_ACTORS = 10;
our $MAX_DIRECTORS = 4;

use GCPlugins::GCPluginsBase;

{
    package GCPlugins::GCTVepisodes::GCTVepisodesPluginsBase;

    use base qw(GCPluginParser);
    
    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless ($self, $class);
        return $self;
    }
    
    sub getSearchFieldsArray
    {
        return ['series'];
    }

    sub loadUrl
    {
        my ($self, $url) = @_;
        
        $self->SUPER::loadUrl($url);

        if (! $self->{curInfo}->{title} && $self->{curInfo}->{original})
        {
            $self->{curInfo}->{title} = $self->{curInfo}->{original};
            $self->{curInfo}->{original} = '';
        }
        return $self->{curInfo};
    }
    
}

1;
