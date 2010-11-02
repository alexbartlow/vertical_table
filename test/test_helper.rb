require 'rubygems'
gem 'rails', '~>2.3'
require 'active_support'
require 'active_support/testing/assertions'
require 'active_record'
require 'test/unit'
require 'shoulda'
require 'logger'
require 'vertical_table'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])
ActiveRecord::Base.store_full_sti_class = true
ActiveRecord::Schema.define(:version => 0) do
  create_table :verticals, :force => true do |t|
    t.integer :normal_id
    t.string  :category
    t.string  :attribute
    t.string  :value
  end
  
  create_table :wierd_verticals, :force => true do |t|
    t.integer :normal_id
    t.string :preference_type
    t.string :setting
  end
  
  create_table :normals, :force => true do |t|
    t.string :name
  end
  
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
  
  def self.define_association_class(parent_class_name, child_class_name)
    name = parent_class_name + "_" + child_class_name
    name = name.classify
  
    unless self.const_defined(name)
      self.const_set(name, Class.new(DbAssociation))
    end
    name
  end
  
  def self.schemaless_has_many(assoc_name, klass)
    schemaless_symbol = (assoc_name.to_s + "_schemaless").to_sym
    
    association_class_name = klass.constantize.define_association_class(self.to_s, klass)
  
    self.has_many schemaless_symbol, :class_name => association_class_name, 
      :foreign_key => :parent_id
    self.has_many assoc_name,
      :through => schemaless_symbol,
      :source  => :child
  end
  
  def self.schemaless_belongs_to(assoc_name, klass)
    schemaless_symbol = (assoc_name.to_s + "_schemaless").to_sym
    
    association_class_name = klass.constantize.define_association_class(klass, self.to_s)
    
    self.has_many schemaless_symbol, :class_name => association_class_name, 
      :foreign_key => :parent_id
    self.has_many assoc_name,
      :through => schemaless_symbol,
      :source  => :parent
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

class Vertical < ActiveRecord::Base
  belongs_to :normal
end

class WierdVertical < ActiveRecord::Base
  belongs_to :normal
end

class Normal < ActiveRecord::Base
  has_many :verticals, :autosave => true
  include VerticalTable::Attributes
  vertical_attributes_from(:verticals) do |v|
    v.stat_str :category => :stats, :attribute => :strength
    v.stat_dex :category => :stats, :attribute => :dexterity
    v.stat_wis :category => :stats, :attribute => :wisdom
  end
  has_many :wierd_verticals, :autosave => true
  vertical_attributes_from(:wierd_verticals, :value_attribute => :setting) do |v|
    v.stat_int :preference_type => :stat_int
    v.stat_cha :preference_type => :stat_cha
  end
end