require 'test_helper'

class TotalInsanityTest < Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  Person = Class.new(DbObject) do
    has_attributes :fname, :lname, :phone
  end
  
  should "allow me to use a person as if it had real attrs" do
    p = Person.create(:fname => "Alex", 
      :lname => "Bartlow", :phone => '8675309')
    assert_equal "Alex", p.fname
  end
end