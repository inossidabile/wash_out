module WashOut
  module Model
    def wash_out_param_map
      types = {
        :text      => :string,
        :float     => :double,
        :decimal   => :double,
        :timestamp => :string
      }
      map = {}

      columns_hash.each do |key, column|
        type = column.type
        type = types[type] if types.has_key?(type)
        map[key] = type
      end

      map
    end

    def wash_out_param_name
      return name.underscore
    end
  end
end