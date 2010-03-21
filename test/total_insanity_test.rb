require 'test_helper'

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