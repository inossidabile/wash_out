xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.tag! "soap:Body" do
    xml.tag! "soap:Fault" do
      xml.faultcode error_code
      xml.faultstring error_message
      xml.tag! "detail" do
        xml.tag! "#{@operation}Fault" do
          wsdl_data xml, detail
        end
      end unless detail.nil?
    end
  end
end
