module WashOutHelper
  def wsdl_data(xml, param)
    if param.is_a? Hash
      wsdl_data xml, param.map
    else
      param.each do |opt, value|
        xml.tag! opt.name, value.to_s
      end
    end
  end

  def wsdl_type(xml, param)
    more = []

    if param.struct?
      return if param.value.blank?

      xml.complexType :name => param.name do
        xml.sequence do
          param.map.each do |key, value|
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

    extend_with.merge(data)
  end
end
