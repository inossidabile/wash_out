module WashOut
  module Model
   
    def wash_out_columns
      columns_hash
    end

    def wash_out_param_map
      types = {
        :text      => :string,
        :float     => :double,
        :decimal   => :double,
        :timestamp => :string
      }
      map = {}

      wash_out_columns.each do |key, column|
        type = column.type
        type = types[type] if types.has_key?(type)
        map[key] =  { :primitive => type, 
          :member_type => (column.respond_to?(:array) && column.array == true) ? "string" : nil,
          :nillable => column.null,
          :minoccurs => required?(self.class, key) ? 1 : 0 ,
          :maxoccurs =>(column.respond_to?(:array) && column.array == true)  ? "unbounded" : 1
        };
      end

      map
    end
    
    def required?(obj, attr)
      target = (obj.class == Class) ? obj : obj.class
      target.validators_on(attr).map(&:class).include?(
        ActiveModel::Validations::PresenceValidator)
    end

    def wash_out_param_name(*args)
      return name.underscore
    end
  end
end