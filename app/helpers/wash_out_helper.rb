module WashOutHelper
  def wsdl_data(xml, params)
    params.each do |param|
      if param.multiplied
        param.value.each{|v| wsdl_data_value xml, param, v}
      else
        wsdl_data_value xml, param
      end
    end
  end
  
  def wsdl_data_value(xml, param, value=false)
    value  ||= param.value.to_s
    tag_name = "tns:#{param.name}"
    
    if param.struct?
      xml.tag! tag_name, "xsi:type" => param.namespaced_type do
        wsdl_data(xml, param.map)
      end
    else
      xml.tag! tag_name, value, "xsi:type" => param.namespaced_type
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
      "xsi:minOccurs" => 0,
      "xsi:maxOccurs" => 'unbounded'
    }

    extend_with.merge(data)
  end
end
