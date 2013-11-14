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
          xml.tag! "xsd:sequence" do
            param.map.each do |value|
              more << value if value.struct?
              xml.tag! "xsd:element", wsdl_occurence(value, false, :name => value.name, :type => value.namespaced_type)
            end
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

  def get_complex_types_names(map)
    defined = []
    map.each do |operation, formats|
        (formats[:in] + formats[:out]).each do |p|
          defined << p.source_class_name unless p.source_class_name.nil?
        end
      end
    defined.sort_by { |name| name.downcase }.uniq
  end

  def get_fault_types_names(map)
    defined = []
    map.each do |operation, formats|
      faults = formats[:raises]
      unless faults.blank?
        faults = [formats[:raises]] if !faults.is_a?(Array)
         faults.each do |p|
          defined << p.to_s.classify
        end
      end
    end
    defined.sort_by { |name| name.downcase }.uniq
  end

  def get_soap_action_names(map)
    defined = []
    unless map.blank?
      map.each do |operation, formats|
        defined << operation.to_s
      end
    end
    defined.sort_by { |name| name.downcase }.uniq
  end
end
