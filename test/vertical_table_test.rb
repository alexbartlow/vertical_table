require 'test_helper'

class VerticalTableTest < Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  context "Vertical table attributes declaration" do
    should "raise about trying to use a has_one association" do
      assert_raise VerticalTable::Attributes::AssociationMismatch do
        klass = Class.new(ActiveRecord::Base) do
          has_one :vertical
          include VerticalTable::Attributes
          vertical_attributes_from(:vertical) {}
        end
      end
    end
    
    should "raise about trying to use a belongs_to association" do
      assert_raise VerticalTable::Attributes::AssociationMismatch do
        klass = Class.new(ActiveRecord::Base) do
          belongs_to :vertical
          include VerticalTable::Attributes
          vertical_attributes_from(:vertical) {}
        end
      end
    end
        
    should "not raise about trying to use a has_many" do
      assert_nothing_raised VerticalTable::Attributes::AssociationMismatch do
        klass = Class.new(ActiveRecord::Base) do
          has_many :verticals
          include VerticalTable::Attributes
          vertical_attributes_from(:verticals) {}
        end
      end
    end
    
    should "give the base class setter methods" do
      %w{stat_str stat_dex stat_wis stat_int stat_cha}.each do |s|
        assert Normal.instance_methods.include?((s + "=").to_sym)
      end
    end
    
    should "define before_typecast for rails" do
      assert Normal.instance_methods.include?("stat_str_before_type_cast".to_sym)
    end
    
    should "give the base class getter methods" do
      %w{stat_str stat_dex stat_wis stat_int stat_cha}.each do |s|
        assert Normal.instance_methods.include?(s.to_sym)
      end
    end
  end
  
  context "vertical table attributes operations" do
    setup do
      @normal = Normal.create
    end
    
    should "add a record to the vertical table when " << 
    "setting a new attribute" do
      assert_difference 'Vertical.count' do
        @normal.stat_str = 18
        @normal.save
      end
    end
    
    should "have the added attribute be associated with the record" do
      @normal.update_attribute(:stat_str, 17)
      assert_equal 17, Vertical.last.value.to_i
      assert_equal @normal.id, Vertical.last.normal_id
    end
    
    should "build a vertical attribute on set" do
      @normal.stat_str = 18
      assert_equal 1, @normal.verticals.size
      assert_equal 18, @normal.verticals.last.value
      @normal.save && @normal.reload
      assert_equal 1, @normal.verticals.count
    end
    
    should "be able to retreive the set attribute" do
      @normal.update_attribute(:stat_str, 17)
      assert_equal 17, Normal.find(@normal.id).stat_str.to_i
    end
    
    should "set the scope when saving a new vertical attribute" do
      @normal.update_attribute(:stat_str, 17)
      obj = Normal.find(@normal.id).verticals.first
      
      assert_equal "stats", obj.category
      assert_equal "strength", obj.attribute
    end
    
    should "set the scope when saving a new wierd vertical attribute" do
      @normal.update_attribute(:stat_int, 18)
      obj = Normal.find(@normal.id).wierd_verticals.first
      
      assert_equal "stat_int", obj.preference_type
    end
    
    should "Add the virtual attributes to the attributes hash" do
      assert @normal.attributes.has_key?(:stat_int)
    end
    
    should "Still keep the normal attributes" do
      assert @normal.attributes.has_key?(:name), "Expected attributes to have name, instead was #{@normal.attributes.inspect}"
    end
    
    should "be able to set a vertical attribute using a custom value field" do
      assert_difference 'WierdVertical.count' do
        @normal.stat_int = 18
        @normal.save
      end
      assert_equal 1, Normal.find(@normal.id).wierd_verticals.count
      assert_equal 18, Normal.find(@normal.id).stat_int.to_i
    end
  end
end
