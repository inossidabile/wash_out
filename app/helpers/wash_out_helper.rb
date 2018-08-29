module WashOutHelper

  def wsdl_data_options(param)
    case controller.soap_config.wsdl_style
      when 'rpc'
        if param.map.present? || !param.value.nil?
          {:"xsi:type" => param.namespaced_type}
        else
          {:"xsi:nil" => true}
        end
      when 'document'
        {}
    end
  end

  def wsdl_data_attrs(param)
    param.map.reduce({}) do |memo, p|
      if p.respond_to?(:attribute?) && p.attribute?
        memo.merge p.attr_name => p.value
      else
        memo
      end
    end
  end

  def wsdl_data(xml, params)
    params.each do |param|
      next if param.attribute?

      tag_name = param.name
      param_options = wsdl_data_options(param)
      param_options.merge! wsdl_data_attrs(param)

      if param.struct?
        if param.multiplied
          if param.map.size == 0
            # skip
          else
            xml.tag! tag_name, "soap-enc:arrayType" => param.array_instance_type, "xsi:type" => "soap-enc:Array" do
              param.map.each do |p|
                attrs = wsdl_data_attrs p
                if p.is_a?(Array) || p.map.size > attrs.size
                  blk = proc { wsdl_data(xml, p.map) }
                end
                attrs.reject! { |_, v| v.nil? }
                xml.tag! "Item", &blk #todo add array level object
              end
            end
          end
        else
          xml.tag! tag_name, param_options do
            wsdl_data(xml, param.map)
          end
        end
      else
        if param.multiplied
          param.value = [] unless param.value.is_a?(Array)
          xml.tag! tag_name, "soap-enc:arrayType" => param.array_instance_type, "xsi:type" => "soap-enc:Array" do
            param.value.each do |v|
              xml.tag! "Item", v
            end
          end
        else
          xml.tag! tag_name, param.string_value, param_options
        end
      end
    end
  end


  def wsdl_type(xml, param, defined=[])
    more = []
    if param.struct?
      if !defined.include?(param.basic_type)
        wsdl_basic_type(xml, param, defined)
        wsdl_array_type(xml, param)
        defined << param.basic_type
      elsif !param.classified?
        raise RuntimeError, "Duplicate use of `#{param.basic_type}` type name. Consider using classified types."
      end
    elsif param.multiplied
      if !defined.include?(param.array_type)
        wsdl_array_type(xml, param)
        defined << param.array_type
      end
    end
  end

  def wsdl_parameter(param)
    if param.multiplied
      {:name => param.name, :type => param.namespaced_type}
    else
      wsdl_occurence(param, true, :name => param.name, :type => param.namespaced_type)
    end
  end

  private


  def wsdl_basic_type(xml, param, defined)
    more = []
    xml.tag! "xsd:complexType", :name => param.basic_type do
      attrs, elems = [], []
      param.map.each do |value|
        more << value if value.struct? || value.multiplied
        if value.attribute?
          attrs << value
        else
          elems << value
        end
      end
      if elems.any?
        xml.tag! "xsd:sequence" do
          elems.each do |value|
            if value.multiplied
              wsdl_array_of(xml, value)
            else
              xml.tag! "xsd:element", wsdl_occurence(value, true, :name => value.name, :type => value.namespaced_type)
            end
          end
        end
      end
      attrs.each do |value|
        xml.tag! "xsd:attribute", wsdl_occurence(value, true, :name => value.attr_name, :type => value.namespaced_type)
      end
    end
    more.each do |p|
      wsdl_type xml, p, defined
    end
  end

  #
  # .Net soap helper type for array of type
  #
  def wsdl_array_of(xml, param)
    if param.struct?
      xml.tag! "xsd:element", :name => param.name, :type => param.namespaced_type
    else
      xml.tag! "xsd:element", wsdl_occurence(param, true, :name => param.name, :type => param.namespaced_type)
    end
  end

  def wsdl_array_type(xml, param)
    xml.tag! "xsd:complexType", :name => param.array_type do
      xml.tag! "xsd:complexContent" do
        xml.tag! "xsd:restriction", base: "soap-enc:Array" do
          xml.tag! "xsd:attribute", {"ref" => "soap-enc:arrayType",
                                     "wsdl:arrayType" => "#{param.namespaced_basic_type}[]"}

        end
      end
    end
  end


  def wsdl_occurence(param, inject, extend_with = {})
    data = {"#{'xsi:' if inject}nillable" => 'true'}
    if param.multiplied
      data["#{'xsi:' if inject}minOccurs"] = 0
      data["#{'xsi:' if inject}maxOccurs"] = 'unbounded'
    end
    extend_with.merge(data)
  end

end
