module WashOutHelper
  def wsdl_data(xml, params)
    params.each do |param|
      tag_name = "tns:#{param.name}"

      if !param.struct?
        if !param.multiplied
          xml.tag! tag_name, param.value, "xsi:type" => param.namespaced_type
        else
          param.value = [] unless param.value.is_a?(Array)
          param.value.each do |v|
            xml.tag! tag_name, v, "xsi:type" => param.namespaced_type
          end
        end
      else
        if !param.multiplied
          xml.tag! tag_name, "xsi:type" => param.namespaced_type do
            wsdl_data(xml, param.map)
          end
        else
          param.map.each do |p|
            xml.tag! tag_name, "xsi:type" => param.namespaced_type do
              wsdl_data(xml, p.map)
            end
          end
        end
      end
    end
  end

  def wsdl_type(xml, param, types={})
    more = []

    if param.struct?
      name       = param.name
      param.name = param.name + types[param.name].to_s

      xml.tag! "xsd:complexType", :name => param.name do
        types[name] ||= 0
        types[name]  += 1

        xml.tag! "xsd:sequence" do
          param.map.each do |value|
            more << value if value.struct?
            xml.tag! "xsd:element", wsdl_occurence(value, false, :name => value.name, :type => value.namespaced_type)
          end
        end
      end
    end

    more.each do |p|
      wsdl_type xml, p, types
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
