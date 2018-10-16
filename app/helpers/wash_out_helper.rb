module WashOutHelper

  def wsdl_data_options(param)
    case controller.soap_config.wsdl_style
    when 'rpc'
      if param.map.present? || param.value
        { :"xsi:type" => param.namespaced_type }
      else
        { :"xsi:nil" => true }
      end
    when 'document'
      { }
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
    if (param.multiplied && param.optional)
       data = {
        "#{'xsi:' if inject}minOccurs" => 0,
        "#{'xsi:' if inject}maxOccurs" => 'unbounded',
        "#{'xsi:' if inject}nillable" => 'true'
      }

    elsif param.multiplied
      data = {
        "#{'xsi:' if inject}minOccurs" => 0,
        "#{'xsi:' if inject}maxOccurs" => 'unbounded'
      }
    elsif param.optional
      data = {"#{'xsi:' if inject}nillable" => 'true'}
      # data = {
      #   "#{'xsi:' if inject}minOccurs" => 0,
      # }
    else
      data = {}
    end

    extend_with.merge(data)
  end

  def wsdl_data(xml, params)
    Rails.logger.debug params 
    params.each do |param|
      tag_name = param.name

      if !param.struct?
        if param.multiplied
          param.value = [] unless param.value.is_a?(Array)
          param.value.each do |v|
            xml.tag! tag_name, v, "xsi:type" => param.namespaced_type
          end
        elsif param.optional
          if !param.value.nil?
            xml.tag! tag_name, param.value, "xsi:type" => param.namespaced_type
          end
        else
          xml.tag! tag_name, param.value, "xsi:type" => param.namespaced_type
        end
      else
        if param.multiplied
          param.map.each do |p|
            xml.tag! tag_name, "xsi:type" => param.namespaced_type do
              wsdl_data(xml, p.map)
            end
          end
        elsif param.optional
          if !param.map.empty?
              xml.tag! tag_name, "xsi:type" => param.namespaced_type do
                wsdl_data(xml, param.map)
              end
          end
        else
          xml.tag! tag_name, "xsi:type" => param.namespaced_type do
            wsdl_data(xml, param.map)
          end
        end
      end
    end
  end
end
