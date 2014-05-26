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
      mapper = {}

      wash_out_columns.each do |key, column|
        type = column.type
        type = types[type] if types.has_key?(type)
        mapper[key] =  { :primitive => type, 
          :member_type => (column.respond_to?(:array) && column.array == true) ? "string" : nil,
          :nillable => column.respond_to?(:null) ? column.null : true,
          :minoccurs => required?( key) ? 1 : 0 ,
          :maxoccurs =>(column.respond_to?(:array) && column.array == true)  ? "unbounded" : 1
        };
      end

      mapper
    end
    
   def map
     wash_out_param_map
   end
    
    def required?( attr)
      validators_on(attr).map(&:class).include?(
        ActiveModel::Validations::PresenceValidator)
    end

    def wash_out_param_name(*args)
      return name.underscore
    end
  end
end