module WashOutHelper
  def wsdl_data(xml, param)
    if param.struct?
      param.value.values.each do |p|
        wsdl_data xml, p
      end
    else
      xml.tag! param.name, param.value.to_s
    end
  end
  
  def wsdl_type(xml, param)
    more = []
    
    if param.struct?
      return if param.value.blank?
      
      xml.complexType :name => param.name do
        xml.sequence do
          param.value.each do |key, value|
            more << value if value.struct?
            xml.element wsdl_occurence(value, :name => key, :type => value.namespaced_type)
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
      :minOccurs => 0,
      :maxOccurs => 'unbounded'
    }
    
    return extend_with.merge(data)
  end
end