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

Total Insanity
==============

    create_table :db_objects, :force => true do |t|
      t.string :type
    end

    create_table :db_attributes, :force => true do |t|
      t.integer :db_object_id
      t.string :key
      t.string :value
    end

    create_table :db_associations, :force => true do |t|
      t.string  :type
      t.integer :parent_id
      t.integer :child_id
    end
    
    class DbObject < ActiveRecord::Base
      has_many :db_attributes, :autosave => true
      include VerticalTable::Attributes

      def self.has_attributes(*attrs)
        vertical_attributes_from(:db_attributes) do |v|
          attrs.each do |a|
            v.send(a, :key => a)
          end
        end
      end

      def self.schemaless_association(assoc_name, source)
        schemaless_symbol = (assoc_name.to_s + "_schemaless").to_sym
        klass_name = assoc_name.to_s.classify
        self.const_set(klass_name, Class.new(DbAssociation))
        self.has_many schemaless_symbol, :class_name => klass_name, 
          :foreign_key => :parent_id
        self.has_many assoc_name,
          :through => schemaless_symbol,
          :source  => source
      end

      def self.schemaless_has_many(assoc_name)
        schemaless_association(assoc_name, :child)
      end

      def self.schemaless_belongs_to(assoc_name)
        schemaless_association(assoc_name, :parent)
      end
    end

    # id, db_object_id, key, value
    class DbAttribute < ActiveRecord::Base
      belongs_to :db_object
    end

    class DbAssociation < ActiveRecord::Base
      belongs_to :parent, :class_name => "DbObject"
      belongs_to :child,  :class_name => "DbObject"
    end
    
And now we can generate a bunch of schemaless classes:

    class TotalInsanityTest < Test::Unit::TestCase
      include ActiveSupport::Testing::Assertions
      class Person < DbObject
        has_attributes :fname, :lname, :phone
        schemaless_has_many :shit
      end
  
      class Crap < DbObject
        has_attributes :name, :description
        schemaless_belongs_to :person
      end
  
      should "allow me to use a person as if it had real attrs" do
        p = Person.create(:fname => "Alex", 
          :lname => "Bartlow", :phone => '8675309')
        assert_equal "Alex", p.fname
      end
  
      should "allow me to associate crap to a person" do 
        p = Person.create
        p.shit << Crap.new
        p.save
        assert_equal 1, Person.find(p).shit.size
      end
    end
    
Adding associations is an exercise to the reader.

Contributing
============

This is a simple plugin to solve a simple problem - but I welcome any changes, especially with associated test cases.

Copyright (c) 2010 Alexander Bartlow, released under the MIT license
