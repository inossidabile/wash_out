module WashOutHelper
  def wsdl_data(xml, params)
    params.each do |param|
      tag_name = "tns:#{param.name}"

      if !param.struct?
        if !param.multiplied
          xml.tag! tag_name, param.value, "xsi:type" => param.namespaced_type
        else
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

  def wsdl_type(xml, param)
    more = []

    if param.struct?
      xml.tag! "xsd:complexType", :name => param.name do
        xml.tag! "xsd:sequence" do
          param.map.each do |value|
            more << value if value.struct?
            xml.tag! "xsd:element", wsdl_occurence(value, :name => value.name, :type => value.namespaced_type)
          end
        end
      end
    end

    more.each do |p|
      wsdl_type xml, p
    end
  end

  def wsdl_occurence(param, extend_with = {})
    data = !param.multiplied ? {} : {
      "minOccurs" => 0,
      "maxOccurs" => 'unbounded'
    }

    extend_with.merge(data)
  end
end
