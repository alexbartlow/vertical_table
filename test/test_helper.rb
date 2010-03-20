require 'rubygems'
gem 'rails', '2.3.5'
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