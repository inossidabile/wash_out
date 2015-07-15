module WashOutHelper

  def wsdl_data_options(param)
    case controller.soap_config.wsdl_style
    when 'rpc'
      { :"xsi:type" => param.namespaced_type }
    when 'document'
      { }
    end
  end

  def wsdl_data(xml, params)
    params.each do |param|
      tag_name = param.name
      param_options = wsdl_data_options(param)

      if !param.struct?
        if !param.multiplied
          xml.tag! tag_name, param.value, param_options
        else
          param.value = [] unless param.value.is_a?(Array)
          param.value.each do |v|
            xml.tag! tag_name, v, param_options
          end
        end
      else
        if !param.multiplied
          xml.tag! tag_name,  param_options do
            wsdl_data(xml, param.map)
          end
        else
          param.map.each do |p|
            xml.tag! tag_name, param_options do
              wsdl_data(xml, p.map)
            end
          end
        end
      end
    end
  end

  def wsdl_type(xml, param, defined=[])
    more = []

    if param.struct?
      if !defined.include?(param.basic_type)
        xml.tag! "xsd:complexType", :name => param.basic_type do
          attrs, elems = [], []
          param.map.each do |value|
            more << value if value.struct?
            if value.attribute?
              attrs << value
            else
              elems << value
            end
          end

          if elems.any?
            xml.tag! "xsd:sequence" do
              elems.each do |value|
                xml.tag! "xsd:element", wsdl_occurence(value, false, :name => value.name, :type => value.namespaced_type)
              end
            end
          end

          attrs.each do |value|
            xml.tag! "xsd:attribute", wsdl_occurence(value, false, :name => value.attr_name, :type => value.namespaced_type)
          end
        end

        defined << param.basic_type
      elsif !param.classified?
        raise RuntimeError, "Duplicate use of `#{param.basic_type}` type name. Consider using classified types."
      end
    end

    more.each do |p|
      wsdl_type xml, p, defined
    end
  end

  def wsdl_occurence(param, inject, extend_with = {})
    data = !param.multiplied ? {} : {
      "#{'xsi:' if inject}minOccurs" => 0,
      "#{'xsi:' if inject}maxOccurs" => 'unbounded'
    }

    extend_with.merge(data)
  end
end
