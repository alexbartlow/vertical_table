module VerticalTable
  module Attributes
    
    class AssociationMismatch < Exception ; end  
    
    def self.included(base)
      base.send :extend, VerticalTable::Attributes::ClassMethods
    end
    module ClassMethods
      def vertical_attributes_from(assoc, opts = {}, &block)
        raise AssociationMismatch unless [
          :has_many, :has_and_belongs_to_many
        ].include? self.reflections[assoc].macro
        b = VerticalTable::Attributes::MethodBuilder.new(assoc, self, opts)
        yield b
        
        if self.instance_methods.include?(:attributes)
          old_attributes = instance_method(:attributes)
          define_method(:attributes_with_vertical) do
            virtual_attributes = b.new_attributes.inject({}) do |hsh, nattr|
              hsh.update({nattr => self.send(nattr.to_s + "_object").send(opts[:value_attribute_get])})
            end
            old_attributes.bind(self).call().update(virtual_attributes).with_indifferent_access
          end
        end
      end
    end
    
    class MethodBuilder
      attr_accessor :assoc, :base, :opts, :new_attributes
      def initialize(association_name, base, opts)
        @assoc, @base, @opts = association_name, base, opts
        @new_attributes = []
        @opts[:value_attribute] ||= :value
        @opts[:value_attribute_get] ||= @opts[:value_attribute]
        @opts[:value_attribute_set] ||= (@opts[:value_attribute].to_s + "=").to_sym
      end
      
      def method_missing(sym, *args, &blk)
        @new_attributes << sym
        assoc, base = @assoc, @base
        scope = args.extract_options!
        
        create_scope = scope.dup
        # convert all of these to_s, or they'll get persisted as a yaml
        # for a symbol. yuck.
        scope.each_key do |k|
          create_scope[k] = create_scope[k].to_s
        end
        get_val = @opts[:value_attribute_get]
        set_val = @opts[:value_attribute_set]
        @base.class_eval do
          define_method sym.to_s + "_object" do
            object ||= self.send(assoc).detect do |candidate|
              create_scope.keys.all? do |key|
                candidate.send(key).to_s == create_scope[key].to_s
              end
            end 
            object ||= self.send(assoc).build(create_scope)
            object
          end
          define_method sym do
            self.send(sym.to_s + "_object").try(:send, get_val)
          end
          define_method (sym.to_s + "=").to_sym do |value|
            self.send(sym.to_s + "_object").try(:send, set_val, value)
          end
          
          alias_method sym.to_s + "_before_type_cast", sym
        end
      end
    end
  end
end