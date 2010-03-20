VerticalTable
=============

Vertical tables are a technique for storing relatively free form data - where
the row contains one field of actual information, and then potentially many
pieces of meta-data, describing _what_ the stored field is. [I found a good blog post about it here.](http://weblogs.foxite.com/andykramek/archive/2009/05/03/8369.aspx)

However, ActiveRecord doesn't tend to like these structures that are at best handy and at worst the hold-over from some god-awful legacy schema. This plugin smoothes over a lot of the silliness entailed dealing with these tables, and give you standard attribute methods on an object using them.

Usage
=====

*  Create a `has_many` or `has_and_belongs_to_many` association to use to
hold all of your attributes, using the `:autosave` option.
*  Include the `VerticalTable::Attributes` module in your class
*  Declare all of the attributes to be stored in the vertical table inside a `vertical_attributes_from` block

Example
=======

    class CharacterInfo < ActiveRecord::Base
      belongs_to :role_playing_character
    end

    class RolePlayingCharacter < ActiveRecord::Base
      has_many :character_infos, :autosave => true
      include VerticalTable::Attributes
      vertical_attributes_from(:character_infos) do |v|
        v.stat_str :category => :stats, :attribute => :strength
        v.stat_dex :category => :stats, :attribute => :dexterity
        v.stat_wis :category => :stats, :attribute => :wisdom
        v.description :category => :fluff, :attribute => :description
      end
    end

    r = RolePlayingCharacter.new(:stat_str => 18)
    r.save
    r.reload.stat_str #=> "18"

Now, all of the methods declared inside of the vertical table block are
available to the `RolePlayingCharacter` as if they were on the table in the
first place.

In addition, you can use a hash passed to each attribute declaration to create
the meta-data. In the first three lines, we set the 'category' column to
stats, and the attribute column to the respective values.

Note that the returned value of 18 came back as a string. This plugin converts
everything to a string for storage in the table. If you'd like to handle the
values differently, consider writing your own Plain Old Ruby Object to handle
the formatting, and use
[composed_of](http://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html#M002198).

There's nothing stopping you from using as many vertical table associations as
you want. Go nuts.

Contributing
============

This is a simple plugin to solve a simple problem - but I welcome any changes or 

Copyright (c) 2010 Alexander Bartlow, released under the MIT license
