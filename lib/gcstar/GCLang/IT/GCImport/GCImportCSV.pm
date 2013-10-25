{
    package GCLang::IT::GCImport::GCImportCSV;

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
#######################################################
#
#  v1.0.2 - Italian localization by Andreas Troschka
#
#  for GCstar v1.1.1
#
#######################################################

    
    use strict;
    use base 'Exporter';

    our @EXPORT = qw(%lang);

    our %lang = (
        'Charset' => 'Charset',
        'Header' => 'Ignora la prima linea',
        'Separator' => 'Delimitatore',
        'Plugin' => 'Lato da utilizzare',
        'UseFirst' => 'In caso di piu\' risultati utilizza il primo',
        'SearchField' => 'Search for items using',
     );
}

1;
