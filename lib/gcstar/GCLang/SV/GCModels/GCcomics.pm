{
    package GCLang::SV::GCModels::GCcomics;

    use utf8;
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
    use base 'Exporter';

    our @EXPORT = qw(%lang);

    our %lang = (
    
        CollectionDescription => 'Comics collection',
        Items => {0 => 'Comics',
                  1 => 'Comic',
                  X => 'Comics'},
        NewItem => 'New comic',
    
    
        Id => 'Id',
        Name => 'Name',
        Series => 'Series',
        Volume => 'Volume',
        Title => 'Title',
        Writer => 'Writer',
        Illustrator => 'Illustrator',
        Colourist => 'Colourist',
        Publisher => 'Publisher',
        Synopsis => 'Synopsis',
        Collection => 'Collection',
        PublishDate => 'Publish Date',
        PrintingDate => 'Printing Date',
        ISBN => 'ISBN',
        Type => 'Type',
		Category => 'Category',
        Format => 'Format',
        NumberBoards => 'Number of Boards',
		Signing => 'Signing',
        Cost => 'Cost',
        Rating => 'Rating',
        Comment => 'Comments',
        Url => 'Web page',

        FilterRatingSelect => 'Rating At _Least...',

        Main => 'Main items',
        General => 'General',
        Details => 'Details',
     );
}

1;
