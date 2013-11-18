xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.tag! "soap:Body" do
    xml.tag! "soap:Fault" do
      xml.faultcode error_faultcode
      xml.faultstring error_message
      xml.errors errors
    end
  end
end
