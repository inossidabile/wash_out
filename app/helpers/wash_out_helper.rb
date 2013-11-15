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



  def get_complex_class_name(p, defined = [])
    complex_class = nil
    if !p.source_class_name.nil?  # it is a class and has ancestor WashOut::Type
      complex_class=  p.source_class_name
    elsif p.type == "struct" && !p.source_class.blank?    # it is a class
      complex_class = p.source_class
    elsif p.type == "struct" #TODO figure out a way to avoid collissions for hashes
      complex_class = p.name.classify
    end
    unless complex_class.nil? && defined.blank?
      timestamp = defined.blank? ? p.timestamp : Time.now.to_i 

      found = false
      defined.each do |hash|
        found = true if hash[:class] == complex_class
      end
      if found == true && p.type =="struct"
       # found a nested hash or a class
        complex_class = complex_class+timestamp.to_s
        p.timestamp = timestamp
      end
    end
    return complex_class
  end


  def get_complex_types(map)
    defined = []
    map.each do |operation, formats|
      (formats[:in] + formats[:out]).each do |p|
        complex_class = get_complex_class_name(p, defined)
        defined << {:class =>complex_class, :obj => p} unless complex_class.nil?
        if washout_param_is_complex?(p)
          c_names = []
          p.map.each do |obj|
            complex_class = get_complex_class_name(obj, defined)
            defined << {:class =>complex_class, :obj => obj} unless complex_class.nil?
          end
          defined.concat(c_names)
        end
      end
    end
    defined.sort_by { |hash| hash[:class].downcase }.uniq
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


  def washout_param_is_complex?(p)
    !p.source_class_name.nil? || (p.type == "struct" && !p.source_class.blank?) || p.type =="struct" # it is a class and has ancestor WashOut::Type
  end

  def create_html_complex_types(xml, map)
    map.each do |operation, formats|
      (formats[:in] + formats[:out]).each do |p|
        if  washout_param_is_complex?(p)
          create_type_html(xml, p)
        end
      end
    end
  end

  def create_element_html(xml, element)

  end

  def create_type_html(xml, param)
    complex_class = get_complex_class_name(param)
    xml.a( "name" => "#{complex_class}")  { }
    if param.is_a?(Array)
      xml.p  { |y|
        y << "This is an array type of <span class='pre'>";
        if WashOut::Type::BASIC_TYPES.include?(param[0].class.to_s.downcase)
          xml.span("class" => "blue") {  "#{param[0].class.to_s}" }
        else
          xml.a("href" => "##{param[0].source_class_name}") { |x| x << "<span class='lightBlue'>#{param[0].source_class_name}</span>" }
        end
      }
    elsif param.is_a?(WashOut::Param)
      raise YAML::dump(param)

    end

  end

  def create_html_fault_types_details(xml, map)
    unless map.blank?
      map.sort_by { |operation, formats| formats[:raises].to_s.downcase }.uniq
      map.each do |operation, formats|
        faults = formats[:raises]
        unless faults.blank?
          faults = [formats[:raises]] if !faults.is_a?(Array)
          faults.each do |p|
            create_html_fault_type(xml, p)
          end
        end
      end
    end
  end

  def create_html_fault_type(xml, param)


  end

  def create_html_public_methods(xml, map)
    unless map.blank?
      map =map.sort_by { |operation, formats| operation.downcase }.uniq

      map.each do |operation, formats|
        create_html_public_method(xml, operation, formats)
      end
    end
  end



  def create_html_public_method(xml, operation, formats)
    # raise YAML::dump(formats[:in])
    xml.h3 "#{operation}"
    xml.a("name" => "#{operation}") {}

    xml.p("class" => "pre"){ |pre|
      if !formats[:out].nil?
        if WashOut::Type::BASIC_TYPES.include?(formats[:out][0].type)
          xml.span("class" => "blue") { |y| y<<  "#{formats[:out][0].type}" }
        else
          xml.a("href" => "##{formats[:out][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:out][0].type}" } }
        end
      else
        pre << "void"
      end

      xml.span("class" => "bold") {|y|  y << "#{operation} (" }
      mlen = formats[:in].size
      xml.br if mlen > 1
      spacer = "&nbsp;&nbsp;&nbsp;&nbsp;"
      if mlen > 0
        j=0
        while j<mlen
          param = formats[:in][j]
          use_spacer =  mlen > 1 ? true : false
          if WashOut::Type::BASIC_TYPES.include?(param.type)
            pre << "#{use_spacer ? spacer: ''}<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            complex_class = get_complex_class_name(param)
            unless complex_class.nil?
              pre << "#{use_spacer ? spacer: ''}<a href='##{complex_class}'><span class='lightBlue'>#{complex_class}<span></a>&nbsp;<span class='bold'>#{param.name}</span>"
            end
          end
          if j< (mlen-1)
            xml.span ", "
          end
          if mlen > 1
            xml.br
          end
          if (j+1) == mlen
            xml.span("class" => "bold") {|y|  y << ")" }
          end
          j+=1
        end

      end



    }
    xml.p "#{formats[:description]}" if !formats[:description].blank?
    xml.p "Parameters:"

    xml.ul {
      j=0
      mlen = formats[:in].size
      while j<mlen
        param = formats[:in][j]
        xml.li("class" => "pre") { |pre|
          if WashOut::Type::BASIC_TYPES.include?(param.type)
            pre << "<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            complex_class = get_complex_class_name(param)
            unless complex_class.nil?
              pre << "<a href='##{complex_class}'><span class='lightBlue'>#{complex_class}<span></a>&nbsp;<span class='bold'>#{param.name}</span>"
            end
          end
        }
        j+=1
      end

    }

    xml.p "Return value:"
    xml.ul {
      xml.li {
        if !formats[:out].nil?

          if WashOut::Type::BASIC_TYPES.include?(formats[:out][0].type)
            xml.span("class" => "pre") { |xml| xml.span("class" => "blue") { |sp| sp << "#{formats[:out][0].type}" } }
          else
            xml.span("class" => "pre") { xml.a("href" => "##{formats[:out][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:out][0].type}" } } }
          end
        else
          xml.span("class" => "pre") { |sp| sp << "void" }
        end

      }
    }
    unless formats[:raises].blank?
      faults = formats[:raises]
      faults = [formats[:raises]] if !faults.is_a?(Array)

      xml.p "Exceptions:"
      xml.ul {
        faults.each do |p|
          xml.li("class" => "pre"){ |y| y<< "<a href='##{p.to_s.classify}'><span class='lightBlue'> #{p.to_s.classify}</span></a>" }
        end
      }
    end
  end

end
