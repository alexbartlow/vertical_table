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
        yield VerticalTable::Attributes::MethodBuilder.new(assoc, self, opts)
      end
    end
    
    class MethodBuilder
      attr_accessor :assoc, :base, :opts
      def initialize(association_name, base, opts)
        @assoc, @base, @opts = association_name, base, opts
        @opts[:value_attribute] ||= :value
        @opts[:value_attribute_get] ||= @opts[:value_attribute]
        @opts[:value_attribute_set] ||= (@opts[:value_attribute].to_s + "=").to_sym
      end
      
      def method_missing(sym, *args, &blk)
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
            self.send(assoc).all.find do |candidate|
              create_scope.keys.all? do |key|
                candidate.send(key).to_s == create_scope[key].to_s
              end
            end
          end
          define_method sym do
            value = instance_variable_get("@#{sym.to_s}")
            return value if value
            o = self.send(sym.to_s + "_object")
            instance_variable_set("@#{sym.to_s}", o.send(get_val)) if o
          end
          define_method (sym.to_s + "=").to_sym do |value|
            x = self.send(sym.to_s + "_object") ||
              self.send(assoc).build(create_scope)
            x.send(set_val, value)
            instance_variable_set("@#{sym.to_s}", value)
          end
          
          alias_method sym.to_s + "_before_type_cast", sym
        end
      end
    end
  end
end